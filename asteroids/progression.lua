local Progression = {}
Progression.__index = Progression

function Progression.new()
    return setmetatable({
        thrust = 220,
        fireInterval = 0.28,
        shotCount = 1,
        shieldFor = 0,
        rapidFireFor = 0,
        magnetFor = 0,
        scoreMultiplier = 1
    }, Progression)
end

function Progression:reset()
    self.thrust = 220
    self.fireInterval = 0.28
    self.shotCount = 1
    self.shieldFor = 0
    self.rapidFireFor = 0
    self.magnetFor = 0
    self.scoreMultiplier = 1
end

function Progression:update(dt)
    self.shieldFor = math.max(0, self.shieldFor - dt)
    self.rapidFireFor = math.max(0, self.rapidFireFor - dt)
    self.magnetFor = math.max(0, self.magnetFor - dt)
end

function Progression:apply(kind)
    if kind == "shield" then
        self.shieldFor = math.max(self.shieldFor, 8)
    elseif kind == "rapid" then
        self.rapidFireFor = math.max(self.rapidFireFor, 10)
    elseif kind == "double" then
        self.shotCount = math.min(2, self.shotCount + 1)
    elseif kind == "engine" then
        self.thrust = math.min(340, self.thrust + 30)
    elseif kind == "multiplier" then
        self.scoreMultiplier = math.min(3, self.scoreMultiplier + 0.5)
    elseif kind == "life" then
        return "life"
    elseif kind == "magnet" then
        self.magnetFor = math.max(self.magnetFor, 12)
    elseif kind == "explosion" then
        return "explosion"
    end
end

function Progression:currentFireInterval()
    if self.rapidFireFor > 0 then return 0.12 end
    return math.max(0.12, self.fireInterval - (self.shotCount - 1) * 0.02)
end

function Progression:hasShield()
    return self.shieldFor > 0
end

return Progression
