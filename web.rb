require 'celluloid'
require 'celluloid/io'
require './arena'

configure do
  @@port_range = (10000..11000).to_a
end

get "/" do
  @arenas = Celluloid::Actor.all
  haml :arenas
end

post "/arena/start" do
  port = @@port_range.delete @@port_range.sample  
  arena = Arena.new(request.host, port, request.port)    
  arena.map_url = params[:map_url] || "http://#{request.host_with_port}/maps/map.txt"
  arena.spritesheet_url = params[:spritesheet_url] || "http://#{request.host_with_port}/spritesheets/spritesheet.png"
  arena.default_hp = params[:default_hp].to_i || 10  
  Celluloid::Actor[:"arena_#{port}"] = arena
  redirect "/"
end


get "/arena/stop/:name" do
  raise "No such arena" unless Celluloid::Actor[params[:name].to_sym]
  Celluloid::Actor[params[:name].to_sym].terminate
  redirect "/"
end

get "/config/:name" do
  arena = Celluloid::Actor[params[:name].to_sym]
  array = [arena.map_url, arena.spritesheet_url, arena.default_hp.to_s].join("|")
end