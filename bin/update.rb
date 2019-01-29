#!/usr/bin/env ruby

require 'bundler/setup'
require 'json'
require 'pg'
require 'open-uri'
require 'nokogiri'

TABLE = 'coindata'
ROW_KEY = 1  # We only ever store/update this row

def main
  create_table
  set_timestamp_to_now
  json = fetch_data.to_json
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

def fetch_data
  puts 'fetch_data'
  html = fetch_with_user_agent('https://masternodes.online')
  page = Nokogiri::HTML(html)
  trs = page.css('#masternodes_table tr')
  trs[1..999].inject([]) { |arr, tr| arr << coin_data_from_tr(tr) }
end

def fetch_with_user_agent(url)
  open(url, 'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36').read
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

def coin_data_from_tr(tr)
  tds = tr.css('td')
  title = tds[2].css('strong a').first.text

  params = parse_title(title)
  params[:price_dollars] = get_last_value(tds[3].to_s)
  params[:change_percent] = tds[4].css('span').first.text
  params[:volume_dollars] = get_last_value(tds[5].to_s)
  params[:market_cap_dollars] = get_last_value(tds[6].to_s)
  params[:roi_percent] = tds[7].css('span').first.text
  params[:num_masternodes] = get_last_value(tds[8].to_s)
  params[:coins_per_masternode] = tds[9].css('span').first.text
  params[:masternode_value_dollars] = get_last_value(tds[10].to_s)

  params
end

def parse_title(str)
  if /(.*) \((.*)\)/.match(str)
    { name: $1, symbol: $2 }
  end
end

def get_last_value(str)
  if /span>(.*)<\/td>/.match(str)
    $1
  end
end


main

