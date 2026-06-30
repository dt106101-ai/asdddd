-- 厭璃卡密系統 - 絢麗多彩現代化 UI (HWID 完全修復版)
_G.YANLI_LOADER_LIVE = true
if not _G.YANLI_LOADER_LIVE then return end

local BASE_URL = "https://yli-panel-loader.vercel.app"
local API_KEY = "1b1e2s5t2_3b5l4o7x5f8ru2i6t2_6s3c7r1i7p2t7_2Y4L7I4_0T9e3a6m4_8t4e8s2t8_3a7p5i52"

local http_request = request or http_request or (syn and syn.request)
if not http_request then
    warn("[KEX] Executor does not support HTTP requests.")
    return
end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local localPlayer = Players.LocalPlayer

-- ===== 1. 獲取本機 HWID (完全重寫) =====
local function generateValidHWID()
    -- 嘗試獲取執行器 HWID
    local rawHWID = nil
    
    if gethwid then
        rawHWID = gethwid()
    elseif syn and syn.request and syn.get_hwid then
        rawHWID = syn.get_hwid()
    end
    
    -- 如果獲取到了 HWID，清理並驗證
    if rawHWID and type(rawHWID) == "string" then
        -- 移除所有非十六進制字符
        rawHWID = rawHWID:lower():gsub("[^0-9a-f]", "")
        
        -- 如果長度正確（64字符），直接使用
        if #rawHWID == 64 then
            print("[Yanli] 使用執行器 HWID")
            return rawHWID
        end
        
        -- 如果長度不足，填充到 64 字符
        if #rawHWID > 0 and #rawHWID < 64 then
            rawHWID = rawHWID .. string.rep("0", 64 - #rawHWID)
            print("[Yanli] 使用填充後的執行器 HWID")
            return rawHWID
        end
    end
    
    -- 備用方案：生成基於用戶信息的穩定 HWID
    print("[Yanli] 生成基於用戶的穩定 HWID")
    
    local function stringToHex(str, targetLength)
        local hex = ""
        for i = 1, #str do
            hex = hex .. string.format("%02x", string.byte(str, i))
        end
        -- 重複直到達到目標長度
        while #hex < targetLength do
            hex = hex .. hex
        end
        return hex:sub(1, targetLength)
    end
    
    -- 使用用戶 ID + 用戶名 + 固定鹽值生成穩定的 HWID
    local userId = tostring(localPlayer.UserId)
    local userName = localPlayer.Name
    local salt = "YanliPremiumAuth2024"
    local combined = userId .. userName .. salt
    
    return stringToHex(combined, 64)
end

local FULL_HWID = generateValidHWID()

-- 驗證 HWID 格式
local isValidFormat = FULL_HWID:match("^[0-9a-f]+$") and #FULL_HWID == 64
print("[Yanli Debug] HWID:", FULL_HWID)
print("[Yanli Debug] HWID 長度:", #FULL_HWID)
print("[Yanli Debug] HWID 格式有效:", isValidFormat)

-- ===== 2. 挑戰題數學演算法 =====
local function imul(a, b)
    local a_lo = bit32.band(a, 0xFFFF)
    local a_hi = bit32.rshift(a, 16)
    local b_lo = bit32.band(b, 0xFFFF)
    local b_hi = bit32.rshift(b, 16)
    local lo = a_lo * b_lo
    local mid = (a_hi * b_lo) + (a_lo * b_hi)
    return bit32.band(lo + bit32.lshift(mid, 16), 0xFFFFFFFF)
end

local function rol(value, shift)
    shift = shift % 32
    if shift == 0 then return bit32.band(value, 0xFFFFFFFF) end
    local left = bit32.lshift(value, shift)
    local right = bit32.rshift(value, 32 - shift)
    return bit32.band(bit32.bor(left, right), 0xFFFFFFFF)
end

local function applyOp(a, b, op)
    a = bit32.band(a, 0xFFFFFFFF)
    b = bit32.band(b, 0xFFFFFFFF)
    if op == "mul" then return imul(a, b)
    elseif op == "add" then return bit32.band(a + b, 0xFFFFFFFF)
    elseif op == "sub" then return bit32.band(a - b + 0x100000000, 0xFFFFFFFF)
    elseif op == "xor" then return bit32.band(bit32.bxor(a, b), 0xFFFFFFFF)
    elseif op == "rol" then return rol(a, b % 32) end
    return a
end

local function solveChallenge(challenge, hwid)
    local nums = challenge.nums
    local ops = challenge.ops
    local nonce = challenge.nonce
    local seed = challenge.seed
    local solveTime = challenge.solveTime

    local result = bit32.band(nums[1], 0xFFFFFFFF)
    for i = 1, #ops do result = applyOp(result, nums[i + 1], ops[i]) end

    local nonceNum = 0
    for i = 1, #nonce do nonceNum = bit32.band(imul(nonceNum, 31) + string.byte(nonce, i), 0xFFFFFFFF) end

    local hwidTruncated = hwid:sub(1, 8)
    local hwidNum = 0
    for i = 1, #hwidTruncated do hwidNum = bit32.band(imul(hwidNum, 31) + string.byte(hwidTruncated, i), 0xFFFFFFFF) end

    result = applyOp(result, seed, "xor")
    result = applyOp(result, nonceNum, "add")
    result = applyOp(result, hwidNum, "xor")
    
    local timeSec = math.floor(solveTime / 1000)
    result = applyOp(result, timeSec, "add")

    return bit32.band(result, 0xFFFFFFFF)
end

-- ===== 3. 核心下載與執行腳本 =====
local function runCoreScript()
    local timestamp = os.time() * 1000

    local challengeOk, challengeRes = pcall(function()
        return http_request({
            Url = BASE_URL .. "/api/challenge",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["x-kex-api-key"] = API_KEY,
                ["x-kex-hwid"] = FULL_HWID,
                ["x-kex-timestamp"] = tostring(timestamp)
            },
            Body = "{}"
        })
    end)

    if not challengeOk or not challengeRes then return false, "網路連線失敗" end

    local statusCode = challengeRes.StatusCode or challengeRes.status
    if statusCode ~= 200 then return false, "無法取得題目" end

    local jsonDecode = HttpService.JSONDecode
    local responseData = jsonDecode(HttpService, challengeRes.Body or challengeRes.body)
    
    local challengeId = responseData.challengeId
    local challengeData = responseData.challenge

    if not challengeId or not challengeData then return false, "題目解析失敗" end

    local answer = solveChallenge(challengeData, FULL_HWID)
    local clientNonce = tostring(math.random(100000, 999999)) .. tostring(os.time())

    local scriptOk, scriptRes = pcall(function()
        return http_request({
            Url = BASE_URL .. "/api/script",
            Method = "GET",
            Headers = {
                ["x-kex-api-key"] = API_KEY,
                ["x-kex-hwid"] = FULL_HWID,
                ["x-kex-timestamp"] = tostring(timestamp),
                ["x-kex-nonce"] = clientNonce,
                ["x-kex-challenge-id"] = challengeId,
                ["x-kex-challenge-answer"] = tostring(answer)
            }
        })
    end)

    local scriptStatusCode = scriptRes and (scriptRes.StatusCode or scriptRes.status)
    if not scriptOk or scriptStatusCode ~= 200 then return false, "最終驗證未通過" end

    local scriptBody = scriptRes.Body or scriptRes.body
    
    task.spawn(function()
        local pOk, pErr = pcall(function() loadstring(scriptBody)() end)
        if not pOk then warn("[KEX] Script error: " .. tostring(pErr)) end
    end)
    
    return true
end

-- ===== 4. 動畫工具函數 =====
local function tweenProperty(instance, property, targetValue, duration, easingStyle, easingDirection)
    easingStyle = easingStyle or Enum.EasingStyle.Quart
    easingDirection = easingDirection or Enum.EasingDirection.Out
    
    local tweenInfo = TweenInfo.new(duration, easingStyle, easingDirection)
    local tween = TweenService:Create(instance, tweenInfo, {[property] = targetValue})
    tween:Play()
    return tween
end

local function createNotification(parent, title, message, duration, notifType)
    local NotifFrame = Instance.new("Frame")
    NotifFrame.Size = UDim2.new(0, 0, 0, 90)
    NotifFrame.Position = UDim2.new(1, -20, 0, 20)
    NotifFrame.AnchorPoint = Vector2.new(1, 0)
    NotifFrame.BackgroundColor3 = notifType == "success" and Color3.fromRGB(50, 215, 130) or 
                                  notifType == "error" and Color3.fromRGB(255, 75, 100) or 
                                  Color3.fromRGB(90, 170, 255)
    NotifFrame.BorderSizePixel = 0
    NotifFrame.ClipsDescendants = true
    NotifFrame.ZIndex = 100
    NotifFrame.Parent = parent
    
    local NotifCorner = Instance.new("UICorner")
    NotifCorner.CornerRadius = UDim.new(0, 14)
    NotifCorner.Parent = NotifFrame
    
    local NotifGradient = Instance.new("UIGradient")
    if notifType == "success" then
        NotifGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 215, 130)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 195, 110))
        }
    elseif notifType == "error" then
        NotifGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 75, 100)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(235, 55, 80))
        }
    else
        NotifGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 90, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 170, 255))
        }
    end
    NotifGradient.Rotation = 135
    NotifGradient.Parent = NotifFrame
    
    local NotifIcon = Instance.new("TextLabel")
    NotifIcon.Size = UDim2.fromOffset(40, 40)
    NotifIcon.Position = UDim2.new(0, 15, 0, 25)
    NotifIcon.BackgroundTransparency = 1
    NotifIcon.Text = notifType == "success" and "✓" or notifType == "error" and "✕" or "ℹ"
    NotifIcon.TextColor3 = Color3.new(1, 1, 1)
    NotifIcon.TextSize = 26
    NotifIcon.Font = Enum.Font.GothamBold
    NotifIcon.Parent = NotifFrame
    
    local NotifTitle = Instance.new("TextLabel")
    NotifTitle.Size = UDim2.new(1, -65, 0, 25)
    NotifTitle.Position = UDim2.new(0, 60, 0, 15)
    NotifTitle.BackgroundTransparency = 1
    NotifTitle.Text = title
    NotifTitle.TextColor3 = Color3.new(1, 1, 1)
    NotifTitle.TextSize = 15
    NotifTitle.Font = Enum.Font.GothamBold
    NotifTitle.TextXAlignment = Enum.TextXAlignment.Left
    NotifTitle.Parent = NotifFrame
    
    local NotifMessage = Instance.new("TextLabel")
    NotifMessage.Size = UDim2.new(1, -65, 0, 40)
    NotifMessage.Position = UDim2.new(0, 60, 0, 40)
    NotifMessage.BackgroundTransparency = 1
    NotifMessage.Text = message
    NotifMessage.TextColor3 = Color3.fromRGB(255, 255, 255)
    NotifMessage.TextTransparency = 0.2
    NotifMessage.TextSize = 12
    NotifMessage.Font = Enum.Font.Gotham
    NotifMessage.TextXAlignment = Enum.TextXAlignment.Left
    NotifMessage.TextWrapped = true
    NotifMessage.Parent = NotifFrame
    
    tweenProperty(NotifFrame, "Size", UDim2.new(0, 340, 0, 90), 0.5, Enum.EasingStyle.Back)
    
    task.delay(duration or 3, function()
        tweenProperty(NotifFrame, "Size", UDim2.new(0, 0, 0, 90), 0.4)
        tweenProperty(NotifFrame, "BackgroundTransparency", 1, 0.4)
        task.wait(0.5)
        NotifFrame:Destroy()
    end)
end

-- ===== 5. 絢麗多彩現代化 UI =====
task.spawn(function()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "YanliPremiumAuth"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999
    
    pcall(function()
        ScreenGui.Parent = game:GetService("CoreGui")
    end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = localPlayer:WaitForChild("PlayerGui")
    end

    local BlurBackground = Instance.new("Frame")
    BlurBackground.Name = "BlurBG"
    BlurBackground.Size = UDim2.new(1, 0, 1, 0)
    BlurBackground.Position = UDim2.new(0, 0, 0, 0)
    BlurBackground.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    BlurBackground.BackgroundTransparency = 1
    BlurBackground.BorderSizePixel = 0
    BlurBackground.ZIndex = 1
    BlurBackground.Parent = ScreenGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainWindow"
    MainFrame.Size = UDim2.fromOffset(500, 600)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = false
    MainFrame.ZIndex = 2
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 18)
    MainCorner.Parent = MainFrame

    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.Size = UDim2.new(1, 50, 1, 50)
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    Shadow.ImageColor3 = Color3.new(0, 0, 0)
    Shadow.ImageTransparency = 0.5
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    Shadow.ZIndex = 1
    Shadow.Parent = MainFrame

    local TopGradient = Instance.new("Frame")
    TopGradient.Size = UDim2.new(1, 0, 0, 140)
    TopGradient.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    TopGradient.BorderSizePixel = 0
    TopGradient.ZIndex = 3
    TopGradient.Parent = MainFrame

    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 18)
    TopCorner.Parent = TopGradient

    local TopGrad = Instance.new("UIGradient")
    TopGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 180)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(150, 80, 255)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(80, 150, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 220, 200))
    }
    TopGrad.Rotation = 45
    TopGrad.Parent = TopGradient

    task.spawn(function()
        while TopGradient and TopGradient.Parent do
            for i = 0, 360, 2 do
                if not TopGradient or not TopGradient.Parent then break end
                TopGrad.Rotation = i
                task.wait(0.05)
            end
        end
    end)

    local LogoContainer = Instance.new("Frame")
    LogoContainer.Size = UDim2.fromOffset(70, 70)
    LogoContainer.Position = UDim2.new(0, 25, 0, 30)
    LogoContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    LogoContainer.BackgroundTransparency = 0.1
    LogoContainer.BorderSizePixel = 0
    LogoContainer.ZIndex = 4
    LogoContainer.Parent = TopGradient

    local LogoContainerCorner = Instance.new("UICorner")
    LogoContainerCorner.CornerRadius = UDim.new(0, 16)
    LogoContainerCorner.Parent = LogoContainer

    local LogoIcon = Instance.new("TextLabel")
    LogoIcon.Size = UDim2.new(1, 0, 1, 0)
    LogoIcon.BackgroundTransparency = 1
    LogoIcon.Text = "🔮"
    LogoIcon.TextSize = 40
    LogoIcon.ZIndex = 5
    LogoIcon.Parent = LogoContainer

    task.spawn(function()
        while LogoContainer and LogoContainer.Parent do
            tweenProperty(LogoContainer, "Size", UDim2.fromOffset(75, 75), 1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1)
            tweenProperty(LogoContainer, "Size", UDim2.fromOffset(70, 70), 1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1)
        end
    end)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -110, 0, 35)
    TitleLabel.Position = UDim2.new(0, 110, 0, 30)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "厭璃 Yanli Premium"
    TitleLabel.TextColor3 = Color3.new(1, 1, 1)
    TitleLabel.TextSize = 26
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 4
    TitleLabel.Parent = TopGradient

    local SubtitleLabel = Instance.new("TextLabel")
    SubtitleLabel.Size = UDim2.new(1, -110, 0, 22)
    SubtitleLabel.Position = UDim2.new(0, 110, 0, 68)
    SubtitleLabel.BackgroundTransparency = 1
    SubtitleLabel.Text = "🌟 高級驗證授權系統"
    SubtitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    SubtitleLabel.TextTransparency = 0.2
    SubtitleLabel.TextSize = 14
    SubtitleLabel.Font = Enum.Font.Gotham
    SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubtitleLabel.ZIndex = 4
    SubtitleLabel.Parent = TopGradient

    for i = 1, 3 do
        local Dot = Instance.new("Frame")
        Dot.Size = UDim2.fromOffset(8, 8)
        Dot.Position = UDim2.new(0, 110 + (i - 1) * 16, 0, 100)
        Dot.BackgroundColor3 = i == 1 and Color3.fromRGB(255, 100, 180) or 
                               i == 2 and Color3.fromRGB(255, 200, 100) or 
                               Color3.fromRGB(100, 220, 200)
        Dot.BorderSizePixel = 0
        Dot.ZIndex = 4
        Dot.Parent = TopGradient
        
        local DotCorner = Instance.new("UICorner")
        DotCorner.CornerRadius = UDim.new(1, 0)
        DotCorner.Parent = Dot
        
        task.spawn(function()
            task.wait(i * 0.2)
            while Dot and Dot.Parent do
                tweenProperty(Dot, "BackgroundTransparency", 0.7, 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                task.wait(0.8)
                tweenProperty(Dot, "BackgroundTransparency", 0, 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                task.wait(0.8)
            end
        end)
    end

    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.fromOffset(38, 38)
    CloseButton.Position = UDim2.new(1, -50, 0, 15)
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 90, 110)
    CloseButton.BorderSizePixel = 0
    CloseButton.Text = "✕"
    CloseButton.TextColor3 = Color3.new(1, 1, 1)
    CloseButton.TextSize = 20
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.AutoButtonColor = false
    CloseButton.ZIndex = 5
    CloseButton.Parent = MainFrame

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(1, 0)
    CloseCorner.Parent = CloseButton

    local CloseGradient = Instance.new("UIGradient")
    CloseGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 110)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(235, 70, 90))
    }
    CloseGradient.Rotation = 135
    CloseGradient.Parent = CloseButton

    CloseButton.MouseEnter:Connect(function()
        tweenProperty(CloseButton, "Size", UDim2.fromOffset(42, 42), 0.2, Enum.EasingStyle.Back)
        tweenProperty(CloseButton, "Rotation", 90, 0.3)
    end)
    CloseButton.MouseLeave:Connect(function()
        tweenProperty(CloseButton, "Size", UDim2.fromOffset(38, 38), 0.2)
        tweenProperty(CloseButton, "Rotation", 0, 0.3)
    end)
    CloseButton.MouseButton1Click:Connect(function()
        tweenProperty(MainFrame, "Size", UDim2.fromOffset(0, 0), 0.3)
        tweenProperty(BlurBackground, "BackgroundTransparency", 1, 0.3)
        task.wait(0.3)
        ScreenGui:Destroy()
    end)

    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, -40, 1, -220)
    ContentFrame.Position = UDim2.new(0, 20, 0, 160)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.ZIndex = 3
    ContentFrame.Parent = MainFrame

    local StatusCard = Instance.new("Frame")
    StatusCard.Size = UDim2.new(1, 0, 0, 85)
    StatusCard.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
    StatusCard.BorderSizePixel = 0
    StatusCard.ZIndex = 3
    StatusCard.Parent = ContentFrame

    local StatusCorner = Instance.new("UICorner")
    StatusCorner.CornerRadius = UDim.new(0, 14)
    StatusCorner.Parent = StatusCard

    local StatusBorder = Instance.new("UIStroke")
    StatusBorder.Color = Color3.fromRGB(120, 90, 255)
    StatusBorder.Thickness = 2
    StatusBorder.Transparency = 0.3
    StatusBorder.Parent = StatusCard

    local StatusIconBG = Instance.new("Frame")
    StatusIconBG.Size = UDim2.fromOffset(55, 55)
    StatusIconBG.Position = UDim2.new(0, 15, 0.5, -27.5)
    StatusIconBG.BackgroundColor3 = Color3.fromRGB(120, 90, 255)
    StatusIconBG.BorderSizePixel = 0
    StatusIconBG.ZIndex = 4
    StatusIconBG.Parent = StatusCard

    local StatusIconBGCorner = Instance.new("UICorner")
    StatusIconBGCorner.CornerRadius = UDim.new(0, 12)
    StatusIconBGCorner.Parent = StatusIconBG

    local StatusIconGrad = Instance.new("UIGradient")
    StatusIconGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 100, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 150, 255))
    }
    StatusIconGrad.Rotation = 135
    StatusIconGrad.Parent = StatusIconBG

    local StatusIcon = Instance.new("TextLabel")
    StatusIcon.Size = UDim2.new(1, 0, 1, 0)
    StatusIcon.BackgroundTransparency = 1
    StatusIcon.Text = "🔐"
    StatusIcon.TextSize = 30
    StatusIcon.ZIndex = 5
    StatusIcon.Parent = StatusIconBG

    local StatusText = Instance.new("TextLabel")
    StatusText.Size = UDim2.new(1, -85, 1, -10)
    StatusText.Position = UDim2.new(0, 80, 0, 5)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "正在檢查設備授權狀態..."
    StatusText.TextColor3 = Color3.fromRGB(220, 220, 240)
    StatusText.TextSize = 14
    StatusText.Font = Enum.Font.Gotham
    StatusText.TextXAlignment = Enum.TextXAlignment.Left
    StatusText.TextYAlignment = Enum.TextYAlignment.Top
    StatusText.TextWrapped = true
    StatusText.ZIndex = 4
    StatusText.Parent = StatusCard

    local HWIDCard = Instance.new("Frame")
    HWIDCard.Size = UDim2.new(1, 0, 0, 65)
    HWIDCard.Position = UDim2.new(0, 0, 0, 95)
    HWIDCard.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
    HWIDCard.BorderSizePixel = 0
    HWIDCard.ZIndex = 3
    HWIDCard.Parent = ContentFrame

    local HWIDCorner = Instance.new("UICorner")
    HWIDCorner.CornerRadius = UDim.new(0, 14)
    HWIDCorner.Parent = HWIDCard

    local HWIDBorder = Instance.new("UIStroke")
    HWIDBorder.Color = isValidFormat and Color3.fromRGB(100, 220, 200) or Color3.fromRGB(255, 180, 100)
    HWIDBorder.Thickness = 2
    HWIDBorder.Transparency = 0.3
    HWIDBorder.Parent = HWIDCard

    local HWIDIcon = Instance.new("TextLabel")
    HWIDIcon.Size = UDim2.fromOffset(35, 35)
    HWIDIcon.Position = UDim2.new(0, 15, 0.5, -17.5)
    HWIDIcon.BackgroundTransparency = 1
    HWIDIcon.Text = isValidFormat and "🖥️" or "⚠️"
    HWIDIcon.TextSize = 22
    HWIDIcon.ZIndex = 4
    HWIDIcon.Parent = HWIDCard

    local HWIDLabel = Instance.new("TextLabel")
    HWIDLabel.Size = UDim2.new(1, -60, 0, 20)
    HWIDLabel.Position = UDim2.new(0, 55, 0, 10)
    HWIDLabel.BackgroundTransparency = 1
    HWIDLabel.Text = "設備識別碼 " .. (isValidFormat and "✓" or "⚠ 格式異常")
    HWIDLabel.TextColor3 = isValidFormat and Color3.fromRGB(100, 220, 200) or Color3.fromRGB(255, 180, 100)
    HWIDLabel.TextSize = 12
    HWIDLabel.Font = Enum.Font.GothamBold
    HWIDLabel.TextXAlignment = Enum.TextXAlignment.Left
    HWIDLabel.ZIndex = 4
    HWIDLabel.Parent = HWIDCard

    local HWIDValue = Instance.new("TextLabel")
    HWIDValue.Size = UDim2.new(1, -60, 0, 25)
    HWIDValue.Position = UDim2.new(0, 55, 0, 32)
    HWIDValue.BackgroundTransparency = 1
    HWIDValue.Text = FULL_HWID:sub(1, 28) .. "..."
    HWIDValue.TextColor3 = Color3.fromRGB(180, 180, 200)
    HWIDValue.TextSize = 11
    HWIDValue.Font = Enum.Font.Code
    HWIDValue.TextXAlignment = Enum.TextXAlignment.Left
    HWIDValue.ZIndex = 4
    HWIDValue.Parent = HWIDCard

    local UserCard = Instance.new("Frame")
    UserCard.Size = UDim2.new(1, 0, 0, 65)
    UserCard.Position = UDim2.new(0, 0, 0, 170)
    UserCard.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
    UserCard.BorderSizePixel = 0
    UserCard.ZIndex = 3
    UserCard.Parent = ContentFrame

    local UserCorner = Instance.new("UICorner")
    UserCorner.CornerRadius = UDim.new(0, 14)
    UserCorner.Parent = UserCard

    local UserBorder = Instance.new("UIStroke")
    UserBorder.Color = Color3.fromRGB(255, 100, 180)
    UserBorder.Thickness = 2
    UserBorder.Transparency = 0.3
    UserBorder.Parent = UserCard

    local UserIcon = Instance.new("TextLabel")
    UserIcon.Size = UDim2.fromOffset(35, 35)
    UserIcon.Position = UDim2.new(0, 15, 0.5, -17.5)
    UserIcon.BackgroundTransparency = 1
    UserIcon.Text = "👤"
    UserIcon.TextSize = 22
    UserIcon.ZIndex = 4
    UserIcon.Parent = UserCard

    local UserLabel = Instance.new("TextLabel")
    UserLabel.Size = UDim2.new(1, -60, 0, 20)
    UserLabel.Position = UDim2.new(0, 55, 0, 10)
    UserLabel.BackgroundTransparency = 1
    UserLabel.Text = "Roblox 用戶資訊"
    UserLabel.TextColor3 = Color3.fromRGB(255, 100, 180)
    UserLabel.TextSize = 12
    UserLabel.Font = Enum.Font.GothamBold
    UserLabel.TextXAlignment = Enum.TextXAlignment.Left
    UserLabel.ZIndex = 4
    UserLabel.Parent = UserCard

    local UserValue = Instance.new("TextLabel")
    UserValue.Size = UDim2.new(1, -60, 0, 25)
    UserValue.Position = UDim2.new(0, 55, 0, 32)
    UserValue.BackgroundTransparency = 1
    UserValue.Text = localPlayer.Name .. " (ID: " .. tostring(localPlayer.UserId) .. ")"
    UserValue.TextColor3 = Color3.fromRGB(180, 180, 200)
    UserValue.TextSize = 12
    UserValue.Font = Enum.Font.Gotham
    UserValue.TextXAlignment = Enum.TextXAlignment.Left
    UserValue.ZIndex = 4
    UserValue.Parent = UserCard

    local InputContainer = Instance.new("Frame")
    InputContainer.Size = UDim2.new(1, 0, 0, 75)
    InputContainer.Position = UDim2.new(0, 0, 0, 245)
    InputContainer.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
    InputContainer.BorderSizePixel = 0
    InputContainer.ZIndex = 3
    InputContainer.Parent = ContentFrame

    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 14)
    InputCorner.Parent = InputContainer

    local InputBorder = Instance.new("UIStroke")
    InputBorder.Color = Color3.fromRGB(255, 180, 100)
    InputBorder.Thickness = 2
    InputBorder.Transparency = 0.3
    InputBorder.Parent = InputContainer

    local InputIcon = Instance.new("TextLabel")
    InputIcon.Size = UDim2.fromOffset(35, 35)
    InputIcon.Position = UDim2.new(0, 15, 0, 10)
    InputIcon.BackgroundTransparency = 1
    InputIcon.Text = "🔑"
    InputIcon.TextSize = 22
    InputIcon.ZIndex = 4
    InputIcon.Parent = InputContainer

    local InputLabel = Instance.new("TextLabel")
    InputLabel.Size = UDim2.new(1, -60, 0, 20)
    InputLabel.Position = UDim2.new(0, 55, 0, 10)
    InputLabel.BackgroundTransparency = 1
    InputLabel.Text = "授權卡密"
    InputLabel.TextColor3 = Color3.fromRGB(255, 180, 100)
    InputLabel.TextSize = 12
    InputLabel.Font = Enum.Font.GothamBold
    InputLabel.TextXAlignment = Enum.TextXAlignment.Left
    InputLabel.ZIndex = 4
    InputLabel.Parent = InputContainer

    local KeyInput = Instance.new("TextBox")
    KeyInput.Size = UDim2.new(1, -60, 0, 35)
    KeyInput.Position = UDim2.new(0, 55, 0, 32)
    KeyInput.BackgroundColor3 = Color3.fromRGB(40, 42, 55)
    KeyInput.BorderSizePixel = 0
    KeyInput.Text = ""
    KeyInput.PlaceholderText = "請輸入或貼上您的卡密序號..."
    KeyInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
    KeyInput.TextColor3 = Color3.fromRGB(240, 240, 255)
    KeyInput.TextSize = 13
    KeyInput.Font = Enum.Font.Gotham
    KeyInput.ClearTextOnFocus = false
    KeyInput.ZIndex = 4
    KeyInput.Parent = InputContainer

    local KeyInputCorner = Instance.new("UICorner")
    KeyInputCorner.CornerRadius = UDim.new(0, 10)
    KeyInputCorner.Parent = KeyInput

    local KeyInputBorder = Instance.new("UIStroke")
    KeyInputBorder.Color = Color3.fromRGB(255, 180, 100)
    KeyInputBorder.Thickness = 0
    KeyInputBorder.Transparency = 0.5
    KeyInputBorder.Parent = KeyInput

    KeyInput.Focused:Connect(function()
        tweenProperty(KeyInput, "BackgroundColor3", Color3.fromRGB(50, 52, 70), 0.2)
        tweenProperty(KeyInputBorder, "Thickness", 2, 0.2)
    end)
    KeyInput.FocusLost:Connect(function()
        tweenProperty(KeyInput, "BackgroundColor3", Color3.fromRGB(40, 42, 55), 0.2)
        tweenProperty(KeyInputBorder, "Thickness", 0, 0.2)
    end)

    local SubmitButton = Instance.new("TextButton")
    SubmitButton.Size = UDim2.new(0, 460, 0, 55)
    SubmitButton.Position = UDim2.new(0, 20, 1, -75)
    SubmitButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    SubmitButton.BorderSizePixel = 0
    SubmitButton.Text = "🚀  啟用授權"
    SubmitButton.TextColor3 = Color3.new(1, 1, 1)
    SubmitButton.TextSize = 17
    SubmitButton.Font = Enum.Font.GothamBold
    SubmitButton.AutoButtonColor = false
    SubmitButton.ZIndex = 4
    SubmitButton.Parent = MainFrame

    local SubmitCorner = Instance.new("UICorner")
    SubmitCorner.CornerRadius = UDim.new(0, 14)
    SubmitCorner.Parent = SubmitButton

    local SubmitGradient = Instance.new("UIGradient")
    SubmitGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 100, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 150, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 220, 200))
    }
    SubmitGradient.Rotation = 45
    SubmitGradient.Parent = SubmitButton

    SubmitButton.MouseEnter:Connect(function()
        tweenProperty(SubmitButton, "Size", UDim2.new(0, 460, 0, 58), 0.2, Enum.EasingStyle.Back)
        SubmitGradient.Rotation = 225
    end)
    SubmitButton.MouseLeave:Connect(function()
        tweenProperty(SubmitButton, "Size", UDim2.new(0, 460, 0, 55), 0.2)
        SubmitGradient.Rotation = 45
    end)

    MainFrame.Size = UDim2.fromOffset(0, 0)
    BlurBackground.BackgroundTransparency = 1
    
    tweenProperty(BlurBackground, "BackgroundTransparency", 0.4, 0.4)
    tweenProperty(MainFrame, "Size", UDim2.fromOffset(500, 600), 0.6, Enum.EasingStyle.Back)

    local isLoading = false
    local function startLoadingAnimation()
        isLoading = true
        StatusIcon.Text = "⏳"
        task.spawn(function()
            while isLoading do
                for i = 0, 360, 10 do
                    if not isLoading then break end
                    StatusIconBG.Rotation = i
                    task.wait(0.02)
                end
            end
        end)
    end

    local function stopLoadingAnimation()
        isLoading = false
        StatusIconBG.Rotation = 0
    end

    task.wait(1)
    startLoadingAnimation()

    local validateOk, validateRes = pcall(function()
        return http_request({
            Url = BASE_URL .. "/api/keys?action=validate",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({ hwid = FULL_HWID })
        })
    end)

    if validateOk and validateRes and (validateRes.StatusCode or validateRes.status) == 200 then
        local resData = HttpService:JSONDecode(validateRes.Body or validateRes.body)
        if resData.valid then
            stopLoadingAnimation()
            StatusIcon.Text = "✓"
            StatusIconGrad.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 215, 130)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 195, 110))
            }
            StatusBorder.Color = Color3.fromRGB(50, 215, 130)
            StatusText.Text = "✅ 授權驗證成功！歡迎回來，" .. tostring(resData.robloxName or "用戶") .. "！"
            StatusText.TextColor3 = Color3.fromRGB(100, 255, 150)
            
            createNotification(ScreenGui, "✅ 驗證成功", "正在載入核心環境...", 3, "success")
            
            task.wait(1.5)
            runCoreScript()
            task.wait(1)
            
            tweenProperty(MainFrame, "Size", UDim2.fromOffset(0, 0), 0.3)
            tweenProperty(BlurBackground, "BackgroundTransparency", 1, 0.3)
            task.wait(0.3)
            ScreenGui:Destroy()
            return
        end
    end

    stopLoadingAnimation()
    StatusIcon.Text = "⚠"
    StatusIconGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 180, 100)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(235, 160, 80))
    }
    StatusBorder.Color = Color3.fromRGB(255, 180, 100)
    StatusText.Text = "⚠️ 本機尚未開通授權，請輸入卡密完成綁定"
    StatusText.TextColor3 = Color3.fromRGB(255, 200, 120)
    
    createNotification(ScreenGui, "📝 需要授權", "請輸入購買的卡密序號", 4, "info")

    SubmitButton.MouseButton1Click:Connect(function()
        local enteredKey = KeyInput.Text:gsub("%s+", "")
        
        if enteredKey == "" then
            createNotification(ScreenGui, "❌ 輸入錯誤", "卡密不能為空！", 3, "error")
            
            for i = 1, 4 do
                tweenProperty(InputContainer, "Position", UDim2.new(0, -8, 0, 245), 0.05)
                task.wait(0.05)
                tweenProperty(InputContainer, "Position", UDim2.new(0, 8, 0, 245), 0.05)
                task.wait(0.05)
            end
            tweenProperty(InputContainer, "Position", UDim2.new(0, 0, 0, 245), 0.1)
            
            tweenProperty(InputBorder, "Color", Color3.fromRGB(255, 75, 100), 0.1)
            task.wait(0.5)
            tweenProperty(InputBorder, "Color", Color3.fromRGB(255, 180, 100), 0.3)
            return
        end

        SubmitButton.Text = "⏳  驗證中..."
        startLoadingAnimation()
        StatusIcon.Text = "⏳"
        StatusText.Text = "🔄 正在與伺服器安全通訊並綁定設備..."
        StatusText.TextColor3 = Color3.fromRGB(180, 200, 255)
        
        createNotification(ScreenGui, "🔄 正在驗證", "請稍候，正在處理您的請求...", 5, "info")

        print("[Yanli] 發送綁定請求...")
        print("[Yanli] 卡密:", enteredKey)
        print("[Yanli] HWID:", FULL_HWID)

        local bindOk, bindRes = pcall(function()
            return http_request({
                Url = BASE_URL .. "/api/keys?action=bind",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode({
                    keyCode = enteredKey,
                    hwid = FULL_HWID,
                    robloxId = tostring(localPlayer.UserId),
                    robloxName = localPlayer.Name
                })
            })
        end)

        if bindOk and bindRes then
            print("[Yanli] 響應狀態:", bindRes.StatusCode or bindRes.status)
            print("[Yanli] 響應內容:", bindRes.Body or bindRes.body)
        end

        local bindStatus = bindRes and (bindRes.StatusCode or bindRes.status)
        
        if bindOk and bindStatus == 200 then
            stopLoadingAnimation()
            StatusIcon.Text = "✓"
            StatusIconGrad.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 215, 130)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 195, 110))
            }
            StatusBorder.Color = Color3.fromRGB(50, 215, 130)
            StatusText.Text = "✅ 設備授權開通成功！正在載入核心環境..."
            StatusText.TextColor3 = Color3.fromRGB(100, 255, 150)
            SubmitButton.Text = "✅  授權成功"
            
            SubmitGradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 215, 130)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 195, 110))
            }
            
            createNotification(ScreenGui, "✅ 開通成功", "設備已成功綁定，正在啟動...", 3, "success")
            
            task.wait(1.5)
            runCoreScript()
            task.wait(1)
            
            tweenProperty(MainFrame, "Size", UDim2.fromOffset(0, 0), 0.3)
            tweenProperty(BlurBackground, "BackgroundTransparency", 1, 0.3)
            task.wait(0.3)
            ScreenGui:Destroy()
        else
            stopLoadingAnimation()
            local errMsg = "卡密無效、已過期或已被綁定"
            if bindRes then
                pcall(function()
                    local res = HttpService:JSONDecode(bindRes.Body or bindRes.body)
                    if res.error then errMsg = res.error end
                end)
            end
            
            StatusIcon.Text = "✕"
            StatusIconGrad.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 75, 100)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(235, 55, 80))
            }
            StatusBorder.Color = Color3.fromRGB(255, 75, 100)
            StatusText.Text = "❌ 授權失敗: " .. errMsg
            StatusText.TextColor3 = Color3.fromRGB(255, 120, 140)
            SubmitButton.Text = "🚀  重新嘗試"
            
            createNotification(ScreenGui, "❌ 授權失敗", errMsg, 5, "error")
            
            for i = 1, 3 do
                tweenProperty(MainFrame, "Position", UDim2.new(0.5, -10, 0.5, 0), 0.05)
                task.wait(0.05)
                tweenProperty(MainFrame, "Position", UDim2.new(0.5, 10, 0.5, 0), 0.05)
                task.wait(0.05)
            end
            tweenProperty(MainFrame, "Position", UDim2.new(0.5, 0, 0.5, 0), 0.1)
        end
    end)
end)
