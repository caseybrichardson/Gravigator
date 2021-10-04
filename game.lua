Gamestate = require("gamestate")
local moonshine = require("moonshine")
require("utils")


intro = {}

function intro:init()
	local w, h
	w, h = love.window.getMode()
	self.screenSize = {w, h}
	self.screenCenter = {self.screenSize[1] / 2, self.screenSize[2] / 2}
	
	self.startTime = love.timer.getTime()
	self.displayFor = 3.5
	
	self.textFont = love.graphics.newFont("assets/fonts/JetBrainsMono-Bold.ttf", 32)
	self.displayText = "I made this"
	self.textWidth = self.textFont:getWidth(self.displayText)
	
	self.effect = moonshine(moonshine.effects.godsray)
							.chain(moonshine.effects.glow)
	self.effect.godsray.light_x = 0.25
	self.effect.godsray.exposure = 0.1
	-- self.effect.godsray.light_y = 
end

function intro:update(dt)
	local t = love.timer.getTime()
	local elapsed = t - self.startTime
	if elapsed >= self.displayFor then
		Gamestate.switch(menu)
	end
	
	local progress = elapsed / self.displayFor
	self.effect.godsray.light_x = 0.35 + (progress * 0.3)
end

function intro:draw()
	local cx, cy
	cx, cy = unpack(self.screenCenter)
	self.effect(function()
		love.graphics.print(self.displayText, self.textFont, cx - (self.textWidth / 2), cy - 16, 0, 1, 1)
	end)
end


menu = {}

function menu:init()
	local w, h
	w, h = love.window.getMode()
	self.screenSize = {w, h}
	self.screenCenter = {self.screenSize[1] / 2, self.screenSize[2] / 2}
	
	self.textFont = love.graphics.newFont("assets/fonts/JetBrainsMono-Bold.ttf", 32)
end

function menu:keyreleased(key, code)
	if key == "return" then
		Gamestate.switch(transit)
	end
end

function menu:draw()
	local cx, cy
	cx, cy = unpack(self.screenCenter)
	local displayText = "Hit Enter"
	local textWidth = self.textFont:getWidth(displayText)
	love.graphics.print(displayText, self.textFont, cx - (textWidth / 2), cy - 32, 0, 1, 1)
end

transit = {}

function transit:init()
	self.startTime = love.timer.getTime()
	
	local w, h
	w, h = love.window.getMode()
	self.screenSize = {w, h}
	self.screenCenter = {self.screenSize[1] / 2, self.screenSize[2] / 2}
	
	self.moveLimit = 200
	
	self.ship = nil
	self.shipMoveBounds = {self.screenCenter[1] - self.moveLimit, self.screenCenter[1] + self.moveLimit}
	self.shipX = self.screenSize[1] / 2
	self.shipY = self.screenSize[2] / 1.75
	self.slipSpeed = 2
	self.moveSpeed = 15
	self.moveDirection = 0
	self.move = 0
	self.shake = false
	self.shakeMagnitude = 5
	
	self.playerSliceDeg = 6
	self.playerSlice = deg2rad(self.playerSliceDeg)
	
	-- Scoring data
	self.currentOverlap = 0
	self.score = 0
	self.scorePerSecond = 1000
	self.souls = 1000000000
	
	self.starStart = 0
	self.starTime = 120
	self.starProgress = 0
	self.starSize = 255 / 2
	
	self.checkpointStart = 0
	self.checkpointTime = 1
	self.checkpointTargetDeg = nil
	self.checkpointTarget = nil
	self.checkpointProgress = 0
	self.checkpointMinAngleDeg = 9
	self.checkpointAngleDeg = 0
	self.checkpointFinalAngleDeg = 30
	
	self.checkpointTransitionTime = 4
	self.nextCheckpointTargetDeg = nil
	self.nextCheckpointTarget = nil
	self.nextCheckpointPhaseStart = 0
	self.nextCheckpointElapsed = 0
	self.checkpointTransitionProgress = 0
	
	self.distance = 0
	self.direction = 0
	self.moveDifficulty = 0  -- Affects movement ability more the close to 1 this is
	self.controlSlop = 0.05  -- Affects how long it takes for movement to stop
	
	self.textFont = love.graphics.newFont("assets/fonts/JetBrainsMono-Bold.ttf", 32)
	self.ship = love.graphics.newImage("assets/images/shipsmall.png")
	self.shipBody = love.graphics.newImage("assets/images/Ship Body@0.25x.png")
	self.shipBodySize = {self.shipBody:getWidth(), self.shipBody:getHeight()}
	self.shipWheel = love.graphics.newImage("assets/images/Wheel@0.25x.png")
	self.shipWheelSize = {self.shipWheel:getWidth(), self.shipWheel:getHeight()}
	self.wheelAngle = 0
	
	self.numExhausts = 4
	self.exhaustImages = {}
	self.exhaustParticles = {}
	for i=1,self.numExhausts,1 do
		local exhaustPath = string.format("assets/images/stars/Star %s@0.25x.png", i)
		print(exhaustPath)
		self.exhaustImages[i] = love.graphics.newImage(exhaustPath)
		self.exhaustParticles[i] = love.graphics.newParticleSystem(self.exhaustImages[i], 300)
		self.exhaustParticles[i]:setParticleLifetime(2, 3)
		self.exhaustParticles[i]:setEmissionRate(100)
		self.exhaustParticles[i]:setSizes(1)
		-- self.exhaustParticles[i]:setLinearAcceleration(100, 200)
		self.exhaustParticles[i]:setSpeed(500 + love.math.random(-100, 100))
		self.exhaustParticles[i]:setDirection(0.5 * math.pi)
		self.exhaustParticles[i]:setEmissionArea("ellipse", 5, 5, 0.5 * math.pi, false)
		-- self.exhaustParticles[i]:setRelativeRotation(true)
		-- self.exhaustParticles[i]:
	end
	
	
	self.numStreaks = 16
	self.starImages = {}
	self.starParticles = {}
	for i=1,self.numStreaks,1 do
		local starPath = string.format("assets/images/streaks/Streak %s.png", i)
		print(starPath)
		self.starImages[i] = love.graphics.newImage(starPath)
		self.starParticles[i] = love.graphics.newParticleSystem(self.starImages[i], 100)
		self.starParticles[i]:setParticleLifetime(4, 5)
		self.starParticles[i]:setEmissionRate(20)
		self.starParticles[i]:setSizes(0.1, 0.2, 0.3)
		self.starParticles[i]:setRadialAcceleration(100, 200)
		self.starParticles[i]:setSpeed(500 + love.math.random(-100, 100))
		self.starParticles[i]:setEmissionArea("ellipse", 75, 75, 180, true)
		self.starParticles[i]:setRelativeRotation(true)
		-- self.starParticles[i]:
	end
	
	self.effect = moonshine(moonshine.effects.fastgaussianblur)
							.chain(moonshine.effects.godsray)
							.chain(moonshine.effects.vignette)
							.chain(moonshine.effects.chromasep)
	self.effect.vignette.radius = 0.6
end

function transit:getOverlap(playerAngle, playerWidth, targetAngle, targetWidth)
	local targetBound = targetWidth / 2
	local targetLeft = targetAngle - targetBound
	local targetRight = targetAngle + targetBound
	
	local playerBound = playerWidth / 2
	local playerLeft = playerAngle - playerBound
	local playerRight = playerAngle + playerBound
	
	if playerLeft >= targetLeft and playerRight <= targetRight then
		-- Player entirely contained
		return 1
	elseif playerLeft < targetLeft and playerRight >= targetLeft and playerRight <= targetRight then
		-- Player right overlap
		return (playerRight - targetLeft) / playerWidth
	elseif playerLeft >= targetLeft and playerLeft <= targetRight and playerRight > targetRight then
		-- Player left overlap
		return (targetRight - playerLeft) / playerWidth
	else
		-- No overlap
		return 0
	end
end

function transit:trackCheckpoints(dt)
	local t = love.timer.getTime()
	
	-- Check if our checkpoint is expired
	if self.nextCheckpointTarget == nil then
		self.checkpointElapsed = t - self.checkpointStart
		local wasNil = self.checkpointTargetDeg == nil 
		local tComplete = self.checkpointElapsed > self.checkpointTime
		if wasNil and tComplete then
			self.checkpointStart = t
			self.checkpointTargetDeg = randomDegree()
			self.checkpointTarget = deg2rad(self.checkpointTargetDeg)
			self.checkpointProgress = 0
			self.checkpointAngleDeg = self.checkpointMinAngleDeg
		elseif not wasNil and tComplete then
			-- Kickoff the transition
			self.nextCheckpointTargetDeg = randomDegree()
			self.nextCheckpointTarget = deg2rad(self.nextCheckpointTargetDeg)
			self.nextCheckpointPhaseStart = t
			self.nextCheckpointStartDeg = self.checkpointTargetDeg
		else
			self.checkpointProgress = self.checkpointElapsed / self.checkpointTime
			self.checkpointAngleDeg = lerp(self.checkpointMinAngleDeg, self.checkpointFinalAngleDeg, self.checkpointProgress)
		end
	else
		self.nextCheckpointElapsed = t - self.nextCheckpointPhaseStart
		if self.nextCheckpointElapsed > self.checkpointTransitionTime then
			-- Transition is done; kick into the next checkpoint
			self.checkpointStart = t
			self.checkpointTargetDeg = self.nextCheckpointTargetDeg
			self.checkpointTarget = deg2rad(self.checkpointTargetDeg)
			self.checkpointProgress = 0
			self.checkpointAngleDeg = self.checkpointMinAngleDeg
			
			-- Clear out transition
			self.nextCheckpointTargetDeg = nil
			self.nextCheckpointTarget = nil
		else
			-- We're still in transition
			self.checkpointTransitionProgress = self.nextCheckpointElapsed / self.checkpointTransitionTime
			self.checkpointTargetDeg = lerp(self.nextCheckpointStartDeg, self.nextCheckpointTargetDeg, self.checkpointTransitionProgress)
			self.checkpointTarget = deg2rad(self.checkpointTargetDeg)
			self.checkpointAngleDeg = self.checkpointMinAngleDeg
		end
	end
end

function transit:update(dt)
	local leftPressed = love.keyboard.isDown("a")
	local rightPressed = love.keyboard.isDown("d")
	self.moveDifficulty = 1 - (0.15 * (self.distance / self.moveLimit))
	-- move = move + moveSpeed * dt
	
	if not leftPressed and not rightPressed then
		self.moveDirection = 0
	elseif leftPressed then
		self.moveDirection = -1
	elseif rightPressed then
		self.moveDirection = 1
	end
	
	-- Apply movement
	local nextMove = self.moveDirection * self.moveSpeed * dt
	
	-- If we're trying to dig ourselves out of a hole, it should be
	-- more difficult especially close to the edges
	if self.direction == self.moveDirection then
		nextMove = nextMove * self.moveDifficulty
	end
	
	if self.direction ~= 0 then
		local mult = self.distance / 90 * 2
		nextMove = nextMove + (-self.direction * self.slipSpeed * mult * dt)
	end
	
	self.move = self.move + nextMove
	
	local clamped
	self.shipX, clamped = clamp(lerp(self.shipX, self.shipX + self.move, 0.5), unpack(self.shipMoveBounds))
	
	-- If we're not moving, then decay move speed
	if not leftPressed and not rightPressed then
		if math.abs(self.move) > 0.01 then
			self.move = lerp(self.move, 0, self.controlSlop)
		else
			self.move = 0
		end
	end
	
	if clamped then
		self.move = 0
	end
	
	self.starProgress = self.starProgress + 0.005
	
	if self.shipX < self.screenCenter[1] then
		self.distance = self.screenCenter[1] - self.shipX
		self.direction = 1
	elseif self.shipX > self.screenCenter[1] then
		self.distance = self.shipX - self.screenCenter[1]
		self.direction = -1
	else
		self.distance = 0
		self.direction = 0
	end
	self.balance = self.distance * self.direction / self.moveLimit
	self.balance = self.balance * 90
	
	self.degBalance = 90 + self.balance
	self.shake = self.degBalance > 165 or self.degBalance < 15
	self.radBalance = deg2rad(self.degBalance)
	
	self:trackCheckpoints(dt)
	local t = love.timer.getTime()
	
	-- Calculate overlap after updating user location and checkpoint location
	-- TODO: Rewrite to take advantage of self properties instead of passing all vars in
	self.currentOverlap = self:getOverlap(
		self.degBalance, self.playerSliceDeg, self.checkpointTargetDeg, self.checkpointAngleDeg
	)
	
	-- Add our score modifying with current overlap
	self.score = self.score + math.floor(self.scorePerSecond * dt * self.currentOverlap)
	
	-- Update our star progress
	self.starElapsed = t - self.starStart
	if self.starElapsed > self.starTime then
		self.starStart = t
		self.starProgress = 0
	else
		self.starProgress = self.starElapsed / self.starTime
	end
	
	for i=1,self.numExhausts,1 do
		self.exhaustParticles[i]:update(dt)
	end
	
	for i=1,self.numStreaks,1 do
		self.starParticles[i]:update(dt)
	end
	
	self.wheelAngle = deg2rad((t - self.startTime) * 50 % 360)
end

function drawBalance(x, y, current, currentWidth, target, targetWidth, radius, l, r)
	radius = radius or 100
	l = l or 165
	r = r or 15
	
	-- UI thing to indicate gravity beam balance
	local p = math.pi
	cProgress = deg2rad(currentWidth) / 2
	tProgress = deg2rad(targetWidth) / 2
	love.graphics.setColor(PURPLE)
	love.graphics.arc("line", "open", x, y, radius, p, 2 * p)
	love.graphics.arc("line", x, y, radius, -deg2rad(l), -deg2rad(r))
	
	if target ~= nil then
		love.graphics.setColor(PURPLE_BLUE)
		love.graphics.arc("fill", x, y, radius - 8, -target + (tProgress), -target - (tProgress))
	end
	
	love.graphics.setColor(PURPLE)
	love.graphics.arc("fill", x, y, radius - 21, -current + cProgress, -current - cProgress)
end

function drawStar(x, y, t, startRadius, growRadius)
	startRadius = starRadius or 75
	growRadius = growRadius or 75
	local currentRadius = lerp(startRadius, startRadius + growRadius, t)
	love.graphics.setColor(PINK)
	love.graphics.circle("fill", x, y, currentRadius)
	
	-- This makes it easier during dev to tell how far along the level is
	-- love.graphics.circle("line", x, y, 150)
end

function transit:drawShip(x, y, r)
	local cx, cy, w, h
	cx, cy = unpack(self.screenCenter)
	w, h = unpack(self.screenSize)
	love.graphics.setColor({1, 1, 1})
	
	-- Drawing the rotating wheel
	local ww, wh, wx, wy, fx, fy
	ww, wh = unpack(self.shipWheelSize)
	wx = ww / 2
	wy = wh / 2
	fx = x - wx
	fy = y - wy
	love.graphics.translate(x, y)
	love.graphics.rotate(r)
	love.graphics.draw(self.shipWheel, -wx, -wy)
	love.graphics.rotate(-r)
	love.graphics.rotate(-r)
	love.graphics.draw(self.shipWheel, -wx, -wy)
	love.graphics.rotate(r)
	love.graphics.rotate((r + math.pi / 4))
	love.graphics.draw(self.shipWheel, -wx, -wy)
	love.graphics.rotate(-(r + math.pi / 4))
	love.graphics.rotate(-(r + math.pi / 4))
	love.graphics.draw(self.shipWheel, -wx, -wy)
	love.graphics.rotate((r + math.pi / 4))
	
	-- Draw ship body
	local sw, sh, sx, sy
	sw, sh = unpack(self.shipBodySize)
	sx = sw / 2
	sy = sh / 2
	love.graphics.rotate(self.radBalance - math.pi / 2)
	love.graphics.draw(self.shipBody, -sx, -2.5)
	
	local points = {}
	
	for i=1,self.numExhausts,1 do
		local px, py
		px, py = love.graphics.transformPoint(-sw + sx + i * (sw / 5), sh - 20)
	 	points[i] = {px, py}
	end
	love.graphics.rotate(-(self.radBalance - math.pi / 2))
	love.graphics.translate(-x, -y)
	
	for i = 1, self.numExhausts,1 do
		self.exhaustParticles[i]:setDirection(self.radBalance)
		love.graphics.draw(self.exhaustParticles[i], unpack(points[i]))
		print(points[i][1], " ", points[i][2])
	end
end

function transit:draw()
	local cx, cy, w, h
	cx, cy = unpack(self.screenCenter)
	w, h = unpack(self.screenSize)
	-- Used for shaking
	local dx = love.math.random(-self.shakeMagnitude, self.shakeMagnitude)
	local dy = love.math.random(-self.shakeMagnitude, self.shakeMagnitude)
	
	love.graphics.setColor({1, 1, 1})
	self.effect(function()
		for i=1,self.numStreaks,1 do
			love.graphics.draw(self.starParticles[i], cx, cy)
		end
		if self.shake then
			love.graphics.translate(-dx, dy)
		end
		drawStar(cx, cy, self.starProgress)
		if self.shake then
			love.graphics.translate(dx, -dy)
		end
	end)
	
	
	-- love.graphics.setColor(BLUE)
	-- love.graphics.rectangle("fill", self.shipX - 50, self.screenSize[2] - self.screenCenter[2], 100, 200)
	-- if self.shake then
	-- 	love.graphics.translate(dx, dy)
	-- end
	-- love.graphics.draw(self.ship, self.shipX - 50, self.shipY)
	-- if self.shake then
	-- 	love.graphics.translate(-dx, -dy)
	-- end
	-- local sw, sh
	-- sw, sh = unpack(self.shipWheelSize)
	-- sw = sw / 2
	-- sh = sh / 2
	self:drawShip(self.shipX, self.shipY, self.wheelAngle)
	
	drawBalance(cx, h, self.radBalance, self.playerSliceDeg, self.checkpointTarget, self.checkpointAngleDeg)
	
	local souls = string.format("Souls: %s", self.souls)
	love.graphics.print(souls, self.textFont, 10, 10, 0, 1, 1)
	
	local score = string.format("Score: %s", self.score)
	love.graphics.print(score, self.textFont, 10, 35, 0, 1, 1)
end




