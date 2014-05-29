#!/bin/bash 
rm -f *.class
javac *.java
jar -cmf manifest.mf ../jl.jar *.class *.java makejar.sh pcmakejar.bat manifest.mf
rm *.class
