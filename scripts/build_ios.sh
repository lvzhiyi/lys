#!/bin/bash

# 解锁钥匙串

#security -v unlock-keychain -p "123456" /Users/ec2-user/Library/Keychains/login.keychain
#security import /Users/ec2-user/Desktop/distribution.p12 -k /Users/ec2-user/Library/Keychains/login.keychain-db -P "123456" -A
# codesign --force --sign "915AE405306E9787C44959611B9EBA2554EC0B35" /Users/eccodesign --force --sign "915AE405306E9787C44959611B9EBA2554EC0B35" /Users/ec2-user/dev/workspace/app-ios-pub/build/ios/Release-iphoneos/App.framework/App
# security import /Users/ec2-user/Desktop/sports.p12 -k /Users/ec2-user/Library/Keychains/login.keychain-db -P "123456" -A
# 解锁钥匙串
# security unlock-keychain -p "123456" /Users/ec2-user/Library/Keychains/login.keychain-db

# # 设置钥匙串搜索路径
# security list-keychains -s /Users/ec2-user/Library/Keychains/login.keychain-db login.keychain

# # 导入证书
# security import /Users/ec2-user/Desktop/sports.p12 -k /Users/ec2-user/Library/Keychains/login.keychain-db -P "123456" -A

# # 设置钥匙串超时
# security set-keychain-settings -lut 7200 /Users/ec2-user/Library/Keychains/login.keychain-db
# security set-key-partition-list -v -S apple-tool:,apple: -s -k "123456" /Users/ec2-user/Library/Keychains/login.keychain-db

### INSERT BUILD COMMANDS HERE ###
# 从 pubspec.yaml 中获取版本号
ver=$(grep 'version:' pubspec.yaml | head -n 1 | awk '{print $2}')
time=$(date "+%y%m%d")
echo "> Check version from 'pubspec.yaml': '$ver'."

# 定义构建 iOS 应用的函数
build_ios() {
MY_KEYCHAIN="temp.keychain"
MY_KEYCHAIN_PASSWORD="secret"
CERT="/Users/ec2-user/Desktop/development.p12"
CERT_PASSWORD="123456"

security create-keychain -p "$MY_KEYCHAIN_PASSWORD" "$MY_KEYCHAIN" # Create temp keychain
security list-keychains -d user -s "$MY_KEYCHAIN" $(security list-keychains -d user | sed s/\"//g) # Append temp keychain to the user domain
security set-keychain-settings "$MY_KEYCHAIN" # Remove relock timeout
security unlock-keychain -p "$MY_KEYCHAIN_PASSWORD" "$MY_KEYCHAIN" # Unlock keychain
security import $CERT -k "$MY_KEYCHAIN" -P "$CERT_PASSWORD" -T "/usr/bin/codesign" # Add certificate to keychain
CERT_IDENTITY=$(security find-identity -v -p codesigning "$MY_KEYCHAIN" | head -1 | grep '"' | sed -e 's/[^"]*"//' -e 's/".*//') # Programmatically derive the identity
CERT_UUID=$(security find-identity -v -p codesigning "$MY_KEYCHAIN" | head -1 | grep '"' | awk '{print $2}') # Handy to have UUID (just in case)
security set-key-partition-list -S apple-tool:,apple: -s -k $MY_KEYCHAIN_PASSWORD -D "$CERT_IDENTITY" -t private $MY_KEYCHAIN # Enable codesigning from a non user interactive shell
  flutter build ipa --export-options-plist="./ios/ExportOptions.plist"
  # 检查构建是否成功
  if [ $? -ne 0 ]; then
    echo "Error: Export failed."
    exit 1
  fi

  # 移动并重命名生成的 IPA 文件
  ipa_name='live_sports_app';
  ipa_path="./build/ios/ipa/Apps/${ipa_name}.ipa"
  if [ -f "$ipa_path" ]; then
    mv "$ipa_path" "/Users/ec2-user/dev/dist/ios/${ipa_name}.ipa"
    echo "> Built iOS done. '/Users/ec2-user/dev/dist/ios/${ipa_name}.ipa'"
  else
    echo "Error: IPA file not found."
    exit 1
  fi
}

# 执行构建函数
build_ios
security delete-keychain "$MY_KEYCHAIN" # Delete temporary keychain
