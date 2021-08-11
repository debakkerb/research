# Private GKE in Shared VPC

The purpose of this code base is to create a Shared VPC, with 2 subnets and 2 GKE clusters in each subnet.  We are going to use a custom service account for the node pools, so that we don't use the default Compute service account, which is overprivileged.

We are not going to use any Terraform modules, as it's difficult to understand what is happening in this approach.  This guide will walk you through all the components that are required to replicate the architecture described in the following section.

There is already a [great article](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-shared-vpc) out there that describes all the individual steps in more detail.  However, it uses `gcloud`-commands and it doesn't elaborate on some steps as much as I would like to.

## Components
![Architecture](./architecture)

The following components will be created as part of this article:
- Host project
- Service project (2)
- Network and subnets (2)
- Custom service account (2) for the node pools (2)
- GKE cluster (2)

## Service Account
Normally, the GKE cluster runs with the default Compute service account.  Because this service account has very open permissions (Editor-role), I recommend teams to remove those permissions.

This can be done via an organization policy:

```terraform
resource "google_organization_policy" "remove_default_iam_grants" {
  org_id     = var.organization_id
  constraint = "constraints/iam.automaticIamGrantsForDefaultServiceAccounts"
  boolean_policy {
    enforced = false
  }
}
```

The consequence is that the process to create a GKE cluster can't fall back on the default Compute service account to perform necessary operations.  We therefore will create custom service accounts and assign the necessary permissions to these service accounts.  This will allow us to tightly control what these identities can do, making the overall architecture more secure.

## IAM

By using Shared VPC and creating a custom service account, this topic needs a bit more background information, as not everything is documented clearly on our public documentation.

Normally, GKE uses the default Compute service account, which receives Editor permissions on the project at creation time.  However, as mentioned in the introduction, this violates the principle of least privilege and we typically recommend not to use that.  So we will create a custom service account for the cluster.

In addition to this service account, enabling the Container API on the project will also result in two service accounts being created.   These are very important and shouldn’t be tampered with, as this will cause all operations to fail.

### Google Kubernetes Engine Service Account

When enabling the container-api, a service account is automatically created in the form of `service-[PROJECT_NMBR]@container-engine-robot.iam.gserviceaccount.com`.   This service account gives permissions to the Kubernetes Engine control plane to take action on the customer’s behalf on resources in the customer’s project.  Any action that touches customer project resources relies on this account (e.g. creating clusters, creating the peering connection with the network hosting the control plane).

From a Shared VPC perspective, the GKE control plane uses the robot account in the Host project to create firewall rules and routes in the network.  In the Service project(s), the service account is used for all other resources, i.e. instance templates and managed instance groups.  Additionally, the Service Robot from the Service project has to have the `roles/compute.networkUser`-role on the host project (either on a per subnet level or on the network itself), as otherwise it can’t deploy any virtual machines (i.e. nodes) in the Host network.

If you run `gcloud projects get-iam-policy [PROJECT_ID]`, you’ll notice that the role `roles/container.serviceAgent` is assigned to the service account.   You can run `gcloud iam roles describe roles/container.serviceAgent` to list all the permissions assigned to the role.

### Firewall Rules

Firewall rules and routes are managed at the Host-project, so they can only be modified by the robot belonging to the Host project.  If teams are ok with this, they can grant the `Security Admin`-role to the Robot service account in the Service project.
### Google APIs service account

Additionally to the previous service accounts, another one is created: `Google APIs service account`.  It takes the form of `PROJECT_NUMBER@cloudservices.gserviceaccount.com` and is used to call other Google APIs.

It’s not entirely clear what this service account is being used for, but for example creating node pools fails if this service account doesn't have the necessary permissions.  Presumably because it's being used to create the managed instance groups for node pools.

## Configuration

### Projects

To keep this configuration easy to manage, we will go for 3 projects, one host project and two service projects.  Later on we can extend this by adding more service projects, but for now this should be sufficient.

#### Host Project

```terraform
module "gke_host_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 9.0"

  name                 = "${var.project_prefix}-host"
  random_project_id    = true
  org_id               = var.organization_id
  folder_id            = var.folder_id
  billing_account      = var.billing_account_id
  skip_gcloud_download = true

  activate_apis = [
    "container.googleapis.com"
  ]
}
```

### Service Projects

```terraform
module "gke_svc_one" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 9.0"

  name                 = "${var.project_prefix}-svc-1"
  random_project_id    = true
  org_id               = var.organization_id
  billing_account      = var.billing_account_id
  folder_id            = var.folder_id
  skip_gcloud_download = true

  activate_apis = [
    "container.googleapis.com"
  ]
}

module "gke_svc_two" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 9.0"

  name                 = "${var.project_prefix}-svc-2"
  random_project_id    = true
  org_id               = var.organization_id
  billing_account      = var.billing_account_id
  folder_id            = var.folder_id
  skip_gcloud_download = true

  activate_apis = [
    "container.googleapis.com"
  ]
}
```

The Container-API has to be enabled on both the host and service projects.  This will also cause the following APIs to be enabled:

```
bigquery.googleapis.com           
bigquerystorage.googleapis.com
compute.googleapis.com            
containerregistry.googleapis.com
iam.googleapis.com                
iamcredentials.googleapis.com 
monitoring.googleapis.com        
oslogin.googleapis.com            
pubsub.googleapis.com            
storage-api.googleapis.com
```
### Network

As show on the diagram, we will create one host network and two subnetworks.  Each subnetwork will be shared with one service project.  As our nodes won't have any public IP addresses, we enable Private Google Access on the subnet (`private_ip_google_access = true`).  To keep it simple, the subnets are located in two regions, `europe-west1` and `europe-west2`.

#### IP Address Management

This probably mandates an entire book (or at least several chapters in a book), but I'll try to provide some background in a few paragraphs.  When we create the subnets, we create 2 additional secondary ranges (a subnet can have up to 8 secondary ranges).  These secondary ranges will be used to assign IP address to Pods and Services.  Because of this, we are using a VPC Native Cluster, as opposed to a routes based cluster.

**Advantages**

- No need to create any custom routes, as IP addresses are taken from a CIDR block managed by the VPC.
- IP addresses are reserved for Pods **before** any Pods are created.
- Pod IP address ranges are routable from on-prem, in a hybrid network topology.

**IP Address Assignment**

- Nodes get their IP address from the primary subnet range.
- For both Pods and Services, it's recommended to create 2 secondary IP ranges.  They **can not** overlap with the primary address range.
- The number of Pods per node is capped at 110.  You can go lower, but you can't go higher.  This means that GKE will allocate a **/24** (256 addresses) to each node for Pods, which can be overridden.  The reason is that Pods can upscale and downscale together, so they will consume more than just 110 IP addresses.

**Example**

- 500 nodes: /23, which gives you 508 IP addresses (4 are reserved).
- 500 x 256 (110 pods per node) = 128.000 IP addresses for the secondary range.  Which means we need a **/15** for the Pod IP ranges.
- Services: If you want to run 1500 services, you need to provision a **/21** address block as secondary range.

As you can see, these address blocks are quite large.  You need to do your due diligence to ensure that you don't overprovision or underprovision.   You can always increase the IP range of a subnet or secondary alias, but changing it completely will result in the subnet to be recreated.

#### Terraform code

```terraform
# Host Network
resource "google_compute_network" "gke_host_network" {
  project                 = module.gke_host_project.project_id
  name                    = "${var.network_name}-${random_id.randomizer.hex}"
  auto_create_subnetworks = false
  description             = "Host Network for GKE clusters"
}

# Subnetworks
resource "google_compute_subnetwork" "gke_host_subnet_1" {
  project                  = module.gke_host_project.project_id
  ip_cidr_range            = "10.0.4.0/22"
  name                     = "${var.network_name}-sn-euw1"
  network                  = google_compute_network.gke_host_network.self_link
  region                   = "europe-west1"
  private_ip_google_access = true

  secondary_ip_range {
    ip_cidr_range = "10.4.0.0/14"
    range_name    = "gke-pod-euw1-secondary"
  }

  secondary_ip_range {
    ip_cidr_range = "10.0.32.0/20"
    range_name    = "gke-svc-euw1-secondary"
  }
}

resource "google_compute_subnetwork" "gke_host_subnet_2" {
  project                  = module.gke_host_project.project_id
  name                     = "${var.network_name}-sn-euw2"
  network                  = google_compute_network.gke_host_network.self_link
  ip_cidr_range            = "172.16.4.0/22"
  region                   = "europe-west2"
  private_ip_google_access = true

  secondary_ip_range {
    ip_cidr_range = "172.20.0.0/14"
    range_name    = "gke-pod-euw2-secondary"
  }

  secondary_ip_range {
    ip_cidr_range = "172.16.16.0/20"
    range_name    = "gke-service-euw2-secondary"
  }
}
```

### IAM Permissions

As mentioned in one of the previous sections, enabling the Container API will result in 2 service accounts being created (the GKE robot and the service account to communicate with certain GCP APIs).

To make it easier to use these accounts, a locals block is created to construct these accounts.  We also add a list of IAM roles the custom service account for our GKE cluster(s) need on the **service projects**.

```terraform
locals {
  host_gke_robot_sa  = "service-${module.gke_host_project.project_number}@container-engine-robot.iam.gserviceaccount.com"
  service_1_robot_sa = "service-${module.gke_svc_one.project_number}@container-engine-robot.iam.gserviceaccount.com"
  service_2_robot_sa = "service-${module.gke_svc_two.project_number}@container-engine-robot.iam.gserviceaccount.com"

  google_api_svc1_sa = "${module.gke_svc_one.project_number}@cloudservices.gserviceaccount.com"
  google_api_svc2_sa = "${module.gke_svc_two.project_number}@cloudservices.gserviceaccount.com"

  gke_operator_sa_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
  ]
}
```

#### Network Permissions

In order to be able to deploy resources in the Shared VPC, service accounts need the Network User role on either the Shared VPC or the Subnet.  In general, it's best practice to manage these permissions at **subnet level**.  That way you limit the blast radius and you ensure that other teams don't consume any IP addresses from other teams.

These permissions need to be assigned to the both the GKE robot and the Cloud API service account, as it's these service accounts that will deploy the nodes in the shared VPC.

```terraform
resource "google_compute_subnetwork_iam_member" "service_1_robot_network_user" {
  project    = module.gke_host_project.project_id
  member     = "serviceAccount:${local.service_1_robot_sa}"
  region     = "europe-west1"
  subnetwork = google_compute_subnetwork.gke_host_subnet_1.self_link
  role       = "roles/compute.networkUser"
}

resource "google_compute_subnetwork_iam_member" "service_2_robot_network_user" {
  project    = module.gke_host_project.project_id
  member     = "serviceAccount:${local.service_2_robot_sa}"
  subnetwork = google_compute_subnetwork.gke_host_subnet_2.self_link
  region     = "europe-west2"
  role       = "roles/compute.networkUser"
}

resource "google_compute_subnetwork_iam_member" "google_api_svc1_host" {
  project    = module.gke_host_project.project_id
  member     = "serviceAccount:${local.google_api_svc1_sa}"
  subnetwork = google_compute_subnetwork.gke_host_subnet_1.self_link
  region     = "europe-west1"
  role       = "roles/compute.networkUser"
}

resource "google_compute_subnetwork_iam_member" "google_api_svc2_host" {
  project    = module.gke_host_project.project_id
  member     = "serviceAccount:${local.google_api_svc2_sa}"
  subnetwork = google_compute_subnetwork.gke_host_subnet_2.self_link
  region     = "europe-west2"
  role       = "roles/compute.networkUser"
}
```

#### Host Robot

The GKE robots in the service projects need to be able to use the GKE robot in the host robot, to make changes in to the network.  There is a specific IAM role available for that, which is similar to the `serviceAccountUser`-role.

```terraform
// Host Service Agent User
resource "google_project_iam_member" "host_agent_svc_1" {
  project = module.gke_host_project.project_id
  member  = "serviceAccount:${local.service_1_robot_sa}"
  role    = "roles/container.hostServiceAgentUser"
}

resource "google_project_iam_member" "host_agent_svc_2" {
  project = module.gke_host_project.project_id
  member  = "serviceAccount:${local.service_2_robot_sa}"
  role    = "roles/container.hostServiceAgentUser"
}
```

#### Service Accounts

As mentioned in the introduction, the default Compute service account doesn't have the permissions to do anything in the service project.  We therefore need to create a custom service account, which we will attach to the node pool(s).  The minimum set of roles required were documented earlier:

- roles/logging.logWriter
- roles/monitoring.metricWriter
- roles/monitoring.viewer"

```terraform
resource "google_service_account" "gke_svc1_service_account" {
  project      = module.gke_svc_one.project_id
  account_id   = "gke-operator"
  display_name = "GKE Operator"
  description  = "GKE Operator for the GKE cluster."
}

resource "google_service_account" "gke_svc2_service_account" {
  project      = module.gke_svc_two.project_id
  account_id   = "gke-operator"
  display_name = "GKE Operator"
  description  = "GKE Operator for the GKE cluster."
}

resource "google_project_iam_member" "gke_svc1_sa_iam_permissions" {
  for_each = toset(local.gke_operator_sa_roles)
  project  = module.gke_svc_one.project_id
  member   = "serviceAccount:${google_service_account.gke_svc1_service_account.email}"
  role     = each.value
}

resource "google_project_iam_member" "gke_svc2_sa_iam_permissions" {
  for_each = toset(local.gke_operator_sa_roles)
  project  = module.gke_svc_two.project_id
  member   = "serviceAccount:${google_service_account.gke_svc2_service_account.email}"
  role     = each.value
}
```

**Firewall Permissions**

This isn't mandatory for the cluster creation process, but if desired, firewall permissions can be granted to the custom service accounts, on the **host project**.  If this role is too open, you can assign a smaller set of permissions in a custom role.

```terraform 
resource "google_project_iam_member" "gke_svc1_fwl_permissions" {
  project = module.gke_host_project.project_id
  member  = "serviceAccount:${google_service_account.gke_svc1_service_account.email}"
  role    = "roles/compute.securityAdmin"
}

resource "google_project_iam_member" "gke_svc2_fwl_permissions" {
  project = module.gke_host_project.project_id
  member  = "serviceAccount:${google_service_account.gke_svc2_service_account.email}"
  role    = "roles/compute.securityAdmin"
}
```

### GKE Cluster

I only added one cluster in this configuration, but nothing is stopping you from creating an additional one, with a similar configuration.  We are managing the node pool separately, as this is best practice.  What is important to know is that, even with a custom node pool, GKE will create the default nodepool anyway.  Once the process is complete, it deletes the default node pool and replaces it with the custom node pool.

#### Cluster

In terms of configuration, you can see the following aspects:
- The default node pool is removed (`remove_default_node_pool`)
- The release channel is set to `RAPID`, which is not the recommendation for PRD.
- The current configuration for `master_auth` is set in such a way that
- By setting an empty `username` and `password`, you disable **basic** authentication.  This is done by default for GKE > 1.19, but it doesn't hurt.
- The IP addresses are taken from the secondary IP ranges configured during the network creation.
- The nodes are not getting a public IP address (`enable_private_nodes`)
- The public endpoint for the Master is disabled (`enable_private_endpoint`)

##### Node Config

You will see that for both the cluster and the node pool, the `node_config`-block is specified, with the Service Account.  As mentioned earlier, the GKE cluster first creates the default nodepool and then deletes it, to replace it with the custom node pool.  As we removed the permissions from the Compute default service account, we need to assign the necessary permissions to the default node pool as well, as otherwise the health checks time out.

##### Master Endpoint

In this configuration, we disabled the public endpoint.  This means that developers will **not** be able to use `kubectl` from their local machine, unless you add an authorized network (e.g. on-prem) and they are connected to the corporate network.  An alternative is to create a VM in the same network as the node pools and run the commands from there or to use `kube proxy`.

For the sake of brevity, access to the master endpoint has three flavours:
- Public endpoint disabled.
- Public endpoint enabled, master authorised networks enabled: Master can be accessed from the list of authorised networks, even public ones.
- Public endpoing access enabled, master authorised networks disabled: Anyone can access the master.

##### Code

```terraform 
resource "google_container_cluster" "gke_cluster" {
  project     = module.bdb_gke_svc_1.project_id
  name        = "gke-cluster-one"
  description = "GKE cluster to use for troubleshooting issues."
  location    = "europe-west1"
  network     = google_compute_network.gke_host_network.self_link
  subnetwork  = google_compute_subnetwork.gke_host_subnet_1.self_link

  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = "RAPID"
  }

  master_auth {
    username = ""
    password = ""
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pod-euw1-secondary"
    services_secondary_range_name = "gke-svc-euw1-secondary"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = "10.255.0.0/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = google_compute_subnetwork.gke_host_subnet_1.ip_cidr_range
    }

    cidr_blocks {
      cidr_block = google_compute_subnetwork.gke_host_subnet_2.ip_cidr_range
    }
  }

  node_config {
    service_account = google_service_account.gke_svc1_service_account.email
    oauth_scopes = [
      "storage-ro",
      "logging-write",
      "monitoring"
    ]
  }

  timeouts {
    create = "10m"
    update = "20m"
  }

  depends_on = [
    google_project_iam_member.host_agent_svc_2,
    google_project_iam_member.host_agent_svc_1,
    google_project_iam_member.gke_svc1_sa_iam_permissions,
    google_project_iam_member.gke_svc1_fwl_permissions,
    google_project_iam_member.gke_svc2_sa_iam_permissions,
    google_project_iam_member.gke_svc2_fwl_permissions,
    google_compute_subnetwork_iam_member.google_api_svc1_host,
    google_compute_subnetwork_iam_member.google_api_svc2_host,
    google_compute_subnetwork_iam_member.service_1_robot_network_user,
    google_compute_subnetwork_iam_member.service_2_robot_network_user,
    google_compute_shared_vpc_host_project.bdb_prd_host,
    google_compute_shared_vpc_service_project.bdb_svc_1,
    google_compute_shared_vpc_service_project.bdb_svc_2,
  ]
}
```

#### Node Pool

For the node pool, I chose a standard configuration.  The only things to highlight are the service account (yes, it has to be added to both the cluster and the node pool) and the fact that we use Sandbox nodes, as opposed to standard ones.

```terraform
resource "google_container_node_pool" "gke_node_pool" {
  provider   = google-beta
  project    = module.gke_svc_one.project_id
  name       = "gke-fin-nodes"
  cluster    = google_container_cluster.gke_cluster.name
  location   = "europe-west1"
  node_count = 1

  node_config {
    image_type   = "cos_containerd"
    machine_type = "n2-standard-4"

    service_account = google_service_account.gke_svc1_service_account.email
    oauth_scopes = [
      "storage-ro",
      "logging-write",
      "monitoring"
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    sandbox_config {
      sandbox_type = "gvisor"
    }

    disk_size_gb = 20
    disk_type    = "pd-ssd"
  }

  depends_on = [
    google_project_iam_member.host_agent_svc_2,
    google_project_iam_member.host_agent_svc_1,
    google_project_iam_member.gke_svc1_sa_iam_permissions,
    google_project_iam_member.gke_svc1_fwl_permissions,
    google_project_iam_member.gke_svc2_sa_iam_permissions,
    google_project_iam_member.gke_svc2_fwl_permissions,
    google_compute_subnetwork_iam_member.google_api_svc1_host,
    google_compute_subnetwork_iam_member.google_api_svc2_host,
    google_compute_subnetwork_iam_member.service_1_robot_network_user,
    google_compute_subnetwork_iam_member.service_2_robot_network_user,
    google_compute_shared_vpc_host_project.bdb_prd_host,
    google_compute_shared_vpc_service_project.bdb_svc_1,
    google_compute_shared_vpc_service_project.bdb_svc_2,
  ]
}
```

 