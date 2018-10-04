#!/usr/bin/env bash

sudo apt-get -qq update
sudo apt-get install software-properties-common
curl --fail --retry 3 --retry-delay 1 --connect-timeout 3 --max-time 30 https://cli-assets.heroku.com/install-ubuntu.sh | sh
