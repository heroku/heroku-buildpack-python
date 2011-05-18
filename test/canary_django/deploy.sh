#!/bin/bash
[[ $GIT_PASSWORD = "" ]] && { echo "usage: GIT_PASSWORD=xxx ./push.sh"; exit 1; }
heroku destroy --app canary-django --confirm canary-django

rm -rf .git
git init .
git add . && git commit -m 'Django skeleton'
heroku create canary-django --stack cedar
heroku config:add LANGUAGE_PACK_URL=https://nzoschke:${GIT_PASSWORD}@github.com/heroku/language-pack-python.git --app canary-django
git push heroku master
rm -rf .git

curl --head http://canary-django.herokuapp.com/
