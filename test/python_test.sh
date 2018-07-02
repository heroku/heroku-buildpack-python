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
    
    assertContains "-----> Attempting to install" "`cat ${STD_OUT}`"
    assertNotContains "Unfortunately," "`cat ${STD_OUT}`"
    assertNotContains "heroku stack:set heroku-16" "`cat ${STD_OUT}`"
    assertEquals 0 ${rtrn}
}

testDeterminePython33() {
    touch ${BUILD_DIR}/test-runtime.txt
    echo "python-3.3" >| ${BUILD_DIR}/test-runtime.txt
    
    compile

    assertContains "The latest version of Python 3 is" "`cat ${STD_OUT}`"
    assertContains "Unfortunately," "`cat ${STD_OUT}`"
    assertContains "heroku stack:set heroku-16" "`cat ${STD_OUT}`"
    # This test is fragile as older versions of python 3 may or may not
    # be supported. Python 3.3 is unsupported, but this is checked
    # not by $PYTHON_VERSION but by curling for the python binary at
    # the $VENDOR_URL, and may or may not return an error code.
    assertEquals 1 ${rtrn}
}
