#!/bin/bash
set -o history
set -f
sudo chmod 777 /dev/ttyUSB*
(while true; do read -e lastcmd; history -s $lastcmd; echo $lastcmd; done) | java -jar /usr/share/javalogo/jl.jar "$@"

