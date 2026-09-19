local Player = require("player")
local Asteroid = require("asteroid")
local Bullet = require("bullet")
local Collision = require("collision")
local Progression = require("progression")
local Powerup = require("powerup")
local Particles = require("particles")
local Ufo = require("ufo")
local Highscores = require("highscores")
local Controls = require("controls")
local Music = require("music")
local ScoreOrb = require("score_orb")

local player
local asteroids = {}
local bullets = {}
local score = 0
local highScore = 0
local lives = 3
local state = "menu"
local wave = 1
local maxWaves = 10
local spawnTimer = 0
local fireCooldown = 0
local difficultyMultiplier = 1
local explosions = {}
local particles = {}
local powerups = {}
local scoreOrbs = {}
local enemyBullets = {}
local ufo
local ufoShootTimer = 2
local progression = Progression.new()
local highscores = {}
local playerName = ""
local timeRemaining = 60
local missionProgress = 0
local missionTarget = 20
local missionKind = "destroy"
local waveBannerFor = 0
local damageFlashFor = 0
local debugHitboxes = false
local background
local backgrounds = {}
local logo
local uiFont
local sounds = {}
local music
local settingsPreviousState
local settingsSelection = 1
local controlsSelection = 1
local waitingForControlKey = false
local controls = Controls.new()
local controlActions = { "rotateLeft", "rotateRight", "thrust", "fire", "pause", "settings" }
local controlLabels = {
    rotateLeft = "Rotate left", rotateRight = "Rotate right", thrust = "Accelerate",
    fire = "Fire", pause = "Pause", settings = "Settings"
}
local settings = {
    difficulty = "normal",
    mode = "campaign",
    sound = true,
    music = true,
    hitboxes = false,
    controlHints = true
}
local settingsOptions = {
    { key = "mode", label = "Game mode", values = { "campaign", "endless", "time trial" } },
    { key = "difficulty", label = "Difficulty", values = { "easy", "normal", "hard" } },
    { key = "sound", label = "Sound", values = { true, false } },
    { key = "music", label = "Music", values = { true, false } },
    { key = "hitboxes", label = "Hitboxes", values = { true, false } },
    { key = "controlHints", label = "Control hints", values = { true, false } }
}

local function playSound(sound)
    if settings.sound and sound then
        sound:stop()
        sound:play()
    end
end

local function settingLabel(option)
    local value = settings[option.key]
    if type(value) == "boolean" then
        return value and "ON" or "OFF"
    end
    return string.upper(value)
end

local function changeSetting(direction)
    local option = settingsOptions[settingsSelection]
    local currentIndex = 1
    for index, value in ipairs(option.values) do
        if value == settings[option.key] then
            currentIndex = index
            break
        end
    end
    currentIndex = ((currentIndex - 1 + direction) % #option.values) + 1
    settings[option.key] = option.values[currentIndex]
    debugHitboxes = settings.hitboxes
    if music then music:play(settings.music) end
end

local function screenSize()
    return love.graphics.getWidth(), love.graphics.getHeight()
end

local function setBackgroundForWave()
    if #backgrounds > 0 then
        local backgroundIndex = ((wave - 1) % #backgrounds) + 1
        background = backgrounds[backgroundIndex]
    end
end

local function spawnWave()
    local width, height = screenSize()
    setBackgroundForWave()
    local count = math.min(3 + wave, 12)
    local difficultyBase = settings.difficulty == "easy" and 0.82
        or settings.difficulty == "hard" and 1.22
        or 1
    difficultyMultiplier = difficultyBase + math.min(wave - 1, 8) * 0.12

    for i = 1, count do
        local x = love.math.random(0, width)
        local y = love.math.random(0, height)

        while Collision.distance(x, y, player.x, player.y) < 160 do
            x = love.math.random(0, width)
            y = love.math.random(0, height)
        end

        local variant = love.math.random() < math.min(0.2 + wave * 0.03, 0.5) and "grey" or "brown"
        local size = "large"
        if wave >= 4 and love.math.random() < math.min((wave - 3) * 0.08, 0.35) then
            size = "medium"
        end
        local behavior = "normal"
        if wave >= 4 and love.math.random() < 0.12 then
            behavior = "explosive"
        elseif wave >= 5 and love.math.random() < 0.12 then
            behavior = "chaser"
        end
        table.insert(asteroids, Asteroid.new(x, y, size, difficultyMultiplier, variant, behavior))
    end

    if wave >= 3 and not ufo then
        ufo = Ufo.new(width, height, wave == maxWaves and settings.mode == "campaign")
        ufoShootTimer = 1.5
    end
    waveBannerFor = 2.2
end

local function resetPlayer()
    local width, height = screenSize()
    player:reset(width / 2, height / 2)
end

local function restartGame()
    score = 0
    lives = 3
    wave = 1
    state = "playing"
    maxWaves = settings.mode == "endless" and 999 or 10
    timeRemaining = 60
    missionProgress = 0
    missionKind = settings.mode == "time trial" and "survive" or "destroy"
    missionTarget = missionKind == "survive" and 60 or 20
    playerName = ""
    asteroids = {}
    bullets = {}
    enemyBullets = {}
    powerups = {}
    scoreOrbs = {}
    explosions = {}
    particles = {}
    ufo = nil
    progression:reset()
    fireCooldown = 0
    resetPlayer()
    spawnWave()
end

local function loadHighScore()
    if love.filesystem.getInfo("highscore.txt") then
        highScore = tonumber(love.filesystem.read("highscore.txt")) or 0
    end
end

local function saveHighScore()
    if score > highScore then
        highScore = score
        love.filesystem.write("highscore.txt", tostring(highScore))
    end
end

local function addExplosion(x, y, radius)
    table.insert(explosions, { x = x, y = y, radius = radius, age = 0, duration = 0.35 })
    Particles.burst(particles, x, y, { 1, 0.55, 0.15 }, 14)
end

local function updateExplosions(dt)
    for index = #explosions, 1, -1 do
        local explosion = explosions[index]
        explosion.age = explosion.age + dt
        if explosion.age >= explosion.duration then
            table.remove(explosions, index)
        end
    end
end

local function fire()
    if state ~= "playing" or fireCooldown > 0 then
        return
    end
    local bulletSpeed = 420 + math.min(wave - 1, 8) * 10
    table.insert(bullets, Bullet.new(player.x, player.y, player.angle, bulletSpeed))
    if progression.shotCount > 1 then
        table.insert(bullets, Bullet.new(player.x, player.y, player.angle + 0.12, bulletSpeed))
    end
    fireCooldown = progression:currentFireInterval()
    playSound(sounds.laser)
end

local function splitAsteroid(asteroid)
    if asteroid.size == "large" then
        table.insert(asteroids, Asteroid.new(asteroid.x, asteroid.y, "medium", difficultyMultiplier, asteroid.variant))
        table.insert(asteroids, Asteroid.new(asteroid.x, asteroid.y, "medium", difficultyMultiplier, asteroid.variant))
    elseif asteroid.size == "medium" then
        table.insert(asteroids, Asteroid.new(asteroid.x, asteroid.y, "small", difficultyMultiplier, asteroid.variant))
        table.insert(asteroids, Asteroid.new(asteroid.x, asteroid.y, "small", difficultyMultiplier, asteroid.variant))
    end
end

local function triggerAsteroidExplosion(source, width, height)
    local radius = source.radius * 3
    for index = #asteroids, 1, -1 do
        local target = asteroids[index]
        if target ~= source and Collision.distance(source.x, source.y, target.x, target.y) < radius then
            table.remove(asteroids, index)
            score = score + math.floor(target.points * progression.scoreMultiplier)
            addExplosion(target.x, target.y, target.radius)
        end
    end
    Particles.burst(particles, source.x, source.y, { 1, 0.2, 0.05 }, 24)
end

local function triggerNova()
    for index = #asteroids, 1, -1 do
        local asteroid = table.remove(asteroids, index)
        score = score + math.floor(asteroid.points * progression.scoreMultiplier)
        addExplosion(asteroid.x, asteroid.y, asteroid.radius)
        missionProgress = missionProgress + 1
    end
    Particles.burst(particles, player.x, player.y, { 0.5, 0.8, 1 }, 42)
end

local function finishGame(nextState)
    state = nextState
    saveHighScore()
    if Highscores.qualifies(highscores, score) then
        playerName = ""
        state = "name_entry"
    end
end

function love.load()
    love.window.setTitle("Asteroids - Collision Lab")
    background = love.graphics.newImage("resources/Backgrounds/blue.png")
    backgrounds = {
        love.graphics.newImage("resources/Backgrounds/blue.png"),
        love.graphics.newImage("resources/Backgrounds/purple.png"),
        love.graphics.newImage("resources/Backgrounds/darkPurple.png"),
        love.graphics.newImage("resources/Backgrounds/black.png")
    }
    logo = love.graphics.newImage("resources/logo.png")
    uiFont = love.graphics.newFont("resources/Bonus/kenvector_future.ttf", 14)
    love.graphics.setFont(uiFont)
    love.graphics.setBackgroundColor(0.03, 0.04, 0.08)
    sounds.laser = love.audio.newSource("resources/Bonus/sfx_laser1.ogg", "static")
    sounds.explosion = love.audio.newSource("resources/Bonus/sfx_zap.ogg", "static")
    sounds.lose = love.audio.newSource("resources/Bonus/sfx_lose.ogg", "static")
    sounds.shieldUp = love.audio.newSource("resources/Bonus/sfx_shieldUp.ogg", "static")
    sounds.shieldDown = love.audio.newSource("resources/Bonus/sfx_shieldDown.ogg", "static")
    music = Music.new()
    music:play(settings.music)
    controls = Controls.load()
    player = Player.new()
    loadHighScore()
    highscores = Highscores.load()
end

function love.keypressed(key)
    if state == "controls" then
        if waitingForControlKey then
            if key == "escape" then
                waitingForControlKey = false
            else
                Controls.rebind(controls, controlActions[controlsSelection], key)
                Controls.save(controls)
                waitingForControlKey = false
            end
        elseif key == "escape" then
            state = "settings"
        elseif key == "up" or key == "w" then
            controlsSelection = ((controlsSelection - 2) % #controlActions) + 1
        elseif key == "down" or key == "s" then
            controlsSelection = (controlsSelection % #controlActions) + 1
        elseif key == "return" or key == "space" then
            waitingForControlKey = true
        end
    elseif state == "tutorial" then
        if key == "escape" or key == "return" or key == "space" then state = "menu" end
    elseif state == "name_entry" then
        if key == "backspace" then
            playerName = playerName:sub(1, -2)
        elseif key == "return" and #playerName > 0 then
            highscores = Highscores.save(highscores, playerName:upper(), score, settings.difficulty)
            state = "leaderboard"
        end
    elseif state == "leaderboard" then
        if key == "return" or key == "space" then restartGame() end
    elseif state == "settings" then
        if key == "escape" then
            state = settingsPreviousState or "menu"
        elseif key == "c" then
            state = "controls"
        elseif key == "up" or key == "w" then
            settingsSelection = ((settingsSelection - 2) % #settingsOptions) + 1
        elseif key == "down" or key == "s" then
            settingsSelection = (settingsSelection % #settingsOptions) + 1
        elseif key == "left" or key == "a" then
            changeSetting(-1)
        elseif key == "right" or key == "d" or key == "return" or key == "space" then
            changeSetting(1)
        end
    elseif state == "menu" and (key == "return" or key == "space") then
        restartGame()
    elseif state == "menu" and key == "s" then
        settingsPreviousState = state
        state = "settings"
    elseif state == "menu" and key == "t" then
        state = "tutorial"
    elseif (state == "gameover" or state == "victory") and (key == "r" or key == "return") then
        restartGame()
    elseif key == controls.fire then
        fire()
    elseif key == controls.pause and (state == "playing" or state == "paused") then
        state = state == "playing" and "paused" or "playing"
    elseif key == "h" then
        debugHitboxes = not debugHitboxes
        settings.hitboxes = debugHitboxes
    elseif key == controls.settings and (state == "playing" or state == "paused") then
        settingsPreviousState = state
        state = "settings"
    end
end

function love.textinput(text)
    if state == "name_entry" and #playerName < 10 and text:match("^[%w%s]+$") then
        playerName = playerName .. text
    end
end

function love.update(dt)
    updateExplosions(dt)
    Particles.update(particles, dt)
    waveBannerFor = math.max(0, waveBannerFor - dt)
    damageFlashFor = math.max(0, damageFlashFor - dt)

    if state ~= "playing" then
        return
    end

    progression:update(dt)
    fireCooldown = math.max(0, fireCooldown - dt)
    if settings.mode == "time trial" then
        timeRemaining = math.max(0, timeRemaining - dt)
        if timeRemaining <= 0 then finishGame("victory") return end
    end
    local width, height = screenSize()
    player:update(dt, width, height, progression.thrust, controls)

    for _, asteroid in ipairs(asteroids) do
        asteroid:update(dt, width, height, player)
    end

    for _, bullet in ipairs(bullets) do
        bullet:update(dt, width, height)
    end

    for _, bullet in ipairs(enemyBullets) do
        bullet:update(dt, width, height)
    end

    for _, powerup in ipairs(powerups) do
        powerup:update(dt, width, height)
        if progression.magnetFor > 0 then
            local dx, dy = player.x - powerup.x, player.y - powerup.y
            local distance = math.max(1, math.sqrt(dx * dx + dy * dy))
            if distance < 220 then
                powerup.x = powerup.x + dx / distance * 130 * dt
                powerup.y = powerup.y + dy / distance * 130 * dt
            end
        end
    end

    for _, orb in ipairs(scoreOrbs) do orb:update(dt) end

    if ufo then
        ufo:update(dt, width, height, player)
        ufoShootTimer = ufoShootTimer - dt
        if ufoShootTimer <= 0 then
            local angle = math.atan(player.y - ufo.y, player.x - ufo.x)
            table.insert(enemyBullets, Bullet.new(ufo.x, ufo.y, angle, 180))
            ufoShootTimer = ufo.isBoss and 0.75 or 1.8
        end
    end

    for bulletIndex = #bullets, 1, -1 do
        local bullet = bullets[bulletIndex]
        if bullet.life <= 0 then
            table.remove(bullets, bulletIndex)
        else
            for asteroidIndex = #asteroids, 1, -1 do
                local asteroid = asteroids[asteroidIndex]
                if Collision.circlesCollide(bullet, asteroid, width, height) then
                    table.remove(bullets, bulletIndex)
                    table.remove(asteroids, asteroidIndex)
                    splitAsteroid(asteroid)
                    addExplosion(asteroid.x, asteroid.y, asteroid.radius)
                    if asteroid.explosive then triggerAsteroidExplosion(asteroid, width, height) end
                    playSound(sounds.explosion)
                    score = score + math.floor(asteroid.points * progression.scoreMultiplier)
                    missionProgress = missionProgress + 1
                    if love.math.random() < 0.35 then
                        table.insert(scoreOrbs, ScoreOrb.new(asteroid.x, asteroid.y, asteroid.points))
                    end
                    if love.math.random() < 0.12 then
                        table.insert(powerups, Powerup.random(asteroid.x, asteroid.y))
                    end
                    break
                end
            end
        end
    end

    for bulletIndex = #bullets, 1, -1 do
        local bullet = bullets[bulletIndex]
        if ufo and Collision.circlesCollide(bullet, ufo, width, height) then
            table.remove(bullets, bulletIndex)
            ufo.health = ufo.health - 1
            addExplosion(ufo.x, ufo.y, 8)
            if ufo.health <= 0 then
                score = score + (ufo.isBoss and 2000 or 500)
                Particles.burst(particles, ufo.x, ufo.y, { 0.2, 0.8, 1 }, 30)
                ufo = nil
            end
        end
    end

    for bulletIndex = #enemyBullets, 1, -1 do
        local bullet = enemyBullets[bulletIndex]
        if bullet.life <= 0 then
            table.remove(enemyBullets, bulletIndex)
        elseif Collision.circlesCollide(player, bullet, width, height) then
            table.remove(enemyBullets, bulletIndex)
            if progression:hasShield() then
                progression.shieldFor = 0
                playSound(sounds.shieldDown)
            else
                damageFlashFor = 0.3
                lives = lives - 1
                if lives <= 0 then
                    finishGame("gameover")
                else
                    resetPlayer()
                end
            end
        end
    end

    for index = #powerups, 1, -1 do
        local powerup = powerups[index]
        if Collision.circlesCollide(player, powerup, width, height) then
            table.remove(powerups, index)
            local effect = progression:apply(powerup.kind)
            if effect == "life" then
                lives = math.min(5, lives + 1)
            elseif effect == "explosion" then
                triggerNova()
            end
            playSound(sounds.shieldUp)
            score = score + 100
        end
    end

    for index = #scoreOrbs, 1, -1 do
        local orb = scoreOrbs[index]
        if progression.magnetFor > 0 then
            local dx, dy = player.x - orb.x, player.y - orb.y
            local distance = math.max(1, math.sqrt(dx * dx + dy * dy))
            if distance < 260 then
                orb.x = orb.x + dx / distance * 180 * dt
                orb.y = orb.y + dy / distance * 180 * dt
            end
        end
        if Collision.circlesCollide(player, orb, width, height) then
            table.remove(scoreOrbs, index)
            score = score + math.floor(orb.value * progression.scoreMultiplier)
        end
    end

    if missionKind == "survive" then missionProgress = 60 - timeRemaining end

    for asteroidIndex = #asteroids, 1, -1 do
        if player.invulnerableFor <= 0 and Collision.circlesCollide(player, asteroids[asteroidIndex], width, height) then
            local asteroid = asteroids[asteroidIndex]
            table.remove(asteroids, asteroidIndex)
            addExplosion(player.x, player.y, player.radius)
            if asteroid.explosive then triggerAsteroidExplosion(asteroid, width, height) end
            playSound(sounds.lose)
            if progression:hasShield() then
                progression.shieldFor = 0
                playSound(sounds.shieldDown)
                resetPlayer()
            else
                damageFlashFor = 0.3
                lives = lives - 1
                if lives <= 0 then
                    finishGame("gameover")
                else
                    resetPlayer()
                end
            end
            break
        end
    end

    if ufo and player.invulnerableFor <= 0 and Collision.circlesCollide(player, ufo, width, height) then
        if progression:hasShield() then
            progression.shieldFor = 0
            playSound(sounds.shieldDown)
        else
            lives = lives - 1
            damageFlashFor = 0.3
            if lives <= 0 then
                finishGame("gameover")
            else
                resetPlayer()
            end
        end
    end

    if #asteroids == 0 and not ufo and spawnTimer <= 0 then
        if wave >= maxWaves and settings.mode ~= "endless" then
            finishGame("victory")
        else
            wave = wave + 1
            spawnTimer = math.max(0.45, 1.2 - math.min(wave - 1, 10) * 0.05)
        end
    end

    if spawnTimer > 0 then
        spawnTimer = spawnTimer - dt
        if spawnTimer <= 0 then
            spawnWave()
        end
    end
end

local function drawSettings()
    local width, height = screenSize()
    local panelWidth = math.min(560, width - 80)
    local panelHeight = 450
    local panelX = (width - panelWidth) / 2
    local panelY = (height - panelHeight) / 2

    love.graphics.setColor(0.02, 0.04, 0.1, 0.94)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 10, 10)
    love.graphics.setColor(0.25, 0.65, 1, 0.85)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 10, 10)

    love.graphics.setColor(0.7, 0.9, 1)
    love.graphics.printf("SETTINGS", panelX, panelY + 26, panelWidth, "center")
    love.graphics.setColor(0.45, 0.55, 0.7)
    love.graphics.printf("Configure your flight experience", panelX, panelY + 52, panelWidth, "center")

    for index, option in ipairs(settingsOptions) do
        local rowY = panelY + 96 + (index - 1) * 54
        local selected = index == settingsSelection
        if selected then
            love.graphics.setColor(0.12, 0.28, 0.48, 0.9)
            love.graphics.rectangle("fill", panelX + 24, rowY - 8, panelWidth - 48, 42, 6, 6)
        end

        love.graphics.setColor(selected and 1 or 0.75, selected and 0.9 or 0.82, 1)
        love.graphics.print((selected and ">  " or "    ") .. option.label, panelX + 40, rowY + 2)
        love.graphics.setColor(0.35, 0.8, 1)
        love.graphics.printf("<  " .. settingLabel(option) .. "  >", panelX + panelWidth - 190, rowY + 2, 150, "right")
    end

    love.graphics.setColor(0.55, 0.65, 0.8)
    love.graphics.printf("UP/DOWN select   LEFT/RIGHT change   C controls   ESC back", panelX, panelY + panelHeight - 32, panelWidth, "center")
    love.graphics.setColor(1, 1, 1)
end

function love.draw()
    local width, height = screenSize()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(background, 0, 0, 0, width / background:getWidth(), height / background:getHeight())

    if state == "menu" or state == "settings" then
        love.graphics.draw(
            logo,
            width / 2,
            height / 2 - 92,
            0,
            0.15,
            0.15,
            logo:getWidth() / 2,
            logo:getHeight() / 2
        )
    else
        player:draw()
    end
    for _, asteroid in ipairs(asteroids) do
        asteroid:draw()
    end
    for _, bullet in ipairs(bullets) do
        bullet:draw()
    end
    for _, bullet in ipairs(enemyBullets) do
        bullet:draw()
    end
    for _, powerup in ipairs(powerups) do
        powerup:draw()
    end
    for _, orb in ipairs(scoreOrbs) do orb:draw() end
    if ufo then ufo:draw() end
    Particles.draw(particles)

    for _, explosion in ipairs(explosions) do
        local progress = explosion.age / explosion.duration
        love.graphics.setColor(1, 0.5 + progress * 0.5, 0.1, 1 - progress)
        love.graphics.circle("line", explosion.x, explosion.y, explosion.radius * (1 + progress))
    end

    if debugHitboxes and state ~= "settings" then
        love.graphics.setColor(0.2, 1, 0.3, 0.8)
        Collision.drawCircle(player)
        for _, asteroid in ipairs(asteroids) do Collision.drawCircle(asteroid) end
        for _, bullet in ipairs(bullets) do Collision.drawCircle(bullet) end
    end

    if progression:hasShield() and state == "playing" then
        love.graphics.setColor(0.25, 0.8, 1, 0.65)
        love.graphics.circle("line", player.x, player.y, player.radius + 10 + math.sin(love.timer.getTime() * 5) * 2)
        love.graphics.setColor(1, 1, 1)
    end

    if damageFlashFor > 0 then
        love.graphics.setColor(1, 0.08, 0.08, damageFlashFor / 0.3 * 0.22)
        love.graphics.rectangle("fill", 0, 0, width, height)
        love.graphics.setColor(1, 1, 1)
    end

    love.graphics.setColor(1, 1, 1)
    local timerLabel = settings.mode == "time trial" and string.format("   Time: %02d", math.ceil(timeRemaining)) or ""
    love.graphics.print(string.format("Score: %d   Best: %d   Lives: %d   Wave: %d%s", score, highScore, lives, wave, timerLabel), 16, 16)
    if state == "playing" then
        love.graphics.setColor(0.7, 0.85, 1)
        local missionText = missionKind == "survive"
            and string.format("Mission: survive %ds/%ds", math.floor(missionProgress), missionTarget)
            or string.format("Mission: destroy asteroids %d/%d", math.min(missionProgress, missionTarget), missionTarget)
        love.graphics.print(missionText, 16, 36)
        love.graphics.setColor(1, 1, 1)
    end
    if state == "playing" and wave < 999 then
        love.graphics.setColor(0.2, 0.7, 1, 0.8)
        love.graphics.rectangle("fill", 16, 55, 180 * (#asteroids > 0 and (1 - math.min(#asteroids / math.max(3 + wave, 1), 1)) or 1), 4)
        love.graphics.setColor(1, 1, 1)
    end
    if state == "playing" and waveBannerFor > 0 then
        local alpha = math.min(1, waveBannerFor)
        love.graphics.setColor(0.55, 0.85, 1, alpha)
        love.graphics.printf(string.format("WAVE %02d", wave), 0, height / 2 - 70, width, "center")
        love.graphics.setColor(1, 1, 1)
    end
    if settings.controlHints and state ~= "settings" then
        love.graphics.print("A/D rotate  W accelerate  SPACE fire  P pause  S settings", 16, 72)
    end

    if state == "menu" then
        love.graphics.printf("ASTEROIDS\n\nPress ENTER or SPACE to start\nPress S for settings\nPress T for tutorial", 0, love.graphics.getHeight() / 2 - 60, love.graphics.getWidth(), "center")
    elseif state == "settings" then
        drawSettings()
    elseif state == "controls" then
        love.graphics.setColor(0.02, 0.04, 0.1, 0.95)
        love.graphics.rectangle("fill", 90, 60, width - 180, height - 120, 10, 10)
        love.graphics.setColor(0.7, 0.9, 1)
        love.graphics.printf("CONTROLS", 100, 88, width - 200, "center")
        for index, action in ipairs(controlActions) do
            local y = 135 + (index - 1) * 42
            local selected = index == controlsSelection
            love.graphics.setColor(selected and 0.15 or 0.08, selected and 0.35 or 0.12, selected and 0.55 or 0.2, 0.95)
            love.graphics.rectangle("fill", 150, y - 6, width - 300, 32, 5, 5)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print((selected and "> " or "  ") .. controlLabels[action], 175, y)
            love.graphics.printf(string.upper(controls[action]), 400, y, width - 575, "right")
        end
        love.graphics.setColor(0.6, 0.7, 0.85)
        local footer = waitingForControlKey and "Press a key to assign it (ESC cancels)" or "UP/DOWN select   ENTER change   ESC back"
        love.graphics.printf(footer, 100, height - 88, width - 200, "center")
        love.graphics.setColor(1, 1, 1)
    elseif state == "tutorial" then
        love.graphics.setColor(0.02, 0.04, 0.1, 0.95)
        love.graphics.rectangle("fill", 90, 80, width - 180, height - 160, 10, 10)
        love.graphics.setColor(0.7, 0.9, 1)
        love.graphics.printf("HOW TO PLAY", 100, 112, width - 200, "center")
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Destroy asteroids, collect power-ups and survive each wave.\n\nW / UP     accelerate\nA / D      rotate\nSPACE      fire\nP          pause\nS          settings\n\nShield blocks one collision. Power-ups improve your ship permanently for this run.\n\nPress ENTER or ESC to return", 140, 165, width - 280, "center")
    elseif state == "name_entry" then
        love.graphics.printf("NEW HIGH SCORE\n\nEnter your pilot name:\n\n" .. (playerName == "" and "_" or playerName:upper()) .. "\n\nPress ENTER to save", 80, height / 2 - 100, width - 160, "center")
    elseif state == "leaderboard" then
        local lines = "LEADERBOARD\n\n"
        for index, entry in ipairs(highscores) do
            lines = lines .. string.format("%d. %-10s %5d  %s  %s\n", index, entry.name, entry.score, entry.difficulty, entry.date)
        end
        love.graphics.printf(lines .. "\nPress ENTER to play again", 80, 100, width - 160, "center")
    elseif state == "paused" then
        love.graphics.printf("PAUSED", 0, love.graphics.getHeight() / 2 - 12, love.graphics.getWidth(), "center")
    elseif state == "gameover" then
        love.graphics.setColor(0.08, 0.03, 0.08, 0.94)
        love.graphics.rectangle("fill", 110, 145, width - 220, 300, 12, 12)
        love.graphics.setColor(1, 0.35, 0.3)
        love.graphics.printf("GAME OVER", 120, 185, width - 240, "center")
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Score: " .. score .. "\nBest: " .. highScore .. "\nWave reached: " .. wave .. "\n\nPress R or ENTER to restart", 130, 245, width - 260, "center")
    elseif state == "victory" then
        love.graphics.printf("VICTORY!\nYou cleared all " .. maxWaves .. " levels.\nScore: " .. score .. "   Best: " .. highScore .. "\nPress R or ENTER to play again", 0, love.graphics.getHeight() / 2 - 48, love.graphics.getWidth(), "center")
    end
end
