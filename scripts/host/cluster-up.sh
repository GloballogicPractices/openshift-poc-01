#!/bin/bash
################################################################################
# Launch OpenShift cluster                                                     #
################################################################################

cd /var/origin/bin/

oc cluster up --host-data-dir /var/openshift/data/ --use-existing-config --public-hostname=pocopenshift.northeurope.cloudapp.azure.com