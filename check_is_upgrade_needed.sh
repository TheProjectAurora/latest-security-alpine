#!/bin/sh
#USAGE:
# docker run -it --rm -u root ecr/customer_alpine:3.12.1 /check_is_upgrade_needed.sh
set -e
apk upgrade --no-cache --ignore  | grep -q Upgrading && echo SYSTEM UPGRADE NEEDED