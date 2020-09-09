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




 