require 'rubygems'
require 'bundler'
Bundler.require
$stdout.sync = true
require './web'
run Rack::URLMap.new "/" => Sinatra::Application
