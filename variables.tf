#  The region that will be used for to deploy the OKD cluster into.
variable "region" {
  default = "eu-west-2"
}

#  The public key to use for SSH access.
variable "public_key_path" {
  //default = "~/.ssh/id_rsa.pub"
  default = "key.pem.pub"
}

# The ec2 instnace types to use in the deployment
variable "ec2_instances" {
  type = list(object({
    ec2_bastion = string
    ec2_master = string
    ec2_infra = string
    ec2_node = string
  }))
  default = [
    {
      ec2_bastion = "t2.micro"
      ec2_master = "m4.xlarge"
      ec2_infra = "m4.large"
      ec2_node = "m4.large"
    }
  ]
}

# Set the domain name to use with Route53 Hosted Zones.
variable "domain_dns" {
  default = "tarben.co.uk"
}
