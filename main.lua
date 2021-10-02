require("constants")
require("utils")

local screenSize = {1024, 768}
local screenCenter = {screenSize[1] / 2, screenSize[2] / 2}


local moveLimit = 200

local ship = nil
local shipMoveBounds = {screenCenter[1] - moveLimit, screenCenter[1] + moveLimit}
local shipX = screenSize[1] / 2
local shipY = screenSize[2] / 2
local moveSpeed = 10
local moveDirection = 0
local move = 0
local playerSliceDeg = 3
local playerSlice = deg2rad(playerSliceDeg)
local currentOverlap = 0

local starStart = 0
local starTime = 10
local starProgress = 0
local starSize = 255 / 2

local checkpointStart = 0
local checkpointTime = 10
local checkpointTarget = 90
local checkpointProgress = 0
local checkpointAngleDeg = 0
local checkpointFinalAngleDeg = 10

local distance = 0
local direction = 1
local moveDifficulty = 0  -- Affects movement ability more the close to 1 this is
local controlSlop = 0.075  -- Affects how long it takes for movement to stop


function love.load()
	love.window.setTitle("Generational Epochs")
	love.window.setMode(screenSize[1], screenSize[2])
	
	textFont = love.graphics.newFont("assets/fonts/JetBrainsMono-Bold.ttf")
	ship = love.graphics.newImage("assets/images/shipsmall.png")
	
	starStart = love.timer.getTime()
	
	checkpointStart = love.timer.getTime()
	checkpointTarget = deg2rad(randomDegree())
end

function love.keypressed(key, code, isrepeat)
	
end

function getOverlap(playerAngle, playerWidth, targetAngle, targetWidth)
	targetBound = targetWidth / 2
	targetLeft = targetAngle - targetBound
	targetRight = targetAngle + targetBound
	
	playerBound = playerWidth / 2
	playerLeft = playerAngle - playerBound
	playerRight = playerAngle + playerBound
	
	if playerLeft >= targetLeft and playerRight <= targetRight then
		-- Player entirely contained
		return 1
	elseif playerLeft < targetLeft and playerRight >= targetLeft and playerRight <= targetRight then
		-- Player right overlap
		return (playerRight - targetLeft) / playerWidth
	elseif playerLeft >= targetLeft and playerLeft <= targetRight and playerRight > targetRight then
		-- Player left overlap
		return (playerLeft - targetRight) / playerWidth
	else
		-- No overlap
		return 0
	end
end

function love.update()
	dt = love.timer.getDelta()
	
	leftPressed = love.keyboard.isDown("a")
	rightPressed = love.keyboard.isDown("d")
	moveDifficulty = 1 - (0.35 * (distance / moveLimit))
	-- move = move + moveSpeed * dt
	
	if not leftPressed and not rightPressed then
		moveDirection = 0
	elseif leftPressed then
		moveDirection = -1
	elseif rightPressed then
		moveDirection = 1
	end
	
	-- Apply movement
	nextMove = moveDirection * moveSpeed * dt
	
	-- If we're trying to dig ourselves out of a hole, it should be
	-- more difficult especially close to the edges
	if direction == moveDirection then
		nextMove = nextMove * moveDifficulty
	end
	
	move = move + nextMove
	
	shipX, clamped = clamp(lerp(shipX, shipX + move, 0.5), unpack(shipMoveBounds))
	
	-- If we're not moving, then decay move speed
	if not leftPressed and not rightPressed then
		if math.abs(move) > 0.01 and not clamped then
			move = lerp(move, 0, controlSlop)
		else
			move = 0
		end
	end
	
	starProgress = starProgress + 0.005
	
	absX = shipX - screenCenter[1]
	
	if shipX < screenCenter[1] then
		distance = screenCenter[1] - shipX
		direction = 1
	elseif shipX > screenCenter[1] then
		distance = shipX - screenCenter[1]
		direction = -1
	else
		distance = 0
		direction = 1
	end
	balance = distance * direction / moveLimit
	balance = balance * 90
	
	degBalance = 90 + balance
	radBalance = deg2rad(degBalance)
	
	t = love.timer.getTime()
	
	-- Check if our checkpoint is expired
	checkpointElapsed = t - checkpointStart
	if checkpointElapsed > checkpointTime then
		checkpointStart = t
		checkpointTarget = deg2rad(randomDegree())
		checkpointProgress = 0
		checkpointAngleDeg = 0
	else
		checkpointProgress = checkpointElapsed / checkpointTime
		checkpointAngleDeg = lerp(0, checkpointFinalAngleDeg, checkpointProgress)
	end
	
	-- Update our star progress
	starElapsed = t - starStart
	if starElapsed > starTime then
		starStart = t
		starProgress = 0
	else
		starProgress = starElapsed / starTime
	end
end


function drawBalance(current, target, targetWidth, radius)
	radius = radius or 100
	-- UI thing to indicate gravity beam balance
	p = math.pi
	bottom = screenSize[2] + 1
	progress = deg2rad(targetWidth) / 2
	love.graphics.setColor(PURPLE)
	love.graphics.arc("line", screenCenter[1], bottom, radius, p, 2 * p)
	love.graphics.arc("line", screenCenter[1], bottom, radius, -deg2rad(165), -deg2rad(15))
	
	love.graphics.setColor(PURPLE_BLUE)
	love.graphics.arc("fill", screenCenter[1], bottom, radius - 5, -target + (progress), -target - (progress))
	
	love.graphics.setColor(PURPLE)
	love.graphics.arc("fill", screenCenter[1], bottom, radius - 10, -current + playerSlice, -current - playerSlice)
end

function drawStar(t)
	radius = 75 + (75 * t)
	love.graphics.setColor(PINK)
	love.graphics.circle("fill", screenCenter[1], screenCenter[2], radius)
	
	-- This makes it easier during dev to tell how far along the level is
	love.graphics.circle("line", screenCenter[1], screenCenter[2], 150)
end

function love.draw()
	drawStar(starProgress)
	
	love.graphics.setColor(BLUE)
	-- love.graphics.print("Hello", textFont, shipX, 300, 0, 1, 1)
	love.graphics.rectangle("fill", shipX - 50, screenSize[2] - screenCenter[2], 100, 200)
	love.graphics.draw(ship, shipX - 50, shipY)
	drawBalance(radBalance, checkpointTarget, checkpointAngleDeg, 150)
	-- love.graphics.print(degBalance, textFont, 10, screenSize[2] - 30, 0, 1, 1)
	-- love.graphics.print(balance, textFont, 10, screenSize[2] - 60, 0, 1, 1)
	love.graphics.print(getOverlap(degBalance, playerSliceDeg, checkpointTarget, checkpointAngleDeg), textFont, 10, screenSize[2] - 90, 0, 1, 1)
	if direction == moveDirection then
		love.graphics.print("fight", textFont, 10, screenSize[2] - 70, 0, 1, 1)
	else
		love.graphics.print("easy", textFont, 10, screenSize[2] - 70, 0, 1, 1)
	end
end

function love.resize(w, h)
	
end