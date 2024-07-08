#!/usr/bin/env bash

GIT_DIR=$(git rev-parse --git-dir)
if [ $? -ne 0 ]; then
    echo "不是git项目，安装失败！"
    exit 1
fi
cd $GIT_DIR/..

gitBranch="develop"
folderScripts="scripts"
preCommitFile="./pre-commit.sh"
installFile="guard-install.sh"

echo "installing..."

if [ ! -d $folderScripts ]; then
  mkdir $folderScripts
fi

if [ ! -d $GIT_DIR/hooks ]; then
  mkdir $GIT_DIR/hooks
fi

if [ -f $GIT_DIR/hooks/pre-commit ]; then
  rm -f $GIT_DIR/hooks/pre-commit
fi

ln -s ../../scripts/$preCommitFile $GIT_DIR/hooks/pre-commit

echo "安装完成!"

# rm -rf $installFile
