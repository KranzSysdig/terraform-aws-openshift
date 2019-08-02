SSHPASS=UaRD4a9bbyNN
#ENCPASS=$$1$$J67GEhvK$$99MR19Qr9rlluoSoYdgRC0

infrastructure:
	# Get the modules, create the infrastructure.
	terraform init && terraform get && terraform apply -auto-approve

# Installs OpenShift on the cluster.
openshift:
	# Add our identity for ssh, add the host key to avoid having to accept the
	# the host key manually. Also add the identity of each node to the bastion.
	#ssh-add ~/.ssh/id_rsa
	#ssh-keygen -t rsa -N "" -f key.pem
	ssh-add key.pem
	ssh-keyscan -t rsa -H $$(terraform output bastion-public_ip) >> ~/.ssh/known_hosts
	ssh -A ec2-user@$$(terraform output bastion-public_ip) "ssh-keyscan -t rsa -H master.openshift.local >> ~/.ssh/known_hosts"
	ssh -A ec2-user@$$(terraform output bastion-public_ip) "ssh-keyscan -t rsa -H node1.openshift.local >> ~/.ssh/known_hosts"
	ssh -A ec2-user@$$(terraform output bastion-public_ip) "ssh-keyscan -t rsa -H node2.openshift.local >> ~/.ssh/known_hosts"
	ssh -A ec2-user@$$(terraform output bastion-public_ip) "ssh-keyscan -t rsa -H node3.openshift.local >> ~/.ssh/known_hosts"

	# Copy our inventory to the master and run the install script.
	scp ./inventory.cfg ec2-user@$$(terraform output bastion-public_ip):~
	cat install-from-bastion.sh | ssh -o StrictHostKeyChecking=no -A ec2-user@$$(terraform output bastion-public_ip)

	# Change the ec2-user password on master node so we can SSH using password auth
	#echo 'sudo usermod -p '$(ENCPASS)' ec2-user' | ssh -A ec2-user@$$(terraform output bastion-public_ip) ssh master.openshift.local
	# Change SSH config to allow password based logins to the master node, leave the restart to later host reboot
	#- echo 'sudo sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config' | ssh -A ec2-user@$$(terraform output bastion-public_ip) ssh master.openshift.local

	# Now the installer is done, run the postinstall steps on each host.
	# Note: these scripts cause a restart, so we use a hyphen to ignore the ssh
	# connection termination.
	- cat ./scripts/postinstall-master.sh | ssh -A ec2-user@$$(terraform output bastion-public_ip) ssh master.openshift.local
	- cat ./scripts/postinstall-node.sh | ssh -A ec2-user@$$(terraform output bastion-public_ip) ssh node1.openshift.local
	- cat ./scripts/postinstall-node.sh | ssh -A ec2-user@$$(terraform output bastion-public_ip) ssh node2.openshift.local
	- cat ./scripts/postinstall-node.sh | ssh -A ec2-user@$$(terraform output bastion-public_ip) ssh node3.openshift.local
	# Install kernel headers / devel libraries to each of the hosts so the Sysdig Agent works
	echo 'Sleeping in the wildly unscientific assumption that everything will reboot within 30 seconds! If not, you may need to run the ./install-kernel-headers.sh script'
	sleep 30
	- echo 'sudo yum -y install kernel-devel-$(uname -r)' | ssh -A ec2-user@$$(terraform output bastion-public_ip) ssh master.openshift.local
	- echo 'sudo yum -y install kernel-devel-$(uname -r)' | ssh -A ec2-user@$$(terraform output bastion-public_ip) ssh node1.openshift.local
	- echo 'sudo yum -y install kernel-devel-$(uname -r)' | ssh -A ec2-user@$$(terraform output bastion-public_ip) ssh node2.openshift.local
	- echo 'sudo yum -y install kernel-devel-$(uname -r)' | ssh -A ec2-user@$$(terraform output bastion-public_ip) ssh node3.openshift.local
	echo "Complete! Wait a minute for hosts to restart, then run 'make browse-openshift' to login with user 'admin' and password 'sysdig123password'."
	echo "SSH password for the master node is '$(SSHPASS)'"
	echo "Copy key.pem, chmod 0400, then SSH through the bastion $$(terraform output bastion-public_ip)"
	echo "i.e. $$ ssh -t -A -i key.pem ec2-user@$$(terraform output bastion-public_ip) ssh master.openshift.local"

# Destroy the infrastructure.
destroy:
	terraform init && terraform destroy -auto-approve

# Open the console.
browse-openshift:
	open $$(terraform output master-url)

# SSH onto the master.
ssh-bastion:
	ssh -t -A ec2-user@$$(terraform output bastion-public_ip)
ssh-master:
	ssh -t -A ec2-user@$$(terraform output bastion-public_ip) ssh master.openshift.local
ssh-node1:
	ssh -t -A ec2-user@$$(terraform output bastion-public_ip) ssh node1.openshift.local
ssh-node2:
	ssh -t -A ec2-user@$$(terraform output bastion-public_ip) ssh node2.openshift.local
ssh-node3:
	ssh -t -A ec2-user@$$(terraform output bastion-public_ip) ssh node3.openshift.local

# Create sample services.
sample:
	oc login $$(terraform output master-url) --insecure-skip-tls-verify=true -u=admin -p=123
	oc new-project sample
	oc process -f ./sample/counter-service.yml | oc create -f -

# Lint the terraform files. Don't forget to provide the 'region' var, as it is
# not provided by default. Error on issues, suitable for CI.
lint:
	terraform get
	TF_VAR_region="us-east-1" tflint --error-with-issues

# Run the tests.
test:
	echo "Simulating tests..."

# Run the CircleCI build locally.
circleci:
	circleci config validate -c .circleci/config.yml
	circleci build --job lint

.PHONY: sample
