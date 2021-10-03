require("constants")
require("utils")
require("game")

Gamestate = require("gamestate")

io.stdout:setvbuf "no"

function love.load()
	Gamestate.registerEvents()
	Gamestate.switch(transit)
end

function love.keypressed(key, code, isrepeat)
end

function love.update(dt)
end

function love.draw()
end

function love.resize(w, h)
end