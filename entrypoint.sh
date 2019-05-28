#!/bin/bash
set -e

bundle exec whenever --update-crontab --set environment=$RAILS_ENV

exec "$@"
