#!/bin/bash

# [Script run by build-electron workflow]
# Replaces the version numbers in init.js, service-worker.js and package.json with the following priority:
#
# 1. use the override value set in the workflow dispatch;
# 2. use the tag pattern (if there is a tag and no override value was set)
#
# This script can be tested manually by replacing ${INPUT_VERSION} and ${TAG_VERSION}
# with test strings

# Use the override value by preference
VERSION=${INPUT_VERSION}
# If the script was launched by Cron, then there will be no INPUT_VERSION, so construct a nightly version number
if [[ "qq${CRON_LAUNCHED}" != "qq" ]]; then
  echo "This script was launched by the GitHub Cron job"
  COMMIT_ID=$(git rev-parse --short HEAD)
  # Get version from init.js
  VERSION="$(grep 'params\[.appVersion' www/js/init.js | sed -E "s/[^[:digit:]]+([^\"']+).*/\1/")"
  VERSION="v$VERSION-$COMMIT_ID"
fi
if [[ $VERSION =~ ^v?[0-9.]+ ]]; then
  VERSION=$(sed 's/^v//' <<<"$VERSION") # Remove any leading v
  echo "Using the valid override input and setting version to $VERSION"
else
  # If no valid override input was entered, then try to use the release tag
  VERSION=${TAG_VERSION}
  if [[ $VERSION =~ ^v?[0-9.]+ ]]; then
    VERSION=$(sed 's/^v//' <<<"$VERSION")
    echo "Using the release tag and setting version to $VERSION"
  else
    echo "No valid override or tag was provided. File version numbers were unchanged."
    echo "To rewrite version numbers in app, ensure the tag matches ^v?[0-9.]+"
  fi
fi
# If Version matches a release pattern, then set the appVersion in the files to be published
if [[ $VERSION =~ ^[0-9.]+ ]]; then
  echo "Rewriting appVersion in service-worker.js and init.js to $VERSION ..."
  sed -i -E "s/appVersion\s*=\s*[^;]+/appVersion = '$VERSION'/" ./service-worker.js
  sed -i -E "s/params..appVersion[^=]+?=\s*[^;]+/params['appVersion'] = '$VERSION'/" ./www/js/init.js
  echo "Rewriting version in package.json to $VERSION-E"
  sed -i -E 's/"version":\s*"[^"]+"/"version": "'$VERSION'-E"/' ./package.json
fi