@echo off
echo Setting DevEco Studio JDK for current session...

REM Set environment variables for DevEco Studio
set JAVA_HOME=D:\DevEco Studio\jbr
set PATH=D:\DevEco Studio\jbr\bin;%PATH%

echo Environment variables set temporarily
echo JAVA_HOME=%JAVA_HOME%
echo.
echo Now try to build your project in DevEco Studio
pause