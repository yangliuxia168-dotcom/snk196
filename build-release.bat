@echo off
chcp 65001 >nul
echo ============================================
echo  CQ即时通讯 - Flutter客户端多平台构建脚本
echo ============================================
echo.

:: 检查Flutter环境
flutter --version >nul 2>&1
if errorlevel 1 (
    echo [错误] 未找到Flutter SDK，请先安装Flutter
    echo 下载地址: https://docs.flutter.dev/get-started/install
    pause
    exit /b 1
)

:: 进入项目目录
cd /d "%~dp0"

:: 步骤1: 生成平台目录(如果不存在)
if not exist "android" (
    echo [1/6] 生成平台目录...
    flutter create --org com.cq --project-name cq_app --platforms=android,ios,windows,web .
) else (
    echo [1/6] 平台目录已存在，跳过
)

:: 步骤2: 清理缓存
echo [2/6] 清理构建缓存...
flutter clean

:: 步骤3: 获取依赖
echo [3/6] 获取依赖包...
flutter pub get

:: 步骤4: 创建输出目录
if not exist "build_output" mkdir build_output

:: 步骤5: 构建各平台
echo [4/6] 构建Android APK...
flutter build apk --release
if errorlevel 1 (
    echo [警告] Android APK构建失败
) else (
    copy /Y "build\app\outputs\flutter-apk\app-release.apk" "build_output\CQ-v1.0.0-android.apk"
    echo [成功] Android APK -> build_output\CQ-v1.0.0-android.apk
)

echo [5/6] 构建Windows桌面应用...
flutter build windows --release
if errorlevel 1 (
    echo [警告] Windows构建失败
) else (
    echo [成功] Windows应用 -> build\windows\x64\runner\Release\
    :: 打包Windows为zip
    powershell -Command "Compress-Archive -Path 'build\windows\x64\runner\Release\*' -DestinationPath 'build_output\CQ-v1.0.0-windows.zip' -Force"
    echo [成功] Windows ZIP -> build_output\CQ-v1.0.0-windows.zip
)

echo [6/6] 构建Web版本...
flutter build web --release
if errorlevel 1 (
    echo [警告] Web构建失败
) else (
    powershell -Command "Compress-Archive -Path 'build\web\*' -DestinationPath 'build_output\CQ-v1.0.0-web.zip' -Force"
    echo [成功] Web ZIP -> build_output\CQ-v1.0.0-web.zip
)

echo.
echo ============================================
echo  构建完成! 输出目录: build_output\
echo ============================================
echo.
echo 注意:
echo  - iOS构建需要macOS + Xcode环境
echo    命令: flutter build ipa --release
echo  - 鸿蒙系统暂用Web版本替代(PWA模式)
echo.
dir build_output\
echo.
pause
