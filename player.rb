require 'gosu'
require 'celluloid/io'
require 'socket'
require 'securerandom'
require 'open-uri'
require './settings'
require './map'
require './tank'
require './shot'

include Gosu

class Client
  include Celluloid::IO

  def initialize(server, port)
    begin
      @socket = TCPSocket.new(server, port)
    rescue
      $error_message = "Cannot find game server."
    end
  end

  def send_message(message)
    @socket.write(message) if @socket
  end

  def read_message
    @socket.readpartial(4096) if @socket
  end
end

class GameWindow < Window
  attr_reader :spritesheet, :player, :map, :client

  def initialize(server, port, player, color)
    super(WIDTH, HEIGHT, false)
    self.caption = NAME
    
    @client = Client.new(server, port) # client that communicates with the server
    
    config = @client.read_message
    map_url, spritesheet_url, default_hp = nil, nil, nil      
    open(config) { |file| map_url, spritesheet_url, default_hp = *file.read.split("|") }      
    open('sprites.png', 'wb') { |file| file << open(spritesheet_url).read }    
    @spritesheet = Image.load_tiles(self, 'sprites.png', 32, 32, true)
    @map = Map.new(self, map_url)  # map representing the movable area    

    @player = player # player name
    @font = Font.new(self, 'Courier New', 20)  # for the player names

    @me = spawn player, color, default_hp.to_i    
    @me_shots = Array.new # a list of my shots

    @other_tanks = Hash.new # hash of player names => tank objects (other than me)
    @other_shots = Hash.new # a hash of shot objects (other than mine); in a hash to be unique
    
    @messages = Array.new # list of messages to send to the server at the end of each round
    @valid_sprites = Array.new # list of valid sprite uuids from the server
    
    # send message to let server know that this player has signed in
    add_to_message_queue('obj', @me)
  end

  def update
    begin
      # move the tank but store the previous location    
      move_tank
      px, py = @me.x, @me.y
      @me.move

      # don't overlap the wall or go outside of the battlefield
      @me.warp_to(px, py) if @me.hit_wall? or @me.outside_battlefield?

      # don't overlap another tank
      @other_tanks.each do |player, tank|
        @me.warp_to(px, py) if tank.alive? and @me.collide_with?(tank, 30)
      end

      # tell the server that the player has moved
      add_to_message_queue('obj', @me)    

      # move other people's shots, see if it hits me
      @other_shots.each_value do |shot|
        if @me.alive? and @me.collide_with?(shot, 16)
          @me.hit       
          add_to_message_queue('obj', @me)     
        end
      end
      
      # move my shots 
      @me_shots.each do |shot|
        shot.move # move the bullet
        if shot.hit_wall? or shot.outside_battlefield?
          @me_shots.delete shot
          add_to_message_queue('del', shot)
        else
          add_to_message_queue('obj', shot)
        end
      end

      # send collected messages to the server
      @client.send_message @messages.join("\n")
      @messages.clear

      # read messages from the server
      if msg = @client.read_message
        @valid_sprites.clear
        data = msg.split("\n")
        # create sprites or alter existing sprites from messages from the server
        data.each do |row|
          sprite = row.split("|")
          if sprite.size == 9 # make sure we have the complete sprite
            player = sprite[3]
            @valid_sprites << sprite[0]
            case sprite[1]          
            when 'tank' 
              unless player == @player                        
                if @other_tanks[player]
                   @other_tanks[player].points = sprite[7].to_i
                   @other_tanks[player].warp_to(sprite[4], sprite[5], sprite[6])
                else
                  @other_tanks[player] = Tank.from_sprite(self, sprite)
                end
              else
                @me.points = sprite[7].to_i
              end
          
            when 'shot'
              unless player == @player
                shot = Shot.from_sprite(self, sprite)
                @other_shots[shot.uuid] = shot
                shot.warp_to(sprite[4], sprite[5], sprite[6])                
              end
            end
          end # end check for sprite size
        end

        # remove other sprites not coming from the server
        @other_shots.delete_if do |uuid, shot|
          !@valid_sprites.include?(uuid)
        end
        @other_tanks.delete_if do |user, tank|
          !@valid_sprites.include?(tank.uuid)
        end
      end
    rescue Exception => e
      puts e.backtrace
    end
  end

  def move_tank
    @me.go(:left) and @me.accelerate and return if button_down? KbLeft
    @me.go(:right) and @me.accelerate and return if button_down? KbRight      
    @me.go(:up) and @me.accelerate and return if button_down? KbUp
    @me.go(:down) and @me.accelerate and return if button_down? KbDown    
  end

  def draw
    @map.draw
    @me.draw
    @me_shots.each {|shot| shot.draw}
    @other_tanks.each_value {|tank| tank.draw}
    @other_shots.each_value {|shot| shot.draw}
    draw_player_names
    draw_you_lose unless @me.alive?
    draw_error_message if $error_message
  end

  def button_down(id)
    @me.shoot if button_down? KbSpace
    close if id == KbEscape
  end

  def spawn(player, color, default_hp=10)
    # randomly assign a position to start
    px, py = *random_position
    while @map.solid?(px+16, py+16) or @map.solid?(px-16, py-16) or @map.solid?(px+16, py-16) or @map.solid?(px-16, py+16) do
      px, py = *random_position
    end  
    Tank.new(self, SpriteImage::Tank, player, px, py, 0.0, default_hp, color) # create tank representing the player
  end
  
  # add a message to the queue to send to the server
  def add_to_message_queue(msg_type, sprite)
    @messages << "#{msg_type}|#{sprite.uuid}|#{sprite.type}|#{sprite.sprite_image}|#{sprite.player}|#{sprite.x}|#{sprite.y}|#{sprite.angle}|#{sprite.points}|#{sprite.color}"
  end

  def add_shot(shot)
    @me_shots << shot
    add_to_message_queue('obj', shot)
  end

  def draw_player_names
    @font.draw("*#{@player} (#{@me.points})", 5, 0, 5, 1, 1, Gosu::Color::AQUA)
    @other_tanks.keys.each_with_index do |name, i|
      @font.draw("#{name} (#{@other_tanks[name].points})", 5, (i+1) * 20, 5)
    end
  end

  def draw_you_lose
    @font.draw("YOU WERE DESTROYED!", 150, (HEIGHT/2) - 20, 100, 2.1, 2.1)
  end

  def draw_error_message
    @font.draw($error_message, 150, (HEIGHT/2) - 20, 100, 1.6, 1.6, Gosu::Color::RED)
  end

  def random_position
    [rand(32..WIDTH-32), rand(32..HEIGHT-32)]
  end
end

server = ARGV[0] || SERVER
port = ARGV[1] || PORT
player = ARGV[2] || PLAYER_NAME
color = COLORS[ARGV[3]] || PLAYER_COLOR
game = GameWindow.new(server, port.to_i, player, color)
game.show
