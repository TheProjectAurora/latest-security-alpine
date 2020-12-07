# latestalpine
Script that use alpine:latest and solve it version. 
If alpine:latest is changed from previous round it bake ecr/customer_alpine:latest and ecr/customer_alpine:&lt;version> images with inbuilded security. 

# TEST USAGE:
docker pull alpine:3.11
docker tag alpine:3.11 ecr/docker_hub_alpine:previous_latest
./alpine_base_image.s
## RESULT:
shoisko@DuuniWin10:~/repos/github/Aurora/latestalpine$ docker image ls | grep alpine
ecr/customer_alpine                                    3.12.1              7488510fd20f        4 seconds ago       6.32MB
ecr/customer_alpine                                    latest              7488510fd20f        4 seconds ago       6.32MB
ecr/docker_hub_alpine                                  previous_latest     d6e46aa2470d        6 weeks ago         5.57MB
alpine                                                 latest              d6e46aa2470d        6 weeks ago         5.57MB
alpine                                                 3.11                f70734b6a266        7 months ago        5.61MB