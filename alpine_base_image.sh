#!/bin/bash
set -e
rm -f alpine_is_upgraded

# TESTING STARING POINT:
###  $ docker image ls | grep alpine | grep -v python
###  alpine                                                 3.12.1              d6e46aa2470d        6 weeks ago         5.57MB
###  alpine                                                 latest              d6e46aa2470d        6 weeks ago         5.57MB
###  alpine                                                 3.11                f70734b6a266        7 months ago        5.61MB
###  ecr/docker_hub_alpine                                  previous_latest     f70734b6a266        7 months ago        5.61MB


ECR_REPO="ecr"
ECR_CUSTOMER="customer"

#DOCKER HUB alpine:latest INFORMATION
docker pull alpine:latest
docker_hub_hash=$(docker inspect --format='{{index .RepoDigests 0}}' alpine:latest | grep -o sha.*)

# customer IN USE IMAGE INFORMATION
#---TEST---#docker pull ${ECR_REPO}/docker_hub_alpine:previous_latest
ecr_hash=$(docker inspect --format='{{index .RepoDigests 0}}' ${ECR_REPO}/docker_hub_alpine:previous_latest | grep -o sha.*)

upgrade_alpine_images () {  
    #SOLVE ALPINE VERSION FROM DOCKER HUB: alpine:latest
    alpine_version=$( docker run -it --rm alpine:latest /bin/cat /etc/alpine-release |  tr -d '\r' )
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
    docker build -t ${ECR_REPO}/${ECR_CUSTOMER}_alpine:${alpine_version} .
    #---TEST---#docker push ${ECR_REPO}/${ECR_CUSTOMER}_alpine:${alpine_version}
    docker tag ${ECR_REPO}/${ECR_CUSTOMER}_alpine:${alpine_version} ${ECR_REPO}/${ECR_CUSTOMER}_alpine:${alpine_majorversion}
    #---TEST---#docker push ${ECR_REPO}/${ECR_CUSTOMER}_alpine:${alpine_majorversion}
    docker tag ${ECR_REPO}/${ECR_CUSTOMER}_alpine:${alpine_version} ${ECR_REPO}/${ECR_CUSTOMER}_alpine:latest
    #---TEST---#docker push ${ECR_REPO}/${ECR_CUSTOMER}_alpine:latest

    #SAVE LAST USED DOCKER HUB VERSION alpine:latest TO ECR 
    # => Needed in next compare round.
    docker tag alpine:latest ${ECR_REPO}/docker_hub_alpine:previous_latest
    #---TEST---#docker push ${ECR_REPO}/docker_hub_alpine:latest

    #OFFER FLAG WHEN IMAGES ARE UPGRADED
    touch alpine_is_upgraded
}

# ACTION IF customer IMAGE IS DIFFERENT THAN DOCKER HUB IMAGE
if [ "${docker_hub_hash}" != "${ecr_hash}" ]
then
    echo "INFO: alpine:latest image updated! => Build new versions of ${ECR_REPO}/${ECR_CUSTOMER}_alpine"
    upgrade_alpine_images
else
    echo "INFO: No changes in image! ${ECR_REPO}/docker_hub_alpine:previous_latest IS SAME THAN alpine:latest"
    alpine_system_upgrade=$(echo `docker run -it --rm -u root ecr/${ECR_CUSTOMER}_alpine:latest /check_is_upgrade_needed.sh` | grep -o "SYSTEM UPGRADE NEEDED"; /bin/true)
    # ACTION IF customer SYSTEM UPGRADE NEEDED
    if [ ! -z "${alpine_system_upgrade}" ]
    then
        echo "INFO: Alpine images:${ECR_REPO}/docker_hub_alpine SYSTEM UPGRADE NEEDED"
        upgrade_alpine_images
    else
        echo "INFO: NO UPGRADE NEEDED AT ALL"
    fi
fi
exit