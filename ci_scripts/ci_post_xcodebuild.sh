#!/bin/zsh

# ci_post_xcodebuild.sh
# This script runs after the build phase in Xcode Cloud

# Write to a file that TestFlight can use
#!/bin/zsh
#  ci_post_xcodebuild.sh


commit_message=$(git log -1 --pretty=%B)

if [[ -d "$CI_APP_STORE_SIGNED_APP_PATH" ]]; then
  TESTFLIGHT_DIR_PATH=../TestFlight
  mkdir $TESTFLIGHT_DIR_PATH
  echo "$commit_message" > $TESTFLIGHT_DIR_PATH/WhatToTest.en-US.txt
fi

echo "Release notes created with commit info"
echo "Commit: $CI_COMMIT - $commit_message"