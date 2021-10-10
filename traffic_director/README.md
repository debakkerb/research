# Traffic Director

The purpose of this config is to create a GKE cluster with an application deployed, and to setup [Traffic Director](https://cloud.google.com/traffic-director/docs/overview) to manage routing in the mesh.  

## Control Plane vs Data Plane
Before we start, it's important to point out that Traffic Director is the control plane, **not** the data plane.  In short, this means that Traffic Director holds the overview of where requests should be routed.  It creates the routing table for requests.  As Traffic Director is not the data plane, it does not intervene in actually sending the packets back and forth.  It's only responsible for establishing *the policy*.  

## Setup
I will be documenting a fairly straightforward deployment, using GKE, a simple app and exposing that over an HTTPS load balancer.  It will be a combination of Terraform and YAML to deploy resources on top of Kubernetes.

Steps:
1. Create GCP infrastructure (Project, Network, Cluster)
2. Deploy a simple pod.
3. Create the necessary TD resources to handle traffic and health checks.

## Resources

