#!/bin/bash
################################################################################
# Prvisioning script to deploy the PoC on an OpenShift environment             #
################################################################################

function print_header() {
  echo
  echo "-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/"
  echo $1
  echo "-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/"
}

# Create Projects
function create_projects() {
  print_header "Creating OpenShift projects..."

  echo "Creating project $PRJ_CI"
  oc new-project $PRJ_CI --display-name='CI/CD' --description='CI/CD Subsystem (Jenkins, Nexus, etc)' >/dev/null
  
  for project in $PRJ_CI
  do
    oc adm policy add-role-to-group admin system:serviceaccounts:$PRJ_CI -n $project
    oc adm policy add-role-to-group admin system:serviceaccounts:$project -n $project
  done

  if [ $LOGGEDIN_USER == 'system:admin' ] ; then
    for project in $PRJ_CI
    do
      oc adm policy add-role-to-user admin $ARG_USERNAME -n $project
      oc annotate --overwrite namespace $project demo=demo1-$PRJ_SUFFIX demo=demo-modern-arch-$PRJ_SUFFIX
    done
    oc adm pod-network join-projects --to=$PRJ_CI >/dev/null 2>&1
  fi
}

# Create Projects (in reversed order)
function delete_projects() {
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
ARG_PROJECT_SUFFIX=

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


