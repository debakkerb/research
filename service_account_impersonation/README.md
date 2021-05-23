# Service Account Impersonation

On Google Cloud, IAM permissions can be granted to a number of identity types.  The most important ones are service accounts, which are frequently being used by GCP services.  For example, when you create an AppEngine application, the platform will automatically create a service account which acts as the identity of your app.  If your app accesses any APIs, it will use that service account to authenticate.

## Automation
When building pipelines to orchestrate your GCP environment, you will use service accounts to create all your resources.  However, using one identity isn't a good idea, as this becomes both your single point of failure **and** increases the blast radius if your service account is compromised.  That's why it's a much better idea to split your deployment in separate layers and let different service accounts manage each individual layer.  This is an example of what that *can* look like in the real world.

```shell
├── 01_-_foundation
├── 02_-_folders
├── 03_-_network
├── 04_-_security
├── 05_-_audit
├── 06_-_workloads
```

This is just an example of what a structure can look like, but much will depend on how you manage your organisation and what service your team delivers to other teams.  The names should be straightforward, but the idea is that foundation contains service accounts + permissions, where you have the following split:

| Service Account | Purpose                                                                                          |
|-----------------|--------------------------------------------------------------------------------------------------|
| Orchestrator    | Account with no permissions, other than impersonating the ones listed below.                     |
| Folder creator  | Account that can create Folders and grant permissions.                                           |
| Network         | Account managing the network layer in your organisation.                                         |
| Security        | Account that creates VPC SC perimeters, access policies and resources to audit your environment. |
| Audit           | Account that creates audit log sinks for your organization.                                      |
| Workloads       | Account that manages resources belonging to workloads running in your organization.              |

The idea is that the orchestrator has no permissions, other than the `roles/iam.serviceAccountTokenCreator`-role on the other service accounts.  This service account should be used by your CI/CD pipelines.