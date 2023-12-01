@echo off
del .\compiled\assembled\* /q /s
xcopy  .\compiled\*.exe .\compiled\assembled\*
xcopy  .\LICENSE* .\compiled\assembled\LICENSE*
xcopy .\assets\appIcon.ico .\compiled\assembled\assets\
xcopy  .\assets\Scripts .\compiled\assembled\Scripts /S /E /Q /Y /I /R /K

set "folderPath=.\compiled\assembled"

REM Get the name of the first file in the "assembled" folder that matches the pattern "AHKser*"
for %%F in ("%folderPath%\AHKser.exe") do set "baseFileName=%%~nF"

cd "%folderPath%"

powershell Compress-Archive -Path * -DestinationPath "..\..\release\%baseFileName%-compiled.zip" -Force

echo Zip file %baseFileName%-compiled.zip has been created in ".\release"

cd "..\..\"

del .\compiled\assembled\* /q /s
xcopy  .\AHKser.ahk .\compiled\assembled\
xcopy  .\LICENSE* .\compiled\assembled\LICENSE*
xcopy .\assets\appIcon.ico .\compiled\assembled\assets\
xcopy  .\assets\Scripts .\compiled\assembled\Scripts /S /E /Q /Y /I /R /K

set "folderPath=.\compiled\assembled"

REM Get the name of the first file in the "assembled" folder that matches the pattern "AHKser*"
for %%F in ("%folderPath%\AHKser.ahk") do set "baseFileName=%%~nF"

cd "%folderPath%"

powershell Compress-Archive -Path * -DestinationPath "..\..\release\%baseFileName%-uncompiled.zip" -Force

echo Zip file %baseFileName%-uncompiled.zip has been created in ".\release"
