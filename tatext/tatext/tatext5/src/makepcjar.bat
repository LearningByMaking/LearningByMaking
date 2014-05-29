echo off
copy Logo.java logo.class
del *.class
copy ..\startup.logo startup.logo
javac -source 1.4 *.java
jar -cmf manifest.mf ..\tatext.jar *.class *.java startup.logo makepcjar.bat manifest.mf images
del *.class


