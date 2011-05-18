#!/bin/bash
[[ $GITHUB_AUTH = "" ]] && { echo "usage: GITHUB_AUTH=user:pass ./deploy.sh"; exit 1; }
heroku destroy --app canary-django --confirm canary-django

rm -rf .git
git init .
git add . && git commit -m 'Django skeleton'
heroku create canary-django --stack cedar
heroku config:add LANGUAGE_PACK_URL=https://${GITHUB_AUTH}@github.com/heroku/language-pack-python.git --app canary-django
git push heroku master

curl --head http://canary-django.herokuapp.com/
