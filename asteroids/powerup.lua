local Powerup = {}
Powerup.__index = Powerup

local definitions = {
    shield = { label = "SHIELD", color = { 0.3, 0.8, 1 }, asset = "powerupBlue_shield.png" },
    rapid = { label = "RAPID FIRE", color = { 1, 0.8, 0.2 }, asset = "powerupYellow_bolt.png" },
    double = { label = "DOUBLE SHOT", color = { 0.5, 1, 0.4 }, asset = "powerupGreen_star.png" },
    engine = { label = "ENGINE", color = { 1, 0.4, 0.3 }, asset = "powerupRed.png" },
    multiplier = { label = "SCORE x", color = { 1, 0.55, 0.2 }, asset = "powerupYellow_star.png" },
    life = { label = "EXTRA LIFE", color = { 1, 0.35, 0.55 }, asset = "powerupRed_star.png" },
    explosion = { label = "NOVA", color = { 1, 0.3, 0.1 }, asset = "powerupRed_bolt.png" },
    magnet = { label = "MAGNET", color = { 0.7, 0.35, 1 }, asset = "powerupBlue.png" }
}

function Powerup.new(x, y, kind)
    local definition = definitions[kind]
    return setmetatable({
        x = x, y = y, kind = kind, radius = 15, age = 0,
        velocityY = 12, definition = definition,
        image = love.graphics.newImage("resources/PNG/Power-ups/" .. definition.asset)
    }, Powerup)
end

function Powerup.random(x, y)
    local kinds = { "shield", "rapid", "double", "engine", "multiplier", "life", "explosion", "magnet" }
    return Powerup.new(x, y, kinds[love.math.random(#kinds)])
end

function Powerup:update(dt, width, height)
    self.age = self.age + dt
    self.y = (self.y + self.velocityY * dt) % height
end

function Powerup:draw()
    local pulse = 1 + math.sin(self.age * 5) * 0.08
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.image, self.x, self.y, 0, 0.45 * pulse, 0.45 * pulse,
        self.image:getWidth() / 2, self.image:getHeight() / 2)
    love.graphics.setColor(self.definition.color[1], self.definition.color[2], self.definition.color[3], 0.8)
    love.graphics.circle("line", self.x, self.y, self.radius + 4 + math.sin(self.age * 4) * 2)
    love.graphics.setColor(1, 1, 1)
end

return Powerup
