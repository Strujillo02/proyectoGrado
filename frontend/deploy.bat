@echo off
setlocal

echo Limpiando proyecto...
call flutter.bat clean

echo Obteniendo dependencias...
call flutter.bat pub get

echo Compilando APK...
call flutter.bat build apk --release

REM IDs de tus dispositivos
set DEVICE1=R58N225A25R
set DEVICE2=ZY326RJXH4

echo Instalando en dispositivo %DEVICE1%...
call flutter.bat install -d %DEVICE1%

echo Instalando en dispositivo %DEVICE2%...
call flutter.bat install -d %DEVICE2%

echo Instalacion completada en ambos dispositivos.
pause
