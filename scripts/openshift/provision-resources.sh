#!/bin/bash
################################################################################
# Prvisioning script to deploy the PoC on an OpenShift environment             #
################################################################################

# TODO
# 1. Create 3 projects (ci\cd, dev, prod)
# 2. Setup permissions between projects
# 3. Split templates into 3 parts (ci\cd, stage, prod)
# 4. deploy templates to corresponding projects
# 5. configure and test stage-> prod propagation
# 6. add 2 back-end microservices, configure builds/pipelines
# 7. update Web app to call microservices
# 8. create multi-node cluster

function print_header() {
  echo
  echo "-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/"
  echo $1
  echo "-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/"
}

function wait_service(name, namespace) {
  i=1
  oc get ep $name -o yaml -n $namespace | grep "\- addresses:"
  while [ ! $? -eq 0 ]
  do
    sleep 60
    i=$(( $i + 1 ))

    if [ $i -gt 10 ]
    then
      exit 255
    fi

    oc get ep $name -o yaml -n $namespace | grep "\- addresses:"
done
}

# Create Projects
function create_projects() {
  print_header "Creating OpenShift projects..."

  echo "Creating projects $PRJ_CI"
  oc new-project $PRJ_CI --display-name='CI/CD' --description='CI/CD Subsystem (Jenkins, pipelines, builds, images, etc)' >/dev/null
  oc new-project $PRJ_DEV --display-name='Development' --description='Development (Dev deployment)' >/dev/null
  oc new-project $PRJ_PROD --display-name='Production' --description='Production (Prod deployment)' >/dev/null
  
  for project in $PRJ_CI $PRJ_DEV $PRJ_PROD
  do
    oc adm policy add-role-to-group admin system:serviceaccounts:$PRJ_CI -n $project
    oc adm policy add-role-to-group admin system:serviceaccounts:$project -n $project
  done

  if [ $LOGGEDIN_USER == 'system:admin' ] ; then
    for project in $PRJ_CI $PRJ_DEV $PRJ_PROD
    do
      oc adm policy add-role-to-user admin $ARG_USERNAME -n $project
      oc annotate --overwrite namespace $project demo=demo1-$PRJ_SUFFIX demo=demo-modern-arch-$PRJ_SUFFIX
    done
    oc adm pod-network join-projects --to=$PRJ_CI >/dev/null 2>&1
  fi
}

# Create Projects (in reversed order)
function delete_projects() {
  oc delete project $PRJ_PROD
  oc delete project $PRJ_DEV
  oc delete project $PRJ_CI
}

# Deploy Jenkins
function deploy_jenkins() {
  print_header "Deploying Jenkins..."
  
  oc new-app jenkins-persistent -l app=jenkins -p MEMORY_LIMIT=1Gi -n $PRJ_CI
  sleep 2
  oc set resources dc/jenkins --limits=cpu=1,memory=2Gi --requests=cpu=200m,memory=1Gi -n $PRJ_CI
}

# GPTE convention
function set_default_project() {
  if [ $LOGGEDIN_USER == 'system:admin' ] ; then
    oc project default >/dev/null
  fi
}

ARG_USERNAME=
ARG_COMMAND=deploy
ARG_PROJECT_SUFFIX=dotnet-core

while :; do
    case $1 in
        --deploy)
            ARG_COMMAND=deploy
            ;;
        --delete)
            ARG_COMMAND=delete
            ;;
        --user)
            if [ -n "$2" ]; then
                ARG_USERNAME=$2
                shift
            else
                printf 'ERROR: "--user" requires a non-empty value.\n' >&2
                exit 1
            fi
            ;;
        --project-suffix)
            if [ -n "$2" ]; then
                ARG_PROJECT_SUFFIX=$2
                shift
            else
                printf 'ERROR: "--project-suffix" requires a non-empty value.\n' >&2
                exit 1
            fi
            ;;
        --)
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            shift
            ;;
        *)
            break
    esac

    shift
done

################################################################################
# CONFIGURATION                                                                #
################################################################################
LOGGEDIN_USER=$(oc whoami)
OPENSHIFT_USER=${ARG_USERNAME:-$LOGGEDIN_USER}

# projects
PRJ_SUFFIX=${ARG_PROJECT_SUFFIX:-`echo $OPENSHIFT_USER | sed -e 's/[-@].*//g'`}
PRJ_CI=ci-$PRJ_SUFFIX
PRJ_DEV=dev-$PRJ_SUFFIX
PRJ_PROD=prod-$PRJ_SUFFIX

# config
GITHUB_ACCOUNT=${GITHUB_ACCOUNT:-andriy-gnennyy-gl}
GITHUB_REF=${GITHUB_REF:-master}
GITHUB_URI=https://github.com/$GITHUB_ACCOUNT/openshift-poc-01.git

################################################################################
# MAIN                                                                         #
################################################################################

pushd ~
START=`date +%s`

print_header "OpenShift PoC ($(date))"

case "$ARG_COMMAND" in
    delete)
        echo "Delete OpenShift PoC..."
        delete_projects
        exit 0
        ;;

    *)
        echo "Deploying OpenShift PoC..."
        create_projects 
        #print_info
        #deploy_nexus
        #wait_for_nexus_to_be_ready
        #build_images
        #deploy_guides
        #deploy_gogs
        deploy_jenkins
		wait_service("jenkins", $PRJ_CI)
        #add_inventory_template_to_projects
        #deploy_coolstore_test_env
        #deploy_coolstore_prod_env
        #deploy_inventory_dev_env
        #promote_images
        #deploy_pipeline
esac

set_default_project
popd

END=`date +%s`
echo
echo "Provisioning done! (Completed in $(( ($END - $START)/60 )) min $(( ($END - $START)%60 )) sec)"


