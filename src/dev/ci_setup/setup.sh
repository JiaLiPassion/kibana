#!/usr/bin/env bash

set -e

source src/dev/ci_setup/setup_env.sh true

echo " -- KIBANA_DIR='$KIBANA_DIR'"
echo " -- XPACK_DIR='$XPACK_DIR'"
echo " -- PARENT_DIR='$PARENT_DIR'"
echo " -- KIBANA_PKG_BRANCH='$KIBANA_PKG_BRANCH'"
echo " -- TEST_ES_SNAPSHOT_VERSION='$TEST_ES_SNAPSHOT_VERSION'"

###
### copy .bazelrc-ci into $HOME/.bazelrc
###
cp "src/dev/ci_setup/.bazelrc-ci" "$HOME/.bazelrc";

###
### append auth token to buildbuddy into "$HOME/.bazelrc";
###
echo "# Appended by src/dev/ci_setup/setup.sh" >> "$HOME/.bazelrc"
echo "build --remote_header=x-buildbuddy-api-key=$KIBANA_BUILDBUDDY_CI_API_KEY" >> "$HOME/.bazelrc"

if [[ "$BUILD_TS_REFS_CACHE_ENABLE" != "true" ]]; then
  export BUILD_TS_REFS_CACHE_ENABLE=false
fi

###
### install dependencies
###
echo " -- installing node.js dependencies"
yarn kbn bootstrap --verbose

###
### upload ts-refs-cache artifacts as quickly as possible so they are available for download
###
if [[ "$BUILD_TS_REFS_CACHE_CAPTURE" == "true" ]]; then
  cd "$KIBANA_DIR/target/ts_refs_cache"
  gsutil cp "*.zip" 'gs://kibana-ci-ts-refs-cache/'
  cd "$KIBANA_DIR"
fi

if [[ "$DISABLE_BOOTSTRAP_VALIDATIONS" != "true" ]]; then
  source "$KIBANA_DIR/src/dev/ci_setup/bootstrap_validations.sh"
fi

###
### Download es snapshots
###
echo " -- downloading es snapshot"
node scripts/es snapshot --download-only;
