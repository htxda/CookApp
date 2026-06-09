@echo off
echo Setting up HarmonyOS development environment...

REM Set DevEco Studio JDK path
set DEVECO_JDK=D:\DevEco Studio\jbr

REM Set environment variables temporarily
set JAVA_HOME=%DEVECO_JDK%
set PATH=%DEVECO_JDK%\bin;%PATH%

echo.
echo Configuration completed!
echo JAVA_HOME: %JAVA_HOME%
echo.
echo Verifying Java version:
java -version
echo.
echo Now please rebuild your project in DevEco Studio
pause