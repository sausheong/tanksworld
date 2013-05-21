require 'open-uri'
class Map
  def initialize(window, mapfile)
    lines = ""
    open(mapfile) do |file|
      lines = file.readlines.map { |line| line.chomp }
    end
    @window, @height, @width = window, lines.size, lines.first.size    
    @tiles = Array.new(@width) do |x|    
      Array.new(@height) do |y|
        case lines[y][x]
        when '.'
          SpriteImage::Earth
        when "#"
          SpriteImage::Wall
        when '"'
          SpriteImage::Grass
        end        
      end
    end
  end

  def draw
    @height.times do |y|
      @width.times do |x|        
        tile = @tiles[x][y]
        @window.spritesheet[tile].draw(x * 32, y * 32, 1)
      end
    end    
  end

  def solid?(x, y)
    tx, ty = x/32, y/32
    return true if @tiles[tx][ty] == SpriteImage::Wall
    return false
  end

end