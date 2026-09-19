local Highscores = {}
local path = "highscores.txt"

function Highscores.load()
    local result = {}
    if not love.filesystem.getInfo(path) then return result end
    for line in love.filesystem.lines(path) do
        local name, points, difficulty, date = line:match("([^|]+)|(%d+)|([^|]+)|([^|]+)")
        if not name then
            name, points, difficulty = line:match("([^|]+)|(%d+)|([^|]+)")
        end
        if name then table.insert(result, { name = name, score = tonumber(points), difficulty = difficulty, date = date or "unknown" }) end
    end
    table.sort(result, function(a, b) return a.score > b.score end)
    return result
end

function Highscores.save(entries, name, score, difficulty)
    table.insert(entries, { name = name, score = score, difficulty = difficulty, date = os.date("%Y-%m-%d") })
    table.sort(entries, function(a, b) return a.score > b.score end)
    while #entries > 5 do table.remove(entries) end
    local lines = {}
    for _, entry in ipairs(entries) do
        table.insert(lines, string.format("%s|%d|%s|%s", entry.name, entry.score, entry.difficulty, entry.date or "unknown"))
    end
    love.filesystem.write(path, table.concat(lines, "\n"))
    return entries
end

function Highscores.qualifies(entries, score)
    return #entries < 5 or score > entries[#entries].score
end

return Highscores
