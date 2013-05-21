require './colors'

WIDTH       = 640
HEIGHT      = 480

module SpriteImage
  Grass  = 5
  Earth  = 4
  Gravel = 3
  Wall   = 2
  Bullet = 1
  Tank   = 0
end

NAME        = "Tanks!"
SERVER      = '0.0.0.0'
PORT        = 1234

require 'randexp'
PLAYER_NAME = Randgen.first_name(length: 6)
PLAYER_COLOR = COLORS.values[rand(COLORS.size)]