#!/usr/bin/env ruby

require 'bundler/setup'
require 'sinatra/base'
require 'json'

class App < Sinatra::Base
  set :port, ENV.fetch('PORT')
  set :bind, '0.0.0.0'

  get '/' do
    @data = JSON.parse(File.read('mno.json'))
    erb :index
  end

  run! if app_file == $0
end
