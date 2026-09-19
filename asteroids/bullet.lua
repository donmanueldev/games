local Bullet = {}
Bullet.__index = Bullet

function Bullet.new(x, y, angle, speed)
    speed = speed or 420
    return setmetatable({
        x = x, y = y, radius = 3, life = 1.2,
        velocityX = math.cos(angle) * speed, velocityY = math.sin(angle) * speed,
        image = love.graphics.newImage("resources/PNG/Lasers/laserBlue01.png")
    }, Bullet)
end

function Bullet:update(dt, width, height)
    self.x = (self.x + self.velocityX * dt) % width
    self.y = (self.y + self.velocityY * dt) % height
    self.life = self.life - dt
end

function Bullet:draw()
    love.graphics.setColor(1, 0.9, 0.3)
    love.graphics.draw(
        self.image,
        self.x,
        self.y,
        math.atan(self.velocityY, self.velocityX) + math.pi / 2,
        0.45,
        0.45,
        self.image:getWidth() / 2,
        self.image:getHeight() / 2
    )
    love.graphics.setColor(1, 1, 1)
end

return Bullet
