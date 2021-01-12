#!/bin/bash
set -e
rm -f alpine_is_upgraded

helpFunction()
{
   echo ""
   echo "Usage: $0"
   echo -e "\t-r <docker_registry> e.g. REGISTRY/image:tag"
   echo -e "\t-n <customername> e.g. registry/CUSTOMERNAME_alpine:tag"
   echo -e "\t-i rollback/initialize regitsty/docker_hub_alpine:previous_latest image that is used in next rounds"
   echo -e "\t-t take image push to regitsty off, just to testing purposes"
   exit 1 # Exit script after printing help
}

INITIALIZE=false
PRODUCTION=true
while getopts "r:n:it" opt
do
   case "$opt" in
      r ) ECR_REPO="$OPTARG" ;;
      n ) ECR_CUSTOMER="$OPTARG" ;;
      i ) INITIALIZE=true ;;
      t ) PRODUCTION=false ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done
if [ "${ECR_REPO}" == "" ];
then
    echo "ERROR: -r <ECR_REPO> parameter is required"
    exit 1
fi

if [ "${ECR_CUSTOMER}" == "" ];
then
    echo "ERROR: -n <CUSTOMERNAME> parameter is required"
    exit 1
fi

if [ ${INITIALIZE} = true ];
then
    echo "INFO: Just initialize setup"
    docker pull docker.io/alpine:3.12.1
    docker tag docker.io/alpine:3.12.1 ${ECR_REPO}/docker_hub_alpine:previous_latest
    if [ ${PRODUCTION} = true ];
    then
        docker push ${ECR_REPO}/docker_hub_alpine:previous_latest
    fi
    exit 0
fi

#NOTE: CHANGE THESE BEFORE REAL USAGE
# REMOVE FROM FILE LINE BEGINNINGS: ####### ACTIVATE WHEN IN USE #######


#DOCKER HUB alpine:latest INFORMATION
docker pull alpine:latest
docker_hub_hash=$(docker image ls --format "{{.ID}}" alpine:latest)

if [ ${PRODUCTION} = true ];
then
    docker pull ${ECR_REPO}/docker_hub_alpine:previous_latest
fi
ecr_hash=$(docker image ls --format "{{.ID}}"  ${ECR_REPO}/docker_hub_alpine:previous_latest)

upgrade_alpine_images () {
    #SOLVE ALPINE VERSION FROM DOCKER HUB: alpine:latest
    alpine_version=$( docker run --rm alpine:latest /bin/cat /etc/alpine-release |  tr -d '\r' )
    alpine_majorversion=$( echo ${alpine_version} | awk -F'.' '{print $1}' )
    echo "INFO: Alpine major version:${alpine_majorversion} AND full version:${alpine_version}"
    test ! ${alpine_majorversion} -eq 0 #Should be integer

    # BUILD customer_base_alpine WITH:
    # - Security upgrades
    # - notroot user
    # - alpine_information.txt
    echo '#!/bin/sh' | tee alpine_information.sh
    echo "set -xe" | tee -a alpine_information.sh
    echo "export IMAGE_INFO=${ECR_REPO}/${ECR_CUSTOMER}_alpine:${alpine_version}" | tee -a alpine_information.sh
    echo "export IMAGE_VERSION=${alpine_version}" | tee -a alpine_information.sh
    echo "export BUILD_TIMESTAMP=$(date)" | tee -a alpine_information.sh
    echo "export BUILD_JOB=PIPELINE JOB NUMBER HERE" | tee -a alpine_information.sh
    #BAKE ${ECR_REPO}/customer_alpine:${alpine_version}
    echo '#!/bin/sh' > push_to_ecr.sh
    echo "set -xe" >> push_to_ecr.sh
    echo "# EXECUTE https://github.com/aquasecurity/trivy BEFORE PUSH => Use push_to_ecr.sh to push." >> push_to_ecr.sh
    echo "# Trivy have to be executed against ${ECR_REPO}/${ECR_CUSTOMER}_alpine:latest">> push_to_ecr.sh

    echo "INFO: Create images: "
    echo "INFO: Image: ${ECR_REPO}/${ECR_CUSTOMER}_alpine:${alpine_version}"
    docker build -t ${ECR_REPO}/${ECR_CUSTOMER}_alpine:${alpine_version} .
    echo "docker push ${ECR_REPO}/${ECR_CUSTOMER}_alpine:${alpine_version}" >> push_to_ecr.sh

    echo "INFO: Image: ${ECR_REPO}/${ECR_CUSTOMER}_alpine:${alpine_majorversion}"
    docker tag ${ECR_REPO}/${ECR_CUSTOMER}_alpine:${alpine_version} ${ECR_REPO}/${ECR_CUSTOMER}_alpine:${alpine_majorversion}
    echo "docker push ${ECR_REPO}/${ECR_CUSTOMER}_alpine:${alpine_majorversion}" >> push_to_ecr.sh

    echo "INFO: Image: ${ECR_REPO}/${ECR_CUSTOMER}_alpine:latest"
    docker tag ${ECR_REPO}/${ECR_CUSTOMER}_alpine:${alpine_version} ${ECR_REPO}/${ECR_CUSTOMER}_alpine:latest
    echo "docker push ${ECR_REPO}/${ECR_CUSTOMER}_alpine:latest" >> push_to_ecr.sh

    #SAVE LAST USED DOCKER HUB VERSION alpine:latest TO ECR
    # => Needed in next compare round.
    echo "INFO: Image: ${ECR_REPO}/docker_hub_alpine:previous_latest"
    docker tag alpine:latest ${ECR_REPO}/docker_hub_alpine:previous_latest
    echo "docker push ${ECR_REPO}/docker_hub_alpine:previous_latest" >> push_to_ecr.sh

    #OFFER FLAG WHEN IMAGES ARE UPGRADED
    touch alpine_is_upgraded
}

# ACTION IF customer IMAGE IS DIFFERENT THAN DOCKER HUB IMAGE
echo "INFO: alpine:latest compare to ${ECR_REPO}/docker_hub_alpine:previous_latest"
echo "INFO: previous_latest hash: ${ecr_hash}"
echo "INFO: latest          hash: ${docker_hub_hash}"
if [ "${docker_hub_hash}" != "${ecr_hash}" ]
then
    echo "INFO: alpine:latest image updated! => Build new versions of ${ECR_REPO}/${ECR_CUSTOMER}_alpine"
    upgrade_alpine_images
else
    echo "INFO: No changes in alpine image, ${ECR_REPO}/docker_hub_alpine:previous_latest is same than docker.io/alpine:latest"
    if [ ${PRODUCTION} = true ];
    then
        docker pull ${ECR_REPO}/${ECR_CUSTOMER}_alpine:latest
    fi
    echo "INFO: Check is system package upgrades needed to ${ECR_REPO}/${ECR_CUSTOMER}_alpine:latest"
    alpine_system_upgrade=$(echo `docker run --rm -u root ${ECR_REPO}/${ECR_CUSTOMER}_alpine:latest /check_is_upgrade_needed.sh` | grep -o "SYSTEM UPGRADE NEEDED"; /bin/true)
    # ACTION IF customer SYSTEM UPGRADE NEEDED
    if [ ! -z "${alpine_system_upgrade}" ]
    then
        echo "INFO: Alpine ${ECR_REPO}/${ECR_CUSTOMER}_alpine:latest SYSTEM UPGRADE NEEDED"
        upgrade_alpine_images
    else
        echo "INFO: NO UPGRADE NEEDED AT ALL"
    fi
fi
exit
