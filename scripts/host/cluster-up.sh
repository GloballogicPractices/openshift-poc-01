#!/bin/bash
################################################################################
# Launch OpenShift cluster                                                     #
################################################################################

cd /var/lib/origin/bin/

#oc cluster up --host-data-dir /var/lib/origin/data/ --use-existing-config --public-hostname=pocopenshift.northeurope.cloudapp.azure.com

oc cluster up --host-data-dir /var/lib/origin/data/ --public-hostname=52.138.147.33.nip.io --env=ROUTER_SUBDOMAIN=52.138.147.33.nip.io