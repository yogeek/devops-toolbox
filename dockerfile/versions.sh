#!/bin/sh

# Information about deploy-toolobox

echo '
____________________________________________
		Deploy Toolbox
____________________________________________

This image aims to provide useful tools
to deploy infrastructure and applications.

The UID of current dir (bind-mount) is mapped to the 'devops' user in the container
to avoid permissions problems.

Tools versions :
----------------
'
env | grep "_VERSION"
echo '

'
