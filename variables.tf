#  The region that will be used for to deploy the OKD cluster into.
variable "region" {
  default = "eu-west-2"
  }

# Set the VPC name for the OpenShift deployment
variable "vpc_name" {
  default = "okd"
  }

# Set the cluster name to be used for the OpenShift deployment.
variable "cluster_name" {
  default = "okd"
  }

# Set the environment name for the OpenShift deployment.
variable "environment_name" {
  default = "stage"
  }

# Set the domain name to use with Route53 Hosted Zones.
variable "domain_dns" {
  default = "tarben.co.uk"
  }

# Set the VPC cidr block to use for the deployment
variable "cidr_vpc" {
  default = "172.16.0.0/16"
  }

# Set the public subnet cidr address, use a range for a HA cluster deployed into multiple AZ's
variable "cidr_public" {
  type = list(object({
    cidrpublic_subnet1 = string
    cidrpublic_subnet2 = string
    cidrpublic_subnet3 = string
    }))
  default = [
    {
      cidrpublic_subnet1 = "172.16.1.0/24"
      cidrpublic_subnet2 = "172.16.2.0/24"
      cidrpublic_subnet3 = "172.16.3.0/24"
      }
    ]
  }

# Set the private subnet cidr address, use a range for a HA cluster deployed into multiple AZ's
variable "cidr_private" {
  type = list(object({
    cidrprivate_subnet1 = string
    cidrprivate_subnet2 = string
    cidrprivate_subnet3 = string
    }))
  default = [
    {
      cidrprivate_subnet1 = "172.16.16.0/20"
      cidrprivate_subnet2 = "172.16.32.0/20"
      cidrprivate_subnet3 = "172.16.48.0/20"
      }
    ]
  }

# Set the ec2 instnace types to use in the deployment
variable "ec2_instances" {
  type = object({
    ec2_bastion = string
    ec2_master  = string
    ec2_infra   = string
    ec2_node    = string
    })
  default = [
    {
      ec2_bastion = "t2.micro"
      ec2_master  = "m4.xlarge"
      ec2_infra   = "m4.large"
      ec2_node    = "m4.large"
      }
    ]
  }

# Set the AWS AMI details to use with RHEL release
variable "rhel_release" {
  default = "rhel-7.5"
  }

# Set the AWS AMI details to use with CentOS release
variable "centos_release" {
  type = object ({
    centos_version = string
    product_code   = string
    product_owner  = sting
    })
  default = [
    {
      centos_version = "7"
      product_code   = "aw0evgkw8e5c1q413zgy5pjce"
      product_owner  = "aws-marketplace"
      }
    ]
  }

#  The public key to use for SSH access.
variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
  #default = "key.pem.pub"
  }
