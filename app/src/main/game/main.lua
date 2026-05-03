-- ================= 水果接接乐（最终无错版） =================
-- 功能：开始界面、游戏主循环、暂停、游戏结束、音效、图片、触摸/键盘
-- 使用默认英文字体，按钮文字为英文，无需外部字体文件

-- 游戏状态常量
STATE_MENU = 1
STATE_PLAYING = 2
STATE_PAUSED = 3
STATE_GAMEOVER = 4

function love.load()
    -- 定义字体（使用默认字体，可显示英文）
    smallFont = love.graphics.newFont(20)
    mediumFont = love.graphics.newFont(30)
    largeFont = love.graphics.newFont(50)
    
    -- 1. 加载背景图 ------------------------------------------------
    bg = love.graphics.newImage("bg.png")
    
    -- 2. 加载图片 -------------------------------------------------
    basketImg = love.graphics.newImage("basket.png")
    bombImg = love.graphics.newImage("bomb.png")
    
    local fruitDefs = {
        cherry = {img = "cherry.png", score = 5},
        strawberry = {img = "strawberry.png", score = 5},
        banana = {img = "banana.png", score = 8},
        pear = {img = "pear.png", score = 8},
        kiwi = {img = "kiwi.png", score = 10},
        watermelon = {img = "watermelon.png", score = 15},
        durian = {img = "durian.png", score = 20}
    }
    fruits = {}
    fruitNames = {}
    for name, data in pairs(fruitDefs) do
        fruits[name] = {
            img = love.graphics.newImage(data.img),
            score = data.score
        }
        table.insert(fruitNames, name)
    end
    
    -- 3. 加载音效 -------------------------------------------------
    local function safeLoadSound(filename)
        local success, sound = pcall(love.audio.newSource, filename, "static")
        if success then return sound else return nil end
    end
    moveSound = safeLoadSound("move.mp3") or safeLoadSound("move.wav") or safeLoadSound("move.ogg")
    scoreSound = safeLoadSound("score.mp3") or safeLoadSound("score.wav") or safeLoadSound("score.ogg")
    bombSound = safeLoadSound("bomb.mp3") or safeLoadSound("bomb.wav") or safeLoadSound("bomb.ogg")
    
    -- 4. 游戏配置 -------------------------------------------------
    GRID_W = 20
    GRID_H = 15
    basketX = math.floor(GRID_W / 2)
    score = 0
    items = {}
    spawnTimer = 0
    
    -- 5. 状态机 ---------------------------------------------------
    gameState = STATE_MENU
    finalScore = 0
    
    -- 6. 触摸/鼠标 -------------------------------------------------
    touchStartX = nil
    
    -- 7. 按钮定义（英文）-------------------------------------------
    menuButtons = {
        {text = "START", action = function() startNewGame() end}
    }
    pauseButtons = {
        {text = "RESUME", action = function() gameState = STATE_PLAYING end},
        {text = "QUIT", action = function() love.event.quit() end}
    }
    gameoverButtons = {
        {text = "RETRY", action = function() startNewGame() end},
        {text = "QUIT", action = function() love.event.quit() end}
    }
end

-- 开始新游戏
function startNewGame()
    gameState = STATE_PLAYING
    score = 0
    items = {}
    basketX = math.floor(GRID_W / 2)
    spawnTimer = 0
    finalScore = 0
end

-- 生成掉落物
function spawnItem()
    local x = math.random(0, GRID_W - 1)
    if math.random(1, 5) == 1 then   -- 20% 炸弹
        table.insert(items, {
            x = x,
            y = 0,
            type = "bomb",
            img = bombImg
        })
    else
        local fruitName = fruitNames[math.random(#fruitNames)]
        local fruit = fruits[fruitName]
        table.insert(items, {
            x = x,
            y = 0,
            type = "fruit",
            fruitName = fruitName,
            score = fruit.score,
            img = fruit.img
        })
    end
end

-- 游戏逻辑更新
function love.update(dt)
    if gameState ~= STATE_PLAYING then return end
    
    spawnTimer = spawnTimer + dt
    if spawnTimer > 0.4 then
        spawnTimer = 0
        if #items < 30 then
            spawnItem()
        end
    end
    
    for i = #items, 1, -1 do
        local item = items[i]
        item.y = item.y + dt * 3
        if item.y >= GRID_H - 1 and math.floor(item.x) == basketX then
            if item.type == "fruit" then
                score = score + item.score
                if scoreSound then scoreSound:play() end
            else
                if bombSound then bombSound:play() end
                finalScore = score
                gameState = STATE_GAMEOVER
                return
            end
            table.remove(items, i)
        elseif item.y >= GRID_H then
            table.remove(items, i)
        end
    end
end

-- 绘制游戏场景（背景、网格、物品、篮子、UI）
function drawGameScene()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local cellW = w / GRID_W
    local cellH = h / GRID_H
    
    -- 背景
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(bg, 0, 0, 0, w / bg:getWidth(), h / bg:getHeight())
    
    -- 极淡网格线（可删除）
    love.graphics.setColor(1, 1, 1, 0.1)
    for i = 0, GRID_W do love.graphics.line(i * cellW, 0, i * cellW, h) end
    for i = 0, GRID_H do love.graphics.line(0, i * cellH, w, i * cellH) end
    
    -- 掉落物
    for _, item in ipairs(items) do
        local x = item.x * cellW
        local y = item.y * cellH
        local scaleX = cellW / item.img:getWidth()
        local scaleY = cellH / item.img:getHeight()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(item.img, x, y, 0, scaleX, scaleY)
    end
    
    -- 篮子
    local basketY = (GRID_H - 1) * cellH
    local scaleX = cellW / basketImg:getWidth()
    local scaleY = cellH / basketImg:getHeight()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(basketImg, basketX * cellW, basketY, 0, scaleX, scaleY)
    
    -- 分数和提示
    love.graphics.setFont(smallFont)
    love.graphics.setColor(1, 1, 0.8)
    love.graphics.print("Score: " .. score, 15, 15)
    love.graphics.print("A / D  or  SWIPE", 15, h - 35)
    
    -- 暂停按钮（仅在游戏中显示）
    if gameState == STATE_PLAYING then
        love.graphics.setColor(0.2, 0.2, 0.2, 0.7)
        love.graphics.rectangle("fill", w - 70, 10, 60, 40)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("||", w - 55, 18)
    end
end

-- 通用按钮绘制函数
function drawButton(btn, screenW, screenH, offsetX, offsetY)
    local x = (screenW - btn.w) / 2 + (offsetX or 0)
    local y = (screenH - btn.h) / 2 + (offsetY or 0) + (btn.y or 0)
    
    -- 按钮背景
    love.graphics.setColor(0.2, 0.5, 0.1, 0.95)
    love.graphics.rectangle("fill", x, y, btn.w, btn.h, 10)
    -- 边框
    love.graphics.setColor(1, 1, 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, btn.w, btn.h, 10)
    
    -- 文字（白色居中）
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(mediumFont)
    local textW = mediumFont:getWidth(btn.text)
    local textX = x + (btn.w - textW) / 2
    local textY = y + (btn.h - mediumFont:getHeight()) / 2
    love.graphics.print(btn.text, textX, textY)
    
    -- 保存点击区域
    btn.screenX = x
    btn.screenY = y
    btn.screenW = btn.w
    btn.screenH = btn.h
end

-- 检查按钮点击
function checkButtonClick(buttons, x, y)
    for _, btn in ipairs(buttons) do
        if btn.screenX and x >= btn.screenX and x <= btn.screenX + btn.screenW and
           y >= btn.screenY and y <= btn.screenY + btn.screenH then
            if btn.action then btn.action() end
            return true
        end
    end
    return false
end

-- 绘制主界面
function love.draw()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    
    if gameState == STATE_MENU then
        drawGameScene()
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", 0, 0, w, h)
        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.setFont(largeFont)
        love.graphics.printf("Fruit Catcher", 0, h * 0.2, w, "center")
        -- 开始按钮
        local btn = menuButtons[1]
        btn.w = 250; btn.h = 70
        drawButton(btn, w, h, 0, 80)
        
    elseif gameState == STATE_PLAYING then
        drawGameScene()
        
    elseif gameState == STATE_PAUSED then
        drawGameScene()
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, w, h)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(largeFont)
        love.graphics.printf("PAUSED", 0, h * 0.3, w, "center")
        local btnCont = pauseButtons[1]; btnCont.w = 200; btnCont.h = 60
        local btnQuit = pauseButtons[2]; btnQuit.w = 200; btnQuit.h = 60
        drawButton(btnCont, w, h, -120, 100)
        drawButton(btnQuit, w, h, 120, 100)
        
    elseif gameState == STATE_GAMEOVER then
        drawGameScene()
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, w, h)
        love.graphics.setColor(1, 0.5, 0.5)
        love.graphics.setFont(largeFont)
        love.graphics.printf("GAME OVER", 0, h * 0.2, w, "center")
        love.graphics.setColor(1, 1, 0.8)
        love.graphics.setFont(mediumFont)
        love.graphics.printf("Your Score: " .. finalScore, 0, h * 0.38, w, "center")
        local btnAgain = gameoverButtons[1]; btnAgain.w = 220; btnAgain.h = 60
        local btnQuit = gameoverButtons[2]; btnQuit.w = 220; btnQuit.h = 60
        drawButton(btnAgain, w, h, -130, 100)
        drawButton(btnQuit, w, h, 130, 100)
    end
end

-- 键盘事件
function love.keypressed(key)
    if gameState == STATE_PLAYING then
        if key == "a" or key == "left" then
            basketX = math.max(0, basketX - 1)
            if moveSound then moveSound:play() end
        elseif key == "d" or key == "right" then
            basketX = math.min(GRID_W - 1, basketX + 1)
            if moveSound then moveSound:play() end
        elseif key == "p" or key == "escape" then
            gameState = STATE_PAUSED
        end
    elseif gameState == STATE_PAUSED then
        if key == "p" or key == "escape" then
            gameState = STATE_PLAYING
        end
    elseif gameState == STATE_MENU then
        if key == "return" or key == "space" then
            startNewGame()
        end
    elseif gameState == STATE_GAMEOVER then
        if key == "r" then
            startNewGame()
        elseif key == "escape" then
            love.event.quit()
        end
    end
end

-- 鼠标/触摸按下
function love.mousepressed(x, y, button)
    if button ~= 1 then return end
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    if gameState == STATE_MENU then
        checkButtonClick(menuButtons, x, y)
    elseif gameState == STATE_PLAYING then
        if x > w - 70 and x < w - 10 and y > 10 and y < 50 then
            gameState = STATE_PAUSED
        else
            touchStartX = x
        end
    elseif gameState == STATE_PAUSED then
        checkButtonClick(pauseButtons, x, y)
    elseif gameState == STATE_GAMEOVER then
        checkButtonClick(gameoverButtons, x, y)
    end
end

function love.touchpressed(id, x, y)
    love.mousepressed(x, y, 1)
end

-- 触摸滑动
function love.touchmoved(id, x, y)
    if gameState ~= STATE_PLAYING then return end
    if touchStartX then
        local delta = x - touchStartX
        if delta > 20 then
            basketX = math.min(GRID_W - 1, basketX + 1)
            if moveSound then moveSound:play() end
            touchStartX = x
        elseif delta < -20 then
            basketX = math.max(0, basketX - 1)
            if moveSound then moveSound:play() end
            touchStartX = x
        end
    end
end

function love.touchreleased(id, x, y)
    touchStartX = nil
end