del .\compiled\assembled\* /q /s
xcopy  .\compiled\*.exe .\compiled\assembled\*
xcopy  .\LICENSE* .\compiled\assembled\LICENSE*
xcopy  .\README* .\compiled\assembled\README*
xcopy  .\CHANGELOG* .\compiled\assembled\CHANGELOG*
xcopy  .\assets\Scripts .\compiled\assembled\Scripts /S /E /Q /Y /I /R /K

set "folderPath=.\compiled\assembled"

REM Get the name of the first file in the "assembled" folder that matches the pattern "AHKser*"
for %%F in ("%folderPath%\AHKser.exe") do set "baseFileName=%%~nF"

cd "%folderPath%"

powershell Compress-Archive -Path * -DestinationPath "..\..\%baseFileName%.zip" -Force

echo Zip file %baseFileName%.zip has been created in %folderPath%
