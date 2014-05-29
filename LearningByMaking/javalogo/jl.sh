#!/bin/bash
set -o history
set -f
(while true; do read -e lastcmd; history -s $lastcmd; echo $lastcmd; done) | java -jar jl.jar

