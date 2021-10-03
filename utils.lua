
function deg2rad(deg)
	return deg * (2 * math.pi) / 360
end

function rad2deg(rad)
	return rad * 360 / (2 * math.pi)
end

function randomDegree()
	offset = 15
	return love.math.random(180 - offset * 2) + offset
end

function lerp(from, to, t)
	return from + (to - from) * t
end

function clamp(value, min, max)
	if value >= min and value <= max then
		return value, false
	elseif value < min then
		return min, true
	elseif value > max then
		return max, true
	end
end
