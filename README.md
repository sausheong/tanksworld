# TanksWorld

Tanks is a Gosu-based simple, online, real-time multi-player game, based on the popular retro game, [Tank Battalion](http://en.wikipedia.org/wiki/Tank_Battalion). Rev up your tank and battle it out in the deadly Tanks arena, if you dare!

TanksWorld is the webified version of Tanks that has a web interface to control and start Tank game servers, also called arenas.

## Install

Tanks primarily uses 2 external libraries -- [Gosu](http://www.libgosu.org/) and Celluloid-IO (https://github.com/celluloid/celluloid-io). Install the needed and related gems by running `bundle install`. Once you've done that you're good to go!

If you encounter problems when running a variant of Linux, make sure you have all the dependencies install. Read up more about it here - https://github.com/jlnr/gosu/wiki/Getting-Started-on-Linux

As of writing, it's only been tested on a Linux machine and on a Mac OS X Mountain Lion, running in Ruby 1.9.3 or Ruby 2.0.0.

In addition to these 2 libraries, TanksWorld uses Sinatra and Haml to create a simple web interface to start and control arenas.

## Run


Just do this:

1. Start the TanksWorld web application using thin.
 
    `$ thin start`

   (You can also start the server at any other port)

2. Go to the url http://<web_app_hostname>:<web_app_port>. You should see the TanksWorld web interface. Click on the 'start a new arena' box.

3. You will have the choice to use different maps, sprite sheets and default starting hit points in separate arenas. The defaults are provided. Once an arena is started, you'll see the port you can connect to.
     
3. Run the game client in any computer in the same network, and connecting to the server.

    `$ ruby player.rb  <server> <port> <player name> <tank color>`
      
The server is the host that your TanksWorld is running on. The port is given by the interface as above. Tank colors can be any [X11 color names](http://en.wikipedia.org/wiki/Web_colors) in snake case e.g. `yellow_green`, `light_steel_blue` and so on. 
   
