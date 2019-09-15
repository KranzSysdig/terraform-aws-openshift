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

#  Create the OpenShift cluster using defined child modules nested under the openshift module at "modules/openshift".
module "openshift" {
  source = "./modules/openshift"
  region = "${var.region}"
  ec2_type_bastion = "${var.ec2_bastion}"  #m4.xlarge is the smallest ami that meets the min specs for openshift of 4 vCPU and 16GB memory
  ec2_type_master = "${var.ec2_master}"
  ec2_type_infra = "${var.ec2_infra}"
  ec2_type_node = "${var.ec2_node}"
  node_amisize = "m4.large"    # Large enough node for infra and compute to run containers on
  vpc_cidr = "172.16.0.0/16"
  public_subnet_cidr = "172.16.0.0/24"
  private_subnet_cidr = "172.16.16.0/20"
  key_name = "${var.clusterid}.${var.dns_domain}"
  public_key_path = "${var.public_key_path}"
  cluster_name = "${var.clusterid}"
  cluster_id = "openshift-cluster-${var.region}"
}

//  Output some useful variables for quick SSH access etc.
output "master-url" {
  value = "https://${module.openshift.master-public_ip}.xip.io:8443"
}
output "master-public_ip" {
  value = "${module.openshift.master-public_ip}"
}
output "bastion-public_ip" {
  value = "${module.openshift.bastion-public_ip}"
}
