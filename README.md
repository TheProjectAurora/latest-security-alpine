# General information
Script that use docker.io/alpine:latest from docker hub and solve it version by using docker.io/alpine:latest@/etc/alpine-release file content. 
If docker.io/alpine:latest is changed from previous round (ecr/docker_hub_alpine:latest) it bake ecr/customer_alpine:latest and ecr/customer_alpine:< version > images with inbuilded security. If docker.io/alpine:latest up to date version is in use then it check ecr/customer_alpine:latest system upgrades and bake new versions of ecr/customer_alpine images is system upgrades to images is required. 

# USAGE:
NOTE: ecr is your docker registry. Log in to ecr registry before executing these. 
## First execution round and RE-execute with simulation when docker.io/alpine:latest is updated
```
docker pull alpine:3.11
docker tag alpine:3.11 ecr/docker_hub_alpine:previous_latest
docker push ecr/docker_hub_alpine:previous_latest
```
## Simulation when ecr/customer_alpine need system components upgrade
```
docker pull ecr/customer_alpine:3.12.1
docker tag ecr/customer_alpine:3.12.1 ecr/customer_alpine:latest
docker push ecr/customer_alpine:latest
```
## EXECUTION: 
```
./alpine_base_image.sh
```
## RESULT:
Script pull alpine:latest and based to that create ecr/customer_alpine tagged with 3, 3.12.1 and latest => Those sematic versions it get from alpine:latest image
```
$ docker image ls | grep alpine
ecr/customer_alpine               3                   7488510fd20f        4 seconds ago       6.32MB
ecr/customer_alpine               3.12.1              7488510fd20f        4 seconds ago       6.32MB
ecr/customer_alpine               latest              7488510fd20f        4 seconds ago       6.32MB
ecr/docker_hub_alpine             previous_latest     d6e46aa2470d        6 weeks ago         5.57MB
alpine                            latest              d6e46aa2470d        6 weeks ago         5.57MB
alpine                            3.11                f70734b6a266        7 months ago        5.61MB
```

## Functionality / Helper files of alpine_base_image.sh:
- Generate image_information.txt file and bake it inside of ecr/customer_alpine images (it keep tracability even latest tag images are in use)
- check_is_upgrade_needed.sh is baked it inside of ecr/customer_alpine images. It purpose is check is system level component upgrades needed "e.g. using apk upgrade" and if upgrades is needed print out "SYSTEM UPGRADE NEEDED". Similar way upgrade checking could be implemented by using other package management tools e.g pip. It doesn't matter how manytimes "SYSTEM UPGRADE NEEDED" is printed to STDOUT. Script is utilized in alpine_base_image.sh and in upstrem pipeline trigger.
- Create alpine_is_upgraded if docker.io/alpine:latest or system component upgrade is done to ecr/customer_alpine
- Create push_to_ecr.sh script that inclde information what ecr/customer_alpine images are needed to push ECR
- alpine_base_image_POST_actions.sh check does alpine_is_upgraded exist and is images upgraded. If images are upgraded it execute trivy against images and push those to ECR by using push_to_ecr.sh and end of all trick upstream pippelines (e.g. customer_alpine_jre and customer_alpine_node that utilize ecr/customer_alpine:latest).
- Pipeline of customer_alpine have to be trigged by cron every day at 12:00