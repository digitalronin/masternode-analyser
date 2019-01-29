#!/usr/bin/env ruby

require 'bundler/setup'
require 'sinatra/base'

class App < Sinatra::Base
  set :port, ENV.fetch('PORT')
  set :bind, '0.0.0.0'

  get '/' do
    "<h1>Masternode Analyser</h1>"
  end

  run! if app_file == $0
end
