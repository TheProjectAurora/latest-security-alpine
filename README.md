# General information
Script that use alpine:latest and solve it version by using alpine:latest@/etc/alpine-release file content. If alpine:latest is changed from previous round it bake ecr/customer_alpine:latest and ecr/customer_alpine:< version > images with inbuilded security. If alpine:latest version is in use then it check ecr/customer_alpine:latest system upgrades and bake new versions of ecr/customer_alpine images is system upgrades to images is required. 

# USAGE:
NOTE: ecr is your docker registry. Log in to that registry before executing these. 
## First execution round execute:
```
docker pull alpine:3.11
docker tag alpine:3.11 ecr/docker_hub_alpine:previous_latest
docker push ecr/docker_hub_alpine:previous_latest
```
## After first round script should work right away. 
```
./alpine_base_image.sh
```
## RESULT:
Script pull alpine:latest and based to that create ecr/customer_alpine tagged with 3, 3.12.1 and latest => Those sematic versions it get from alpine:latest image
```
$ docker image ls | grep alpine
ecr/customer_alpine                                    3                   7488510fd20f        4 seconds ago       6.32MB
ecr/customer_alpine                                    3.12.1              7488510fd20f        4 seconds ago       6.32MB
ecr/customer_alpine                                    latest              7488510fd20f        4 seconds ago       6.32MB
ecr/docker_hub_alpine                                  previous_latest     d6e46aa2470d        6 weeks ago         5.57MB
alpine                                                 latest              d6e46aa2470d        6 weeks ago         5.57MB
alpine                                                 3.11                f70734b6a266        7 months ago        5.61MB
```

# CLEANUP & re-execute
1. delete all ecr/customer_alpine images
2. tag "alpine:3.11 ecr/docker_hub_alpine:previous_latest"