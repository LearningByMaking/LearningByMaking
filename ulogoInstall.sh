#!/bin/sh

unzip LearningByMaking.zip
sudo cp -r javalogo/ /usr/share/javalogo
cp -r ulogo/ LearningByMaking
rm -rf ulogo/ javalogo/
#rm -rf LearningByMaking.zip
