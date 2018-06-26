#!/bin/bash

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

testDeterminePython27() {
    touch ${BUILD_DIR}/test-runtime.txt
    echo "python-2.7.14" >| ${BUILD_DIR}/test-runtime.txt
    
    compile

    assertContains "Unfortunately," "`cat ${STD_OUT}`"
    assertContains "heroku stack:set heroku-16" "`cat ${STD_OUT}`"
    assertEquals 1 ${rtrn}
}

testDeterminePython36() {
    touch ${BUILD_DIR}/test-runtime.txt
    echo "python-3.6.6" >| ${BUILD_DIR}/test-runtime.txt
    
    compile

    # echo "`cat ${BUILD_DIR}/test-runtime.txt`"
    echo `cat ${STD_ERR}`
    assertNotContains "Unfortunately," "`cat ${STD_OUT}`"
    assertNotContains "heroku stack:set heroku-16" "`cat ${STD_OUT}`"
    assertEquals 0 ${rtrn}
}

testDeterminePython33() {
    touch ${BUILD_DIR}/test-runtime.txt
    echo "python-3.3" >| ${BUILD_DIR}/test-runtime.txt
    
    compile

    assertContains "Unfortunately," "`cat ${STD_OUT}`"
    assertContains "heroku stack:set heroku-16" "`cat ${STD_OUT}`"
}
