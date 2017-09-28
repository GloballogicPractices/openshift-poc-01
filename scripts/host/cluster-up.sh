#!/bin/bash
################################################################################
# Launch OpenShift cluster                                                     #
################################################################################

cd /var/lib/origin/bin/

sudo oc cluster up --host-data-dir /var/lib/origin/data/ --public-hostname=52.236.37.25.nip.io --routing-suffix=52.236.37.25.nip.io