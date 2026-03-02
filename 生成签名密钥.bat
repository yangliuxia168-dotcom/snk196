@echo off
chcp 65001 >nul
echo ============================================
echo  Android 应用签名密钥生成工具
echo ============================================
echo.
echo 此工具将生成用于 Android 应用签名的密钥文件
echo 密钥信息请妥善保管，丢失后无法更新应用！
echo.
pause
echo.

echo [1/3] 生成密钥库文件...
echo.
keytool -genkey -v -keystore android\app\cq_app_key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias cq_app

if errorlevel 1 (
    echo.
    echo [错误] 密钥生成失败！
    echo 请检查是否安装了 Java JDK
    pause
    exit /b 1
)

echo.
echo [2/3] 配置密钥信息...
echo.
set /p STORE_PASSWORD=请输入刚才设置的密钥库密码: 
set /p KEY_PASSWORD=请输入刚才设置的别名密码: 

echo storePassword=%STORE_PASSWORD%> android\key.properties
echo keyPassword=%KEY_PASSWORD%>> android\key.properties
echo keyAlias=cq_app>> android\key.properties
echo storeFile=cq_app_key.jks>> android\key.properties

echo.
echo [3/3] 完成！
echo.
echo ============================================
echo  密钥文件已生成！
echo ============================================
echo.
echo 密钥文件位置: android\app\cq_app_key.jks
echo 配置文件位置: android\key.properties
echo.
echo 重要提示:
echo 1. 请妥善保管密钥文件和密码
echo 2. 不要将密钥文件提交到代码仓库
echo 3. 建议备份密钥文件到安全位置
echo.
pause
