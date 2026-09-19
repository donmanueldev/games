local ScoreOrb = {}
ScoreOrb.__index = ScoreOrb

function ScoreOrb.new(x, y, value)
    return setmetatable({ x = x, y = y, value = value or 25, radius = 7, age = 0 }, ScoreOrb)
end

function ScoreOrb:update(dt)
    self.age = self.age + dt
end

function ScoreOrb:draw()
    local pulse = 1 + math.sin(self.age * 6) * 0.15
    love.graphics.setColor(1, 0.85, 0.2, 0.95)
    love.graphics.circle("fill", self.x, self.y, self.radius * pulse)
    love.graphics.setColor(1, 1, 0.65, 0.9)
    love.graphics.circle("line", self.x, self.y, self.radius * pulse + 3)
    love.graphics.setColor(1, 1, 1)
end

return ScoreOrb
