#!/bin/bash

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

testDetect()
{ 
    touch ${BUILD_DIR}/requirements.txt
    touch ${BUILD_DIR}/setup.py
    touch ${BUILD_DIR}/Pipfile
    detect
    assertCapturedSuccess
    assertCaptured "Python"
}

testRequirements()
{ 
    touch ${BUILD_DIR}/requirements.txt
    detect
    assertCapturedSuccess
    assertCaptured "Python"
}

testPipfile()
{ 
    
    touch ${BUILD_DIR}/Pipfile
    detect
    assertCapturedSuccess
    assertCaptured "Python"
}

testSetup()
{ 
    touch ${BUILD_DIR}/setup.py
    detect
    assertCapturedSuccess
    assertCaptured "Python"
}

testMissingAnyVersionFile()
{ 
    detect
    assertEquals 1 ${rtrn}
}