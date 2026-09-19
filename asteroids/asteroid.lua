local Asteroid = {}
Asteroid.__index = Asteroid

local sizes = {
    large = { radius = 34, speed = 45, points = 20 },
    medium = { radius = 22, speed = 70, points = 50 },
    small = { radius = 12, speed = 100, points = 100 }
}

function Asteroid.new(x, y, size, speedMultiplier, variant, behavior)
    local data = sizes[size]
    speedMultiplier = speedMultiplier or 1
    variant = variant or "brown"
    local angle = love.math.random() * math.pi * 2
    local prefix = variant == "grey" and "meteorGrey_" or "meteorBrown_"
    local imageName = size == "large" and prefix .. "big1.png"
        or size == "medium" and prefix .. "med1.png"
        or prefix .. "small1.png"

    return setmetatable({
        x = x, y = y, size = size, variant = variant, behavior = behavior or "normal",
        explosive = behavior == "explosive", chaser = behavior == "chaser",
        radius = data.radius, points = data.points,
        velocityX = math.cos(angle) * data.speed * speedMultiplier,
        velocityY = math.sin(angle) * data.speed * speedMultiplier,
        rotation = love.math.random() * math.pi * 2,
        rotationSpeed = (love.math.random() - 0.5) * 2,
        image = love.graphics.newImage("resources/PNG/Meteors/" .. imageName)
    }, Asteroid)
end

function Asteroid:update(dt, width, height, target)
    if self.chaser and target then
        local angle = math.atan(target.y - self.y, target.x - self.x)
        self.velocityX = self.velocityX + math.cos(angle) * 18 * dt
        self.velocityY = self.velocityY + math.sin(angle) * 18 * dt
    end
    self.x = (self.x + self.velocityX * dt) % width
    self.y = (self.y + self.velocityY * dt) % height
    self.rotation = self.rotation + self.rotationSpeed * dt
end

function Asteroid:draw()
    if self.explosive then
        love.graphics.setColor(1, 0.35, 0.15)
    elseif self.chaser then
        love.graphics.setColor(0.55, 0.8, 1)
    else
        love.graphics.setColor(0.8, 0.72, 0.55)
    end
    local scale = self.radius * 2 / math.max(self.image:getWidth(), self.image:getHeight())
    love.graphics.draw(
        self.image,
        self.x,
        self.y,
        self.rotation,
        scale,
        scale,
        self.image:getWidth() / 2,
        self.image:getHeight() / 2
    )
    if self.explosive then
        love.graphics.setColor(1, 0.2, 0.05, 0.65)
        love.graphics.circle("line", self.x, self.y, self.radius + 5)
    end
    love.graphics.setColor(1, 1, 1)
end

return Asteroid
