## Description

This architecture allows you create an EKS (Elastic Kubernetes Service) cluster in AWS with its node group and native VPC CNI configuration for networking.

It also contains the IAM roles needed for both the cluster and the node group.

It accepts incoming traffic from internet through the internet gateway and route it to the subnets.

**N.B:**

- The Terraform code is automatically generated with best practices and contains variables that you can customize to fit your needs.
- You have full control to change, add, delete resources or their configuration. The newly generated code will reflect these changes.
- You can replace some resources with Terraform modules.

> terraform apply status: successful

## Architecture components

Here are all the components of this architecture:
- VPC
- Subnets
- Internet gateway
- Route table and route table associations in every subnet
- IAM roles and policies for both the cluster and the node group
- Security group with its rule(s).

## Requirements

| Name | Configuration |
| --- | --- |
| Terraform | all versions |
| Provider | AWS |
| Provider version | >= 5.33.0 |
| Access | Admin access |

## How to use the architecture

Clone the architecture and modify the following variables according to your needs:

| Variable | Description |
| --- | --- |
| cluster-name | Name of the EKS cluster |
| scaling | Parameters of the scaling, including min and max capacity |
| sg_name | Security group name |
| subnets | Subnets with their configuration |
| tags | Tags that are added to all resources |
| vpc_cidr | The CIDR of the VPC |
| workstation-external-cidr | The external IP address that is allowed to access the cluster |

**N.B:**

- Feel free to remove the resources that are not relevant to your use-case.
- Some variables have default values, please change it if it doesn't fit your deployment.

## Maintainer(s)

You can reach out to these maintainers if you need help or assistance:

- [Brainboard team](mailto:support@brainboard.co)
