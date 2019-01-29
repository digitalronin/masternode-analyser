#!/usr/bin/env ruby

require 'bundler/setup'
require 'nokogiri'
require 'open-uri'
require 'awesome_print'
require 'json'

# class Coin
#   attr_reader :name, :symbol, :price, :change, :volume, :market_cap, :roi,
#              :masternodes, :coins_per_masternode, :masternode_value
#
#   def initialize(args)
#     @name = args[:name]
#     @symbol = args[:symbol]
#     @price = args[:price]
#     @change = args[:change]
#     @volume = args[:volume]
#     @market_cap = args[:market_cap]
#     @roi = args[:roi]
#     @masternodes = args[:masternodes]
#     @coins_per_masternode = args[:coins_per_masternode]
#     @masternode_value = args[:masternode_value]
#   end
# end

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

# WARNING: Set a desktop browser useragent when fetching data from MNO. If you don't, they will replace values with incorrect data
#   curl -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36' https://masternodes.online

page = Nokogiri::HTML(open("mno.html"))

trs = page.css('#masternodes_table tr')
data = trs[1..999].inject([]) { |arr, tr| arr << coin_data_from_tr(tr) }

File.open('mno.json', 'w') { |f| f.puts data.to_json }

