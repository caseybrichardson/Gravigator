require("constants")
require("utils")
require("game")

Gamestate = require("gamestate")

io.stdout:setvbuf "no"

function love.load()
	Gamestate.registerEvents()
	Gamestate.switch(transit)
end
