#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

testVersion()
{
  mkdir ${BUILD_DIR}/bin
  touch ${BUILD_DIR}/bin/detect
  touch ${BUILD_DIR}/bin/compile
  touch ${BUILD_DIR}/bin/release
  mkdir ${BUILD_DIR}/test
  
  detect
  assertCapturedSuccess
  assertCaptured "Python"
}