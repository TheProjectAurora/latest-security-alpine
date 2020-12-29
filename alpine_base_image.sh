#!/bin/bash
set -e
rm -f alpine_is_upgraded

# TESTING STARING POINT:
###  $ docker image ls | grep alpine | grep -v python
###  alpine                                                 3.12.1              d6e46aa2470d        6 weeks ago         5.57MB
###  alpine                                                 latest              d6e46aa2470d        6 weeks ago         5.57MB
###  alpine                                                 3.11                f70734b6a266        7 months ago        5.61MB
###  ecr/docker_hub_alpine                                  previous_latest     f70734b6a266        7 months ago        5.61MB


#NOTE: CHANGE THESE BEFORE REAL USAGE
# REMOVE FROM FILE LINE BEGINNINGS: ####### ACTIVATE WHEN IN USE #######
ECR_REPO="ecr"
ECR_CUSTOMER="customer"

#DOCKER HUB alpine:latest INFORMATION
docker pull alpine:latest
docker_hub_hash=$(docker image ls --format "{{.ID}}" alpine:latest)

####### ACTIVATE WHEN IN USE #######docker pull ${ECR_REPO}/docker_hub_alpine:previous_latest
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
    echo "INFO: No changes in image! ${ECR_REPO}/docker_hub_alpine:previous_latest IS SAME THAN alpine:latest"
    ####### ACTIVATE WHEN IN USE #######docker pull ${ECR_REPO}/${ECR_CUSTOMER}_alpine:latest
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
