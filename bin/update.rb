#!/usr/bin/env ruby

require 'bundler/setup'
require 'json'
require 'pg'

TABLE = 'coindata'
ROW_KEY = 1  # We only ever store/update this row

def main
  create_table
  set_timestamp_to_now
  json = File.read('mno.json')
  store json
end

def create_table
  puts 'create_table'
  db_conn.exec("CREATE TABLE IF NOT EXISTS #{TABLE} (id INTEGER PRIMARY KEY, json BYTEA, updated_at TIMESTAMP)")
end

# Ensure we don't end up with multiple, concurrent
# update scripts running.
def set_timestamp_to_now
  puts 'set_timestamp_to_now'
  db_conn.prepare 'set_timestamp_to_now', "INSERT INTO #{TABLE} (id, updated_at) VALUES (#{ROW_KEY}, $1)
                      ON CONFLICT(id) DO UPDATE SET updated_at = excluded.updated_at"
  db_conn.exec_prepared 'set_timestamp_to_now', [Time.now]
end

def store(json)
  puts 'store'
  data = db_conn.escape_bytea(json)
  db_conn.prepare 'store', "INSERT INTO #{TABLE} (id, json, updated_at) VALUES (#{ROW_KEY}, $1, $2)
                      ON CONFLICT(id) DO UPDATE SET json = excluded.json, updated_at = excluded.updated_at"
  db_conn.exec_prepared 'store', [data, Time.now]
end

def db_conn
  @conn ||= PG.connect(ENV.fetch('DATABASE_URL'))
end

main

