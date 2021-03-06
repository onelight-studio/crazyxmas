-- Scene Game

require "game"
require "paddle"
require "item"

-- constants

local COUNTDOWN = 1500
local PRESENT_SPEED = { { 3, 4 }, { 3, 5 }, { 4, 5 }, { 4, 6 }, { 4, 6 }, { 5, 6 }, { 5, 6 }, { 5, 7 }, { 5, 8 }, { 6, 8 } }
local DELAY_BETWEEN_PRESENTS = { 1000, 800, 600, 450, 300, 300, 300, 250, 250, 250 }
local DELAY_BETWEEN_BOMBS = { 5000, 4500, 4000, 3500, 3500, 3500, 3500, 3500, 3000, 3000 }
local DELAY_BETWEEN_BONUS = 11000
local AUDIO_PITCH = { 1.0, 1.05, 1.1, 1.15, 1.2, 1.25, 1.3, 1.35, 1.4, 1.45 }
local IMP_DELAY = 10000
local MAX_ITEMS_ON_SCREEN = { 3, 4, 5, 5, 6, 6, 7, 7, 8, 8 }
local X2_DELAY = 10000
local SNOWFLAKE_DELAY = 10000
local DELAY_BETWEEN_MAX_ITEMS_ON_SCREEN = 15000
local LIVES_START = 10
local LAST_CHANCE_MIN_LEVEL = 8
local LAST_CHANCE_MIN_LIVES = 3
local LAST_CHANCE_MIN_RATIO = 5

-- variables

local storyboard = require "storyboard"
local widget = require "widget"
local scene = storyboard.newScene()
local bg
local menuButton
local delayBetweenPresents
local delayBetweenBombs
local itemsCountOnScreen
local items = {}
local game
local paddle
local audioLoop
local audioLoopSource
local audioLoopPitch
local presentTimerId
local bombTimerId
local bonusTimerId
local impBonusTimerId
local x2BonusTimerId
local snowflakeBonusTimerId
local impBlinkTimerId
local impToLeft
local starWaterfallTimerId
local starDroppingIndex = 0
local starDroppingMax = 20
local isOnPause = false
local isOnX2Bonus = false
local isOnSnowflakeBonus = false
local songChannel
local imp
local level
local lastBonusType = -1
local bonusTutoTimerId

-- local functions

local function createMenuBtn()
	menuButton = widget.newButton({
		defaultFile = "img/game_pause.png",
		overFile = "img/game_pause_pressed.png",
		onRelease = function(event)
			showPause()
		end
	})
	menuButton.x = menuButton.width / 2 + 5
	menuButton.y = menuButton.height / 2 + 5
end

local function countdown(x)
	local countdownTxt = display.newText(x > 0 and x or language:getString("countdown.go"), 0, 0, FONT, 80)
	countdownTxt.x = display.contentCenterX
	countdownTxt.y = display.contentCenterY
	transition.to(countdownTxt, {
		alpha = 1, time = COUNTDOWN / 6, onComplete = function()
			transition.to(countdownTxt, {
				alpha = 0, time = COUNTDOWN / 6, onComplete = function()
					display.remove(countdownTxt)
					countdownTxt = nil
					if x > 0 then
						countdown(x - 1)
					end
				end
			})
		end
	})
end

function showPause()
	storyboard.showOverlay( "scene_game_pause", {isModal = true, params = { game = game }} )
end

function pauseGame()
	isOnPause = true
	menuButton:removeSelf()
	menuButton = nil

	audio.pause(songChannel)

	if starWaterfallTimerId ~= nil then
		timer.pause(starWaterfallTimerId)
	end
	if impBonusTimerId ~= nil then
		timer.pause(impBonusTimerId)
		timer.pause(impBlinkTimerId)
	end
	if x2BonusTimerId ~= nil then
		timer.pause(x2BonusTimerId)
	end
	if snowflakeBonusTimerId ~= nil then
		timer.pause(snowflakeBonusTimerId)
	end
	if bonusTutoTimerId ~= nil then
		timer.pause(bonusTutoTimerId)
	end

	timer.pause(bombTimerId)
	timer.pause(bonusTimerId)
	timer.pause(presentTimerId)

	paddle:pausePaddle()
end

function resumeGame()
	countdown(3)
	timer.performWithDelay(COUNTDOWN, function()
		if gameSettings.soundEnable then
			audio.resume(songChannel)
		end

		if starWaterfallTimerId ~= nil then
			timer.resume(starWaterfallTimerId)
		end
		if impBonusTimerId ~= nil then
			timer.resume(impBonusTimerId)
			timer.resume(impBlinkTimerId)
		end
		if x2BonusTimerId ~= nil then
			timer.resume(x2BonusTimerId)
		end
		if snowflakeBonusTimerId ~= nil then
			timer.resume(snowflakeBonusTimerId)
		end
		if bonusTutoTimerId ~= nil then
			timer.resume(bonusTutoTimerId)
		end
		timer.resume(bombTimerId)
		timer.resume(bonusTimerId)
		timer.resume(presentTimerId)

		paddle:resumePaddle()

		createMenuBtn()
		isOnPause = false
	end)
end

function startHit()
	for i, item in pairs(items) do
		item:remove()
	end

	timer.pause(bombTimerId)
	timer.pause(presentTimerId)

	al.Source(audioLoopSource, al.PITCH, 2)

	dropPresentLine()
end

function impHit()
	imp = Item(TYPE_IMP, nil, nil)

	if impToLeft == nil or impToLeft == false then
		impToLeft = true
		imp:impToLeft(true)
		imp:onEnterScene(IMP_WIDTH / 2, display.contentHeight / 2)
	else
		imp:impToLeft(false)
		imp:onEnterScene(display.contentWidth - (IMP_WIDTH / 2), display.contentHeight / 2)
		impToLeft = false
	end

	impBlinkTimerId = timer.performWithDelay(IMP_DELAY - 2000, function ()
		if imp ~= nil and imp:elem() ~= nil then 
			blink(imp:elem(), BLINK_SPEED_NORMAL)
		end
	end)

	impBonusTimerId = timer.performWithDelay(IMP_DELAY, endImp)
end

function endImp()
	if imp ~= nil then
		imp:onExitScene()
		imp = nil
		impBonusTimerId = nil
		impBlinkTimerId = nil
	end
end

function x2Hit()
	isOnX2Bonus = true
	x2BonusTimerId = timer.performWithDelay(X2_DELAY, endX2)
	for i,item in ipairs(items) do
		if item.type == TYPE_PRESENT then
			local newItem = Item(TYPE_X2_PRESENT, function() game:increaseScore(2) end, item.fall, item.speed, item.speed)
			newItem:onEnterScene(item.element.x, item.element.y)
			item:remove()
			item = nil
			items[i] = newItem
		end
	end
end

function endX2()
	isOnX2Bonus = false
	x2BonusTimerId = nil
end

function snowflakeHit()
	isOnSnowflakeBonus = true
	snowflakeBonusTimerId = timer.performWithDelay(SNOWFLAKE_DELAY, endSnowflake)
	for i,item in ipairs(items) do
		if item.type == TYPE_PRESENT then
			local newItem = Item(TYPE_SNOWFLAKE_PRESENT, item.hit, item.fall, PRESENT_SPEED[game.level][1] / 3, PRESENT_SPEED[game.level][2] / 3)
			newItem:onEnterScene(item.element.x, item.element.y)
			item:remove()
			item = nil
			items[i] = newItem
		end
	end
end

function endSnowflake()
	isOnSnowflakeBonus = false
	snowflakeBonusTimerId = nil
end

function dropPresentLine()
	if starDroppingIndex < starDroppingMax then
		local prensentNumberPerRow = math.floor(display.contentWidth / PRESENT_WIDTH) / 10
		
		for i=0, prensentNumberPerRow, 1 do
			local present = Item(TYPE_STAR_PRESENT, function() game:increaseScore(1) end, nil)
			table.insert(items, present)
			present:onEnterScene()
		end

		starDroppingIndex = starDroppingIndex + 1
		if starDroppingIndex < starDroppingMax then
			starWaterfallTimerId = timer.performWithDelay(200, dropPresentLine)
		else
			starWaterfallTimerId = timer.performWithDelay(2000, dropPresentLine)
		end
	else
		starWaterfallTimerId = nil
		starDroppingIndex = 0
		timer.resume(bombTimerId)
		timer.resume(presentTimerId)

		al.Source(audioLoopSource, al.PITCH, audioLoopPitch)

		clearItems()
	end
end

local function dropLife()
	if math.random(1, LAST_CHANCE_MIN_RATIO) == 1 then
		local life = Item(TYPE_LIFE_BONUS, function() game:increaseLives(3) end, nil, nil)
		table.insert(items, life)
		life:onEnterScene()
	end
end

local function dropPresent()
	if table.getn(items) < itemsCountOnScreen then
		local present
		if isOnX2Bonus then
			present = Item(TYPE_X2_PRESENT, 
				function() 
					game:increaseScore(2) 
				end, 
				function()
					game:decreaseLives(1)
					if game.lives <= LAST_CHANCE_MIN_LIVES and game.level >= LAST_CHANCE_MIN_LEVEL then
						dropLife()
					end
				end, 
				PRESENT_SPEED[game.level][1], 
				PRESENT_SPEED[game.level][2]
			)
		elseif isOnSnowflakeBonus then
			present = Item(TYPE_SNOWFLAKE_PRESENT,
				function() 
					game:increaseScore(1) 
				end,
				function()
					game:decreaseLives(1)
					if game.lives <= LAST_CHANCE_MIN_LIVES and game.level >= LAST_CHANCE_MIN_LEVEL then
						dropLife()
					end
				end,
				PRESENT_SPEED[game.level][1] / 3,
				PRESENT_SPEED[game.level][2] / 3
			)
		else
			present = Item(TYPE_PRESENT,
				function() 
					game:increaseScore(1) 
				end, 
				function()
					game:decreaseLives(1)
					if game.lives <= LAST_CHANCE_MIN_LIVES and game.level >= LAST_CHANCE_MIN_LEVEL then
						dropLife()
					end
				end,
				PRESENT_SPEED[game.level][1],
				PRESENT_SPEED[game.level][2]
			)
		end

		table.insert(items, present)
		present:onEnterScene()
		if not gameSettings.tuto[TYPE_PRESENT] then
			bonusTutoTimerId = timer.performWithDelay(500, function()
				gameSettings.tuto[TYPE_PRESENT] = true
				loadsave.saveTable(gameSettings, GAME_SETTINGS)
				storyboard.showOverlay("scene_bonus_tuto", { isModal = true, params = { bonusType = TYPE_PRESENT, bonusItem = present } } )
			end)
		end
	end

	audioLoopPitch = AUDIO_PITCH[game.level]
	al.Source(audioLoopSource, al.PITCH, audioLoopPitch)
	itemsCountOnScreen = MAX_ITEMS_ON_SCREEN[game.level]
	delayBetweenPresents = DELAY_BETWEEN_PRESENTS[game.level]
	presentTimerId = timer.performWithDelay(delayBetweenPresents, dropPresent)
end

local function dropBomb()
	local bomb = Item(TYPE_BOMB, function()
		game:decreaseLives(5)
		blink(paddle:elem(), BLINK_SPEED_BOMB)
		if game.lives <= LAST_CHANCE_MIN_LIVES and game.level >= LAST_CHANCE_MIN_LEVEL then
			dropLife()
		end
	end, nil)
	table.insert(items, bomb)
	bomb:onEnterScene()
	if not gameSettings.tuto[TYPE_BOMB] then
		bonusTutoTimerId = timer.performWithDelay(500, function()
			gameSettings.tuto[TYPE_BOMB] = true
			loadsave.saveTable(gameSettings, GAME_SETTINGS)
			storyboard.showOverlay("scene_bonus_tuto", { isModal = true, params = { bonusType = TYPE_BOMB, bonusItem = bomb } } )
		end)
	end

	delayBetweenBombs = DELAY_BETWEEN_BOMBS[game.level]
	bombTimerId = timer.performWithDelay(delayBetweenBombs, dropBomb)
end

local function dropBonus()
	local bonusType = 0
	if game.newLevel and game.level <= 7 then
		bonusType = game.level
		game.newLevel = false
	else
		bonusType = math.random(1, math.min(game.level, 7))
	end
	local bonus
	
	if bonusType == 1 then
		bonus = Item(TYPE_X2_BONUS, function() x2Hit() end, nil, nil)
	elseif bonusType == 2 then
		bonus = Item(TYPE_IMP_BONUS, function() impHit() end, nil, nil)
	elseif bonusType == 3 then
		bonus = Item(TYPE_ASPIRATOR_BONUS, function() paddle:toAspiratorMode(true) end, nil, nil)
	elseif bonusType == 4 then
		bonus = Item(TYPE_LIFE_BONUS, function() game:increaseLives(3) end, nil, nil)
	elseif bonusType == 5 then
		bonus = Item(TYPE_STAR_BONUS, function() startHit() end, nil, nil)
	elseif bonusType == 6 then
		bonus = Item(TYPE_SNOWFLAKE_BONUS, function() snowflakeHit() end, nil, nil)
	elseif bonusType == 7 then
		bonus = Item(TYPE_BIG_BONUS, function() paddle:toBigMode(true) end, nil, nil)
	end

	if game.level > 1 and bonusType == lastBonusType then
		-- force a different bonus
		dropBonus()
	else
		lastBonusType = bonusType
		table.insert(items, bonus)
		bonus:onEnterScene()
		bonusTimerId = timer.performWithDelay(DELAY_BETWEEN_BONUS, dropBonus)

		if not gameSettings.tuto[bonus.type] then
			bonusTutoTimerId = timer.performWithDelay(300, function()
				gameSettings.tuto[bonus.type] = true
				loadsave.saveTable(gameSettings, GAME_SETTINGS)
				storyboard.showOverlay("scene_bonus_tuto", { isModal = true, params = { bonusType = bonus.type, bonusItem = bonus } } )
			end)
		end
	end
end

-- events

local function onEveryFrame(event)
	if isOnPause == false then
		-- move paddle
		paddle:move()

		local impBounds
		local itemBounds
		local paddleAspiratorBounds
		local paddleBounds = paddle:contentBounds()

		if paddle.mode == PADDLE_MODE_ASPIRATOR then
			paddleAspiratorBounds = paddle:aspiratorContentBounds()
		end

		if imp ~= nil then
			impBounds = imp:contentBounds()
		end

		-- move each item
		for i, item in pairs(items) do
			item:startTranslate()

			itemBounds = item:contentBounds()

			if itemBounds ~= nil and paddleBounds ~= nil then
				-- remove the item if it is in the paddle
				if paddleAspiratorBounds ~= nil and item.type ~= TYPE_BOMB and item.aspirated == nil then
					if isBoundsInBounds(itemBounds, paddleAspiratorBounds) then
						local toX = paddleBounds.xMin + ((paddleBounds.xMax - paddleBounds.xMin) / 2)
						local toY = paddleBounds.yMin + 10

						item:aspiratedTo(toX, toY)
					end
				else
					if isBoundsInBounds(itemBounds, paddleBounds) or item:aspiratedDone() then
						table.remove(items, i)
						item:remove()

						if paddle.mode == PADDLE_MODE_BIG and item.type == TYPE_BOMB then
							--item:onHit(game, true)
						else
							item:onHit(game)
						end
					end
				end

				-- remove only present items if it is in the imp
				if imp ~= nil and impBounds ~= nil then
					if isBoundsInBounds(itemBounds, impBounds) then
						table.remove(items, i)
						item:remove()
						if item.type ~= TYPE_BOMB then
							item:onHit(game)
						end
					end
				end
				
				-- remove the item if it is out of the screen
				if itemBounds.yMin > display.contentHeight then
					table.remove(items, i)
					item:remove()
					item:onFall(game)
				end
			end

			-- put bombs to front
			if item.type == TYPE_BOMB then
				item:toFront()
			end
		end

		-- check lives
		if game.lives <= 0 then
			Runtime:removeEventListener("enterFrame", onEveryFrame)
			game:gameOver()
			storyboard.showOverlay( "scene_game_over", {isModal = true, params = { game = game }} )
		elseif game.score >= LEVELS[table.getn(LEVELS)] then
			-- game if finished
			gameSettings.finished = true
			loadsave.saveTable(gameSettings, GAME_SETTINGS)
			storyboard.showOverlay("scene_game_finished", { params = { game = game } })
		else
			-- keep the text visible
			game:scoreLivesToFront()
			menuButton:toFront()
			paddle:toFront()
		end
	end
end

function clearItems()
	for i, item in pairs(items) do
		item:onExitScene()
		items[i] = nil
	end
end

-- scene functions

function scene:createScene( event )
	-- Nothing
end

function scene:willEnterScene( event )
	-- Nothing
end

function scene:enterScene( event )
    paddle = Paddle()
	game = Game(event.params and event.params.level or 1, LIVES_START)

	-- init
	math.randomseed(os.time())

	audio.stop()
	audio.setVolume(1.0)

	bg = display.newImage( "img/bg.jpg" )

	delayBetweenPresents = DELAY_BETWEEN_PRESENTS[game.level]
	delayBetweenBombs = DELAY_BETWEEN_BOMBS[game.level]
	itemsCountOnScreen = MAX_ITEMS_ON_SCREEN[game.level]

	lastBonusType = -1

	paddle:onEnterScene()
	game:onEnterScene()

	local firstTime = not gameSettings.tuto[TYPE_PRESENT]
	-- don't show the countdown the first time: the game will be stopped with the first present
	if not firstTime then
		countdown(3)
	end

	timer.performWithDelay(firstTime and 0 or COUNTDOWN, function()
		-- listeners
		Runtime:addEventListener("enterFrame", onEveryFrame)
		-- sounds
		audioLoop = audio.loadSound("sound/jingle_bells.mp3")
		songChannel = audio.play(audioLoop, { channel=1, loops=-1 })
		if gameSettings.soundEnable == false then
			audio.pause(songChannel)
		end
		audioLoopSource = audio.getSourceFromChannel(1)
		audioLoopPitch = AUDIO_PITCH[game.level]
		al.Source(audioLoopSource, al.PITCH, audioLoopPitch)

		createMenuBtn()

		dropPresent()
		bombTimerId = timer.performWithDelay(delayBetweenBombs, dropBomb)
		bonusTimerId = timer.performWithDelay(DELAY_BETWEEN_BONUS, dropBonus)
	end)
end

function scene:exitScene( event )
	Runtime:removeEventListener("enterFrame", onEveryFrame)

	display.remove(bg)
	bg = nil
	display.remove(menuButton)
	menuButton = nil

	paddle:onExitScene()
	game:onExitScene()
	endImp()
	clearItems()

	timer.cancel(presentTimerId)
	timer.cancel(bombTimerId)
	timer.cancel(bonusTimerId)
	if impBonusTimerId ~= nil then
		timer.cancel(impBonusTimerId)
		timer.cancel(impBlinkTimerId)
	end
	if x2BonusTimerId ~= nil then
		timer.cancel(x2BonusTimerId)
		isOnX2Bonus = false
	end
	if snowflakeBonusTimerId ~= nil then
		timer.cancel(snowflakeBonusTimerId)
		isOnSnowflakeBonus = false
	end
	if starWaterfallTimerId ~= nil then
		timer.cancel(starWaterfallTimerId)
	end

	audio.stop(songChannel)
end

function scene:destroyScene( event )
	-- Nothing
end

function scene:overlayBegan( event )
    pauseGame()
end

function scene:overlayEnded( event )
	if game.restart then
		self:exitScene()
		isOnPause = false
		self:enterScene({ params = { level = game.level } })
	elseif game.quit then
		self:exitScene()
		isOnPause = false
	else
		resumeGame()
	end
end

-- core

scene:addEventListener( "createScene", scene )
scene:addEventListener( "willEnterScene", scene )
scene:addEventListener( "enterScene", scene )
scene:addEventListener( "exitScene", scene )
scene:addEventListener( "destroyScene", scene )
scene:addEventListener( "overlayBegan" )
scene:addEventListener( "overlayEnded" )

return scene
