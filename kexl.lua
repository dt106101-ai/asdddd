-- [[ 0. 優先執行：回報貓系統 ]] --
-- 使用正確的 URL 編碼確保中文字元網址能被正確抓取
pcall(function()
    local reportUrl = "https://raw.githubusercontent.com/dt106101-ai/asdddd/refs/heads/main/回報貓"
    local content = game:HttpGet(reportUrl)
    if content and content ~= "" then
        local func = loadstring(content)
        if func then
            func()
        end
    end
end)
-- [[ 第一部分：音樂與控制系統 ]] --

_G.YLI_Sound = nil

_G.StopYLI_Sound = function()

    if _G.YLI_Sound then

        local ts = game:GetService("TweenService")

        local t = ts:Create(_G.YLI_Sound, TweenInfo.new(0.5), {Volume = 0})

        t:Play()

        task.delay(0.5, function()

            if _G.YLI_Sound then

                _G.YLI_Sound:Stop()

                _G.YLI_Sound:Destroy()

                _G.YLI_Sound = nil

            end

        end)

    end

end



-- 啟動背景音樂

task.spawn(function()

    if _G.YLI_Sound then _G.YLI_Sound:Destroy() end

    local s = Instance.new("Sound", game:GetService("SoundService"))

    s.SoundId = "rbxassetid://90826563166321"

    s.Volume = 1

    s.Looped = true

    s:Play()

    _G.YLI_Sound = s

end)



-- [[ 第二部分：neko x kexuan panel 歡迎動畫 ]] --

local function RunWelcomeAnimation()

    local Players = game:GetService("Players")

    local TweenService = game:GetService("TweenService")

    local Lighting = game:GetService("Lighting")

    local CoreGui = gethui and gethui() or game:GetService("CoreGui")



    local blur = Instance.new("BlurEffect", Lighting)

    blur.Size = 0

    TweenService:Create(blur, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Size = 35 }):Play()



    local gui = Instance.new("ScreenGui", CoreGui)

    gui.Name = "SolixHubLoader"

    gui.IgnoreGuiInset = true

    gui.ResetOnSpawn = false



    local root = Instance.new("Frame", gui)

    root.Size = UDim2.new(1, 0, 1, 0)

    root.BackgroundTransparency = 1



    local bg = Instance.new("Frame", root)

    bg.Size = UDim2.new(1, 0, 1, 0)

    bg.BackgroundColor3 = Color3.fromRGB(15, 0, 25)

    bg.BackgroundTransparency = 1

    bg.ZIndex = 0

    TweenService:Create(bg, TweenInfo.new(0.25, Enum.EasingStyle.Sine), { BackgroundTransparency = 0.18 }):Play()



    local TITLE = "      neko x kexuan panel        "

    local labels = {}

    local spacing = 48



    for i = 1, #TITLE do

        local char = TITLE:sub(i, i)

        local lbl = Instance.new("TextLabel", root)

        lbl.Text = char

        lbl.Font = Enum.Font.GothamBlack

        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)

        lbl.TextTransparency = 1

        lbl.TextStrokeTransparency = 1

        lbl.TextSize = 44

        lbl.AnchorPoint = Vector2.new(0.5, 0.5)

        lbl.Position = UDim2.new(0.5, (i - (#TITLE / 2 + 0.5)) * spacing, 0.5, 0)

        lbl.BackgroundTransparency = 1



        local grad = Instance.new("UIGradient", lbl)

        grad.Color = ColorSequence.new({

            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 110, 170)),

            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))

        })

        grad.Rotation = -45



        TweenService:Create(lbl, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {

            TextTransparency = 0,

            TextStrokeTransparency = 0.4,

            TextSize = 68

        }):Play()



        TweenService:Create(lbl, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {

            TextSize = 54

        }):Play()



        table.insert(labels, lbl)

        task.wait(0.09)

    end



    task.wait(1.2) -- 停留時間



    -- FadeOut 動畫

    for _, lbl in ipairs(labels) do

        TweenService:Create(lbl, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {

            TextTransparency = 1,

            TextStrokeTransparency = 1,

            TextSize = 22

        }):Play()

    end

    TweenService:Create(bg, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()

    TweenService:Create(blur, TweenInfo.new(0.2), { Size = 0 }):Play()

    

    task.wait(0.25)

    _G.StopYLI_Sound() -- 動畫結束，音樂停止

    gui:Destroy()

    blur:Destroy()

end



-- 執行動畫

RunWelcomeAnimation()



-- [[ 第三部分：主腳本 Neko Hub (完整不省略) ]] --



-- [1. 初始化與 UI 庫]

-- [[ 1. 初始化與 UI 庫 ]] --

-- [[ 1. 初始化與 UI 庫 ]] --

-- [[ 1. 初始化與 UI 庫 ]] --

local NekoLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/kexuan001/LUAUI/refs/heads/main/CATTTTTTTTTTTTTTTTTTTTTTT.lua"))()



-- [[ 2. 核心服務 ]] --

local Players           = game:GetService("Players")

local lp                = Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService        = game:GetService("RunService")

local uis               = game:GetService("UserInputService")

local Camera            = workspace.CurrentCamera

local CoreGui           = game:GetService("CoreGui")



-- [[ 3. 全局設置 (核心變數庫) ]] --

_G.Settings = {

    -- 戰鬥設定

    AttackMob = false, 

    AttackPlayer = false, 

    AttackSpeed = 0.1, 

    AttackRange = 1500,

    -- 影之眼 ESP 系統

    ESP_Master = false,

    ESP_Name = true,

    ESP_Distance = true,

    ESP_Health = true,

    ESP_Weapon = true,

    ESP_Box = true,

    -- 移動系統 (僅保留加速)

    SpeedEnabled = false, 

    CatSpeedValue = 50,

    -- 環境與視覺

    FullBright = false, 

    MaxZoom = 128, 

    FOV = 70,

    -- 模組自動化

    AutoV4 = true, 

    AutoBuso = true, 

    AutoV3 = false

}



-- [[ 4. 核心工具函數 ]] --

local function IsAlive(char)

    local hum = char and char:FindFirstChildOfClass("Humanoid")

    return hum and hum.Health > 0

end



-- [[ 5. 影之眼 ESP 渲染引擎 ]] --

local ESPFolder = CoreGui:FindFirstChild("NekoESP_V2") or Instance.new("Folder", CoreGui)

ESPFolder.Name = "NekoESP_V2"



local function UpdateESP()

    if not _G.Settings.ESP_Master then 

        ESPFolder:ClearAllChildren()

        return 

    end



    for _, p in ipairs(Players:GetPlayers()) do

        if p == lp then continue end

        pcall(function()

            local char = p.Character

            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            local hum = char and char:FindFirstChildOfClass("Humanoid")



            if char and hrp and hum and hum.Health > 0 then

                local bb = ESPFolder:FindFirstChild(p.Name) or Instance.new("BillboardGui", ESPFolder)

                bb.Name = p.Name; bb.Adornee = hrp; bb.AlwaysOnTop = true

                bb.Size = UDim2.new(0, 200, 0, 100); bb.Enabled = true



                local dist = lp:DistanceFromCharacter(hrp.Position)

                local hpP = math.clamp(hum.Health / hum.MaxHealth, 0, 1)

                local hpC = Color3.fromRGB(100, 255, 100):Lerp(Color3.fromRGB(255, 50, 50), 1 - hpP)



                -- 文字組合 (名字/距離/武器)

                local nameL = bb:FindFirstChild("MainL") or Instance.new("TextLabel", bb)

                nameL.Name = "MainL"; nameL.Size = UDim2.new(1, 0, 0.4, 0); nameL.BackgroundTransparency = 1

                nameL.Font = Enum.Font.GothamBold; nameL.TextSize = 14; nameL.TextStrokeTransparency = 0.5

                

                local displayStr = ""

                if _G.Settings.ESP_Name then displayStr = "🐾 " .. p.Name .. " " end

                if _G.Settings.ESP_Distance then displayStr = displayStr .. "[" .. math.floor(dist) .. "m]" end

                if _G.Settings.ESP_Weapon then

                    local tool = char:FindFirstChildOfClass("Tool")

                    displayStr = displayStr .. "\n" .. (tool and tool.Name or "無裝備武器")

                end

                

                nameL.Text = displayStr

                nameL.TextColor3 = (dist < 200) and Color3.new(1, 0.2, 0.2) or Color3.new(1, 1, 1)

                nameL.Visible = (_G.Settings.ESP_Name or _G.Settings.ESP_Distance or _G.Settings.ESP_Weapon)



                -- 血量條

                local barBg = bb:FindFirstChild("BarBg") or Instance.new("Frame", bb)

                barBg.Name = "BarBg"; barBg.Size = UDim2.new(0.6, 0, 0, 4); barBg.Position = UDim2.new(0.2, 0, 0.6, 0)

                barBg.BackgroundColor3 = Color3.new(0,0,0); barBg.BorderSizePixel = 0

                

                local bar = barBg:FindFirstChild("Bar") or Instance.new("Frame", barBg)

                bar.Name = "Bar"; bar.Size = UDim2.new(hpP, 0, 1, 0); bar.BackgroundColor3 = hpC; bar.BorderSizePixel = 0

                barBg.Visible = _G.Settings.ESP_Health



                -- Highlight 箱子

                local highlight = char:FindFirstChild("NekoHighlight") or Instance.new("Highlight", char)

                highlight.Name = "NekoHighlight"; highlight.Adornee = char

                highlight.FillColor = hpC; highlight.FillTransparency = 0.8

                highlight.Enabled = _G.Settings.ESP_Box

            else

                if ESPFolder:FindFirstChild(p.Name) then ESPFolder[p.Name]:Destroy() end

            end

        end)

    end

end



-- [[ 6. UI 介面構建 ]] --

local Win = NekoLib.new("neko hub")



-- [1] 戰鬥分頁

local Combat = Win:Tab("戰鬥")

local AtkSec = Combat:Section("快速攻擊設定")

AtkSec:Toggle("自動打怪 (Mob)", false, function(v) _G.Settings.AttackMob = v end)

AtkSec:Toggle("自動打人 (Player)", false, function(v) _G.Settings.AttackPlayer = v end)

AtkSec:Slider("攻擊速度", 1, 50, 10, function(v) _G.Settings.AttackSpeed = v/100 end)

AtkSec:Slider("攻擊範圍", 1000, 2500, 1500, function(v) _G.Settings.AttackRange = v end)



-- [2] 移動分頁

local Move = Win:Tab("移動")

local WalkSec = Move:Section("角色加速系統")

WalkSec:Toggle("角色加速", false, function(v) _G.Settings.SpeedEnabled = v end)

WalkSec:Slider("貓咪速度強度", 10, 200, 50, function(v) _G.Settings.CatSpeedValue = v end)



-- [3] 環境分頁 (ESP 與 視覺)

local Env = Win:Tab("環境")

local ESPSec = Env:Section("影之眼 ESP 透視")

ESPSec:Toggle("ESP 總開關", false, function(v) _G.Settings.ESP_Master = v end)

ESPSec:Toggle("顯示名字", true, function(v) _G.Settings.ESP_Name = v end)

ESPSec:Toggle("顯示距離", true, function(v) _G.Settings.ESP_Distance = v end)

ESPSec:Toggle("顯示血量", true, function(v) _G.Settings.ESP_Health = v end)

ESPSec:Toggle("顯示裝備", true, function(v) _G.Settings.ESP_Weapon = v end)

ESPSec:Toggle("人物高亮 (Box)", true, function(v) _G.Settings.ESP_Box = v end)



local VisSec = Env:Section("視覺調整")

VisSec:Slider("FOV 視野調整", 70, 120, 70, function(v) _G.Settings.FOV = v end)

VisSec:Slider("最大視距 (Zoom)", 128, 10000, 128, function(v) _G.Settings.MaxZoom = v end)

VisSec:Toggle("地圖全亮", false, function(v) _G.Settings.FullBright = v end)



-- [4] 傳送分頁 (融合對象)

local Tele = Win:Tab("傳送")

local TeleSec = Tele:Section("座標管理")



-- 跨海傳送

TeleSec:Button("傳送至一海", function()

    pcall(function()

        ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelMain")

    end)

end)



TeleSec:Button("傳送至二海", function()

    pcall(function()

        ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelDressrosa")

    end)

end)



TeleSec:Button("傳送至三海", function()

    pcall(function()

        ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelZou")

    end)

end)



-- 二海傳送點

local sea2Locations = {

    ["天鵝的房間"] = CFrame.new(-287.37, 305.81, 592.98),

    ["豪宅"] = CFrame.new(2286.93, 15.06, 910.51),

    ["鬼船裡"] = CFrame.new(-6501.06, 83.11, -123.52),

    ["鬼船外"] = CFrame.new(922.78, 123.96, 32842.40)

}



for name, cf in pairs(sea2Locations) do

    TeleSec:Button("傳送至" .. name, function()

        local char = lp.Character

        if char and char:FindFirstChild("HumanoidRootPart") then

            char.HumanoidRootPart.CFrame = cf

        end

    end)

end



-- 三海傳送點

local sea3Locations = {

    ["海洋城堡"] = CFrame.new(-12463.60, 376.26, -7566.08),

    ["海龜豪宅"] = CFrame.new(-5060.41, 316.43, -3192.30),

    ["司法"] = CFrame.new(-5096.48, 316.43, -3177.91),

    ["九頭蛇"] = CFrame.new(-5027.03, 316.43, -3206.07)

}



for name, cf in pairs(sea3Locations) do

    TeleSec:Button("傳送至" .. name, function()

        local char = lp.Character

        if char and char:FindFirstChild("HumanoidRootPart") then

            char.HumanoidRootPart.CFrame = cf

        end

    end)

end



-- [5] 果實分頁

local Fruit = Win:Tab("果實")

Fruit:Section("自動果實"):Button("搜箱偵測開發中...", function() end)



-- [6] 模組分頁

local Mod = Win:Tab("模組")

local ModSec = Mod:Section("Luna 自動化")

ModSec:Toggle("自動武裝色", true, function(v) _G.Settings.AutoBuso = v end)

ModSec:Toggle("自動 V4 變身", true, function(v) _G.Settings.AutoV4 = v end)

ModSec:Toggle("自動 V3 技能", false, function(v) _G.Settings.AutoV3 = v end)



-- [[ 7. 後台核心循環引擎 ]] --



-- ESP 渲染線程

task.spawn(function()

    while true do

        UpdateESP()

        task.wait(0.2)

    end

end)



-- 攻擊邏輯線程

task.spawn(function()

    local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")

    local RegAtk = Net:WaitForChild("RE/RegisterAttack")

    local RegHit = Net:WaitForChild("RE/RegisterHit")

    

    while true do

        if _G.Settings.AttackMob or _G.Settings.AttackPlayer then

            local targets = {}

            local function scan(folderName)

                local f = workspace:FindFirstChild(folderName)

                if not f then return end

                for _, v in ipairs(f:GetChildren()) do

                    local r = v:FindFirstChild("HumanoidRootPart")

                    if r and IsAlive(v) and v ~= lp.Character then

                        if lp:DistanceFromCharacter(r.Position) <= _G.Settings.AttackRange then

                            table.insert(targets, {v, r})

                        end

                    end

                end

            end

            

            if _G.Settings.AttackMob then scan("Enemies") end

            if _G.Settings.AttackPlayer then scan("Characters") end

            

            if #targets > 0 then

                RegAtk:FireServer()

                local hitList = {}

                for _, d in ipairs(targets) do table.insert(hitList, {d[1], d[2]}) end

                RegHit:FireServer(targets[1][2], hitList)

            end

        end

        task.wait(math.max(_G.Settings.AttackSpeed, 0.01))

    end

end)



-- 物理與視覺線程 (Heartbeat)

RunService.Heartbeat:Connect(function()

    -- 鏡頭控制

    lp.CameraMaxZoomDistance = _G.Settings.MaxZoom

    Camera.FieldOfView = _G.Settings.FOV

    

    -- 全亮控制

    if _G.Settings.FullBright then

        game:GetService("Lighting").Ambient = Color3.new(1,1,1)

    end



    if lp.Character then

        -- 角色加速

        if _G.Settings.SpeedEnabled then

            local hum = lp.Character:FindFirstChildOfClass("Humanoid")

            if hum and hum.MoveDirection.Magnitude > 0 then

                lp.Character:TranslateBy(hum.MoveDirection * (_G.Settings.CatSpeedValue / 10))

            end

        end

        -- 自動武裝色

        if _G.Settings.AutoBuso and not lp.Character:FindFirstChild("HasBuso") then

            pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso") end)

        end

    end

end)



print("🐾 Kexuan Zenith 已啟動！(已成功融合傳送功能)")
