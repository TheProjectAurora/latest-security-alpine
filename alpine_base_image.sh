#!/bin/bash
set -e

# TESTING STARING POINT:
###  shoisko@DuuniWin10:~/repos/customers/adhoc/dockerpipeline$ docker image ls | grep alpine | grep -v python
###  alpine                                                 3.12.1              d6e46aa2470d        6 weeks ago         5.57MB
###  alpine                                                 latest              d6e46aa2470d        6 weeks ago         5.57MB
###  alpine                                                 3.11                f70734b6a266        7 months ago        5.61MB
###  ecr/docker_hub_alpine                                  previous_latest     f70734b6a266        7 months ago        5.61MB
###  shoisko@DuuniWin10:~/repos/customers/adhoc/dockerpipeline$

ECR_REPO="ecr"
ECR_CUSTOMER="customer"

#DOCKER HUB alpine:latest INFORMATION
docker pull alpine:latest
docker_hub_hash=$(docker inspect --format='{{index .RepoDigests 0}}' alpine:latest | grep -o sha.*)

# customer IN USE IMAGE INFORMATION
#---TEST---#docker pull ${ECR_REPO}/docker_hub_alpine:previous_latest
ecr_hash=$(docker inspect --format='{{index .RepoDigests 0}}' ${ECR_REPO}/docker_hub_alpine:previous_latest | grep -o sha.*)

# ACTION IF customer IMAGE IS DIFFERENT THAN DOCKER HUB IMAGE
if [ "${docker_hub_hash}" != "${ecr_hash}" ]
then
    echo "INFO: alpine:latest image updated! => Build new version of ${ECR_REPO}/customer_alpine"

    #SOLVE ALPINE VERSION FROM DOCKER HUB: alpine:latest
    alpine_version=$( docker run -it --rm alpine:latest /bin/cat /etc/alpine-release |  tr -d '\r' )

    # BUILD customer_base_alpine WITH:
    # - Security upgrades
    # - notroot user
    # - alpine_information.txt
    echo "set -xa" | tee alpine_information.sh
    echo "export IMAGE_INFO=${ECR_REPO}/customer_alpine:${alpine_version}" | tee -a alpine_information.sh
    echo "export IMAGE_VERSION=${alpine_version}" | tee -a alpine_information.sh
    echo "export BUILD_TIMESTAMP=$(date)" | tee -a alpine_information.sh
    echo "export BUILD_JOB=PIPELINE JOB NUMBER HERE" | tee -a alpine_information.sh
    #BAKE ${ECR_REPO}/customer_alpine:${alpine_version}
    docker build -t ${ECR_REPO}/customer_alpine:${alpine_version} .
    #---TEST---#docker push ${ECR_REPO}/customer_alpine:${alpine_version}
    # NOTE: This is a version that is in use as base image in rest of alpine based images in customer
    docker tag ${ECR_REPO}/customer_alpine:${alpine_version} ${ECR_REPO}/customer_alpine:latest
    #---TEST---#docker push ${ECR_REPO}/customer_alpine:latest

    #SAVE LAST USED DOCKER HUB VERSION alpine:latest TO ECR 
    # => Needed in next compare round.
    docker tag alpine:latest ${ECR_REPO}/docker_hub_alpine:previous_latest
    #---TEST---#docker push ${ECR_REPO}/docker_hub_alpine:latest
else
    echo "INFO: No changes in image! ${ECR_REPO}/docker_hub_alpine:previous_latest IS SAME THAN alpine:latest"
fi
exit