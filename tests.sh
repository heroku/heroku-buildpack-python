#!/usr/bin/env bash

if [[ ! "$STACK" ]]; then
    echo '$STACK must be set! (heroku-16 | cedar-14)'
    exit 1
fi

if [[ "$STACK" == "cedar-14" ]]; then
    make test-cedar-14
    exit $?
fi

if [[ "$STACK" == "heroku-16" ]]; then
    make test-heroku-16
    exit $?
fi

if [[ "$STACK" == "heroku-18" ]]; then
    make test-heroku-18
    exit $?
fi
