@echo off
REM Windows helper — same as: dart run tool/bootstrap.dart
cd /d "%~dp0\.."
dart run tool/bootstrap.dart %*
