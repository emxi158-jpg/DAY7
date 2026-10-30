@echo off
setlocal
set "GODOT_EXE=D:\yingyong\godot4.6\Godot_v4.6-stable_win64.exe"
if not exist "%GODOT_EXE%" (
  echo Godot executable not found: %GODOT_EXE%
  pause
  exit /b 1
)
"%GODOT_EXE%" --path "%~dp0godot" res://main.tscn