local Particles = {}

function Particles.burst(collection, x, y, color, amount)
    for _ = 1, amount or 10 do
        local angle = love.math.random() * math.pi * 2
        local speed = love.math.random(35, 150)
        table.insert(collection, {
            x = x, y = y, velocityX = math.cos(angle) * speed,
            velocityY = math.sin(angle) * speed, age = 0,
            duration = love.math.random() * 0.35 + 0.3, color = color
        })
    end
end

function Particles.update(collection, dt)
    for index = #collection, 1, -1 do
        local particle = collection[index]
        particle.age = particle.age + dt
        particle.x = particle.x + particle.velocityX * dt
        particle.y = particle.y + particle.velocityY * dt
        particle.velocityX = particle.velocityX * 0.97
        particle.velocityY = particle.velocityY * 0.97
        if particle.age >= particle.duration then table.remove(collection, index) end
    end
end

function Particles.draw(collection)
    for _, particle in ipairs(collection) do
        local alpha = 1 - particle.age / particle.duration
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
        love.graphics.circle("fill", particle.x, particle.y, 2 + alpha * 2)
    end
    love.graphics.setColor(1, 1, 1)
end

return Particles
