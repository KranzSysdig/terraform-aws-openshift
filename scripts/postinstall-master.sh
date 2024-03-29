#!/usr/bin/env bash

# Download some apps to be installed by the user later
wget -P ~/ https://github.com/KranzSysdig/training/raw/master/labs.tar.gz
tar -xvzf ~/labs.tar.gz
mkdir ~/microservices-demo
git clone https://github.com/GoogleCloudPlatform/microservices-demo.git ~/microservices-demo
mkdir ~/sysdig-agent
wget -P ~/sysdig-agent/ https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/master/agent_deploy/kubernetes/sysdig-agent-daemonset-v2.yaml
wget -P ~/sysdig-agent/ https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/master/agent_deploy/kubernetes/sysdig-agent-configmap.yaml

# Note: This script runs after the ansible install, use it to make configuration
# changes which would otherwise be overwritten by ansible.
sudo su
#yum -y install kernel-devel-$(uname -r)
echo yum -y install kernel-devel-$(uname -r) >> /etc/rc.local

SSHPASS='UaRD4a9bbyNN'
ENCPASS='$1$J67GEhvK$99MR19Qr9rlluoSoYdgRC0'

# Create an htpasswd file, we'll use htpasswd auth for OpenShift.
htpasswd -cb /etc/origin/master/htpasswd admin sysdig123password
echo "Password for 'admin' set to 'sysdig123password'"

# Update the docker config to allow OpenShift's local insecure registry. Also
# use json-file for logging, so our Splunk forwarder can eat the container logs.
# json-file for logging
sed -i '/OPTIONS=.*/c\OPTIONS="--selinux-enabled --insecure-registry 172.30.0.0/16 --log-driver=json-file --log-opt max-size=1M --log-opt max-file=3"' /etc/sysconfig/docker
echo "Docker configuration updated..."

echo "Changing password for 'ec2-user' to $SSHPASS"
# Change the ec2-user password on master node so we can SSH using password auth
usermod -p $ENCPASS ec2-user
# Change SSH config to allow password based logins to the master node, leave the restart to later host reboot
sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config

# It seems that with OKD 3.10, systemctl restart docker will hang. So just reboot.
echo "Restarting host..."
shutdown -r now "restarting post docker configuration"
