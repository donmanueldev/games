local Ufo = {}
Ufo.__index = Ufo

function Ufo.new(width, height, isBoss)
    return setmetatable({
        x = width + 50, y = height * 0.25, radius = isBoss and 42 or 22,
        health = isBoss and 30 or 3, maxHealth = isBoss and 30 or 3,
        speed = isBoss and 38 or 72, isBoss = isBoss, age = 0,
        image = love.graphics.newImage("resources/PNG/ufoRed.png")
    }, Ufo)
end

function Ufo:update(dt, width, height, target)
    self.age = self.age + dt
    self.x = self.x - self.speed * dt
    self.y = math.max(self.radius, math.min(height - self.radius,
        self.y + math.sin(self.age * 1.8) * (self.isBoss and 42 or 22) * dt))
    if self.x < -self.radius then self.x = width + self.radius end
end

function Ufo:draw()
    local scale = self.isBoss and 0.9 or 0.48
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.image, self.x, self.y, 0, scale, scale,
        self.image:getWidth() / 2, self.image:getHeight() / 2)
    if self.isBoss then
        love.graphics.setColor(0.2, 0.9, 1)
        love.graphics.rectangle("fill", self.x - 45, self.y - 58, 90 * self.health / self.maxHealth, 5)
        love.graphics.setColor(1, 1, 1)
    end
end

return Ufo
