#!/usr/bin/env bash

set_sql_alchemy_url() {
  local database_url=$1
  local environment_variables_prefix=$2

  local pattern="sqlalchemy"
  concerned1=$(cat "requirements.txt" | grep -ic $pattern)
  concerned2=$(cat "Pipfile" | grep -ic $pattern)
  if [ $concerned1 -eq 0 ] && [ $concerned2 -eq 0 ]; then
    return 0
  fi

  if ! [[ $database_url =~ postgres:// ]];then
    return 0
  fi

  local full_database_url
  full_database_url="${database_url/postgres:\/\//postgresql://}"
  eval "export ${environment_variables_prefix}_URL=$full_database_url"
}

for database_url_variable in $(env | awk -F "=" '{print $1}' | grep "SCALINGO_POSTGRESQL_URL"); do
  set_sql_alchemy_url "$(eval echo "\$${database_url_variable}")" "${database_url_variable//_URL/}_ALCHEMY"
done
