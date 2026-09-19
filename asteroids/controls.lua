local Controls = {}

Controls.defaults = {
    rotateLeft = "a",
    rotateRight = "d",
    thrust = "w",
    fire = "space",
    pause = "p",
    settings = "s"
}

function Controls.new()
    local bindings = {}
    for action, key in pairs(Controls.defaults) do bindings[action] = key end
    return bindings
end

function Controls.load()
    local bindings = Controls.new()
    if love.filesystem.getInfo("controls.txt") then
        for line in love.filesystem.lines("controls.txt") do
            local action, key = line:match("([^=]+)=([^=]+)")
            if action and bindings[action] then bindings[action] = key end
        end
    end
    return bindings
end

function Controls.save(bindings)
    local lines = {}
    for _, action in ipairs({ "rotateLeft", "rotateRight", "thrust", "fire", "pause", "settings" }) do
        table.insert(lines, action .. "=" .. bindings[action])
    end
    love.filesystem.write("controls.txt", table.concat(lines, "\n"))
end

function Controls.isDown(bindings, action)
    local key = bindings[action]
    if action == "rotateLeft" then return love.keyboard.isDown(key, "left") end
    if action == "rotateRight" then return love.keyboard.isDown(key, "right") end
    if action == "thrust" then return love.keyboard.isDown(key, "up") end
    return love.keyboard.isDown(key)
end

function Controls.rebind(bindings, action, key)
    if bindings[action] then bindings[action] = key end
end

return Controls
