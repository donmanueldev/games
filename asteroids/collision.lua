local Collision = {}

function Collision.distance(x1, y1, x2, y2)
    local dx, dy = x1 - x2, y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end

function Collision.circlesCollide(a, b, width, height)
    local dx = math.abs(a.x - b.x)
    local dy = math.abs(a.y - b.y)

    if width then dx = math.min(dx, width - dx) end
    if height then dy = math.min(dy, height - dy) end

    return math.sqrt(dx * dx + dy * dy) < a.radius + b.radius
end

function Collision.drawCircle(object)
    love.graphics.circle("line", object.x, object.y, object.radius)
end

return Collision
