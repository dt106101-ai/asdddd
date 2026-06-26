getgenv().PH_HUB_RUNNING = nil
task.wait(0.1)
getgenv().PH_HUB_RUNNING = true

local function clearOldUI()
    local names = {"Neko_Premium_v3", "CatToggleGui", "Premium_UI_V3", "yuzia_X", "DungeonAutoTP"}
    for _, name in pairs(names) do
        local old = game:GetService("CoreGui"):FindFirstChild(name)
                 or game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild(name)
        if old then old:Destroy() end
    end
end
clearOldUI()

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local StarterGui        = game:GetService("StarterGui")
local Workspace         = game:GetService("Workspace")
local Lighting          = game:GetService("Lighting")
local TweenService      = game:GetService("TweenService")
local TeleportService   = game:GetService("TeleportService")
local HttpService       = game:GetService("HttpService")
local LocalPlayer       = Players.LocalPlayer
local Camera            = Workspace.CurrentCamera

if not game:IsLoaded() then game.Loaded:Wait() end

_G.Settings = _G.Settings or {
    ClickDelay       = 0.3,
    AtkRange         = 3000,
    PullEnemies      = false,
    Mode             = "None",
    FOV              = nil,
    MaxZoom          = nil,
    CatSpeedValue    = 100,
    SpeedEnabled     = false,
    InfJump          = false,
    SuperJumpEnabled = false,
    SuperJumpHeight  = 150,
    StickyMode       = "Stop",
    StickyTarget     = nil,
    AutoBuyFruit     = false,
    AimbotEnabled    = false,
    AimbotRange      = 100,
    NoFog            = false,
    Invisible        = false,
    AutoV3           = false,
    AutoHaki         = false,
    NoLava           = false,
}
_G.ToggleStates = _G.ToggleStates or {}
_G.NekoAttack   = false
_G.NekoESP      = false
_G.ESPLoaded    = false

-- ============================================================
--  地城設定（整合自獨立腳本）
-- ============================================================
local DUNGEON = {
    AutoEnabled      = false,       -- 自動偵測開關
    CheckInterval    = 1,           -- 偵測間隔（秒）
    TweenTime        = 0.8,         -- 傳送動畫時間
    EasingStyle      = Enum.EasingStyle.Quad,
    EasingDirection  = Enum.EasingDirection.Out,
    DisableMovement  = true,        -- 傳送時停止移動
    DetectionRadius  = 1000,        -- 偵測半徑
    Cooldown         = 3,           -- 傳送後冷卻（秒）
    TeleporterName   = "ExitTeleporter",
    IsTeleporting    = false,
    LastTeleportTime = 0,
}

-- ============================================================
--  Noclip
-- ============================================================
local NOCLIP_ENABLED = false
local noclipConn

local function setNoclip(state)
    NOCLIP_ENABLED = state
    if state then
        if noclipConn then return end
        noclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end

-- ============================================================
--  水上行走
-- ============================================================
local waterWalkEnabled = false
local waterPlatform

local function createWaterPlatform()
    if waterPlatform then waterPlatform:Destroy() end
    waterPlatform = Instance.new("Part")
    waterPlatform.Size        = Vector3.new(50, 1, 50)
    waterPlatform.Anchored    = true
    waterPlatform.CanCollide  = true
    waterPlatform.Transparency = 1
    waterPlatform.Name        = "WaterWalkPlatform"
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local waterY = Workspace:FindFirstChild("Water") and Workspace.Water.Position.Y or 0
    waterPlatform.Position = Vector3.new(hrp.Position.X, waterY - 3, hrp.Position.Z)
    waterPlatform.Parent   = Workspace
end

local function updateWaterPlatform()
    if not waterPlatform then return end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local waterY = Workspace:FindFirstChild("Water") and Workspace.Water.Position.Y or 0
    if hrp.Position.Y < waterY then
        waterPlatform.CanCollide = false
    else
        waterPlatform.CanCollide = true
        waterPlatform.Position   = Vector3.new(hrp.Position.X, waterY - 3, hrp.Position.Z)
    end
end

RunService.RenderStepped:Connect(function()
    if waterWalkEnabled then
        if not waterPlatform then createWaterPlatform() end
        updateWaterPlatform()
    else
        if waterPlatform then waterPlatform:Destroy(); waterPlatform = nil end
    end
end)

-- ============================================================
--  船隻加速
-- ============================================================
local BoatSpeed = { Enabled = false, Speed = 200, MaxSpeed = 500 }
local ACTIVE_SEAT, ORIGINAL_SEAT_SPEED = nil, nil

local function updateBoatSpeed()
    if not ACTIVE_SEAT then return end
    if BoatSpeed.Enabled then
        ACTIVE_SEAT.MaxSpeed = BoatSpeed.Speed
    elseif ORIGINAL_SEAT_SPEED then
        ACTIVE_SEAT.MaxSpeed = ORIGINAL_SEAT_SPEED
    end
end

local function onCharBoat(char)
    local hum = char:WaitForChild("Humanoid")
    hum.Seated:Connect(function(sitting, seat)
        if seat and seat:IsA("VehicleSeat") and sitting then
            ACTIVE_SEAT = seat
            ORIGINAL_SEAT_SPEED = seat.MaxSpeed
            updateBoatSpeed()
        else
            if ACTIVE_SEAT and ORIGINAL_SEAT_SPEED then
                ACTIVE_SEAT.MaxSpeed = ORIGINAL_SEAT_SPEED
            end
            ACTIVE_SEAT = nil; ORIGINAL_SEAT_SPEED = nil
        end
    end)
end

if LocalPlayer.Character then onCharBoat(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(onCharBoat)

-- ============================================================
--  滑動
-- ============================================================
local SLIDE_MAGNITUDE = 200
local SLIDE_MAX       = 1000
local ACCELERATION    = 12
local DECELERATION    = 18
local slideEnabled    = false
local slideLocked     = false
local moving          = false
local moveConn
local moveKeys        = {W=false,A=false,S=false,D=false}
local currentVelocity = Vector3.zero

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.W then moveKeys.W = true end
    if input.KeyCode == Enum.KeyCode.A then moveKeys.A = true end
    if input.KeyCode == Enum.KeyCode.S then moveKeys.S = true end
    if input.KeyCode == Enum.KeyCode.D then moveKeys.D = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then moveKeys.W = false end
    if input.KeyCode == Enum.KeyCode.A then moveKeys.A = false end
    if input.KeyCode == Enum.KeyCode.S then moveKeys.S = false end
    if input.KeyCode == Enum.KeyCode.D then moveKeys.D = false end
end)

local function startSlide()
    if moving or slideLocked then return end
    moving   = true
    moveConn = RunService.RenderStepped:Connect(function(dt)
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root or slideLocked then return end
        local cam   = Workspace.CurrentCamera
        local look  = Vector3.new(cam.CFrame.LookVector.X,  0, cam.CFrame.LookVector.Z)
        local right = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z)
        local dir   = Vector3.zero
        if moveKeys.W then dir += look  end
        if moveKeys.S then dir -= look  end
        if moveKeys.A then dir -= right end
        if moveKeys.D then dir += right end
        if dir.Magnitude > 0 then dir = dir.Unit end
        local target = dir * SLIDE_MAGNITUDE
        local lerpT  = dir.Magnitude > 0 and ACCELERATION or DECELERATION
        currentVelocity = currentVelocity:Lerp(target, math.clamp(lerpT * dt, 0, 1))
        root.CFrame += Vector3.new(currentVelocity.X, 0, currentVelocity.Z) * dt
    end)
end

local function stopSlide()
    moving = false
    if moveConn then moveConn:Disconnect(); moveConn = nil end
    currentVelocity = Vector3.zero
end

local function toggleSlide(state)
    slideEnabled = state
    if state then startSlide() else stopSlide() end
end

-- ============================================================
--  飛行 TP / 拉怪
-- ============================================================
local FlyTP    = { Enabled = false, HoverHeight = 10, SearchRange = 500 }
local BringNPC = { Enabled = false, PullRange = 100 }
local flyTPConn, bringConn
local targetNPC = nil

local function startFlyTP()
    if flyTPConn then return end
    flyTPConn = RunService.Heartbeat:Connect(function()
        if not FlyTP.Enabled then return end
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local ef = Workspace:FindFirstChild("Enemies")
        if not ef then return end
        local closest, dist = nil, math.huge
        for _, npc in pairs(ef:GetChildren()) do
            if npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 and npc.PrimaryPart then
                local d = (npc.PrimaryPart.Position - hrp.Position).Magnitude
                if d < dist and d <= FlyTP.SearchRange then dist = d; closest = npc end
            end
        end
        targetNPC = closest
        if targetNPC and targetNPC.PrimaryPart then
            hrp.CFrame = CFrame.new(Vector3.new(
                targetNPC.PrimaryPart.Position.X,
                targetNPC.PrimaryPart.Position.Y + FlyTP.HoverHeight,
                targetNPC.PrimaryPart.Position.Z
            ))
        end
    end)
end

local function stopFlyTP()
    if flyTPConn then flyTPConn:Disconnect(); flyTPConn = nil end
    FlyTP.Enabled = false
end

local function startBringNPC()
    if bringConn then return end
    bringConn = RunService.Heartbeat:Connect(function()
        if not BringNPC.Enabled then return end
        if not targetNPC or not targetNPC.PrimaryPart then return end
        local ef = Workspace:FindFirstChild("Enemies")
        if not ef then return end
        local basePos = targetNPC.PrimaryPart.Position
        for _, npc in pairs(ef:GetChildren()) do
            if npc ~= targetNPC and npc:FindFirstChild("Humanoid")
            and npc.Humanoid.Health > 0 and npc.PrimaryPart then
                if (npc.PrimaryPart.Position - basePos).Magnitude <= BringNPC.PullRange then
                    npc:SetPrimaryPartCFrame(CFrame.new(basePos.X, npc.PrimaryPart.Position.Y, basePos.Z))
                end
            end
        end
    end)
end

local function stopBringNPC()
    if bringConn then bringConn:Disconnect(); bringConn = nil end
    BringNPC.Enabled = false
end

-- ============================================================
--  Camlock
-- ============================================================
local CamlockEnabled = false
local CamlockTarget  = nil
local camlockConn

local function startCamlock()
    if camlockConn then camlockConn:Disconnect() end
    camlockConn = RunService.RenderStepped:Connect(function()
        if not CamlockEnabled or not CamlockTarget then return end
        if not CamlockTarget.Character then return end
        local hrp = CamlockTarget.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, hrp.Position), 1)
    end)
end
startCamlock()

-- ============================================================
--  Hitbox
-- ============================================================
local HitboxSize    = 1
local HitboxEnabled = false

local function applyHitbox()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root and root:IsA("BasePart") then
                root.CanCollide   = false
                root.Size         = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                root.Transparency = 0.5
            end
        end
    end
end

-- ============================================================
--  Fruit M1 / SmartFly / SmartTeleport
-- ============================================================
local FRUIT_M1_ENABLED  = false
local FRUIT_M1_INTERVAL = 0.01
local RANGE_MULTIPLIER  = 1000
local fruitM1Timer      = 0

local smartFlyEnabled    = false
local smartNoclipEnabled = false
local smartFlySpeed      = 350
local smartTargetPos     = nil

local function smartEnableFly()
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = true end
end

local function smartDisableFlyAndNoclip()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = true
                p.Velocity   = Vector3.zero
            end
        end
    end
    smartFlyEnabled    = false
    smartNoclipEnabled = false
    smartTargetPos     = nil
end

RunService.Stepped:Connect(function()
    if smartNoclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if smartFlyEnabled and smartTargetPos then
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local dir = smartTargetPos - hrp.Position
            if dir.Magnitude > 1 then
                hrp.Velocity = dir.Unit * smartFlySpeed
            else
                hrp.Velocity = Vector3.zero
                smartDisableFlyAndNoclip()
            end
        end
    end
end)

function SmartTeleport(intermediate, target)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart")
    local distToTarget     = (hrp.Position - target).Magnitude
    local distIntermediate = (intermediate.Position - target).Magnitude
    if distToTarget <= distIntermediate then
        smartTargetPos     = target
        smartFlyEnabled    = true
        smartNoclipEnabled = true
        smartEnableFly()
    else
        hrp.CFrame = intermediate
        task.wait(0.2)
        smartTargetPos     = target
        smartFlyEnabled    = true
        smartNoclipEnabled = true
        smartEnableFly()
    end
end

-- ============================================================
--  傳送點表
-- ============================================================
local TeleportTargets = {
    {Name="海軍戰艦",    Intermediate=CFrame.new(-7906,5546,-379),    Target=Vector3.new(-3161,209,2067)},
    {Name="新手村",      Intermediate=CFrame.new(-7906,5546,-379),    Target=Vector3.new(1106,16,1431)},
    {Name="叢林",        Intermediate=CFrame.new(-7906,5546,-379),    Target=Vector3.new(-1422,48,21)},
    {Name="海盜村",      Intermediate=CFrame.new(-7906,5546,-379),    Target=Vector3.new(-1151,131,4166)},
    {Name="中城",        Intermediate=CFrame.new(-7906,5546,-379),    Target=Vector3.new(-786,74,1607)},
    {Name="可樂(1)",     Intermediate=CFrame.new(-7906,5546,-379),    Target=Vector3.new(-1880,25,-3320)},
    {Name="水下",        Intermediate=CFrame.new(4039,2,-1820),       Target=Vector3.new(4039,2,-1820)},
    {Name="噴泉",        Intermediate=CFrame.new(-7906,5546,-379),    Target=Vector3.new(5668,580,4301)},
    {Name="上空島",      Intermediate=CFrame.new(-4624,853,-1700),    Target=Vector3.new(-7950,5814,-1968)},
    {Name="空島",        Intermediate=CFrame.new(-7906,5546,-379),    Target=Vector3.new(-4913,738,-2578)},
    {Name="沙漠",        Intermediate=CFrame.new(-7906,5546,-379),    Target=Vector3.new(1055,52,4490)},
    {Name="火山",        Intermediate=CFrame.new(-7906,5546,-379),    Target=Vector3.new(-5412,11,8454)},
    {Name="監獄",        Intermediate=CFrame.new(61169,2,1948),       Target=Vector3.new(5327,89,717)},
    {Name="海洋堡壘",    Intermediate=CFrame.new(-7906,5546,-379),    Target=Vector3.new(-5150,375,4445)},
    {Name="雪地(1)",     Intermediate=CFrame.new(61169,2,1948),       Target=Vector3.new(1486,87,-1281)},
    {Name="暴徒領地",    Intermediate=CFrame.new(-7906,5546,-379),    Target=Vector3.new(-2836,7,5325)},
    {Name="碼頭(2)",     Intermediate=CFrame.new(2283,19,911),        Target=Vector3.new(-11,38,2724)},
    {Name="鬼船",        Intermediate=CFrame.new(-6504,83,-123),      Target=Vector3.new(919,126,33133)},
    {Name="墓地",        Intermediate=CFrame.new(922,125,32843),      Target=Vector3.new(-5620,492,-778)},
    {Name="咖啡廳",      Intermediate=CFrame.new(2283,19,911),        Target=Vector3.new(-380,95,252)},
    {Name="黑暗競技場",  Intermediate=CFrame.new(-286,306,593),       Target=Vector3.new(3776,15,-3499)},
    {Name="骷髏島",      Intermediate=CFrame.new(922,125,32843),      Target=Vector3.new(-2682,708,-10966)},
    {Name="狗屋",        Intermediate=CFrame.new(2283,19,911),        Target=Vector3.new(-2059,126,-83)},
    {Name="岩漿",        Intermediate=CFrame.new(922,125,32843),      Target=Vector3.new(-5176,175,-5426)},
    {Name="Raid",        Intermediate=CFrame.new(922,125,32843),      Target=Vector3.new(-6493,305,-4728)},
    {Name="雪地(2)",     Intermediate=CFrame.new(-286,306,593),       Target=Vector3.new(775,410,-5265)},
    {Name="可樂(2)",     Intermediate=CFrame.new(2283,19,911),        Target=Vector3.new(-1842,46,1362)},
    {Name="實驗室",      Intermediate=CFrame.new(922,125,32843),      Target=Vector3.new(-5380,219,-5936)},
    {Name="豪宅",        Intermediate=CFrame.new(2283,19,911),        Target=Vector3.new(-391,322,854)},
    {Name="碼頭(4)",     Intermediate=CFrame.new(922,125,32843),      Target=Vector3.new(-6001,29,-5024)},
    {Name="遠程",        Intermediate=CFrame.new(2283,19,911),        Target=Vector3.new(4756,8,2845)},
    {Name="碼頭(1)",     Intermediate=CFrame.new(2283,19,911),        Target=Vector3.new(-917,8,1807)},
    {Name="冬季城堡",    Intermediate=CFrame.new(2283,19,911),        Target=Vector3.new(6007,294,-6637)},
    {Name="碼頭(3)",     Intermediate=CFrame.new(2283,19,911),        Target=Vector3.new(-1920,6,-2554)},
    {Name="工廠",        Intermediate=CFrame.new(2283,19,911),        Target=Vector3.new(430,211,-430)},
    {Name="未知",        Intermediate=CFrame.new(922,125,32843),      Target=Vector3.new(-5157,3,2377)},
    {Name="港口",        Intermediate=CFrame.new(-5027,317,-3207),    Target=Vector3.new(-572,232,5770)},
    {Name="烏龜屋",      Intermediate=CFrame.new(-5060,317,-3193),    Target=Vector3.new(-12550,337,-7506)},
    {Name="海上城堡",    Intermediate=CFrame.new(-12464,376,-7566),   Target=Vector3.new(-4929,317,-3041)},
    {Name="大媽島",      Intermediate=CFrame.new(-12464,376,-7566),   Target=Vector3.new(-726,381,-10977)},
    {Name="海德拉",      Intermediate=CFrame.new(-5027,317,-3207),    Target=Vector3.new(5761,1089,467)},
    {Name="司法島",      Intermediate=CFrame.new(-5097,317,-3177),    Target=Vector3.new(-15988,470,938)},
    {Name="烏龜中心",    Intermediate=CFrame.new(5369,25,-506),       Target=Vector3.new(-11993,332,-9089)},
    {Name="大樹",        Intermediate=CFrame.new(-5027,317,-3207),    Target=Vector3.new(2551,128,-6950)},
    {Name="烏龜山",      Intermediate=CFrame.new(5369,25,-506),       Target=Vector3.new(-12807,897,-10793)},
    {Name="鬧鬼城堡",    Intermediate=CFrame.new(-5097,317,-3177),    Target=Vector3.new(-9515,164,5787)},
    {Name="花生島",      Intermediate=CFrame.new(-12464,376,-7566),   Target=Vector3.new(-2040,5,-9814)},
    {Name="烏龜入口",    Intermediate=CFrame.new(-5060,317,-3193),    Target=Vector3.new(-10076,332,-8321)},
    {Name="海德拉競技場",Intermediate=CFrame.new(-11993,332,-8837),   Target=Vector3.new(5014,59,-1543)},
    {Name="可可島",      Intermediate=CFrame.new(-12464,376,-7566),   Target=Vector3.new(182,127,-12769)},
    {Name="蛋糕島",      Intermediate=CFrame.new(-12464,376,-7566),   Target=Vector3.new(-2102,70,-12134)},
}

-- ============================================================
--  自動裝備
-- ============================================================
local autoEquipEnabled   = false
local selectedWeaponType = "Melee"

local function equipByType(toolType)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum  = char:WaitForChild("Humanoid")
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == toolType then
            hum:EquipTool(tool)
            break
        end
    end
end

task.spawn(function()
    while true do
        task.wait(0.1)
        if autoEquipEnabled then
            local char = LocalPlayer.Character
            if char then
                local hum  = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    local tool = hum:FindFirstChildOfClass("Tool")
                    if not tool or tool.ToolTip ~= selectedWeaponType then
                        equipByType(selectedWeaponType)
                    end
                end
            end
        end
    end
end)

-- ============================================================
--  低配模式
-- ============================================================
local function ApplyLowGraphics()
    local Terrain = Workspace:FindFirstChildWhichIsA("Terrain")
    if Terrain then
        Terrain.WaterWaveSize    = 0
        Terrain.WaterWaveSpeed   = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 1
    end
    Lighting.GlobalShadows = false
    Lighting.FogEnd        = 9e9
    Lighting.FogStart      = 9e9
    pcall(function() settings().Rendering.QualityLevel = 1 end)
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CastShadow  = false
            v.Material    = Enum.Material.Plastic
            v.Reflectance = 0
        elseif v:IsA("Decal") then
            v.Transparency = 1
            v.Texture = ""
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Lifetime = NumberRange.new(0)
        end
    end
    for _, v in pairs(Lighting:GetDescendants()) do
        if v:IsA("PostEffect") then v.Enabled = false end
    end
    Workspace.DescendantAdded:Connect(function(child)
        task.spawn(function()
            if child:IsA("ForceField") or child:IsA("Sparkles")
            or child:IsA("Smoke") or child:IsA("Fire") or child:IsA("Beam") then
                RunService.Heartbeat:Wait()
                child:Destroy()
            elseif child:IsA("BasePart") then
                child.CastShadow = false
            end
        end)
    end)
end

-- ============================================================
--  Anti-AFK
-- ============================================================
local AntiAFK_ENABLED = false
local AntiAFK_Conn

local function enableAntiAFK()
    if AntiAFK_ENABLED then return end
    AntiAFK_ENABLED = true
    if getconnections then
        for _, c in pairs(getconnections(LocalPlayer.Idled)) do
            if c.Disable then c:Disable() elseif c.Disconnect then c:Disconnect() end
        end
    else
        AntiAFK_Conn = LocalPlayer.Idled:Connect(function()
            pcall(function()
                game:GetService("VirtualUser"):CaptureController()
                game:GetService("VirtualUser"):ClickButton2(Vector2.new())
            end)
        end)
    end
end

local function disableAntiAFK()
    if not AntiAFK_ENABLED then return end
    AntiAFK_ENABLED = false
    if AntiAFK_Conn then AntiAFK_Conn:Disconnect(); AntiAFK_Conn = nil end
end

-- ============================================================
--  內建 ESP
-- ============================================================
local BUILTIN_ESP_ENABLED = false
local espObjects  = {}
local RandomID    = math.random(1, 1000000)

local function getTeamColor(player)
    return player.Team ~= LocalPlayer.Team
        and Color3.fromRGB(255, 60, 60)
        or  Color3.fromRGB(60, 120, 255)
end

local function removeBuiltinESP(player)
    if espObjects[player] then
        for _, v in pairs(espObjects[player]) do
            if typeof(v) == "Instance" and v.Parent then v:Destroy() end
        end
        espObjects[player] = nil
    end
end

local function createBuiltinESP(player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    removeBuiltinESP(player)
    local head = player.Character:FindFirstChild("Head")
    if not head then return end

    local highlight = Instance.new("Highlight")
    highlight.Adornee             = player.Character
    highlight.FillColor           = Color3.fromRGB(30, 30, 30)
    highlight.FillTransparency    = 0.6
    highlight.OutlineColor        = getTeamColor(player)
    highlight.OutlineTransparency = 0
    highlight.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent              = player.Character

    local bill = Instance.new("BillboardGui")
    bill.Name        = "ESP_BB_" .. RandomID
    bill.Adornee     = head
    bill.Size        = UDim2.fromOffset(200, 60)
    bill.StudsOffset = Vector3.new(0, 3, 0)
    bill.AlwaysOnTop = true
    bill.Parent      = head

    local avatar = Instance.new("ImageLabel", bill)
    avatar.Size                   = UDim2.new(0, 46, 0, 46)
    avatar.BackgroundTransparency = 1
    avatar.BorderSizePixel        = 0
    avatar.Image                  = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png"

    local nameLabel = Instance.new("TextLabel", bill)
    nameLabel.Size                   = UDim2.new(1, -52, 0, 22)
    nameLabel.Position               = UDim2.new(0, 52, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3             = getTeamColor(player)
    nameLabel.TextStrokeTransparency = 0.4
    nameLabel.Font                   = Enum.Font.GothamBold
    nameLabel.TextScaled             = true
    nameLabel.TextXAlignment         = Enum.TextXAlignment.Left
    nameLabel.Text                   = player.Name

    local infoLabel = Instance.new("TextLabel", bill)
    infoLabel.Size                   = UDim2.new(1, -52, 0, 18)
    infoLabel.Position               = UDim2.new(0, 52, 0, 24)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextColor3             = Color3.fromRGB(230, 230, 230)
    infoLabel.TextStrokeTransparency = 0.4
    infoLabel.Font                   = Enum.Font.Gotham
    infoLabel.TextScaled             = true
    infoLabel.TextXAlignment         = Enum.TextXAlignment.Left
    infoLabel.Text                   = "HP: -- | --m"

    local barBG = Instance.new("Frame", bill)
    barBG.Size             = UDim2.new(1, -52, 0, 6)
    barBG.Position         = UDim2.new(0, 52, 0, 46)
    barBG.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    barBG.BorderSizePixel  = 0

    local barFG = Instance.new("Frame", barBG)
    barFG.Name             = "HP_Fill"
    barFG.Size             = UDim2.new(1, 0, 1, 0)
    barFG.BackgroundColor3 = Color3.fromRGB(0, 220, 80)
    barFG.BorderSizePixel  = 0

    espObjects[player] = {highlight, bill}

    task.spawn(function()
        local myHrp
        while BUILTIN_ESP_ENABLED and player and player.Parent do
            task.wait(0.2)
            pcall(function()
                myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local char = player.Character
                if not char then return end
                local hum  = char:FindFirstChildOfClass("Humanoid")
                local hrp  = char:FindFirstChild("HumanoidRootPart")
                if not hum or not hrp or not myHrp then return end
                local dist  = math.floor((hrp.Position - myHrp.Position).Magnitude)
                local hp    = math.floor(hum.Health)
                local maxHp = math.floor(hum.MaxHealth)
                local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                infoLabel.Text = string.format("HP: %d/%d | %dm", hp, maxHp, dist)
                barFG.Size     = UDim2.new(ratio, 0, 1, 0)
                barFG.BackgroundColor3 = ratio > 0.6
                    and Color3.fromRGB(0, 220, 80)
                    or  ratio > 0.3
                    and Color3.fromRGB(255, 200, 0)
                    or  Color3.fromRGB(255, 50, 50)
                highlight.OutlineColor = getTeamColor(player)
                nameLabel.TextColor3   = getTeamColor(player)
            end)
        end
    end)
end

local function toggleBuiltinESP(state)
    BUILTIN_ESP_ENABLED = state
    for _, p in ipairs(Players:GetPlayers()) do
        if state then createBuiltinESP(p) else removeBuiltinESP(p) end
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        if BUILTIN_ESP_ENABLED then createBuiltinESP(p) end
    end)
    p.CharacterRemoving:Connect(function() removeBuiltinESP(p) end)
end)
Players.PlayerRemoving:Connect(removeBuiltinESP)

-- ============================================================
--  隱形
-- ============================================================
local inv_char, inv_hum, inv_root
local inv_parts = {}

local function init_inv_character()
    inv_char  = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    inv_hum   = inv_char:WaitForChild("Humanoid", 10)
    inv_root  = inv_char:WaitForChild("HumanoidRootPart", 10)
    inv_parts = {}
    for _, v in pairs(inv_char:GetDescendants()) do
        if v:IsA("BasePart") and v.Transparency == 0 then
            table.insert(inv_parts, v)
        end
    end
end

local function update_invisibility()
    if not inv_char then return end
    for _, p in pairs(inv_parts) do
        if p and p.Parent then
            p.Transparency = _G.Settings.Invisible and 0.5 or 0
        end
    end
end

-- ============================================================
--  其他 Remotes
-- ============================================================
local function callAwakeningRemote()
    pcall(function()
        local Awakening = LocalPlayer.Backpack:FindFirstChild("Awakening")
                       or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Awakening"))
        if Awakening and Awakening:FindFirstChild("RemoteFunction") then
            Awakening.RemoteFunction:InvokeServer(true)
        end
    end)
end

local function callRaceV3Remote()
    pcall(function()
        local r = ReplicatedStorage:FindFirstChild("Remotes")
               and ReplicatedStorage.Remotes:FindFirstChild("CommE")
        if r then r:FireServer("ActivateAbility") end
    end)
end

local function ClearFog()
    pcall(function()
        Lighting.FogEnd        = 999999
        Lighting.FogStart      = 999999
        Lighting.GlobalShadows = false
        Lighting.ClockTime     = 12
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") or v:IsA("Clouds") then v:Destroy() end
        end
    end)
end

local function Sea(cmd)
    local r = ReplicatedStorage:FindFirstChild("Remotes")
           and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
    if r then
        task.spawn(function() pcall(function() r:InvokeServer(cmd) end) end)
    end
end

local function isTalking()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    return pg and (pg:FindFirstChild("DialogueGui") or pg:FindFirstChild("NPCProgressBar"))
end

local function TeleportTo(cf)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cf
    end
end

-- ============================================================
--  地城核心邏輯（整合自獨立腳本）
-- ============================================================

-- 取得所有出口傳送點（照層數排序）
local function getDungeonExits()
    local exits = {}
    local map     = Workspace:FindFirstChild("Map")
    if not map then return exits end
    local dungeon = map:FindFirstChild("Dungeon")
    if not dungeon then return exits end

    for _, level in pairs(dungeon:GetChildren()) do
        local lvNum = tonumber(level.Name)
        if lvNum then
            local tp = level:FindFirstChild(DUNGEON.TeleporterName)
            if tp then
                local root = tp:FindFirstChild("Root") or tp:FindFirstChildWhichIsA("BasePart")
                if root then
                    table.insert(exits, {
                        level    = lvNum,
                        rootPart = root,
                        position = root.Position,
                    })
                end
            end
        end
    end

    table.sort(exits, function(a, b) return a.level < b.level end)
    return exits
end

-- 偵測玩家目前在哪一層（找最近出口判斷）
local function getDungeonCurrentLevel()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local exits = getDungeonExits()
    local closest, minDist = nil, math.huge
    for _, info in ipairs(exits) do
        local dist = (hrp.Position - info.position).Magnitude
        if dist < minDist and dist < DUNGEON.DetectionRadius then
            minDist   = dist
            closest   = info.level
        end
    end
    return closest
end

-- 偵測地城範圍內是否還有存活敵人
local function dungeonHasEnemies()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return false end
    for _, npc in ipairs(enemies:GetChildren()) do
        local hum  = npc:FindFirstChild("Humanoid")
        local root = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Head")
        if hum and hum.Health > 0 and root then
            if (root.Position - hrp.Position).Magnitude <= DUNGEON.DetectionRadius then
                return true
            end
        end
    end
    return false
end

-- 執行傳送（Tween 動畫）
local dungeonStatusLabel = nil  -- 由 UI 段指定

local function dungeonDoTeleport(rootPart, level)
    if DUNGEON.IsTeleporting then return end
    local now = tick()
    if now - DUNGEON.LastTeleportTime < DUNGEON.Cooldown then return end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    DUNGEON.IsTeleporting    = true
    DUNGEON.LastTeleportTime = now

    if dungeonStatusLabel then
        dungeonStatusLabel.Text = "狀態：傳送中 → 第 " .. level .. " 層出口"
    end

    if DUNGEON.DisableMovement then
        hum.WalkSpeed = 0
        hum.JumpPower = 0
    end

    local ti    = TweenInfo.new(DUNGEON.TweenTime, DUNGEON.EasingStyle, DUNGEON.EasingDirection)
    local tween = TweenService:Create(hrp, ti, {CFrame = rootPart.CFrame})
    tween:Play()
    tween.Completed:Connect(function()
        if DUNGEON.DisableMovement then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end
        task.wait(0.4)
        DUNGEON.IsTeleporting = false
        if dungeonStatusLabel then
            dungeonStatusLabel.Text = "狀態：等待中..."
        end
    end)
end

-- 找最近出口並傳送（手動按鈕用）
local function dungeonTeleportNearest()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local exits   = getDungeonExits()
    local best, minDist = nil, math.huge
    for _, info in ipairs(exits) do
        local dist = (hrp.Position - info.position).Magnitude
        if dist < minDist then
            minDist = dist
            best    = info
        end
    end
    if best and minDist < DUNGEON.DetectionRadius * 1.5 then
        dungeonDoTeleport(best.rootPart, best.level)
    end
end

-- 主自動循環（整合進 PH_HUB_RUNNING 生命週期）
task.spawn(function()
    while getgenv().PH_HUB_RUNNING do
        task.wait(DUNGEON.CheckInterval)
        if not DUNGEON.AutoEnabled or DUNGEON.IsTeleporting then continue end
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then continue end

        -- 敵人全清才傳送
        if dungeonHasEnemies() then
            if dungeonStatusLabel then
                dungeonStatusLabel.Text = "狀態：偵測敵人中..."
            end
            continue
        end

        local curLevel = getDungeonCurrentLevel()
        if not curLevel then continue end

        local exits = getDungeonExits()
        for _, info in ipairs(exits) do
            if info.level == curLevel then
                dungeonDoTeleport(info.rootPart, curLevel)
                break
            end
        end
    end
end)

-- ============================================================
--  UI 載入
-- ============================================================
local library = loadstring(game:HttpGet("https://gist.githubusercontent.com/nekooocattt-NEKO/d5120853dfb75a8a2623caf2a16d5f10/raw/UI"))()
local window  = library.new(" yuzia_X ")

-- ── Tab 1 系統 ──────────────────────────────────────────────
local tab1 = window:MainTab("📊 系統")
local sub1 = tab1:SubTab("公告資訊")
sub1:Section("核心資訊"):Button("版本: 4.3.1", function() end)
sub1:Section("重要通知"):Button("簡平安是育成老婆", function() end)
sub1:Section("操作提示"):Button("請遵循安全協議，低調使用", function() end)

-- ── Tab 2 戰鬥 ──────────────────────────────────────────────
local tab2   = window:MainTab("⚔️ 戰鬥")
local sub2_1 = tab2:SubTab("自動攻擊")
local sub2_2 = tab2:SubTab("運動屬性")
local sub2_3 = tab2:SubTab("視覺渲染")

local fightSec = sub2_1:Section("攻擊協議")
fightSec:Toggle("自動攻擊",   function(s) _G.NekoAttack = s end)
fightSec:Toggle("聚怪模組",   function(s) _G.Settings.PullEnemies = s end)
local invToggle = fightSec:Toggle("秒殺/隱形 (G 鍵)", function(s)
    _G.Settings.Invisible = s
    update_invisibility()
end)
fightSec:Textbox("偵測範圍", "3000", function(v) _G.Settings.AtkRange   = tonumber(v) or 3000 end)
fightSec:Textbox("執行週期", "0.01", function(v) _G.Settings.ClickDelay = tonumber(v) or 0.01 end)
fightSec:Toggle("自動覺醒 V4",  function(s) _G.ToggleStates["自動V4"] = s end)
fightSec:Toggle("種族技能 V3",  function(s) _G.Settings.AutoV3   = s end)
fightSec:Toggle("自動武裝色",   function(s) _G.Settings.AutoHaki = s end)

local modeSec = sub2_1:Section("攻擊模式")
modeSec:Button("▶ 點殺模式", function() _G.Settings.Mode = "Mob"; _G.NekoAttack = true  end)
modeSec:Button("☣ 全域屠殺", function() _G.Settings.Mode = "All"; _G.NekoAttack = true  end)
modeSec:Button("⏹ 停止所有", function() _G.Settings.Mode = "None"; _G.NekoAttack = false end)

local m1Sec = sub2_1:Section("Fruit M1")
m1Sec:Toggle("Fruit M1 自動", function(s) FRUIT_M1_ENABLED = s end)

local hitboxSec = sub2_1:Section("Hitbox 擴大")
hitboxSec:Toggle("啟用 Hitbox", function(s)
    HitboxEnabled = s
    if s then applyHitbox() end
end)
hitboxSec:Textbox("Hitbox 大小 (1-20)", "1", function(v)
    HitboxSize = math.clamp(tonumber(v) or 1, 1, 20)
    if HitboxEnabled then applyHitbox() end
end)

local moveSec = sub2_2:Section("移動設定")
moveSec:Toggle("解除速度限制",  function(s) _G.Settings.SpeedEnabled     = s end)
moveSec:Textbox("目標速度", "100", function(v) _G.Settings.CatSpeedValue = tonumber(v) or 100 end)
moveSec:Toggle("多重跳躍",      function(s) _G.Settings.InfJump          = s end)
moveSec:Toggle("垂直跳躍強化",  function(s) _G.Settings.SuperJumpEnabled = s end)
moveSec:Textbox("跳躍高度", "150", function(v) _G.Settings.SuperJumpHeight = tonumber(v) or 150 end)

local slideSec = sub2_2:Section("人物滑動")
slideSec:Toggle("啟用滑動", function(s) toggleSlide(s) end)
slideSec:Textbox("滑動速度 (max 1000)", "200", function(v)
    SLIDE_MAGNITUDE = math.clamp(tonumber(v) or 200, 0, SLIDE_MAX)
end)

local noclipSec = sub2_2:Section("穿牆 Noclip")
noclipSec:Toggle("穿牆", function(s) setNoclip(s) end)

local waterSec = sub2_2:Section("水上行走")
waterSec:Toggle("水上行走", function(s)
    waterWalkEnabled = s
    if s then createWaterPlatform() end
end)

local renderSec = sub2_3:Section("渲染設定")
renderSec:Textbox("視野 FOV (留空=不干預)", "", function(v)
    _G.Settings.FOV = tonumber(v)
end)
renderSec:Textbox("最遠視線 (留空=不干預)", "", function(v)
    local n = tonumber(v)
    _G.Settings.MaxZoom = n
    if n then LocalPlayer.CameraMaxZoomDistance = n end
end)
renderSec:Toggle("移除霧氣", function(s) _G.Settings.NoFog = s; if s then ClearFog() end end)
renderSec:Toggle("移除岩漿", function(s) _G.Settings.NoLava = s end)

local espBuiltinSec = sub2_3:Section("內建 ESP (頭像+血量+距離)")
espBuiltinSec:Toggle("啟用內建 ESP", function(s) toggleBuiltinESP(s) end)

local aimSec = sub2_3:Section("輔助瞄準")
aimSec:Toggle("啟用 Aimbot", function(s) _G.Settings.AimbotEnabled = s end)
aimSec:Textbox("瞄準半徑", "100", function(v) _G.Settings.AimbotRange = tonumber(v) or 100 end)

local camlockSec = sub2_3:Section("視角鎖定 Camlock")
camlockSec:Toggle("視角鎖定", function(s) CamlockEnabled = s end)
sub2_3:List("Camlock 目標",
    function()
        local t = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(t, p.Name) end
        end
        return t
    end,
    function(name) CamlockTarget = Players:FindFirstChild(name) end
)

-- ── Tab 3 傳送 ──────────────────────────────────────────────
local tab3   = window:MainTab("⚡ 傳送")
local sub3_1 = tab3:SubTab("世界網關")
local sub3_2 = tab3:SubTab("一海")
local sub3_3 = tab3:SubTab("二海")
local sub3_4 = tab3:SubTab("三海")
local sub3_5 = tab3:SubTab("快速傳送")
local sub3_6 = tab3:SubTab("目標鎖定")

local seaSec = sub3_1:Section("跨海傳送")
seaSec:Button("第一海域", function() Sea("TravelMain")      end)
seaSec:Button("第二海域", function() Sea("TravelDressrosa") end)
seaSec:Button("第三海域", function() Sea("TravelZou")       end)

local stopFlySec = sub3_1:Section("飛行控制")
stopFlySec:Button("⏹ 停止飛行", function() smartDisableFlyAndNoclip() end)

local sea1Sec   = sub3_2:Section("一海地點")
local sea1Names = {"海軍戰艦","新手村","叢林","海盜村","中城","可樂(1)","水下","噴泉","上空島","空島","沙漠","火山","監獄","海洋堡壘","雪地(1)","暴徒領地"}
for i, name in ipairs(sea1Names) do
    sea1Sec:Button(name, function()
        task.spawn(function() SmartTeleport(TeleportTargets[i].Intermediate, TeleportTargets[i].Target) end)
    end)
end

local sea2Sec   = sub3_3:Section("二海地點")
local sea2Names = {"碼頭(2)","鬼船","墓地","咖啡廳","黑暗競技場","骷髏島","狗屋","岩漿","Raid","雪地(2)","可樂(2)","實驗室","豪宅","碼頭(4)","遠程","碼頭(1)","冬季城堡","碼頭(3)","工廠","未知"}
for i, name in ipairs(sea2Names) do
    sea2Sec:Button(name, function()
        task.spawn(function() SmartTeleport(TeleportTargets[16+i].Intermediate, TeleportTargets[16+i].Target) end)
    end)
end

local sea3Sec   = sub3_4:Section("三海地點")
local sea3Names = {"港口","烏龜屋","海上城堡","大媽島","海德拉","司法島","烏龜中心","大樹","烏龜山","鬧鬼城堡","花生島","烏龜入口","海德拉競技場","可可島","蛋糕島"}
for i, name in ipairs(sea3Names) do
    sea3Sec:Button(name, function()
        task.spawn(function() SmartTeleport(TeleportTargets[36+i].Intermediate, TeleportTargets[36+i].Target) end)
    end)
end

local m2Sec = sub3_5:Section("二海座標")
local sea2QuickLocs = {
    {"天鵝房間", CFrame.new(-287.37, 305.81, 592.98)},
    {"豪華別墅", CFrame.new(2286.93, 15.06, 910.51)},
    {"幽靈船",   CFrame.new(-6501, 83, -123)},
    {"幽靈船外", CFrame.new(922.78, 123.96, 32842.4)},
}
for _, loc in ipairs(sea2QuickLocs) do
    m2Sec:Button(loc[1], function() TeleportTo(loc[2]) end)
end

local m3Sec = sub3_5:Section("三海座標")
local sea3QuickLocs = {
    {"海洋城堡", CFrame.new(-12463, 376, -7566)},
    {"海龜豪宅", CFrame.new(-5060, 316, -3192)},
    {"司法島",   CFrame.new(-5096, 316, -3177)},
    {"九頭蛇島", CFrame.new(-5027, 316, -3206)},
}
for _, loc in ipairs(sea3QuickLocs) do
    m3Sec:Button(loc[1], function() TeleportTo(loc[2]) end)
end

local stickySec = sub3_6:Section("跟隨設定")
local targetBtn = stickySec:Button("🎯 無鎖定目標", function() end)
stickySec:Button("🔹 插值跟隨 (Slow)",  function() _G.Settings.StickyMode = "Slow"  end)
stickySec:Button("🔸 強制同步 (Force)", function() _G.Settings.StickyMode = "Force" end)
stickySec:Button("⚪ 停止跟隨",         function() _G.Settings.StickyMode = "Stop"  end)
sub3_6:List("玩家名單",
    function()
        local t = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(t, p.Name) end
        end
        return t
    end,
    function(name)
        _G.Settings.StickyTarget = name
        targetBtn.Text = "🎯 鎖定中: " .. name
    end
)

-- ── Tab 4 農怪 ──────────────────────────────────────────────
local tab4   = window:MainTab("🌾 農怪")
local sub4_1 = tab4:SubTab("農怪設定")
local sub4_2 = tab4:SubTab("地城")      -- 整合重點
local sub4_3 = tab4:SubTab("船隻")

local npcSec = sub4_1:Section("NPC 控制")
npcSec:Toggle("TP to NPC (飛到最近怪)", function(s)
    FlyTP.Enabled = s
    if s then startFlyTP() else stopFlyTP() end
end)
npcSec:Toggle("Bring NPC (拉怪)", function(s)
    BringNPC.Enabled = s
    if s then startBringNPC() else stopBringNPC() end
end)
npcSec:Textbox("飛行高度 (max 50)",   "10",  function(v) FlyTP.HoverHeight = math.clamp(tonumber(v) or 10,  0, 50)   end)
npcSec:Textbox("搜尋範圍 (max 2000)", "500", function(v) FlyTP.SearchRange  = math.clamp(tonumber(v) or 500, 0, 2000) end)
npcSec:Textbox("拉怪範圍 (max 250)",  "100", function(v) BringNPC.PullRange = math.clamp(tonumber(v) or 100, 0, 250)  end)

local equipSec = sub4_1:Section("自動裝備")
equipSec:Toggle("Auto Equip", function(s)
    autoEquipEnabled = s
    if s then equipByType(selectedWeaponType) end
end)
equipSec:Button("武器：Melee",      function() selectedWeaponType = "Melee";      if autoEquipEnabled then equipByType(selectedWeaponType) end end)
equipSec:Button("武器：Blox Fruit", function() selectedWeaponType = "Blox Fruit"; if autoEquipEnabled then equipByType(selectedWeaponType) end end)
equipSec:Button("武器：Sword",      function() selectedWeaponType = "Sword";      if autoEquipEnabled then equipByType(selectedWeaponType) end end)
equipSec:Button("武器：Gun",        function() selectedWeaponType = "Gun";        if autoEquipEnabled then equipByType(selectedWeaponType) end end)

-- ────────────────────────────────────────────────────────────
--  地城 SubTab（全新整合介面）
-- ────────────────────────────────────────────────────────────
local dungeonSec = sub4_2:Section("自動傳送設定")

-- 主開關
dungeonSec:Toggle("🏰 自動傳送到出口", function(s)
    DUNGEON.AutoEnabled = s
end)

-- 狀態顯示（Button 當 Label 用，不可點）
local dungeonStatusBtn = dungeonSec:Button("狀態：待機中", function() end)
dungeonStatusLabel = dungeonStatusBtn  -- 綁定到全域讓循環更新

-- 手動立即傳送
dungeonSec:Button("⚡ 立即傳送到最近出口", function()
    task.spawn(dungeonTeleportNearest)
end)

local dungeonCfgSec = sub4_2:Section("地城參數")

dungeonCfgSec:Toggle("傳送時停止移動", function(s)
    DUNGEON.DisableMovement = s
end)

dungeonCfgSec:Textbox("偵測範圍 (預設 1000)", "1000", function(v)
    DUNGEON.DetectionRadius = tonumber(v) or 1000
end)

dungeonCfgSec:Textbox("傳送冷卻秒數 (預設 3)", "3", function(v)
    DUNGEON.Cooldown = tonumber(v) or 3
end)

dungeonCfgSec:Textbox("偵測間隔秒數 (預設 1)", "1", function(v)
    DUNGEON.CheckInterval = math.max(0.2, tonumber(v) or 1)
end)

dungeonCfgSec:Textbox("傳送動畫時間 (預設 0.8)", "0.8", function(v)
    DUNGEON.TweenTime = math.clamp(tonumber(v) or 0.8, 0, 3)
end)

-- ────────────────────────────────────────────────────────────

local boatSec = sub4_3:Section("船隻加速")
boatSec:Toggle("船隻加速", function(s) BoatSpeed.Enabled = s; updateBoatSpeed() end)
boatSec:Textbox("船速 (max 500)", "200", function(v)
    BoatSpeed.Speed = math.clamp(tonumber(v) or 200, 0, 500)
    updateBoatSpeed()
end)

-- ── Tab 5 功能 ──────────────────────────────────────────────
local tab5   = window:MainTab("⚙️ 功能")
local sub5_1 = tab5:SubTab("外掛組件")
local sub5_2 = tab5:SubTab("系統優化")
local sub5_3 = tab5:SubTab("伺服器")

sub5_1:Section("飛行系統"):Button("載入飛行控制", function()
    pcall(function()
        loadstring(game:HttpGet("https://gist.githubusercontent.com/nekooocattt-NEKO/499fb11ec2e0587a8f66f25a3ce9772e/raw/%25E9%25A3%259B%25E8%25A1%258C"))()
    end)
end)

sub5_1:Section("視覺擴展"):Button("🎨 自定義技能顏色", function()
    pcall(function()
        loadstring(game:HttpGet("https://gist.githubusercontent.com/nekooocattt-NEKO/0197a5f580f0cd4d068199a98ad150e3/raw/%25E6%2594%25B9%25E8%25AE%258A%25E6%258A%2580%25E8%2583%25BD%25E9%25A1%258F%25E8%2589%25B2"))()
    end)
end)

sub5_1:Section("採集協議"):Toggle("自動果實購買", function(s) _G.Settings.AutoBuyFruit = s end)

local optSec = sub5_2:Section("性能優化")
optSec:Button("🔧 低配模式 (一次性)", function() ApplyLowGraphics() end)
optSec:Toggle("Anti AFK", false, function(s)
    if s then enableAntiAFK() else disableAntiAFK() end
end)

local serverSec = sub5_3:Section("伺服器管理")
serverSec:Button("切換伺服器 (Server Hop)", function()
    task.spawn(function() pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end) end)
end)
serverSec:Button("重進伺服器 (Rejoin)", function()
    task.spawn(function() pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end) end)
end)
serverSec:Button("加入少人伺服器", function()
    task.spawn(function()
        local AllServers = {}
        local ok, servers = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(
                "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
            ))
        end)
        if ok and servers and servers.data then
            for _, s in ipairs(servers.data) do
                if s.id ~= game.JobId and s.playing < s.maxPlayers then
                    table.insert(AllServers, s.id)
                end
            end
        end
        if #AllServers > 0 then
            local randId = AllServers[math.random(1, #AllServers)]
            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, randId, LocalPlayer) end)
        end
    end)
end)

-- ============================================================
--  戰鬥主循環
-- ============================================================
task.spawn(function()
    local RA, RH
    while getgenv().PH_HUB_RUNNING do
        pcall(function()
            local net = ReplicatedStorage:FindFirstChild("Modules")
                     and ReplicatedStorage.Modules:FindFirstChild("Net")
            if net then
                RA = net:FindFirstChild("RE/RegisterAttack")
                RH = net:FindFirstChild("RE/RegisterHit")
            end
        end)
        if RA and RH then break end
        task.wait(1)
    end

    while getgenv().PH_HUB_RUNNING do
        task.wait(_G.Settings.ClickDelay)
        if not isTalking() and _G.NekoAttack and RA and RH then
            pcall(function()
                local MAX_TARGETS = 25
                local ts = {}
                local targetPart = nil

                if _G.Settings.Mode == "All" then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if #ts >= MAX_TARGETS then break end
                        if p == LocalPlayer then continue end
                        local char = p.Character
                        local h = char and char:FindFirstChild("Humanoid")
                        local r = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head") or char.PrimaryPart)
                        if h and h.Health > 0 and r
                        and LocalPlayer:DistanceFromCharacter(r.Position) < _G.Settings.AtkRange then
                            table.insert(ts, {char, r})
                            targetPart = r
                        end
                    end
                end

                if _G.Settings.Mode == "All" or _G.Settings.Mode == "Mob" then
                    local ef = Workspace:FindFirstChild("Enemies")
                    if ef then
                        for _, e in pairs(ef:GetChildren()) do
                            if #ts >= MAX_TARGETS then break end
                            local h = e:FindFirstChild("Humanoid")
                            local r = e:FindFirstChild("Head") or e:FindFirstChild("HumanoidRootPart") or e.PrimaryPart
                            if h and h.Health > 0 and r
                            and LocalPlayer:DistanceFromCharacter(r.Position) < _G.Settings.AtkRange then
                                table.insert(ts, {e, r})
                                if not targetPart then targetPart = r end
                            end
                        end
                    end
                end

                if targetPart and #ts > 0 then
                    RA:FireServer(0)
                    RH:FireServer(targetPart, ts)
                end
            end)
        end
    end
end)

-- ============================================================
--  其他 RunService 循環
-- ============================================================
RunService.Heartbeat:Connect(function(dt)
    if not FRUIT_M1_ENABLED then return end
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    fruitM1Timer += dt
    if fruitM1Timer < FRUIT_M1_INTERVAL then return end
    fruitM1Timer = 0
    local handle = tool:FindFirstChild("Handle")
    if handle and not handle:GetAttribute("HitboxExpanded") then
        handle.Size         = handle.Size * RANGE_MULTIPLIER
        handle.Transparency = 1
        handle.CanCollide   = false
        handle:SetAttribute("HitboxExpanded", true)
    end
    tool:Activate()
end)

task.spawn(function()
    while getgenv().PH_HUB_RUNNING do
        pcall(function()
            if _G.Settings.PullEnemies and not isTalking() then
                local myHrp  = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local enemies = Workspace:FindFirstChild("Enemies")
                if myHrp and enemies then
                    for _, v in pairs(enemies:GetChildren()) do
                        local hrp = v:FindFirstChild("HumanoidRootPart")
                        local hum = v:FindFirstChild("Humanoid")
                        if hrp and hum and hum.Health > 0
                        and (hrp.Position - myHrp.Position).Magnitude < _G.Settings.AtkRange then
                            hrp.CFrame    = myHrp.CFrame * CFrame.new(0, 0, -5)
                            hrp.CanCollide = false
                        end
                    end
                end
            end
            if _G.Settings.AutoHaki
            and LocalPlayer.Character
            and not LocalPlayer.Character:FindFirstChild("HasBuso") then
                local r = ReplicatedStorage:FindFirstChild("Remotes")
                       and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
                if r then r:InvokeServer("Buso") end
            end
            if _G.ToggleStates["自動V4"] then callAwakeningRemote() end
            if _G.Settings.AutoV3        then callRaceV3Remote()     end
            if _G.Settings.NoLava then
                for _, v in pairs(Workspace:GetDescendants()) do
                    if v.Name == "LavaParts"
                    and v.Parent and v.Parent.Name == "CircleIsland"
                    and v.Parent.Parent and v.Parent.Parent.Name == "Map" then
                        v:Destroy()
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end)

RunService.Stepped:Connect(function()
    if not getgenv().PH_HUB_RUNNING then return end
    if _G.Settings.StickyMode ~= "Stop" and _G.Settings.StickyTarget then
        local target = Players:FindFirstChild(_G.Settings.StickyTarget)
        if target and target.Character then
            local tHrp  = target.Character:FindFirstChild("HumanoidRootPart")
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if tHrp and myHrp then
                for _, v in pairs(LocalPlayer.Character:GetChildren()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
                if _G.Settings.StickyMode == "Force" then
                    myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 3)
                else
                    myHrp.CFrame = myHrp.CFrame:Lerp(tHrp.CFrame * CFrame.new(0, 0, 4), 0.1)
                end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if not getgenv().PH_HUB_RUNNING then return end
    pcall(function()
        if _G.Settings.FOV     then Camera.FieldOfView                = _G.Settings.FOV     end
        if _G.Settings.MaxZoom then LocalPlayer.CameraMaxZoomDistance = _G.Settings.MaxZoom  end
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") and _G.Settings.SpeedEnabled then
            char.Humanoid.WalkSpeed = _G.Settings.CatSpeedValue
        end
        if _G.Settings.AimbotEnabled and not isTalking() and char then
            local myHrp = char:FindFirstChild("HumanoidRootPart")
            if myHrp then
                local target, dist = nil, _G.Settings.AimbotRange
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local head = p.Character:FindFirstChild("Head")
                        local hum  = p.Character:FindFirstChild("Humanoid")
                        if head and hum and hum.Health > 0 then
                            local mag = (head.Position - myHrp.Position).Magnitude
                            if mag < dist then dist = mag; target = head end
                        end
                    end
                end
                if target then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
                end
            end
        end
    end)
end)

RunService.Heartbeat:Connect(function()
    if not getgenv().PH_HUB_RUNNING then return end
    if _G.Settings.Invisible and inv_root and inv_hum then
        local old_cf     = inv_root.CFrame
        local old_offset = inv_hum.CameraOffset
        inv_root.CFrame  = old_cf * CFrame.new(0, -200000, 0)
        inv_hum.CameraOffset = inv_root.CFrame:ToObjectSpace(CFrame.new(old_cf.Position)).Position
        RunService.RenderStepped:Wait()
        if inv_root and inv_hum then
            inv_root.CFrame      = old_cf
            inv_hum.CameraOffset = old_offset
        end
    end
end)

-- ============================================================
--  鍵盤輸入
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe or not getgenv().PH_HUB_RUNNING then return end
    if input.KeyCode == Enum.KeyCode.G then
        _G.Settings.Invisible = not _G.Settings.Invisible
        if invToggle then invToggle:Set(_G.Settings.Invisible) end
        update_invisibility()
    end
end)

UserInputService.JumpRequest:Connect(function()
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum and (_G.Settings.InfJump or _G.Settings.SuperJumpEnabled) then
        if _G.Settings.SuperJumpEnabled then hum.JumpPower = _G.Settings.SuperJumpHeight end
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ============================================================
--  切換按鈕（貓咪圖示）
-- ============================================================
local sg = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
sg.Name, sg.ResetOnSpawn = "CatToggleGui", false

local toggleBtn = Instance.new("ImageButton", sg)
toggleBtn.Size             = UDim2.new(0, 45, 0, 45)
toggleBtn.Position         = UDim2.new(1, -70, 0.5, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
toggleBtn.Image            = "rbxassetid://7733960981"
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 12)
local btnStroke = Instance.new("UIStroke", toggleBtn)
btnStroke.Color, btnStroke.Thickness = Color3.fromRGB(255, 80, 160), 2

local tb_dragging, tb_dragStart, tb_startPos, tb_moved = false, nil, nil, false
local DRAG_THRESHOLD = 6

toggleBtn.InputBegan:Connect(function(input)
    local t = input.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        tb_dragging  = true
        tb_moved     = false
        tb_dragStart = input.Position
        tb_startPos  = toggleBtn.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    local t = input.UserInputType
    if tb_dragging and (t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch) then
        local delta = input.Position - tb_dragStart
        if delta.Magnitude > DRAG_THRESHOLD then tb_moved = true end
        if tb_moved then
            local vp   = Camera.ViewportSize
            local newX = math.clamp(tb_startPos.X.Offset + delta.X, 0, vp.X - 45)
            local newY = math.clamp(tb_startPos.Y.Offset + delta.Y, 0, vp.Y - 45)
            toggleBtn.Position = UDim2.new(0, newX, 0, newY)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    local t = input.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        tb_dragging = false
    end
end)

toggleBtn.MouseButton1Click:Connect(function()
    if tb_moved then tb_moved = false; return end
    local ui = LocalPlayer.PlayerGui:FindFirstChild("yuzia_X")
           or game:GetService("CoreGui"):FindFirstChild("yuzia_X")
    if ui then ui.Enabled = not ui.Enabled end
end)

-- ============================================================
--  初始化
-- ============================================================
init_inv_character()
LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart", 10)
    init_inv_character()
    if BUILTIN_ESP_ENABLED then
        for _, p in ipairs(Players:GetPlayers()) do
            createBuiltinESP(p)
        end
    end
    if NOCLIP_ENABLED then setNoclip(true) end
    DUNGEON.IsTeleporting = false  -- 角色重生時重置傳送狀態
end)

window:Toggle(true)

StarterGui:SetCore("SendNotification", {
    Title    = " yuzia_X ",
    Text     = " 歡迎使用 yuzia_X v4.3.1 ",
    Duration = 3
})
