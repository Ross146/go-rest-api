#!/bin/bash
set -e
psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'todo-app'" | grep -q 1 ||
    psql -U postgres <<-EOSQL
  CREATE DATABASE "todo-app" WITH owner=postgres;
EOSQL
psql -U postgres -d nest-recall -tc "CREATE EXTENSION IF NOT EXISTS citext;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS plpgsql;"
