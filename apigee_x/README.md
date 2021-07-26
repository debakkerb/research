# Apigee X

Apigee is an API management platform, which comes in a variety of flavours.  Edge is the SaaS offering, which I'm not going to cover and Apigee X is a hybrid model, where the Apigee components are managed by Apigee themselves, but a VPC peering link is created with your environment, allowing access over a private IP address range.

This example focuses on building an Evaluation org, with external access.  Without external access, Apigee X only supports calls that originate from within your own network.  This is great if you want to develop an internal API platform, but for this example I'm going to focus on allowing external access.

