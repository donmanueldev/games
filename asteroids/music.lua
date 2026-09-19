local Music = {}
Music.__index = Music

function Music.new()
    local rate, duration = 22050, 4
    local data = love.sound.newSoundData(rate * duration, rate, 16, 1)
    for index = 0, data:getSampleCount() - 1 do
        local time = index / rate
        local tone = math.sin(time * math.pi * 2 * 110) * 0.08
            + math.sin(time * math.pi * 2 * 165) * 0.04
        data:setSample(index, tone)
    end
    local source = love.audio.newSource(data, "static")
    source:setLooping(true)
    source:setVolume(0.22)
    return setmetatable({ source = source }, Music)
end

function Music:play(enabled)
    if enabled and not self.source:isPlaying() then self.source:play() end
    if not enabled and self.source:isPlaying() then self.source:pause() end
end

return Music
