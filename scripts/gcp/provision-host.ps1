################################################################################
# Step-by-step script (non-automatic) to provision Azure VM                    #
################################################################################
# TODO: add parameters/automatic login to make the script automatic

az login

az account set --subscription "6f27f626-be5f-461d-a80f-fa2e028b880a"

az group create -l northeurope -n pocopenshift

az group deployment create --name openshift --resource-group pocopenshift --template-file openshift-azuredeploy.json --parameters virtualMachines_openshift_password=...

# az group delete -n pocopenshift