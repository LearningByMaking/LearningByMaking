#!/bin/sh

unzip LearningByMaking.zip
sudo cp -r javalogo/ /usr/share/javalogo
sudo chmod 777 LearningByMaking/ulogo/run.sh
unzip tatext.zip -d TurtleLogo
unzip CGM101V14.zip -d Oscilloscope
cd Oscilloscope
sudo sh Install-Linux-64-bit.sh
sudo chmod 777 CGM101-linux-x86-64

