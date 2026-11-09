@echo off
python "%~dp0/tools/build.py" %*
exit /b %errorlevel%
