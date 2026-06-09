@echo off
echo Starting DevEco Studio with HarmonyOS JDK...

REM Set JDK environment
set JAVA_HOME=D:\DevEco Studio\jbr
set PATH=D:\DevEco Studio\jbr\bin;%PATH%

echo JAVA_HOME=%JAVA_HOME%
echo.

REM Start DevEco Studio
start "" "D:\DevEco Studio\bin\devecostudio64.exe"

echo DevEco Studio started with HarmonyOS JDK
pause