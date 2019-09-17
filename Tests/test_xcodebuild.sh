#!/bin/bash

set -e
set -o pipefail

swift package resolve
swift package generate-xcodeproj
sudo xcode-select --switch /Applications/$1.app/Contents/Developer

xcodebuild -version
xcodebuild build -scheme SwiftlierUIKit-Package \
  -sdk iphonesimulator -destination "$IOS_DEVICE" | xcpretty
