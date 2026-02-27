@echo off
echo =========================================
echo  Asterisk VoIP App - Android Build Script
echo =========================================
echo.

:: Check if flutter is installed
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Flutter is not installed or not in your PATH.
    echo Please install Flutter and try again.
    pause
    exit /b 1
)

echo [INFO] Getting packages...
call flutter pub get
if %errorlevel% neq 0 (
    echo [ERROR] Failed to get packages.
    pause
    exit /b 1
)

echo [INFO] Building Android APK...
call flutter build apk --release
if %errorlevel% neq 0 (
    echo [ERROR] Build failed.
    pause
    exit /b 1
)

echo.
echo =========================================
echo [SUCCESS] Build completed!
echo Your APK is located at:
echo build\app\outputs\flutter-apk\app-release.apk
echo.
echo Make sure your Android device is connected and USB debugging is enabled,
echo then press any key to install and run it on your device...
pause

echo [INFO] Installing to device...
call flutter install

echo [INFO] Done!
pause
