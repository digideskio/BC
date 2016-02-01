-- Includes
require "lib/nhub.nhub"
local Class = require "lib/middleclass.middleclass"
local Hxdx = require "lib/hxdx/hxdx"
local Stateful = require "lib/stateful.stateful"

-- Entities
local Ground = require "Ground"
local Player = require "Player"

-- Game class to be returned
local Game = Class("Game")
Game:include(Stateful)

-- Game states
local menu = Game:addState("Menu")
local pause = Game:addState("Pause")
local play = Game:addState("Play")

-- Game constants
local FONT_BODY_SCALE = 0.4
local FONT = love.graphics.newFont('res/fonts/babyblue.ttf', 48)
local GAME_CHANNEL = "blessed-child"
local GRAVITY = 981
local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()

local server = noobhub.new({ server = "server.kambashi.com"; port = 1337; })

-- Game
function Game:initialize()
    love.graphics.setFont(FONT)

    self:gotoState("Menu")
end

function Game:update(dt)
    server:enterFrame()
end

-- Menu
function menu:draw()
    love.graphics.printf("BLESSED CHILD", 0, SCREEN_HEIGHT / 2 - FONT.getHeight(FONT), SCREEN_WIDTH, 'center')
    love.graphics.printf("Press ENTER to START", 0, SCREEN_HEIGHT / 2 + FONT.getHeight(FONT), SCREEN_WIDTH * 2.5, 'center', 0, FONT_BODY_SCALE, FONT_BODY_SCALE)
end

function menu:update(dt)
    if Input:pressed('return') then
        self:gotoState("Play")
    end
end

-- It's only game.
function play:enteredState()
    if server.sock == nil then
        server:subscribe({
            channel = GAME_CHANNEL,
            callback = function(message)
                if (message.action == "update") then
                end
            end
        });
    end

    play.world = Hxdx.newWorld({ gravity_y = GRAVITY })
    play.ground = Ground:new(play.world, 0, SCREEN_HEIGHT - 30, SCREEN_WIDTH, 30)
    play.player = Player:new(play.world, SCREEN_WIDTH / 2, 100)
end

function play:update(dt)
    Game.update(self, dt)

    play.world:update(dt)

    if Input:pressed('p') then
        return self:pushState("Pause")
    end

    server:publish({
        message = {
            action  =  "update",
            dt = dt
        }
    });
end

function play:draw()
    -- Draw entities
    play.player:draw()
    play.ground:draw()
end

-- Pause
function pause:update(dt)
    Game.update(self, dt)

    if Input:pressed('p') then
        return self:popState("Pause")
    end
end

function pause:draw()
    play:draw()

    love.graphics.setColor(0,0,0, 100)
    love.graphics.rectangle('fill', 0,0, SCREEN_WIDTH,SCREEN_HEIGHT)
    love.graphics.setColor(255,255,255)
    love.graphics.printf("PAUSED", 0, SCREEN_HEIGHT - FONT.getHeight(FONT)*2, SCREEN_WIDTH, 'center')
end

return Game