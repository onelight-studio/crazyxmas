-- Paddle

require 'class'

-- constants

PADDLE_WIDTH = 100
PADDLE_HEIGHT = 90
PADDLE_HEIGHT_GOLD = 113
PADDLE_IMG = "img/game_paddle.png"
PADDLE_IMG_GOLD = "img/game_paddle_gold.png"
PADDLE_INDEX_MIN = 0
PADDLE_INDEX_MAX = 5
PADDLE_SPEED = 60
PADDLE_MODE_NORMAL = 'mode_normal'
PADDLE_MODE_ASPIRATOR = 'mode_aspirator'
DELAY_PADDLE_ASPIRATOR_MODE = 10000
PADDLE_ASPIRATOR_MODE_IMG = "img/game_paddle_with_aspirator.png"
PADDLE_ASPIRATOR_MODE_IMG_GOLD = "img/game_paddle_gold_with_aspirator.png"
PADDLE_ASPIRATOR_PADDING = 50
PADDLE_MODE_BIG = 'mode_big'
DELAY_PADDLE_BIG_MODE = 5500
PADDLE_BIG_MODE_IMG_STATE_1 = "img/game_paddle_big_state_1.png"
PADDLE_BIG_MODE_IMG_STATE_1_GOLD = "img/game_paddle_gold_big_state_1.png"
PADDLE_BIG_MODE_IMG_STATE_1_WIDTH = 130
PADDLE_BIG_MODE_IMG_STATE_1_HEIGHT = 117
PADDLE_BIG_MODE_IMG_STATE_1_HEIGHT_GOLD = 147
PADDLE_BIG_MODE_IMG_STATE_2 = "img/game_paddle_big_state_2.png"
PADDLE_BIG_MODE_IMG_STATE_2_GOLD = "img/game_paddle_gold_big_state_2.png"
PADDLE_BIG_MODE_IMG_STATE_2_WIDTH = 160
PADDLE_BIG_MODE_IMG_STATE_2_HEIGHT = 144
PADDLE_BIG_MODE_IMG_STATE_2_HEIGHT_GOLD = 181
PADDLE_BIG_MODE_IMG_STATE_3 = "img/game_paddle_big_state_3.png"
PADDLE_BIG_MODE_IMG_STATE_3_GOLD = "img/game_paddle_gold_big_state_3.png"
PADDLE_BIG_MODE_IMG_STATE_3_WIDTH = 200
PADDLE_BIG_MODE_IMG_STATE_3_HEIGHT = 180
PADDLE_BIG_MODE_IMG_STATE_3_HEIGHT_GOLD = 226

-- variables

local pad
local lastTouchedX
local currentShowBounds
local timerBlink
local timerEnd
local timerBig

-- functions

local function onTouchScreen(event)
	lastTouchedX = event.x
end

-- core

Paddle = class(function(this)
	this.mode = PADDLE_MODE_NORMAL
end)

function Paddle:move()
	local dist
	local direction

	if lastTouchedX ~= nil and pad ~= nil then
		if pad.x > lastTouchedX then
			dist = pad.x - lastTouchedX
			direction = -1
		else
			dist = lastTouchedX - pad.x
			direction = 1
		end

		if dist < PADDLE_SPEED then
			pad.x = lastTouchedX
		else
			pad:translate(PADDLE_SPEED * direction, 0)
		end
	end
end

function Paddle:elem()
	return pad
end

function Paddle:toFront()
	pad:toFront()
end

function Paddle:onEnterScene()
	pad = display.newImageRect(gameSettings.finished and PADDLE_IMG_GOLD or PADDLE_IMG, PADDLE_WIDTH, gameSettings.finished and PADDLE_HEIGHT_GOLD or PADDLE_HEIGHT)
	pad.x = display.contentCenterX
	pad.y = display.contentHeight - pad.height / 2

	self.mode = PADDLE_MODE_NORMAL

	self:cancelTimerPaddle()

	Runtime:addEventListener("touch", onTouchScreen)
end

function Paddle:onExitScene()
	lastTouchedX = display.contentCenterX

	self:cancelTimerPaddle()
	
	display.remove(pad)
	pad = nil
	Runtime:removeEventListener("touch", onTouchScreen)
end

function Paddle:contentBounds()
	if pad ~= nil then
		local bounds = pad.contentBounds
		bounds.xMin = bounds.xMin
		bounds.xMax = bounds.xMax
		bounds.yMin = bounds.yMin + 10
		bounds.yMax = bounds.yMax - 20

		--currentShowBounds = showBounds(bounds, currentShowBounds)

		return bounds
	end

	return nil
end

function Paddle:aspiratorContentBounds()
	if pad ~= nil then
		local bounds = self:contentBounds()
		bounds.xMin = bounds.xMin - PADDLE_ASPIRATOR_PADDING
		bounds.xMax = bounds.xMax + PADDLE_ASPIRATOR_PADDING
		bounds.yMin = bounds.yMin - PADDLE_ASPIRATOR_PADDING
		bounds.yMax = bounds.yMax + PADDLE_ASPIRATOR_PADDING

		--currentShowBounds = showBounds(bounds, currentShowBounds)

		return bounds
	end

	return nil
end

function Paddle:toAspiratorMode(activate)
	if pad ~= nil then
		if activate == true then
			local oldPad = pad
			pad = display.newImageRect(gameSettings.finished and PADDLE_ASPIRATOR_MODE_IMG_GOLD or PADDLE_ASPIRATOR_MODE_IMG, PADDLE_WIDTH, gameSettings.finished and PADDLE_HEIGHT_GOLD or PADDLE_HEIGHT)
			pad.x = oldPad.x
			pad.y = oldPad.y
			
			display.remove(oldPad)
			oldPad = nil

			self.mode = PADDLE_MODE_ASPIRATOR

			timerBlink = timer.performWithDelay(DELAY_PADDLE_ASPIRATOR_MODE - 2000, function () blink(pad, BLINK_SPEED_NORMAL) end)
			timerEnd = timer.performWithDelay(DELAY_PADDLE_ASPIRATOR_MODE, function () self:toAspiratorMode(false) end)
		else
			local oldPad = pad
			pad = display.newImageRect(gameSettings.finished and PADDLE_IMG_GOLD or PADDLE_IMG, PADDLE_WIDTH, gameSettings.finished and PADDLE_HEIGHT_GOLD or PADDLE_HEIGHT)
			pad.x = oldPad.x
			pad.y = oldPad.y
			
			self.mode = PADDLE_MODE_NORMAL

			self:cancelTimerPaddle()

			display.remove(oldPad)
			oldPad = nil
		end
	end
end

function Paddle:toBigMode(activate)
	if pad ~= nil then
		if activate == true then

			local oldPad = pad
			pad = display.newImageRect(gameSettings.finished and PADDLE_BIG_MODE_IMG_STATE_1_GOLD or PADDLE_BIG_MODE_IMG_STATE_1, PADDLE_BIG_MODE_IMG_STATE_1_WIDTH, gameSettings.finished and PADDLE_BIG_MODE_IMG_STATE_1_HEIGHT_GOLD or PADDLE_BIG_MODE_IMG_STATE_1_HEIGHT)
			pad.x = oldPad.x
			pad.y = display.contentHeight - pad.height / 2
			
			display.remove(oldPad)
			oldPad = nil

			timerBig = timer.performWithDelay(200, function ()
				local oldPad = pad
				pad = display.newImageRect(gameSettings.finished and PADDLE_BIG_MODE_IMG_STATE_2_GOLD or PADDLE_BIG_MODE_IMG_STATE_2, PADDLE_BIG_MODE_IMG_STATE_2_WIDTH, gameSettings.finished and PADDLE_BIG_MODE_IMG_STATE_2_HEIGHT_GOLD or PADDLE_BIG_MODE_IMG_STATE_2_HEIGHT)
				pad.x = oldPad.x
				pad.y = display.contentHeight - pad.height / 2
				
				display.remove(oldPad)
				oldPad = nil
			end)

			timerBig = timer.performWithDelay(400, function ()
				local oldPad = pad
				pad = display.newImageRect(gameSettings.finished and PADDLE_BIG_MODE_IMG_STATE_3_GOLD or PADDLE_BIG_MODE_IMG_STATE_3, PADDLE_BIG_MODE_IMG_STATE_3_WIDTH, gameSettings.finished and PADDLE_BIG_MODE_IMG_STATE_3_HEIGHT_GOLD or PADDLE_BIG_MODE_IMG_STATE_3_HEIGHT)
				pad.x = oldPad.x
				pad.y = display.contentHeight - pad.height / 2
				
				display.remove(oldPad)
				oldPad = nil
			end)

			self.mode = PADDLE_MODE_BIG

			timerBlink = timer.performWithDelay(DELAY_PADDLE_BIG_MODE - 2000, function () blink(pad, BLINK_SPEED_NORMAL) end)
			timerEnd = timer.performWithDelay(DELAY_PADDLE_BIG_MODE, function () self:toBigMode(false) end)
		else
			local oldPad = pad
			pad = display.newImageRect(gameSettings.finished and PADDLE_IMG_GOLD or PADDLE_IMG, PADDLE_WIDTH, gameSettings.finished and PADDLE_HEIGHT_GOLD or PADDLE_HEIGHT)
			pad.x = oldPad.x
			pad.y = display.contentHeight - pad.height / 2
			
			self.mode = PADDLE_MODE_NORMAL

			self:cancelTimerPaddle()

			display.remove(oldPad)
			oldPad = nil
		end
	end
end

function Paddle:pausePaddle()
	if timerBlink ~= nil then
		timer.pause(timerBlink)
	end
	if timerEnd ~= nil then
		timer.pause(timerEnd)
	end
	if timerBig ~= nil then
		timer.pause(timerBig)
	end
end

function Paddle:resumePaddle()
	if timerBlink ~= nil then
		timer.resume(timerBlink)
	end
	if timerEnd ~= nil then
		timer.resume(timerEnd)
	end
	if timerBig ~= nil then
		timer.resume(timerBig)
	end
end

function Paddle:cancelTimerPaddle()
	if timerBlink ~= nil then
		timer.cancel(timerBlink)
	end
	if timerEnd ~= nil then
		timer.cancel(timerEnd)
	end
	if timerBig ~= nil then
		timer.cancel(timerBig)
	end
end
