#!/bin/bash

set -e
set -o pipefail

swift package resolve
sudo xcode-select --switch /Applications/$1.app/Contents/Developer

xcodebuild -version
xcodebuild build -scheme SwiftlierUIKit-Package \
  -sdk iphonesimulator -destination "$IOS_DEVICE" | xcpretty
