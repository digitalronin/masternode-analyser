#!/usr/bin/env ruby

require 'bundler/setup'
require 'sinatra/base'
require 'json'
require 'pg'

TABLE = 'coindata'
ROW_KEY = 1  # We only ever store/update this row
MAX_AGE_SECONDS = 600

def fetch_json
  conn = PG.connect(ENV.fetch('DATABASE_URL'))
  result = conn.exec "SELECT json, updated_at FROM #{TABLE} WHERE id = #{ROW_KEY}"
  data, updated_at = result.values.first

  {
    json: conn.unescape_bytea(data),
    age: age_in_seconds(updated_at),
    updated_at: updated_at
  }
end

def age_in_seconds(time_string)
  Time.now.to_i - Time.parse(time_string).to_i
end

class App < Sinatra::Base
  set :port, ENV.fetch('PORT')
  set :bind, '0.0.0.0'

  get '/' do
    result = fetch_json

    if result.fetch(:age) > MAX_AGE_SECONDS
      system 'bin/update.rb &'
    end

    @data = JSON.parse(result.fetch(:json))
    @updated_at = result.fetch(:updated_at)
    erb :index
  end

  run! if app_file == $0
end
