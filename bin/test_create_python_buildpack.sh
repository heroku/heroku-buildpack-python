#!/bin/bash

# To run, from ~/workspace/buildpacks/cf-buildpack-python
#
#   bin/test_create_python_buildpack.sh

# ==================================== Mocks ====================================
# The mocks are not subshell safe.  They work by defining a global bash function that takes precedence over the UNIX
# tools like curl and tar
function curl() {
    args="$@";
    ARGUMENTS_CALLED_WITH_FOR_CURL=("${ARGUMENTS_CALLED_WITH_FOR_CURL[@]}" "$args");
    return 0;
}

function zip() {
    args="$@";
    ARGUMENTS_CALLED_WITH_FOR_ZIP=("${ARGUMENTS_CALLED_WITH_FOR_ZIP[@]}" "$args");
    return 0;
}

# Reset mocks
setUp() {
    ARGUMENTS_CALLED_WITH_FOR_CURL=()
    ARGUMENTS_CALLED_WITH_FOR_ZIP=()
}

# ==================================== Tests ====================================
testDependenciesAreDownloadedInOfflineMode() {
    source $BASE/create_python_buildpack.sh offline

    assertEquals 'curl should download files with the url in the saved filename'     \
                   'http://envy-versions.s3.amazonaws.com/python-2.7.0.tar.bz2 -O -L' \
                   "${ARGUMENTS_CALLED_WITH_FOR_CURL[0]}"

    assertEquals 'curl downloads 12 dependencies' "12" "${#ARGUMENTS_CALLED_WITH_FOR_CURL[@]}"
}

testDependenciesAreNotDownloadedInOnlineMode() {
    source $BASE/create_python_buildpack.sh online

    assertEquals 'curl downloads 0 dependencies' "0" "${#ARGUMENTS_CALLED_WITH_FOR_CURL[@]}"
}

testZipForBuildpackIsCreated() {
    source $BASE/create_python_buildpack.sh

    assertEquals 'Buildpack is zipped' "1" "${#ARGUMENTS_CALLED_WITH_FOR_ZIP[@]}"
}

testExcludeFilesFromTheBuildpack() {
    source $BASE/create_python_buildpack.sh

    arguments=$ARGUMENTS_CALLED_WITH_FOR_ZIP[@]

    assertTrue "zip should exclude .git"       $(contains "$arguments" " --exclude=*.git/*")
    assertTrue "zip should exclude .gitignore" $(contains "$arguments" " --exclude=*.gitignore*")
    assertTrue "zip should exclude cf_spec"    $(contains "$arguments" " --exclude=*cf_spec/*")
    assertTrue "zip should exclude log"        $(contains "$arguments" " --exclude=*log/*")
    assertTrue "zip should exclude test"       $(contains "$arguments" " --exclude=*test/*")
}

# ==================================== Utilities ====================================
function contains() {
    string=$1
    substring=$2

    if [[ $string == *"${substring}"* ]]
    then
        echo '0'
    else
        echo '1'
    fi
}

BASE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $BASE/../vendor/shunit2
