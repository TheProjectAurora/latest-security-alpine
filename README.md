# General information
Script that use docker.io/alpine:latest from docker hub and solve it version by using docker.io/alpine:latest@/etc/alpine-release file content. 
If docker.io/alpine:latest is changed from previous round (registry/docker_hub_alpine:latest) it bake registry/customer_alpine:latest and registry/customer_alpine:< version > images with inbuilded security. If docker.io/alpine:latest up to date version is in use then it check registry/customer_alpine:latest system upgrades and bake new versions of registry/customer_alpine images is system upgrades to images is required. 

# USAGE:
Before use ```docker login registry``` should be executed succesfully.
Use -t parameter if you don't wanna push images to your registry.
## First execution round and RE-execute with simulation when docker.io/alpine:latest is updated
Just initialize registry/docker_hub_alpine:previous_latest to shape so it could be used in next round. 
```
./alpine_base_image.sh -r registry -n asiakas -i
```
## EXECUTION: 
```
./alpine_base_image.sh -r registry -n customer
```
## RESULT:
Script pull alpine:latest and based to that create registry/customer_alpine tagged with 3, 3.12.1 and latest => Those sematic versions it get from alpine:latest image
```
$ docker image ls | grep alpine
registry/customer_alpine               3                   7488510fd20f        4 seconds ago       6.32MB
registry/customer_alpine               3.12.1              7488510fd20f        4 seconds ago       6.32MB
registry/customer_alpine               latest              7488510fd20f        4 seconds ago       6.32MB
registry/docker_hub_alpine             previous_latest     d6e46aa2470d        6 weeks ago         5.57MB
alpine                            latest              d6e46aa2470d        6 weeks ago         5.57MB
alpine                            3.11                f70734b6a266        7 months ago        5.61MB
```

## Functionality / Helper files of alpine_base_image.sh:
- Generate image_information.txt file and bake it inside of ecr/customer_alpine images (it keep tracability even latest tag images are in use)
- check_is_upgrade_needed.sh is baked it inside of ecr/customer_alpine images. It purpose is check is system level component upgrades needed "e.g. using apk upgrade" and if upgrades is needed print out "SYSTEM UPGRADE NEEDED". Similar way upgrade checking could be implemented by using other package management tools e.g pip. It doesn't matter how manytimes "SYSTEM UPGRADE NEEDED" is printed to STDOUT. Script is utilized in alpine_base_image.sh and in upstrem pipeline trigger.
- Create alpine_is_upgraded if docker.io/alpine:latest or system component upgrade is done to ecr/customer_alpine
- Create push_to_registry.sh script that inclde information what ecr/customer_alpine images are needed to push ECR
- alpine_base_image_POST_actions.sh check does alpine_is_upgraded exist and is images upgraded. If images are upgraded it execute trivy against images and push those to ECR by using push_to_registry.sh and end of all trick upstream pippelines (e.g. customer_alpine_jre and customer_alpine_node that utilize ecr/customer_alpine:latest).
- Pipeline of customer_alpine have to be trigged by cron every day at 12:00

## Simulation when registry/customer_alpine need system components upgrade
Execute these with -t parameter:
- [Execute initialize phase](https://github.com/TheProjectAurora/latestalpine#first-execution-round-and-re-execute-with-simulation-when-dockerioalpinelatest-is-updated) (get registry/docker_hub_alpine:previous_latest to shape)
- [Execute EXECUTION phase](https://github.com/TheProjectAurora/latestalpine#execution) (registry/docker_hub_alpine:previous_latest to shape)
- Execution phase should give result: INFO: NO UPGRADE NEEDED AT ALL
- Execute mocking: ```docker build -t registry/customer_alpine:latest -f testing/Dockerfile .```
- [Execute EXECUTION phase](https://github.com/TheProjectAurora/latestalpine#execution) registry/docker_hub_alpine:previous_latest is on shape but it realize: INFO: Check is system package upgrades needed...
- It should print "INFO: SYSTEM UPGRADE NEEDED to registry/asiakas_alpine:latest" and made system upgrade by compiling whole image from scrach.

## Pipeline should look like:
Pipeline that keep regisry/alpine:< tag > images automaticly uptodate and build in security to those.
1. Execute: ```docker login registry```
1. Execute alpine_base_image.sh
1. if alpine_is_upgraded exist then continue pipeline otherwhize quit qith exit 0.
1. Execute https://github.com/aquasecurity/trivy against registry/asiakas_alpine:latest
1. Execute push_to_registry.sh
RESULT it [maintain regisry/alpine:tag images automaticly](https://github.com/TheProjectAurora/latestalpine#result).

# FYI
Upstream pipelines could update check_is_upgrade_needed.sh. Add there check by using all package controll method that are used in upstream pipelines. If that package controll app need update it just need to print to STDOUT message "SYSTEM UPGRADE NEEDED". Then system upgrade checking could happened similar way than in alpine_base_image.sh in lines after "ACTION IF customer SYSTEM UPGRADE NEEDED" comment. That kind of "checking script" could be own pipeline where it check upstream image upgrade and trig upstream pipeline if that upstream componen upgrade is needed.