# Setup our Terraform providers so that we have deterministic dependecy resolution. 
provider "aws" {
  region  = "${var.region}"
  version = "~> 2.19"
}

provider "local" {
  version = "~> 1.3"
}

provider "template" {
  version = "~> 2.1"
}

#  Create the OpenShift cluster using defined child modules nested at "modules/openshift".
module "openshift" {
  source = "./modules/openshift"
  region = "${var.region}"
  clusterid = "${var.cluster_name}"
  domain_dns = "${var.domain_dns}"  
  ec2_type_bastion = "${var.ec2_instances.ec2_bastion}"
  ec2_type_master = "${var.ec2_instances.ec2_master}"
  ec2_type_infra = "${var.ec2_instances.ec2_infra}"
  ec2_type_node = "${var.ec2_instances.ec2_node}"
  vpc_cidr = "${var.cidr_vpc}"
  public_subnet_cidr = "172.16.0.0/24"
  private_subnet_cidr = "172.16.16.0/20"
  key_name = "${var.cluster_name}.${var.dns_domain}"
  public_key_path = "${var.public_key_path}"
}

#  Output some useful variables for quick SSH access etc.
output "master-url" {
  value = "https://${module.openshift.master-public_ip}.xip.io:8443"
}
output "master-public_ip" {
  value = "${module.openshift.master-public_ip}"
}
output "bastion-public_ip" {
  value = "${module.openshift.bastion-public_ip}"
}
