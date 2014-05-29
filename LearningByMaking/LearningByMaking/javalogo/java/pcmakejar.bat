echo off
copy Logo.java logo.class
del *.class
copy ..\startup.logo startup.logo
javac -Xlint:unchecked *.java
jar -cmf manifest.mf ..\jl.jar *.class *.java pcmakejar.bat makejar.sh manifest.mf
del *.class


