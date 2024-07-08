#!/bin/bash

set -e

ver=`grep -m 1 '^version:' pubspec.yaml | awk '{print $2}'`
ver=${ver##'version: '}
time=$(date "+%y%m%d")
echo "> Check version from 'pubspec.yaml': '$ver'."
echo "c1miz2d3DhYeV7P1" | dart pub token add https://dart.cloudsmith.io/workspace-for-wai-loon/sportsdk_package/
android() {
  echo "> Now begin building apk."

  # [--target-platform android-arm]: 指定构建 ARM 架构
  # [--shrink] 代码压缩
  # [--obfuscate] 代码混淆
  # [--split-debug-info=./build/debuginfo] 指定调试信息目录，进一步减小包大小
  flutter build apk  --shrink --obfuscate --split-debug-info=./build/debuginfo
   # 检查构建是否成功
  if [ $? -ne 0 ]; then
    echo "Error: Export failed."
    exit 1
  fi

  # 移动并重命名生成的 APK 文件
  ipa_name='live_sports_app';
  apk_path="./build/app/outputs/apk/release/app-release.apk"
  if [ -f "$apk_path" ]; then
    mv "$apk_path" "/Users/ec2-user/dev/dist/android/${ipa_name}.apk"
    echo "> Built andriod done. '/Users/ec2-user/dev/dist/andriod/${ipa_name}.apk'"
  else
    echo "Error: APK file not found."
    exit 1
  fi

}


pub() {
  # Step 3: Copy the new build to the server
  echo "开始复制资源文件"
  scp -v -o StrictHostKeyChecking=no -i ${centos} -r ./dist/'sports_'$time'_'$ver'.apk' centos@ec2-16-163-214-1.ap-east-1.compute.amazonaws.com:/home/app/android
}

android

# echo "centos:${centos}"
# if [ -f ${centos} ]; then
#   # pub
# fi
