local Player = {}
Player.__index = Player

function Player.new()
    return setmetatable({
        x = 0, y = 0, angle = -math.pi / 2, radius = 22,
        velocityX = 0, velocityY = 0,
        invulnerableFor = 0,
        image = love.graphics.newImage("resources/PNG/playerShip1_blue.png"),
        thrustImage = love.graphics.newImage("resources/PNG/Effects/fire03.png"),
        thrusting = false
    }, Player)
end

function Player:reset(x, y)
    self.x, self.y = x, y
    self.angle = -math.pi / 2
    self.velocityX, self.velocityY = 0, 0
    self.invulnerableFor = 2
end

function Player:update(dt, width, height, thrust, controls)
    self.invulnerableFor = math.max(0, self.invulnerableFor - dt)
    thrust = thrust or 220
    controls = controls or { rotateLeft = "a", rotateRight = "d", thrust = "w" }
    self.thrusting = love.keyboard.isDown(controls.thrust, "up")
    if love.keyboard.isDown(controls.rotateLeft, "left") then self.angle = self.angle - 4 * dt end
    if love.keyboard.isDown(controls.rotateRight, "right") then self.angle = self.angle + 4 * dt end

    if self.thrusting then
        self.velocityX = self.velocityX + math.cos(self.angle) * thrust * dt
        self.velocityY = self.velocityY + math.sin(self.angle) * thrust * dt
    end

    self.velocityX = self.velocityX * (1 - math.min(dt * 0.35, 0.9))
    self.velocityY = self.velocityY * (1 - math.min(dt * 0.35, 0.9))
    self.x = (self.x + self.velocityX * dt) % width
    self.y = (self.y + self.velocityY * dt) % height
end

function Player:draw(scale, x, y)
    if self.invulnerableFor > 0 and math.floor(self.invulnerableFor * 10) % 2 == 0 then
        return
    end

    scale = scale or 0.48
    x = x or self.x
    y = y or self.y
    love.graphics.setColor(1, 1, 1)
    if self.thrusting then
        love.graphics.setColor(1, 0.55, 0.15, 0.9)
        love.graphics.draw(self.thrustImage, x - math.cos(self.angle) * 22, y - math.sin(self.angle) * 22,
            self.angle + math.pi / 2, 0.38, 0.38, self.thrustImage:getWidth() / 2, self.thrustImage:getHeight() / 2)
        love.graphics.setColor(1, 1, 1)
    end
    love.graphics.draw(
        self.image,
        x,
        y,
        self.angle + math.pi / 2,
        scale,
        scale,
        self.image:getWidth() / 2,
        self.image:getHeight() / 2
    )
    love.graphics.setColor(1, 1, 1)
end

return Player
