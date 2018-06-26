#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

testDetect()
{
  mkdir ${BUILD_DIR}/bin
  touch ${BUILD_DIR}/bin/detect
  touch ${BUILD_DIR}/bin/compile
  touch ${BUILD_DIR}/bin/release
  mkdir ${BUILD_DIR}/test
  
  capture ${BUILDPACK_HOME}/bin/detect ${BUILD_DIR}
  
  assertEquals 0 ${rtrn}
  assertEquals "Buildpack Test" "$(cat ${STD_OUT})"
  assertEquals "" "$(cat ${STD_ERR})"
}

testNoDetectMissingBuildpackScripts()
{
  mkdir ${BUILD_DIR}/test

  capture ${BUILDPACK_HOME}/bin/detect ${BUILD_DIR}
 
  assertEquals 1 ${rtrn}
  assertEquals "no" "$(cat ${STD_OUT})"
  assertEquals "" "$(cat ${STD_ERR})"
}

testNoDetectMissingTestDir()
{
  mkdir ${BUILD_DIR}/bin
  touch ${BUILD_DIR}/bin/detect
  touch ${BUILD_DIR}/bin/complie
  touch ${BUILD_DIR}/bin/release

  capture ${BUILDPACK_HOME}/bin/detect ${BUILD_DIR}
 
  assertEquals 1 ${rtrn}
  assertEquals "no" "$(cat ${STD_OUT})"
  assertEquals "" "$(cat ${STD_ERR})"
}
