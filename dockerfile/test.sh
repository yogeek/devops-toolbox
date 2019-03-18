#!/bin/sh

# Test script for deploy-toolbox image

echo '
____________________________________________
		Deploy Toolbox Test
____________________________________________

We test each tool by displaying corresponding version.

Installed Tools versions :
----------------
'

echo "
####### Packer :
$(packer version)

####### Terraform :
$(terraform version)

####### Ansible :
$(ansible --version)

####### Kubectl :
$(kubectl version --client=true --output json)

####### Kops :
$(kops version)

####### Helm :
$(helm version -c)

####### AWS CLI :
$(aws --version 2>&1)

####### Go :
$(go version)

"
