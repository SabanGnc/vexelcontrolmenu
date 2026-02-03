--[[ 
    ============================================================
    VEXEL HUB | ULTIMATE EXTENDED v10.9 (RADAR ICON FIX & TRACERS)
    ============================================================
    Geliştirici: Gemini AI
    
    [GÜNCELLEMELER v10.9]
    + RADAR OKU İKONU DÜZELTİLDİ:
      - "Kağıt gibi" görünen bozuk ikon, net ve pürüzsüz standart beyaz bir ok ile değiştirildi.
      - Dönüş hassasiyeti ayarlandı.
      
    + YENİ ÖZELLİK: TRACERS (ÇİZGİ ESP):
      - "Görsel" sekmesine eklendi.
      - Ekranın altından oyunculara giden çizgiler çizer.
      - Drawing API kullanır (Yüksek performans).
      - Takım rengine (Dost/Düşman) göre renk değiştirir.

    [ÖNCEKİ ÖZELLİKLER]
    + ESP FIX (YENİ DOĞANLAR), AIMBOT, TRIGGER BOT...
    ============================================================
]]

-- // EXECUTOR KONTROLÜ (Drawing API için) // --
local DrawingApiSupported = (Drawing and typeof(Drawing) == "table" and Drawing.new)

-- // SERVİSLER // --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local VirtualUser = game:GetService("VirtualUser")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- // BAĞLANTI LİSTESİ // --
local Connections = {}
local Waypoints = {} 

-- // PERFORMANCE CACHE // --
local NPC_Cache = {} 
local UI_Storage = {}
local TracerCache = {} -- Tracers için cache

-- // DOSYA SİSTEMİ HAZIRLIK // --
local ConfigFolder = "VexelHub_Configs"
local function InitFileSystem()
    if not isfolder(ConfigFolder) then
        makefolder(ConfigFolder)
    end
end
pcall(InitFileSystem)

-- // TEMİZLİK // --
local CleanList = {"VexelHubUI", "VexelIntro", "VexelTracers", "VexelDevESP", "VexelFOV", "VexelArrowUI", "VexelRadar"}
for _, name in pairs(CleanList) do
    if CoreGui:FindFirstChild(name) then CoreGui[name]:Destroy() end
end

-- Tracers temizliği (Drawing objeleri için)
if DrawingApiSupported then
    for i,v in pairs(workspace:GetDescendants()) do
        if v.Name == "VexelTracer" then v:Remove() end
    end
end

-- // AYARLAR (CONFIG) // --
local Config = {
    -- UI
    UIToggleKey = Enum.KeyCode.F1,
    AnonymousMode = false,

    -- Aimbot
    AimbotOn = false,
    AimbotToggleKey = Enum.KeyCode.RightShift, 
    AimPart = "Head", 
    AimKey = Enum.UserInputType.MouseButton2,
    AimHoldMode = true,
    TeamCheck = false,
    WallCheck = false,
    AimSmooth = 1,
    AimFOV = 150,
    ShowFOV = false,
    StickyAim = true,
    Prediction = 0,
    
    -- Trigger Bot
    TriggerBot = false,
    TriggerKey = Enum.KeyCode.E,
    TriggerHoldMode = true,

    -- Karakter
    Speed = 16, SpeedOn = false, NoSlow = false,
    CFrameSpeed = 1, CFrameWalk = false,
    Jump = 50, JumpOn = false, AutoJump = false,
    InfJump = false,
    
    -- Fizik
    Fly = false, FlySpeed = 50, FlyKey = Enum.KeyCode.F,
    GravityOn = false, GravityVal = 196.2,
    NoclipPlayer = false,
    NoclipVehicle = false,
    Jesus = false, Spider = false,
    SafeFall = false, AntiFling = false,
    AirWalk = false,
    AntiVoid = false,
    
    -- Araçlar
    VehicleFly = false, VehFlySpeed = 100,
    AutoClicker = false, ClickKey = Enum.KeyCode.RightAlt, CPS = 10,
    AutoUse = false, InstantPrompt = false, 
    InstantKey = Enum.KeyCode.Q, InstantKeyOn = false,
    ToolBring = false,
    
    -- Görsel (ESP BASİT AYARLAR)
    ESP_Highlight = false,
    ESP_NameTag = false,
    ESP_Health = false,
    ESP_Tracers = false, -- Yeni Özellik
    ESP_MaxDist = 1000,
    
    ESP_NamePos = "Top",    -- Top, Bottom, Left, Right
    ESP_NameSize = 14,
    ESP_BarPos = "Left",    -- Top, Bottom, Left, Right
    ESP_BarSize = 5,       
    
    NoFog = false, TimeChange = false, Time = 14,
    Fullbright = false,
    XRay = false, CamFOV = 70, InfZoom = false,
    Freecam = false, FreecamSpeed = 1, FreecamKey = Enum.KeyCode.P,
    HUD_Active = false, HUD_Pos = 1,
    RadarActive = false,
    
    -- Diğer
    ClickTP = false, KeyTP = false,
    ClickDelete = false,
    ChatSpam = false, SpamMsg = "Vexel Hub v10.9!",
    ChatSpy = false, 
    AntiAFK = false, 
    AutoRejoin = false, 
    Spectating = false,
    
    -- Oyuncu
    LoopFollow = false, FollowDist = 4,
    MonitorActive = false,
    
    -- Koruma
    AntiRagdoll = false,

    -- Developer
    DevInspector = false,
    ViewDeletable = false,
    ShowCoords = false,
    NPC_ESP = false,
    CombatSpy = false,
}

-- // FOV DAİRESİ // --
local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "VexelFOV"
FOVGui.Parent = CoreGui
FOVGui.IgnoreGuiInset = true
local FOVCircle = Instance.new("Frame")
FOVCircle.Parent = FOVGui
FOVCircle.Name = "Circle"
FOVCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.Visible = false
local FOVStroke = Instance.new("UIStroke")
FOVStroke.Parent = FOVCircle
FOVStroke.Color = Color3.fromRGB(115, 0, 255)
FOVStroke.Thickness = 2
FOVStroke.Transparency = 0.5
local FOVCorner = Instance.new("UICorner")
FOVCorner.Parent = FOVCircle
FOVCorner.CornerRadius = UDim.new(1, 0)

-- // RADAR PANELİ // --
local RadarGui = Instance.new("ScreenGui")
RadarGui.Name = "VexelRadar"
RadarGui.Parent = CoreGui
RadarGui.IgnoreGuiInset = true
RadarGui.DisplayOrder = 100

local RadarFrame = Instance.new("Frame")
RadarFrame.Name = "RadarFrame"
RadarFrame.Parent = RadarGui
RadarFrame.Size = UDim2.new(0, 140, 0, 140)
RadarFrame.Position = UDim2.new(0.5, -70, 0.8, -70)
RadarFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
RadarFrame.BackgroundTransparency = 0.2
RadarFrame.Visible = false
local RCorner = Instance.new("UICorner"); RCorner.CornerRadius = UDim.new(0, 12); RCorner.Parent = RadarFrame
local RStroke = Instance.new("UIStroke"); RStroke.Parent = RadarFrame; RStroke.Color = Color3.fromRGB(115, 0, 255); RStroke.Thickness = 2

-- Radar Sürükleme
local rmd, rmdi, rmds, rmsp
RadarFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        rmd = true; rmds = input.Position; rmsp = RadarFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then rmd = false end end)
    end
end)
RadarFrame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then rmdi = input end end)
UserInputService.InputChanged:Connect(function(input) if input == rmdi and rmd then local delta = input.Position - rmds; RadarFrame.Position = UDim2.new(rmsp.X.Scale, rmsp.X.Offset + delta.X, rmsp.Y.Scale, rmsp.Y.Offset + delta.Y) end end)

local RadarArrow = Instance.new("ImageLabel")
RadarArrow.Parent = RadarFrame
RadarArrow.Size = UDim2.new(0, 40, 0, 40) -- Boyut biraz küçültüldü ki daha net dursun
RadarArrow.AnchorPoint = Vector2.new(0.5, 0.5)
RadarArrow.Position = UDim2.new(0.5, 0, 0.5, 0)
RadarArrow.BackgroundTransparency = 1
RadarArrow.Image = "rbxassetid://5897762897" -- NET BEYAZ OK İKONU (Düzeltildi)
RadarArrow.ImageColor3 = Color3.fromRGB(255, 255, 255)

local RadarName = Instance.new("TextLabel")
RadarName.Parent = RadarFrame
RadarName.Size = UDim2.new(1, -10, 0, 20)
RadarName.Position = UDim2.new(0, 5, 0.7, 0)
RadarName.BackgroundTransparency = 1
RadarName.Text = "Target"
RadarName.TextColor3 = Color3.fromRGB(255, 255, 255)
RadarName.Font = Enum.Font.GothamBold
RadarName.TextSize = 13

local RadarHP = Instance.new("TextLabel")
RadarHP.Parent = RadarFrame
RadarHP.Size = UDim2.new(1, -10, 0, 20)
RadarHP.Position = UDim2.new(0, 5, 0.85, 0)
RadarHP.BackgroundTransparency = 1
RadarHP.Text = "100%"
RadarHP.TextColor3 = Color3.fromRGB(100, 255, 100)
RadarHP.Font = Enum.Font.Code
RadarHP.TextSize = 13

-- // INTRO ANIMASYONU // --
local function PlayIntro()
    local IntroGui = Instance.new("ScreenGui")
    IntroGui.Name = "VexelIntro"
    IntroGui.Parent = CoreGui
    IntroGui.IgnoreGuiInset = true
    IntroGui.DisplayOrder = 1000
    
    local Back = Instance.new("Frame", IntroGui)
    Back.Size = UDim2.new(1,0,1,0)
    Back.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Back.BorderSizePixel = 0
    Back.ZIndex = 9999
    
    local TextContainer = Instance.new("Frame", Back)
    TextContainer.Size = UDim2.new(0, 400, 0, 100)
    TextContainer.Position = UDim2.new(0.5, -200, 0.5, -50)
    TextContainer.BackgroundTransparency = 1
    TextContainer.ZIndex = 10000
    
    local Letters = {"V", "E", "X", "E", "L"}
    local Objs = {}
    
    local layout = Instance.new("UIListLayout", TextContainer)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 15)
    
    for _, l in pairs(Letters) do
        local lbl = Instance.new("TextLabel", TextContainer)
        lbl.Text = l
        lbl.TextColor3 = Color3.fromRGB(115, 0, 255)
        lbl.Font = Enum.Font.GothamBlack
        lbl.TextSize = 60
        lbl.TextTransparency = 1 
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(0, 60, 0, 80)
        lbl.ZIndex = 10001
        table.insert(Objs, lbl)
    end
    
    task.wait(0.5)
    
    for _, lbl in pairs(Objs) do
        lbl.Position = UDim2.new(0, 0, 0, 20)
        TweenService:Create(lbl, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0, Position = UDim2.new(0,0,0,0)}):Play()
        task.wait(0.2)
    end
    
    task.wait(1.5)
    
    TweenService:Create(Back, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
    for _, lbl in pairs(Objs) do
        TweenService:Create(lbl, TweenInfo.new(0.5), {TextTransparency = 1, Position = UDim2.new(0,0,0,-20)}):Play()
    end
    
    task.wait(1)
    IntroGui:Destroy()
end

PlayIntro()

-- // UI OLUŞTURMA // --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VexelHubUI"
ScreenGui.Parent = CoreGui
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999

-- Dev Inspector GUI
local DevGUI = Instance.new("ScreenGui")
DevGUI.Name = "VexelDevESP"
DevGUI.Parent = CoreGui
DevGUI.IgnoreGuiInset = true
local DevLabel = Instance.new("TextLabel")
DevLabel.Parent = DevGUI
DevLabel.Size = UDim2.new(0, 300, 0, 100)
DevLabel.Position = UDim2.new(0, 20, 0, 100)
DevLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
DevLabel.BorderColor3 = Color3.fromRGB(115, 0, 255)
DevLabel.BorderSizePixel = 2
DevLabel.Visible = false
DevLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DevLabel.TextSize = 14
DevLabel.Font = Enum.Font.Code
DevLabel.TextXAlignment = Enum.TextXAlignment.Left
DevLabel.TextYAlignment = Enum.TextYAlignment.Top
local DevPad = Instance.new("UIPadding", DevLabel)
DevPad.PaddingLeft = UDim.new(0, 5)
DevPad.PaddingTop = UDim.new(0, 5)

-- STATS HUD
local StatsHUD = Instance.new("Frame")
StatsHUD.Name = "StatsHUD"
StatsHUD.Parent = ScreenGui
StatsHUD.Size = UDim2.new(0, 160, 0, 55)
StatsHUD.Position = UDim2.new(0, 20, 0, 20)
StatsHUD.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
StatsHUD.Visible = false
local HUDCorner = Instance.new("UICorner"); HUDCorner.CornerRadius = UDim.new(0, 8); HUDCorner.Parent = StatsHUD
local HUDStroke = Instance.new("UIStroke"); HUDStroke.Parent = StatsHUD; HUDStroke.Color = Color3.fromRGB(115, 0, 255); HUDStroke.Thickness = 2

local FPSLabel = Instance.new("TextLabel")
FPSLabel.Parent = StatsHUD
FPSLabel.Size = UDim2.new(1, -10, 0.5, 0)
FPSLabel.Position = UDim2.new(0, 10, 0, 0)
FPSLabel.BackgroundTransparency = 1
FPSLabel.Text = "FPS: 60"
FPSLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FPSLabel.Font = Enum.Font.GothamBold
FPSLabel.TextSize = 14
FPSLabel.TextXAlignment = Enum.TextXAlignment.Left

local PingLabel = Instance.new("TextLabel")
PingLabel.Parent = StatsHUD
PingLabel.Size = UDim2.new(1, -10, 0.5, 0)
PingLabel.Position = UDim2.new(0, 10, 0.5, 0)
PingLabel.BackgroundTransparency = 1
PingLabel.Text = "Ping: 50 ms"
PingLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
PingLabel.Font = Enum.Font.Gotham
PingLabel.TextSize = 14
PingLabel.TextXAlignment = Enum.TextXAlignment.Left

-- PLAYER MONITOR
local MonFrame = Instance.new("Frame")
MonFrame.Name = "PlayerMonitor"
MonFrame.Parent = ScreenGui
MonFrame.Size = UDim2.new(0, 260, 0, 160)
MonFrame.Position = UDim2.new(1, -280, 0.5, -80)
MonFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MonFrame.Visible = false
local MonCorner = Instance.new("UICorner"); MonCorner.CornerRadius = UDim.new(0, 10); MonCorner.Parent = MonFrame
local MonStroke = Instance.new("UIStroke"); MonStroke.Parent = MonFrame; MonStroke.Color = Color3.fromRGB(115, 0, 255); MonStroke.Thickness = 3

-- Monitor Sürükleme
local md, mdi, mds, msp
MonFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        md = true; mds = input.Position; msp = MonFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then md = false end end)
    end
end)
MonFrame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then mdi = input end end)
UserInputService.InputChanged:Connect(function(input) if input == mdi and md then local delta = input.Position - mds; MonFrame.Position = UDim2.new(msp.X.Scale, msp.X.Offset + delta.X, msp.Y.Scale, msp.Y.Offset + delta.Y) end end)

local MonTitle = Instance.new("TextLabel")
MonTitle.Parent = MonFrame
MonTitle.Text = "CASUS PANELİ"
MonTitle.Size = UDim2.new(1, 0, 0, 30)
MonTitle.BackgroundTransparency = 1
MonTitle.TextColor3 = Color3.fromRGB(160, 80, 255)
MonTitle.Font = Enum.Font.GothamBlack
MonTitle.TextSize = 18

local MonName = Instance.new("TextLabel")
MonName.Parent = MonFrame
MonName.Text = "İsim: Yok"
MonName.Size = UDim2.new(1, -20, 0, 25)
MonName.Position = UDim2.new(0, 15, 0, 35)
MonName.BackgroundTransparency = 1
MonName.TextColor3 = Color3.fromRGB(255, 255, 255)
MonName.Font = Enum.Font.GothamBold
MonName.TextSize = 16
MonName.TextXAlignment = Enum.TextXAlignment.Left

local MonHealth = Instance.new("TextLabel")
MonHealth.Parent = MonFrame
MonHealth.Text = "Can: N/A"
MonHealth.Size = UDim2.new(1, -20, 0, 25)
MonHealth.Position = UDim2.new(0, 15, 0, 60)
MonHealth.BackgroundTransparency = 1
MonHealth.TextColor3 = Color3.fromRGB(200, 255, 200)
MonHealth.Font = Enum.Font.Gotham
MonHealth.TextSize = 16
MonHealth.TextXAlignment = Enum.TextXAlignment.Left

local MonTeam = Instance.new("TextLabel")
MonTeam.Parent = MonFrame
MonTeam.Text = "Takım: -"
MonTeam.Size = UDim2.new(1, -20, 0, 25)
MonTeam.Position = UDim2.new(0, 15, 0, 85)
MonTeam.BackgroundTransparency = 1
MonTeam.TextColor3 = Color3.fromRGB(255, 255, 100)
MonTeam.Font = Enum.Font.Gotham
MonTeam.TextSize = 16
MonTeam.TextXAlignment = Enum.TextXAlignment.Left

local MonTool = Instance.new("TextLabel")
MonTool.Parent = MonFrame
MonTool.Text = "Eşya: Yok"
MonTool.Size = UDim2.new(1, -20, 0, 25)
MonTool.Position = UDim2.new(0, 15, 0, 110)
MonTool.BackgroundTransparency = 1
MonTool.TextColor3 = Color3.fromRGB(200, 200, 255)
MonTool.Font = Enum.Font.Gotham
MonTool.TextSize = 16
MonTool.TextXAlignment = Enum.TextXAlignment.Left

local MonDist = Instance.new("TextLabel")
MonDist.Parent = MonFrame
MonDist.Text = "Mesafe: 0m"
MonDist.Size = UDim2.new(1, -20, 0, 25)
MonDist.Position = UDim2.new(0, 15, 0, 135)
MonDist.BackgroundTransparency = 1
MonDist.TextColor3 = Color3.fromRGB(255, 200, 100)
MonDist.Font = Enum.Font.Gotham
MonDist.TextSize = 16
MonDist.TextXAlignment = Enum.TextXAlignment.Left

local function Notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title; Text = text; Duration = 3;})
    end)
end

-- PANIC BUTTON
local function FullShutdown()
    ScreenGui:Destroy()
    DevGUI:Destroy()
    FOVGui:Destroy()
    RadarGui:Destroy()
    
    -- Tracers temizle
    if DrawingApiSupported then
        for _, line in pairs(TracerCache) do
            if line and line.Remove then line:Remove() end
        end
    end
    TracerCache = {}

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        if LocalPlayer.Character.HumanoidRootPart:FindFirstChild("VexelStabilizer") then
            LocalPlayer.Character.HumanoidRootPart.VexelStabilizer:Destroy()
        end
    end

    if LocalPlayer.Character then
        for _, p in pairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Transparency = 0 end
        end
    end

    Camera.CameraType = Enum.CameraType.Custom
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default 
    workspace.Gravity = 196.2 
    if LocalPlayer.Character then 
        Camera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid") 
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then root.Anchored = false end
    end
    
    Lighting.Brightness = 1
    Lighting.ClockTime = 14
    Lighting.FogEnd = 10000
    
    for _, conn in pairs(Connections) do
        if conn then conn:Disconnect() end
    end
    
    if LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if root then
            if root:FindFirstChild("VexelFlyBV") then root.VexelFlyBV:Destroy() end
            if root:FindFirstChild("VexelFlyBG") then root.VexelFlyBG:Destroy() end
            root.Anchored = false
        end
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum.PlatformStand = false
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        end
    end
    
    for _, v in pairs(workspace:GetDescendants()) do
        if v:FindFirstChild("VexelNPC_ESP") then v.VexelNPC_ESP:Destroy() end
    end

    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            if p.Character:FindFirstChild("VexelHighlight") then p.Character.VexelHighlight:Destroy() end
            if p.Character:FindFirstChild("Head") and p.Character.Head:FindFirstChild("VexelNameTag") then p.Character.Head.VexelNameTag:Destroy() end
        end
    end

    print("Vexel Hub Tamamen Kapatıldı.")
end

-- [MENÜ AÇ/KAPAT TUŞU]
table.insert(Connections, UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Config.UIToggleKey then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
    -- [AIMBOT TOGGLE KEY]
    if input.KeyCode == Config.AimbotToggleKey then
        Config.AimbotOn = not Config.AimbotOn
        if Config.AimbotOn then Notify("Aimbot", "AKTİF") else Notify("Aimbot", "PASİF") end
    end
end))

-- ANA PENCERE
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.Position = UDim2.new(0.5, -350, 0.5, -275)
MainFrame.Size = UDim2.new(0, 700, 0, 550)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true 
MainFrame.Visible = true 

local UICorner = Instance.new("UICorner"); UICorner.CornerRadius = UDim.new(0, 12); UICorner.Parent = MainFrame
local UIStroke = Instance.new("UIStroke"); UIStroke.Parent = MainFrame; UIStroke.Color = Color3.fromRGB(115, 0, 255); UIStroke.Thickness = 4

-- AÇMA BUTONU
local OpenBtn = Instance.new("TextButton")
OpenBtn.Name = "OpenBtn"
OpenBtn.Parent = ScreenGui
OpenBtn.Size = UDim2.new(0, 120, 0, 45)
OpenBtn.Position = UDim2.new(0, 15, 0.5, -22)
OpenBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
OpenBtn.Text = "AÇ"
OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenBtn.Font = Enum.Font.GothamBlack
OpenBtn.TextSize = 18
OpenBtn.Visible = false 
OpenBtn.BorderSizePixel = 0
local OBCorner = Instance.new("UICorner"); OBCorner.CornerRadius = UDim.new(0, 8); OBCorner.Parent = OpenBtn
local OBStroke = Instance.new("UIStroke"); OBStroke.Parent = OpenBtn; OBStroke.Color = Color3.fromRGB(115, 0, 255); OBStroke.Thickness = 3

OpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    OpenBtn.Visible = false
end)

-- ÜST BAŞLIK & PROFİL
local TitleBar = Instance.new("Frame")
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
TitleBar.Size = UDim2.new(1, 0, 0, 50) 
TitleBar.BorderSizePixel = 0
local TitleCorner = Instance.new("UICorner"); TitleCorner.CornerRadius = UDim.new(0, 12); TitleCorner.Parent = TitleBar

local ProfileImg = Instance.new("ImageLabel")
ProfileImg.Parent = TitleBar
ProfileImg.Size = UDim2.new(0, 36, 0, 36)
ProfileImg.Position = UDim2.new(0, 10, 0.5, -18)
ProfileImg.BackgroundColor3 = Color3.fromRGB(40,40,40)
ProfileImg.BackgroundTransparency = 0
ProfileImg.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
local PCorner = Instance.new("UICorner"); PCorner.CornerRadius = UDim.new(1, 0); PCorner.Parent = ProfileImg 
local PStroke = Instance.new("UIStroke"); PStroke.Parent = ProfileImg; PStroke.Color = Color3.fromRGB(115,0,255); PStroke.Thickness = 2; PStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local ProfileName = Instance.new("TextLabel")
ProfileName.Parent = TitleBar
ProfileName.Text = LocalPlayer.Name
ProfileName.Size = UDim2.new(0, 200, 0, 20)
ProfileName.Position = UDim2.new(0, 55, 0.5, -10)
ProfileName.BackgroundTransparency = 1
ProfileName.TextColor3 = Color3.fromRGB(200, 200, 200)
ProfileName.Font = Enum.Font.GothamBold
ProfileName.TextSize = 14
ProfileName.TextXAlignment = Enum.TextXAlignment.Left

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Parent = TitleBar
TitleLbl.Text = "Vexel Hub - <font color=\"rgb(150,50,255)\">v10.9</font>"
TitleLbl.RichText = true
TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLbl.TextSize = 18
TitleLbl.Font = Enum.Font.GothamBlack
TitleLbl.Size = UDim2.new(0, 200, 1, 0)
TitleLbl.Position = UDim2.new(0.5, -100, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.TextXAlignment = Enum.TextXAlignment.Center
TitleLbl.ZIndex = 2

local MinBtn = Instance.new("TextButton")
MinBtn.Parent = TitleBar
MinBtn.Size = UDim2.new(0, 30, 0, 24)
MinBtn.Position = UDim2.new(1, -145, 0.5, -12)
MinBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 18
local MCorner = Instance.new("UICorner"); MCorner.CornerRadius = UDim.new(0,6); MCorner.Parent = MinBtn

MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenBtn.Visible = true
end)

local PanicBtn = Instance.new("TextButton")
PanicBtn.Parent = TitleBar
PanicBtn.Size = UDim2.new(0, 100, 0, 24)
PanicBtn.Position = UDim2.new(1, -110, 0.5, -12)
PanicBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
PanicBtn.Text = "HİLEYİ SİL"
PanicBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PanicBtn.Font = Enum.Font.GothamBold
PanicBtn.TextSize = 12
local PCorner = Instance.new("UICorner"); PCorner.CornerRadius = UDim.new(0,6); PCorner.Parent = PanicBtn

PanicBtn.MouseButton1Click:Connect(FullShutdown)

-- [UI DRAG FIX]
local dragging, dragInput, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local TabContainer = Instance.new("ScrollingFrame")
TabContainer.Parent = MainFrame
TabContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
TabContainer.Position = UDim2.new(0, 0, 0, 50)
TabContainer.Size = UDim2.new(1, 0, 0, 45)
TabContainer.BorderSizePixel = 0
TabContainer.ZIndex = 0
TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
TabContainer.AutomaticCanvasSize = Enum.AutomaticSize.X
TabContainer.ScrollBarThickness = 0
TabContainer.ScrollingDirection = Enum.ScrollingDirection.X

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.Parent = TabContainer
TabListLayout.FillDirection = Enum.FillDirection.Horizontal
TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 5)

local TabPadding = Instance.new("UIPadding")
TabPadding.Parent = TabContainer
TabPadding.PaddingLeft = UDim.new(0, 10)
TabPadding.PaddingTop = UDim.new(0, 5)

local ContentArea = Instance.new("Frame")
ContentArea.Parent = MainFrame
ContentArea.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
ContentArea.Position = UDim2.new(0, 0, 0, 95)
ContentArea.Size = UDim2.new(1, 0, 1, -95)
ContentArea.BorderSizePixel = 0
ContentArea.ClipsDescendants = true
local ContentCorner = Instance.new("UICorner"); ContentCorner.CornerRadius = UDim.new(0, 12); ContentCorner.Parent = ContentArea

local tabs = {}
local pages = {}

local function CreateTab(name)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Parent = TabContainer
    TabBtn.Text = name
    TabBtn.Size = UDim2.new(0, 95, 0.9, 0)
    TabBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    TabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.TextSize = 13
    TabBtn.BorderSizePixel = 0
    local TabCorner = Instance.new("UICorner"); TabCorner.CornerRadius = UDim.new(0, 8); TabCorner.Parent = TabBtn
    
    local Indicator = Instance.new("Frame")
    Indicator.Parent = TabBtn
    Indicator.BackgroundColor3 = Color3.fromRGB(115, 0, 255)
    Indicator.Size = UDim2.new(0, 0, 0, 3)
    Indicator.Position = UDim2.new(0.5, 0, 1, -3)
    Indicator.BorderSizePixel = 0
    
    local TabPage = Instance.new("ScrollingFrame")
    TabPage.Parent = ContentArea
    TabPage.Size = UDim2.new(1, 0, 1, 0)
    TabPage.BackgroundTransparency = 1
    TabPage.Visible = false
    TabPage.ScrollBarThickness = 4
    TabPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabPage.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local PList = Instance.new("UIListLayout"); PList.Parent = TabPage; PList.Padding = UDim.new(0, 10); PList.HorizontalAlignment = Enum.HorizontalAlignment.Center; PList.SortOrder = Enum.SortOrder.LayoutOrder
    local PPad = Instance.new("UIPadding"); PPad.Parent = TabPage; PPad.PaddingTop = UDim.new(0,15); PPad.PaddingBottom = UDim.new(0, 20)
    
    table.insert(tabs, {Btn = TabBtn, Ind = Indicator})
    table.insert(pages, TabPage)
    
    return TabBtn, TabPage
end

local Tab_Main, Page_Main = CreateTab("Karakter")
local Tab_Aimbot, Page_Aimbot = CreateTab("Aimbot") 
local Tab_Physics, Page_Physics = CreateTab("Fizik") 
local Tab_Tools, Page_Tools = CreateTab("Araçlar")
local Tab_Visual, Page_Visual = CreateTab("Görsel")
local Tab_Player, Page_Player = CreateTab("Oyuncu")
local Tab_Developer, Page_Developer = CreateTab("Developer")
local Tab_Misc, Page_Misc = CreateTab("Diğer")
local Tab_Settings, Page_Settings = CreateTab("Ayarlar")

local function SwitchTab(btn, page)
    for _, p in pairs(pages) do p.Visible = false end
    for _, t in pairs(tabs) do 
        TweenService:Create(t.Btn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(150,150,150), BackgroundColor3 = Color3.fromRGB(25,25,30)}):Play()
        TweenService:Create(t.Ind, TweenInfo.new(0.2), {Size = UDim2.new(0,0,0,3), Position = UDim2.new(0.5,0,1,-3)}):Play()
    end
    page.Visible = true
    TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255,255,255), BackgroundColor3 = Color3.fromRGB(35,35,40)}):Play()
    local ind = btn:FindFirstChild("Frame")
    if ind then TweenService:Create(ind, TweenInfo.new(0.2), {Size = UDim2.new(0.8,0,0,3), Position = UDim2.new(0.1,0,1,-3)}):Play() end
end

Tab_Main.MouseButton1Click:Connect(function() SwitchTab(Tab_Main, Page_Main) end)
Tab_Aimbot.MouseButton1Click:Connect(function() SwitchTab(Tab_Aimbot, Page_Aimbot) end)
Tab_Physics.MouseButton1Click:Connect(function() SwitchTab(Tab_Physics, Page_Physics) end)
Tab_Tools.MouseButton1Click:Connect(function() SwitchTab(Tab_Tools, Page_Tools) end)
Tab_Visual.MouseButton1Click:Connect(function() SwitchTab(Tab_Visual, Page_Visual) end)
Tab_Player.MouseButton1Click:Connect(function() SwitchTab(Tab_Player, Page_Player) end)
Tab_Developer.MouseButton1Click:Connect(function() SwitchTab(Tab_Developer, Page_Developer) end)
Tab_Misc.MouseButton1Click:Connect(function() SwitchTab(Tab_Misc, Page_Misc) end)
Tab_Settings.MouseButton1Click:Connect(function() SwitchTab(Tab_Settings, Page_Settings) end)
SwitchTab(Tab_Main, Page_Main)

local function CreateSection(parent, text)
    local Label = Instance.new("TextLabel")
    Label.Parent = parent
    Label.Text = "  " .. text
    Label.Size = UDim2.new(0.95, 0, 0, 30)
    Label.BackgroundTransparency = 1
    Label.TextColor3 = Color3.fromRGB(160, 80, 255)
    Label.Font = Enum.Font.GothamBlack
    Label.TextSize = 16
    Label.TextXAlignment = Enum.TextXAlignment.Left
end

local function CreateToggle(parent, text, callback)
    local Frame = Instance.new("Frame")
    Frame.Parent = parent
    Frame.Size = UDim2.new(0.95, 0, 0, 40)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(0,8); Corner.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Parent = Frame; Label.Text = text; Label.TextColor3 = Color3.fromRGB(255,255,255); Label.Font = Enum.Font.GothamBold; Label.TextSize = 14
    Label.Position = UDim2.new(0, 10, 0, 0); Label.Size = UDim2.new(0.7, 0, 1, 0); Label.BackgroundTransparency = 1; Label.TextXAlignment = Enum.TextXAlignment.Left
    
    local Button = Instance.new("TextButton")
    Button.Parent = Frame; Button.Size = UDim2.new(0, 40, 0, 24); Button.Position = UDim2.new(1, -50, 0.5, -12); Button.BackgroundColor3 = Color3.fromRGB(50,50,50); Button.Text = ""
    local BtnCorner = Instance.new("UICorner"); BtnCorner.CornerRadius = UDim.new(0,12); BtnCorner.Parent = Button
    
    local Dot = Instance.new("Frame")
    Dot.Parent = Button; Dot.Size = UDim2.new(0, 20, 0, 20); Dot.Position = UDim2.new(0, 2, 0.5, -10); Dot.BackgroundColor3 = Color3.fromRGB(200,200,200)
    local DotCorner = Instance.new("UICorner"); DotCorner.CornerRadius = UDim.new(1,0); DotCorner.Parent = Dot
    
    local enabled = false
    
    local function SetState(val)
        enabled = val
        if enabled then
            TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(115, 0, 255)}):Play()
            TweenService:Create(Dot, TweenInfo.new(0.2), {Position = UDim2.new(1, -22, 0.5, -10)}):Play()
        else
            TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50,50,50)}):Play()
            TweenService:Create(Dot, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -10)}):Play()
        end
        callback(enabled)
    end
    
    Button.MouseButton1Click:Connect(function()
        SetState(not enabled)
    end)
    
    table.insert(UI_Storage, {Type = "Toggle", Name = text, Get = function() return enabled end, Set = SetState})
end

local function CreateSlider(parent, text, min, max, default, callback)
    local Frame = Instance.new("Frame")
    Frame.Parent = parent
    Frame.Size = UDim2.new(0.95, 0, 0, 55)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(0,8); Corner.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Parent = Frame; Label.Text = text; Label.TextColor3 = Color3.fromRGB(255,255,255); Label.Font = Enum.Font.GothamBold; Label.TextSize = 14
    Label.Position = UDim2.new(0, 10, 0, 5); Label.BackgroundTransparency = 1; Label.TextXAlignment = Enum.TextXAlignment.Left
    
    local ValLabel = Instance.new("TextLabel")
    ValLabel.Parent = Frame; ValLabel.Text = tostring(default); ValLabel.TextColor3 = Color3.fromRGB(115, 0, 255); ValLabel.Font = Enum.Font.GothamBold; ValLabel.TextSize = 14
    ValLabel.Position = UDim2.new(1, -40, 0, 5); ValLabel.BackgroundTransparency = 1
    
    local Bar = Instance.new("Frame"); Bar.Parent = Frame; Bar.BackgroundColor3 = Color3.fromRGB(50,50,50); Bar.Size = UDim2.new(0.9, 0, 0, 6); Bar.Position = UDim2.new(0.05, 0, 0.7, 0)
    local BarC = Instance.new("UICorner"); BarC.CornerRadius = UDim.new(1,0); BarC.Parent = Bar
    
    local Fill = Instance.new("Frame"); Fill.Parent = Bar; Fill.BackgroundColor3 = Color3.fromRGB(115, 0, 255); Fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
    local FillC = Instance.new("UICorner"); FillC.CornerRadius = UDim.new(1,0); FillC.Parent = Fill
    
    local Trigger = Instance.new("TextButton"); Trigger.Parent = Bar; Trigger.BackgroundTransparency = 1; Trigger.Size = UDim2.new(1,0,1,0); Trigger.Text = ""
    
    local currentValue = default
    local sliding = false
    
    local function SetValue(val)
        currentValue = math.clamp(val, min, max)
        local pos = (currentValue - min) / (max - min)
        Fill.Size = UDim2.new(pos, 0, 1, 0)
        
        local displayVal = currentValue
        if max > 5 then displayVal = math.floor(displayVal) else displayVal = math.floor(displayVal*100)/100 end
        ValLabel.Text = tostring(displayVal)
        
        callback(currentValue)
    end
    
    Trigger.MouseButton1Down:Connect(function() sliding = true end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end end)
    
    UserInputService.InputChanged:Connect(function(i)
        if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = math.clamp((i.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
            local val = (min + ((max-min)*pos))
            SetValue(val)
        end
    end)
    
    table.insert(UI_Storage, {Type = "Slider", Name = text, Get = function() return currentValue end, Set = SetValue})
end

local function CreateButton(parent, text, callback)
    local Button = Instance.new("TextButton")
    Button.Parent = parent
    Button.Size = UDim2.new(0.95, 0, 0, 35)
    Button.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    Button.Text = text; Button.TextColor3 = Color3.fromRGB(255,255,255); Button.Font = Enum.Font.GothamBold; Button.TextSize = 14
    local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(0,8); Corner.Parent = Button
    
    Button.MouseButton1Click:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(115, 0, 255)}):Play()
        task.wait(0.15)
        TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(45, 45, 50)}):Play()
        callback()
    end)
end

local function CreateKeybind(parent, text, defaultKey, callback)
    local Frame = Instance.new("Frame"); Frame.Parent = parent; Frame.Size = UDim2.new(0.95, 0, 0, 40); Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(0,8); Corner.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Parent = Frame; Label.Text = text; Label.TextColor3 = Color3.fromRGB(255,255,255); Label.Font = Enum.Font.GothamBold; Label.TextSize = 14
    Label.Position = UDim2.new(0, 10, 0, 0); Label.Size = UDim2.new(0.6, 0, 1, 0); Label.BackgroundTransparency = 1; Label.TextXAlignment = Enum.TextXAlignment.Left
    
    local Button = Instance.new("TextButton")
    Button.Parent = Frame; Button.Size = UDim2.new(0, 80, 0, 24); Button.Position = UDim2.new(1, -90, 0.5, -12); Button.BackgroundColor3 = Color3.fromRGB(50,50,50); Button.Text = defaultKey.Name
    Button.TextColor3 = Color3.fromRGB(115, 0, 255); Button.Font = Enum.Font.GothamBold; Button.TextSize = 13
    local BtnCorner = Instance.new("UICorner"); BtnCorner.CornerRadius = UDim.new(0,6); BtnCorner.Parent = Button
    
    local currentKey = defaultKey
    local listening = false
    
    local function SetKey(key)
        currentKey = key
        
        if key == Enum.UserInputType.MouseButton1 then Button.Text = "Mouse1"
        elseif key == Enum.UserInputType.MouseButton2 then Button.Text = "Mouse2"
        else Button.Text = key.Name end
        
        Button.TextColor3 = Color3.fromRGB(115, 0, 255)
        callback(key)
    end
    
    SetKey(defaultKey)
    
    Button.MouseButton1Click:Connect(function()
        listening = true
        Button.Text = "..."
        Button.TextColor3 = Color3.fromRGB(255,255,255)
    end)
    
    table.insert(Connections, UserInputService.InputBegan:Connect(function(input)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                listening = false; SetKey(input.KeyCode)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                listening = false; SetKey(input.UserInputType)
            end
        end
    end))
    
    table.insert(UI_Storage, {Type = "Keybind", Name = text, Get = function() return currentKey end, Set = SetKey})
end

local function CreateTextBox(parent, placeholder, callback)
    local Frame = Instance.new("Frame"); Frame.Parent = parent; Frame.Size = UDim2.new(0.95,0,0,40); Frame.BackgroundColor3 = Color3.fromRGB(30,30,35)
    local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(0,8); Corner.Parent = Frame
    local Box = Instance.new("TextBox"); Box.Parent = Frame; Box.Size = UDim2.new(1,-10,1,0); Box.Position = UDim2.new(0,5,0,0); Box.BackgroundTransparency = 1
    Box.TextColor3 = Color3.fromRGB(255,255,255); Box.PlaceholderText = placeholder; Box.PlaceholderColor3 = Color3.fromRGB(100,100,100); Box.Font = Enum.Font.Gotham; Box.TextSize = 14
    
    local function SetText(txt)
        Box.Text = txt
        callback(txt)
    end
    
    Box.FocusLost:Connect(function(enter) if enter then callback(Box.Text) end end)
    
    table.insert(UI_Storage, {Type = "TextBox", Name = placeholder, Get = function() return Box.Text end, Set = SetText})
end

local function CreateDropdown(parent, text, options, callback)
    local Frame = Instance.new("Frame"); Frame.Parent = parent; Frame.Size = UDim2.new(0.95, 0, 0, 60); Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(0,8); Corner.Parent = Frame
    
    local Label = Instance.new("TextLabel"); Label.Parent = Frame; Label.Text = text; Label.TextColor3 = Color3.fromRGB(255,255,255); Label.Font = Enum.Font.GothamBold; Label.TextSize = 14
    Label.Position = UDim2.new(0, 10, 0, 5); Label.BackgroundTransparency = 1; Label.TextXAlignment = Enum.TextXAlignment.Left
    
    local Button = Instance.new("TextButton"); Button.Parent = Frame; Button.Size = UDim2.new(0.9, 0, 0, 25); Button.Position = UDim2.new(0.05, 0, 0.5, 0); Button.BackgroundColor3 = Color3.fromRGB(50,50,50); Button.Text = options[1]
    Button.TextColor3 = Color3.fromRGB(200,200,200); Button.Font = Enum.Font.Gotham; Button.TextSize = 16 
    local BCorner = Instance.new("UICorner"); BCorner.CornerRadius = UDim.new(0,6); BCorner.Parent = Button
    
    local index = 1
    
    Button.MouseButton1Click:Connect(function()
        index = index + 1
        if index > #options then index = 1 end
        Button.Text = options[index]
        callback(options[index])
    end)
    
    table.insert(UI_Storage, {Type = "Dropdown", Name = text, Get = function() return options[index] end, Set = function(val) 
        for i,v in pairs(options) do if v == val then index = i; Button.Text = v; callback(v) end end
    end})
end

-- =====================================
-- AIMBOT SEKMESİ
-- =====================================
CreateSection(Page_Aimbot, "Genel Ayarlar")
CreateToggle(Page_Aimbot, "Aimbot Aktif", function(v) Config.AimbotOn = v end)
CreateKeybind(Page_Aimbot, "Kilitlenme Tuşu", Config.AimKey, function(k) Config.AimKey = k end)
CreateToggle(Page_Aimbot, "Hold Mode (Basılı Tut)", function(v) Config.AimHoldMode = v end) 
CreateKeybind(Page_Aimbot, "Aç/Kapa Kısayolu", Config.AimbotToggleKey, function(k) Config.AimbotToggleKey = k end)
CreateToggle(Page_Aimbot, "Sticky Aim (Hedefi Bırakma)", function(v) Config.StickyAim = v end)
CreateDropdown(Page_Aimbot, "Hedef Bölge", {"Head", "Torso", "Random"}, function(v) Config.AimPart = v end)

CreateSection(Page_Aimbot, "Trigger Bot")
CreateToggle(Page_Aimbot, "Trigger Bot Aktif", function(v) Config.TriggerBot = v end)
CreateKeybind(Page_Aimbot, "Trigger Tuşu", Config.TriggerKey, function(k) Config.TriggerKey = k end)
CreateToggle(Page_Aimbot, "Hold Mode (Basılı Tut)", function(v) Config.TriggerHoldMode = v end)

CreateSection(Page_Aimbot, "Kısıtlamalar")
CreateToggle(Page_Aimbot, "Team Check (Takım Kontrol)", function(v) Config.TeamCheck = v end)
CreateToggle(Page_Aimbot, "Wall Check (Görünürlük)", function(v) Config.WallCheck = v end)

CreateSection(Page_Aimbot, "Hassasiyet & Görsel")
CreateSlider(Page_Aimbot, "Smoothness (Yumuşaklık)", 0, 1, 1, function(v) Config.AimSmooth = v end)
CreateSlider(Page_Aimbot, "Prediction (Tahmin)", 0, 10, 0, function(v) Config.Prediction = v end)
CreateSlider(Page_Aimbot, "FOV Boyutu", 50, 800, 150, function(v) Config.AimFOV = v; FOVCircle.Size = UDim2.new(0, v*2, 0, v*2); FOVCircle.Position = UDim2.new(0.5, -v, 0.5, -v) end)
CreateToggle(Page_Aimbot, "FOV Dairesini Göster", function(v) Config.ShowFOV = v; FOVCircle.Visible = v end)

-- =====================================
-- DİĞER SEKMELER
-- =====================================

CreateSection(Page_Main, "Hareket")
CreateToggle(Page_Main, "Speed (Standart)", function(v) Config.SpeedOn = v; if not v and LocalPlayer.Character then LocalPlayer.Character.Humanoid.WalkSpeed = 16 end end)
CreateSlider(Page_Main, "Standart Hız", 16, 200, 16, function(v) Config.Speed = v end)

CreateSection(Page_Main, "Bypass Hareket")
CreateToggle(Page_Main, "CFrame Walk (Anti-Cheat)", function(v) Config.CFrameWalk = v end)
CreateSlider(Page_Main, "CFrame Hızı", 0.1, 5, 1, function(v) Config.CFrameSpeed = v end)

CreateSection(Page_Main, "Zıplama")
CreateToggle(Page_Main, "Yüksek Zıplama", function(v) 
    Config.JumpOn = v
    if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        hum.JumpPower = 50 
        hum.UseJumpPower = false
    end
end)
CreateToggle(Page_Main, "Infinite Jump (Havada Zıpla)", function(v) Config.InfJump = v end)
CreateSlider(Page_Main, "Zıplama Gücü", 50, 400, 50, function(v) Config.Jump = v end)

CreateSection(Page_Main, "Koruma")
CreateToggle(Page_Main, "Anti-Ragdoll/Knockback", function(v) Config.AntiRagdoll = v end)
CreateToggle(Page_Main, "Anti-Void (Boşluk Koruma)", function(v) Config.AntiVoid = v end)
CreateToggle(Page_Main, "Safe Fall (Fix)", function(v) Config.SafeFall = v end)
CreateToggle(Page_Main, "No Slow", function(v) Config.NoSlow = v end)
CreateToggle(Page_Main, "Anti-Fling", function(v) Config.AntiFling = v end)

CreateSection(Page_Physics, "Özel Güçler")
CreateToggle(Page_Physics, "Uçma (Fly) - INFINITE YIELD", function(v) 
    Config.Fly = v 
    if not v and LocalPlayer.Character then
         local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
         local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
         if root then
             if root:FindFirstChild("VexelFlyBV") then root.VexelFlyBV:Destroy() end
             if root:FindFirstChild("VexelFlyBG") then root.VexelFlyBG:Destroy() end
         end
         if hum then hum.PlatformStand = false end
    end
end)
CreateKeybind(Page_Physics, "Uçma Tuşu", Config.FlyKey, function(k) Config.FlyKey = k end)
CreateSlider(Page_Physics, "Fly Hızı", 10, 200, 50, function(v) Config.FlySpeed = v end)

CreateSection(Page_Physics, "Yerçekimi (Gravity)")
CreateToggle(Page_Physics, "Gravity Control", function(v) Config.GravityOn = v; if not v then workspace.Gravity = 196.2 end end)
CreateSlider(Page_Physics, "Gravity Force", 0, 500, 196, function(v) Config.GravityVal = v end)

CreateToggle(Page_Physics, "Noclip (OYUNCU)", function(v) 
    Config.NoclipPlayer = v
    if not v and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end)

CreateToggle(Page_Physics, "Noclip (ARAÇ)", function(v) 
    Config.NoclipVehicle = v
    if not v and LocalPlayer.Character and LocalPlayer.Character.Humanoid.SeatPart then
        local veh = LocalPlayer.Character.Humanoid.SeatPart.Parent
        for _, part in pairs(veh:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end)

CreateToggle(Page_Physics, "Jesus Mode", function(v) Config.Jesus = v end)
CreateToggle(Page_Physics, "Spider Man (Fix)", function(v) Config.Spider = v end)
CreateButton(Page_Physics, "Sit (Otur)", function() if LocalPlayer.Character then LocalPlayer.Character.Humanoid.Sit = true end end)

CreateSection(Page_Tools, "Auto Clicker")
CreateSlider(Page_Tools, "Hız (CPS)", 1, 50, 10, function(v) Config.CPS = v end)
CreateKeybind(Page_Tools, "Başlat/Durdur Tuşu", Config.ClickKey, function(k) Config.ClickKey = k end)
CreateToggle(Page_Tools, "Auto Use (Eşya Kullan)", function(v) Config.AutoUse = v end)

CreateSection(Page_Tools, "Eşya Işınlayıcı")
CreateToggle(Page_Tools, "Tool Bringer (Vakum)", function(v) Config.ToolBring = v end)

local ToolList = Instance.new("ScrollingFrame"); ToolList.Parent=Page_Tools; ToolList.Size=UDim2.new(0.95,0,0,150); ToolList.BackgroundColor3=Color3.fromRGB(25,25,30); ToolList.CanvasSize=UDim2.new(0,0,0,0); ToolList.AutomaticCanvasSize = Enum.AutomaticSize.Y
local ToolLayout = Instance.new("UIListLayout"); ToolLayout.Parent=ToolList; ToolLayout.Padding = UDim.new(0,5)
local ToolCorner = Instance.new("UICorner"); ToolCorner.Parent = ToolList

local function RefreshTools()
    for _,v in pairs(ToolList:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    for _,t in pairs(workspace:GetDescendants()) do
        if t:IsA("Tool") and t:FindFirstChild("Handle") then
            local b = Instance.new("TextButton", ToolList); b.Size=UDim2.new(1,-10,0,30); b.Text=t.Name; b.BackgroundColor3=Color3.fromRGB(40,40,45); b.TextColor3=Color3.fromRGB(255,255,255)
            Instance.new("UICorner", b).CornerRadius=UDim.new(0,6)
            b.MouseButton1Click:Connect(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = t.Handle.CFrame
                end
            end)
        end
    end
end
CreateButton(Page_Tools, "Listeyi Yenile", RefreshTools)

CreateSection(Page_Tools, "Ekstra")
CreateToggle(Page_Tools, "Instant Interact (Hızlı E)", function(v) Config.InstantPrompt = v end)

CreateToggle(Page_Tools, "Tuş Kullanımı (Aktif/Pasif)", function(v) Config.InstantKeyOn = v end)
CreateKeybind(Page_Tools, "Hızlı Etkileşim Tuşu", Config.InstantKey, function(k) Config.InstantKey = k end)

CreateToggle(Page_Tools, "Vehicle Fly", function(v) Config.VehicleFly = v end)
CreateSlider(Page_Tools, "Araç Uçuş Hızı", 10, 300, 100, function(v) Config.VehFlySpeed = v end)
CreateButton(Page_Tools, "Platform Oluştur", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local p = Instance.new("Part", workspace); p.Size=Vector3.new(10,1,10); p.Anchored=true; p.Position=LocalPlayer.Character.HumanoidRootPart.Position - Vector3.new(0,3.5,0); p.Color=Color3.fromRGB(115,0,255)
        Notify("Platform", "Oluşturuldu!")
    end
end)
CreateSlider(Page_Tools, "Kamera Açısı (FOV)", 70, 120, 70, function(v) Config.CamFOV = v end)

CreateSection(Page_Visual, "Bilgi Paneli")
CreateToggle(Page_Visual, "FPS/Ping HUD", function(v) Config.HUD_Active = v; StatsHUD.Visible = v end)
CreateButton(Page_Visual, "Konum Değiştir", function() 
    Config.HUD_Pos = Config.HUD_Pos + 1
    if Config.HUD_Pos > 4 then Config.HUD_Pos = 1 end
    if Config.HUD_Pos == 1 then StatsHUD.Position = UDim2.new(0, 20, 0, 20)
    elseif Config.HUD_Pos == 2 then StatsHUD.Position = UDim2.new(1, -180, 0, 20)
    elseif Config.HUD_Pos == 3 then StatsHUD.Position = UDim2.new(1, -180, 1, -75)
    elseif Config.HUD_Pos == 4 then StatsHUD.Position = UDim2.new(0, 20, 1, -75) end
end)

CreateSection(Page_Visual, "Görünüm İyileştirme")
CreateToggle(Page_Visual, "Fullbright (Aydınlık)", function(v) 
    Config.Fullbright = v 
    if not v then
        Lighting.Brightness = 1
        Lighting.ClockTime = 14
        Lighting.FogEnd = 10000
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
    end
end)

CreateSection(Page_Visual, "ESP (Oyuncular)")
CreateSlider(Page_Visual, "ESP Render Distance", 100, 5000, 1000, function(v) Config.ESP_MaxDist = v end)

CreateToggle(Page_Visual, "Chams (Highlight)", function(v) 
    Config.ESP_Highlight = v
    if not v then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("VexelHighlight") then
                p.Character.VexelHighlight:Destroy()
            end
        end
    end
end)

CreateToggle(Page_Visual, "Nametag (İsim)", function(v) 
    Config.ESP_NameTag = v
    if not v then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("Head") and p.Character.Head:FindFirstChild("VexelNameTag") then
                p.Character.Head.VexelNameTag:Destroy()
            end
        end
    end
end)

CreateToggle(Page_Visual, "Health Bar (Can)", function(v)
    Config.ESP_Health = v
    if not v then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("Head") and p.Character.Head:FindFirstChild("VexelNameTag") then
                 if p.Character.Head.VexelNameTag:FindFirstChild("HealthBar") then
                     p.Character.Head.VexelNameTag.HealthBar:Destroy()
                 end
            end
        end
    end
end)

-- [YENİ ÖZELLİK: TRACERS (ÇİZGİ ESP)]
CreateToggle(Page_Visual, "Tracers (Çizgi)", function(v) Config.ESP_Tracers = v end)

-- [BASİTLEŞTİRİLMİŞ ESP AYARLARI]
CreateDropdown(Page_Visual, "İsim Konumu", {"Top", "Bottom", "Right", "Left"}, function(v) Config.ESP_NamePos = v end)
CreateSlider(Page_Visual, "İsim Boyutu", 10, 30, 14, function(v) Config.ESP_NameSize = v end)

CreateDropdown(Page_Visual, "Can Barı Konumu", {"Left", "Right", "Top", "Bottom"}, function(v) Config.ESP_BarPos = v end)
CreateSlider(Page_Visual, "Can Barı Boyutu", 1, 10, 5, function(v) Config.ESP_BarSize = v end)

CreateToggle(Page_Visual, "Radar Paneli", function(v) Config.RadarActive = v; RadarFrame.Visible = v end)

CreateSection(Page_Visual, "Serbest Kamera")
CreateToggle(Page_Visual, "Freecam (Serbest)", function(v) 
    Config.Freecam = v 
    if v then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.Anchored = true
        end
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default 
        Camera.CameraType = Enum.CameraType.Custom 
        if LocalPlayer.Character then 
            Camera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid") 
            if LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.Anchored = false
            end
        end
    end
end)
CreateKeybind(Page_Visual, "Freecam Aç/Kapat", Config.FreecamKey, function(k) Config.FreecamKey = k end)
CreateSlider(Page_Visual, "Kamera Hızı", 0.1, 5, 1, function(v) Config.FreecamSpeed = v end)

CreateSection(Page_Visual, "Görünüm")
CreateToggle(Page_Visual, "X-Ray", function(v) 
    Config.XRay = v
    if not v then for _,o in pairs(workspace:GetDescendants()) do if o:IsA("BasePart") then o.LocalTransparencyModifier = 0 end end end
end)
CreateToggle(Page_Visual, "No Fog", function(v) Config.NoFog = v end)
CreateToggle(Page_Visual, "Inf Zoom (Sınırsız)", function(v) Config.InfZoom = v end)
CreateToggle(Page_Visual, "Zamanı Değiştir", function(v) Config.TimeChange = v end)
CreateSlider(Page_Visual, "Saat", 0, 24, 14, function(v) Config.Time = v end)

local SelectedPlr = nil
local PlrLabel = Instance.new("TextLabel"); PlrLabel.Parent=Page_Player; PlrLabel.Size=UDim2.new(0.95,0,0,40); PlrLabel.BackgroundTransparency=1; PlrLabel.Text="Seçilen: Yok"; PlrLabel.TextColor3=Color3.fromRGB(160,80,255); PlrLabel.Font=Enum.Font.GothamBold; PlrLabel.TextSize = 18

local PlrList = Instance.new("ScrollingFrame"); PlrList.Parent=Page_Player; PlrList.Size=UDim2.new(0.95,0,0,200); PlrList.BackgroundColor3=Color3.fromRGB(25,25,30); PlrList.CanvasSize=UDim2.new(0,0,0,0)
local PlrListCorner = Instance.new("UICorner"); PlrListCorner.CornerRadius = UDim.new(0, 8); PlrListCorner.Parent = PlrList
local PlrListLayout = Instance.new("UIListLayout"); PlrListLayout.Parent=PlrList; PlrListLayout.Padding = UDim.new(0,5)

local function RefreshPlrs()
    for _,v in pairs(PlrList:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    local h=0
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LocalPlayer then
            local b = Instance.new("TextButton"); b.Parent=PlrList; b.Size=UDim2.new(1,-10,0,35); b.Text=p.Name; b.BackgroundColor3=Color3.fromRGB(40,40,45); b.TextColor3=Color3.fromRGB(255,255,255); b.Font=Enum.Font.Gotham; b.TextSize=15
            local bCorner = Instance.new("UICorner"); bCorner.CornerRadius = UDim.new(0, 6); bCorner.Parent = b
            b.MouseButton1Click:Connect(function() 
                SelectedPlr=p
                PlrLabel.Text="Seçilen: "..p.Name
                MonName.Text = "İsim: " .. p.Name
                MonHealth.Text = "Can: ..."
                MonTeam.Text = "Takım: " .. tostring(p.Team)
                MonTool.Text = "Eşya: ..."
                MonDist.Text = "Mesafe: ..."
            end)
            h=h+40
        end
    end
    PlrList.CanvasSize=UDim2.new(0,0,0,h)
end
CreateButton(Page_Player, "Listeyi Yenile", RefreshPlrs)
CreateButton(Page_Player, "Işınlan (TP)", function() if SelectedPlr and SelectedPlr.Character and LocalPlayer.Character then LocalPlayer.Character.HumanoidRootPart.CFrame = SelectedPlr.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3) end end)
CreateToggle(Page_Player, "İzle (Spectate)", function(v) 
    Config.Spectating = v
    if not v and LocalPlayer.Character then 
        Camera.CameraSubject=LocalPlayer.Character.Humanoid 
    end 
end)
CreateToggle(Page_Player, "Loop Follow (Takip Et)", function(v) Config.LoopFollow = v end)
CreateSlider(Page_Player, "Takip Mesafesi", 1, 50, 4, function(v) Config.FollowDist = v end)

CreateToggle(Page_Player, "Monitor (Panel)", function(v) Config.MonitorActive = v; MonFrame.Visible = v end)

CreateSection(Page_Developer, "Dünya & Koordinat")
local CoordLabel = Instance.new("TextLabel")
CoordLabel.Parent = Page_Developer
CoordLabel.Size = UDim2.new(0.95, 0, 0, 30)
CoordLabel.BackgroundTransparency = 1
CoordLabel.Text = "XYZ: 0, 0, 0"
CoordLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
CoordLabel.Font = Enum.Font.Code
CoordLabel.TextSize = 13

CreateToggle(Page_Developer, "Canlı Koordinat Göster", function(v) Config.ShowCoords = v end)
CreateButton(Page_Developer, "Koordinatı Kopyala", function() 
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local pos = LocalPlayer.Character.HumanoidRootPart.Position
        local txt = math.floor(pos.X) .. ", " .. math.floor(pos.Y) .. ", " .. math.floor(pos.Z)
        setclipboard(txt)
        Notify("Kopyalandı", txt)
    end
end)

CreateSection(Page_Developer, "Nesne Müfettişi")
CreateToggle(Page_Developer, "Inspector (Aktif/Pasif)", function(v) Config.DevInspector = v end)

local InspFrame = Instance.new("Frame", Page_Developer)
InspFrame.Size = UDim2.new(0.95, 0, 0, 120)
InspFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
local InspC = Instance.new("UICorner", InspFrame); InspC.CornerRadius = UDim.new(0,8)

local InspText = Instance.new("TextLabel", InspFrame)
InspText.Size = UDim2.new(1, -10, 1, -10)
InspText.Position = UDim2.new(0, 5, 0, 5)
InspText.BackgroundTransparency = 1
InspText.TextXAlignment = Enum.TextXAlignment.Left
InspText.TextYAlignment = Enum.TextYAlignment.Top
InspText.TextColor3 = Color3.fromRGB(200, 200, 200)
InspText.Font = Enum.Font.Code
InspText.TextSize = 13
InspText.Text = "Durum: Bekleniyor...\nFareyi nesneye getir."

local currentPath = ""

CreateButton(Page_Developer, "Yolu Kopyala (Copy Path)", function()
    if currentPath ~= "" then
        setclipboard(currentPath)
        Notify("Kopyalandı", "Nesne yolu panoya alındı.")
    else
        Notify("Hata", "Nesne seçili değil.")
    end
end)

CreateSection(Page_Developer, "Görsel Hata Ayıklama")
CreateToggle(Page_Developer, "NPC ESP (İsim/Can)", function(v) Config.NPC_ESP = v; if not v then for _,v in pairs(workspace:GetDescendants()) do if v.Name == "VexelNPC_ESP" then v:Destroy() end end end end)

CreateToggle(Page_Developer, "View Deletable (Silinebilir)", function(v)
    Config.ViewDeletable = v
    if not v then
        for _, p in pairs(workspace:GetDescendants()) do
            if p:IsA("BasePart") and p:FindFirstChild("DevHighlight") then
                p.DevHighlight:Destroy()
            end
        end
    end
end)

CreateSection(Page_Developer, "Araçlar")
CreateButton(Page_Developer, "Dex Explorer (Full Access)", function()
    Notify("Yükleniyor", "Dex Explorer başlatılıyor...")
    task.spawn(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/peyton2465/Dex/master/out.lua"))()
    end)
end)

CreateButton(Page_Developer, "Print Children (Konsola Yaz)", function()
    if Mouse.Target then
        print("--- " .. Mouse.Target.Name .. " ALT ÖĞELERİ ---")
        for _, c in pairs(Mouse.Target:GetChildren()) do
            print(c.Name .. " [" .. c.ClassName .. "]")
        end
        Notify("Konsol", "F9'a basarak çıktıya bak.")
    end
end)

-- [YENİ EKLENEN KISIM: COMBAT SPY]
CreateSection(Page_Developer, "Combat Spy (Hasar Log)")

local LogScroll = Instance.new("ScrollingFrame")
LogScroll.Parent = Page_Developer
LogScroll.Size = UDim2.new(0.95, 0, 0, 150)
LogScroll.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
LogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
LogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
LogScroll.ScrollBarThickness = 4
local LogList = Instance.new("UIListLayout"); LogList.Parent = LogScroll; LogList.Padding = UDim.new(0,2)
local LogCorner = Instance.new("UICorner"); LogCorner.Parent = LogScroll

local function LogSpy(text, color)
    local lbl = Instance.new("TextLabel", LogScroll)
    lbl.Size = UDim2.new(1, -5, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = "[" .. os.date("%H:%M:%S") .. "] " .. text
    lbl.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    if #LogScroll:GetChildren() > 50 then -- Bellek temizliği için eski logları sil
        for i,v in pairs(LogScroll:GetChildren()) do if v:IsA("TextLabel") and i < 5 then v:Destroy() end end
    end
    LogScroll.CanvasPosition = Vector2.new(0, 9999)
end

CreateToggle(Page_Developer, "Combat Logger (Aktif)", function(v) 
    Config.CombatSpy = v 
    if v then LogSpy("Combat log sistemi aktif...", Color3.fromRGB(100, 255, 100)) end
end)

CreateButton(Page_Developer, "Logları Temizle", function()
    for _,v in pairs(LogScroll:GetChildren()) do if v:IsA("TextLabel") then v:Destroy() end end
end)

local LastHealth = 100
local NPC_Healths = {} -- NPC canlarını takip etmek için

-- Kendi Hasarını Dinle ve Yakın Düşmanı Bul
table.insert(Connections, task.spawn(function()
    while true do
        task.wait(0.1)
        if Config.CombatSpy and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then
                if hum.Health < LastHealth then
                    local dmg = math.floor(LastHealth - hum.Health)
                    
                    -- SALDIRGANI BULMA MANTIĞI (En Yakın NPC)
                    local AttackerName = "Bilinmiyor/Uzak"
                    local MinDist = 99999
                    
                    if LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        for _, npc in pairs(NPC_Cache) do
                            if npc and npc:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
                                local dist = (npc.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                                if dist < MinDist then
                                    MinDist = dist
                                    AttackerName = npc.Name .. " (" .. math.floor(dist) .. "m)"
                                end
                            end
                        end
                    end
                    
                    if MinDist > 30 then AttackerName = "Bilinmiyor (Uzak)" end
                    
                    LogSpy("⚠️ HASAR ALINDI: -" .. dmg .. " | Kimden: " .. AttackerName, Color3.fromRGB(255, 50, 50))
                end
                LastHealth = hum.Health
            end
        end
    end
end))

-- NPC Hasarını Dinle (Bizim vurduklarımız)
table.insert(Connections, task.spawn(function()
    while true do
        task.wait(0.1) -- Hızlı tarama
        if Config.CombatSpy then
            -- NPC Cache'den faydalanıyoruz
            for _, npc in pairs(NPC_Cache) do
                if npc and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("Head") then
                    local currentHP = npc.Humanoid.Health
                    
                    -- Eğer NPC tabloda yoksa ekle
                    if not NPC_Healths[npc] then NPC_Healths[npc] = currentHP end
                    
                    -- Can değişikliği kontrolü
                    if currentHP < NPC_Healths[npc] then
                        local diff = NPC_Healths[npc] - currentHP
                        -- Sadece bize yakınsa (biz vurmuşuzdur mantığı) logla
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            local dist = (npc.Head.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                            if dist < 20 then -- Bize çok yakınsa biz vurmuşuzdur
                                LogSpy("⚔️ HASAR VERİLDİ: " .. npc.Name .. " [-" .. math.floor(diff) .. "] (Kalan: "..math.floor(currentHP)..")", Color3.fromRGB(255, 200, 50))
                            end
                        end
                    end
                    NPC_Healths[npc] = currentHP
                end
            end
        end
    end
end))
-- [YENİ KISIM SONU]

CreateSection(Page_Misc, "Faydalı Araçlar")
CreateButton(Page_Misc, "Rejoin Server (Tekrar Bağlan)", function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
CreateToggle(Page_Misc, "Click Delete (ALT+Tık)", function(v) Config.ClickDelete = v end)
CreateToggle(Page_Misc, "Chat Spy (Gizli Mesaj)", function(v) Config.ChatSpy = v end)
CreateToggle(Page_Misc, "Anti-AFK (Kick Önle)", function(v) Config.AntiAFK = v end)
CreateToggle(Page_Misc, "Auto Rejoin (Kick)", function(v) Config.AutoRejoin = v end)

CreateSection(Page_Misc, "Waypoint (Konum)")
local WP_Name = ""
CreateTextBox(Page_Misc, "Konum Adı...", function(t) WP_Name = t end)

local WP_List = Instance.new("ScrollingFrame"); WP_List.Parent=Page_Misc; WP_List.Size=UDim2.new(0.95,0,0,120); WP_List.BackgroundColor3=Color3.fromRGB(25,25,30); WP_List.CanvasSize=UDim2.new(0,0,0,0)
local WP_Layout = Instance.new("UIListLayout"); WP_Layout.Parent=WP_List; WP_Layout.Padding = UDim.new(0,5)
local WP_Corner = Instance.new("UICorner"); WP_Corner.Parent = WP_List

local function RefreshWP()
    for _,v in pairs(WP_List:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    local h=0
    for i, wp in pairs(Waypoints) do
        local f = Instance.new("Frame", WP_List); f.Size = UDim2.new(1,-5,0,30); f.BackgroundTransparency=1
        local lbl = Instance.new("TextLabel", f); lbl.Text = wp.Name; lbl.Size=UDim2.new(0.6,0,1,0); lbl.TextColor3=Color3.fromRGB(255,255,255); lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.Gotham; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Position=UDim2.new(0,5,0,0)
        
        local btnTP = Instance.new("TextButton", f); btnTP.Text="TP"; btnTP.Size=UDim2.new(0.2,0,1,0); btnTP.Position=UDim2.new(0.6,0,0,0); btnTP.BackgroundColor3=Color3.fromRGB(40,40,45); btnTP.TextColor3=Color3.fromRGB(115,0,255)
        local btnDel = Instance.new("TextButton", f); btnDel.Text="X"; btnDel.Size=UDim2.new(0.15,0,1,0); btnDel.Position=UDim2.new(0.82,0,0,0); btnDel.BackgroundColor3=Color3.fromRGB(200,50,50); btnDel.TextColor3=Color3.fromRGB(255,255,255)
        
        Instance.new("UICorner", btnTP)
        Instance.new("UICorner", btnDel)
        
        btnTP.MouseButton1Click:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = wp.Pos
            end
        end)
        
        btnDel.MouseButton1Click:Connect(function()
            table.remove(Waypoints, i)
            RefreshWP()
        end)
        h=h+35
    end
    WP_List.CanvasSize=UDim2.new(0,0,0,h)
end

CreateButton(Page_Misc, "Konumu Kaydet", function()
    if WP_Name ~= "" and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        table.insert(Waypoints, {Name = WP_Name, Pos = LocalPlayer.Character.HumanoidRootPart.CFrame})
        Notify("Waypoint", WP_Name .. " kaydedildi!")
        RefreshWP()
    else
        Notify("Hata", "İsim girin veya karakter yok.")
    end
end)

CreateSection(Page_Misc, "Admin Scriptleri")
CreateButton(Page_Misc, "Infinite Yield'ı Yükle", function()
    Notify("Yükleniyor", "Infinite Yield başlatılıyor...")
    task.spawn(function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    end)
end)

CreateSection(Page_Misc, "Işınlanma")
CreateToggle(Page_Misc, "CTRL + Click TP", function(v) Config.ClickTP = v end)
CreateToggle(Page_Misc, "Klavye TP (V/B)", function(v) Config.KeyTP = v end)

CreateSection(Page_Misc, "Eğlence")
CreateToggle(Page_Misc, "Chat Spam", function(v) Config.ChatSpam = v end)
CreateTextBox(Page_Misc, "Spam Mesajı...", function(txt) Config.SpamMsg = txt end)
CreateButton(Page_Misc, "Server Hop", function()
    local servers = game.HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    for _, s in pairs(servers.data) do if s.playing ~= s.maxPlayers then TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer); break end end
end)

CreateSection(Page_Settings, "Gizlilik")
CreateToggle(Page_Settings, "Anonim Mod (İsim/Resim Gizle)", function(v) 
    Config.AnonymousMode = v
    if v then
        ProfileName.Text = "Anonim"
        ProfileImg.Image = "rbxassetid://0"
    else
        ProfileName.Text = LocalPlayer.Name
        ProfileImg.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    end
end)

CreateSection(Page_Settings, "Arayüz Ayarları")
CreateKeybind(Page_Settings, "Menü Aç/Kapat Tuşu", Config.UIToggleKey, function(k) Config.UIToggleKey = k end)

CreateSection(Page_Settings, "Config Yönetimi")

local ConfigNameInput = ""
CreateTextBox(Page_Settings, "Config İsmi...", function(t) ConfigNameInput = t end)

local FileScroll = Instance.new("ScrollingFrame")
FileScroll.Parent = Page_Settings
FileScroll.Size = UDim2.new(0.95, 0, 0, 150)
FileScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
FileScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
FileScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
local FSList = Instance.new("UIListLayout"); FSList.Parent = FileScroll; FSList.Padding = UDim.new(0,5)
local FSCorner = Instance.new("UICorner"); FSCorner.Parent = FileScroll

local SelectedFile = nil
local RefreshConfigs -- İleri tanım

local function LoadConfigData(dataString)
    if not dataString or dataString == "" then Notify("Hata", "Boş veri!"); return end
    
    local success, decoded = pcall(function() return HttpService:JSONDecode(dataString) end)
    if not success then Notify("Hata", "Geçersiz JSON verisi."); return end
    
    for _, item in pairs(UI_Storage) do
        if decoded[item.Name] ~= nil then
            if item.Type == "Keybind" then
                local keyName = decoded[item.Name]
                if keyName == "MouseButton1" then item.Set(Enum.UserInputType.MouseButton1)
                elseif keyName == "MouseButton2" then item.Set(Enum.UserInputType.MouseButton2)
                else
                    local keyEnum = Enum.KeyCode[keyName]
                    if keyEnum then item.Set(keyEnum) end
                end
            else
                item.Set(decoded[item.Name])
            end
        end
    end
    Notify("Başarılı", "Config yüklendi!")
end

RefreshConfigs = function()
    for _, v in pairs(FileScroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    
    if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
    local files = listfiles(ConfigFolder)
    
    for _, file in pairs(files) do
        local fileName = file:match("([^/]+)$"):gsub(".json", "")
        local btn = Instance.new("TextButton", FileScroll)
        btn.Size = UDim2.new(1, -10, 0, 30)
        btn.Text = "  " .. fileName
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        local c = Instance.new("UICorner", btn); c.CornerRadius = UDim.new(0, 6)
        
        btn.MouseButton1Click:Connect(function()
            SelectedFile = fileName
            ConfigNameInput = fileName -- Textboxa da yaz
            for _, b in pairs(FileScroll:GetChildren()) do 
                if b:IsA("TextButton") then 
                    b.BackgroundColor3 = Color3.fromRGB(40, 40, 45) 
                    b.TextColor3 = Color3.fromRGB(200, 200, 200)
                end 
            end
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)
    end
end

local function SaveCurrentConfig(name)
    if name == "" then Notify("Hata", "İsim girin!"); return end
    local saveTable = {}
    
    for _, item in pairs(UI_Storage) do
        local val = item.Get()
        if item.Type == "Keybind" then
            if typeof(val) == "EnumItem" then saveTable[item.Name] = val.Name
            else saveTable[item.Name] = "Unknown" end
        else
            saveTable[item.Name] = val
        end
    end
    
    local json = HttpService:JSONEncode(saveTable)
    writefile(ConfigFolder .. "/" .. name .. ".json", json)
    Notify("Kaydedildi", name)
    RefreshConfigs()
end

local BtnContainer = Instance.new("Frame"); BtnContainer.Parent = Page_Settings; BtnContainer.Size = UDim2.new(0.95,0,0,80); BtnContainer.BackgroundTransparency = 1
local UIGrid = Instance.new("UIGridLayout"); UIGrid.Parent = BtnContainer; UIGrid.CellSize = UDim2.new(0.48, 0, 0, 35); UIGrid.CellPadding = UDim2.new(0.04,0,0.05,0)

CreateButton(BtnContainer, "Oluştur / Kaydet", function() SaveCurrentConfig(ConfigNameInput) end)
CreateButton(BtnContainer, "Seçileni Yükle", function() 
    if SelectedFile then 
        local content = readfile(ConfigFolder .. "/" .. SelectedFile .. ".json")
        LoadConfigData(content)
    else
        Notify("Hata", "Dosya seçilmedi")
    end
end)
CreateButton(BtnContainer, "Seçileni Sil", function() 
    if SelectedFile then 
        delfile(ConfigFolder .. "/" .. SelectedFile .. ".json")
        RefreshConfigs()
        SelectedFile = nil
    else
        Notify("Hata", "Dosya seçilmedi")
    end
end)
CreateButton(BtnContainer, "Listeyi Yenile", RefreshConfigs)

CreateSection(Page_Settings, "Dışa/İçe Aktar")

CreateButton(Page_Settings, "Config'i Kopyala (Export)", function()
    local saveTable = {}
    for _, item in pairs(UI_Storage) do
        local val = item.Get()
        if item.Type == "Keybind" then saveTable[item.Name] = val.Name else saveTable[item.Name] = val end
    end
    local json = HttpService:JSONEncode(saveTable)
    setclipboard(json)
    Notify("Başarılı", "Config panoya kopyalandı!")
end)

local ImportBox = ""
CreateTextBox(Page_Settings, "Config Kodunu Yapıştır...", function(t) ImportBox = t end)

CreateButton(Page_Settings, "Koddan Yükle (Import)", function()
    if ImportBox ~= "" then
        LoadConfigData(ImportBox)
    else
        local clip = getclipboard()
        if clip and clip ~= "" then
            LoadConfigData(clip)
        else
            Notify("Hata", "Veri bulunamadı.")
        end
    end
end)

RefreshConfigs()

table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe then
        if input.KeyCode == Config.GhostKey then
            -- Ghost mode kaldirildi
        elseif input.KeyCode == Config.FlyKey then
            Config.Fly = not Config.Fly
            if Config.Fly then Notify("Fly", "AÇIK") else Notify("Fly", "KAPALI") end
        end
    end
end))

table.insert(Connections, Mouse.Button1Down:Connect(function()
    if Config.ClickDelete and UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) and Mouse.Target then
        Mouse.Target:Destroy()
    end
end))

table.insert(Connections, UserInputService.JumpRequest:Connect(function()
    if Config.InfJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end))

table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Config.FreecamKey then
        Config.Freecam = not Config.Freecam
        if Config.Freecam then 
            Notify("Freecam", "AÇIK") 
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.Anchored = true
            end
        else 
            Notify("Freecam", "KAPALI") 
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default 
            Camera.CameraType = Enum.CameraType.Custom
            if LocalPlayer.Character then 
                Camera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid") 
                if LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.Anchored = false
                end
            end
        end
    end
end))

table.insert(Connections, task.spawn(function()
    while true do
        task.wait(0.5)
        if Config.ToolBring and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            for _, item in pairs(workspace:GetDescendants()) do
                if item:IsA("Tool") and item:FindFirstChild("Handle") then
                    item.Handle.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                end
            end
        end
    end
end))

table.insert(Connections, game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
    if child.Name == 'ErrorPrompt' and Config.AutoRejoin then
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end))

LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

local function OnChat(msg, plr)
    if Config.ChatSpy then
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "[SPY] " .. plr.Name .. ": " .. msg;
            Color = Color3.fromRGB(150, 150, 255);
            Font = Enum.Font.SourceSansBold;
            FontSize = Enum.FontSize.Size18;
        })
    end
end

for _, p in pairs(Players:GetPlayers()) do
    p.Chatted:Connect(function(msg) OnChat(msg, p) end)
end
table.insert(Connections, Players.PlayerAdded:Connect(function(p)
    p.Chatted:Connect(function(msg) OnChat(msg, p) end)
end))

table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Config.ClickKey then
        Config.AutoClicker = not Config.AutoClicker
        if Config.AutoClicker then Notify("Clicker", "AÇIK") else Notify("Clicker", "KAPALI") end
    end
end))

table.insert(Connections, task.spawn(function()
    while true do
        if Config.AutoClicker then
            mouse1click()
            task.wait(1 / Config.CPS)
        else
            task.wait(0.1)
        end
    end
end))

table.insert(Connections, task.spawn(function()
    while true do
        task.wait(2)
        if Config.ChatSpam then
            if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral"); if channel then channel:SendAsync(Config.SpamMsg) end else if ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") then ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(Config.SpamMsg, "All") end end
        end
    end
end))

table.insert(Connections, task.spawn(function()
    while true do
        task.wait(0.1) 
        if Config.AutoUse and LocalPlayer.Character then local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool"); if tool then tool:Activate() end end
    end
end))

table.insert(Connections, task.spawn(function()
    while true do
        task.wait(0.1) 
        
        local holdingKey = false
        if Config.InstantKeyOn and Config.InstantKey and Config.InstantKey ~= Enum.KeyCode.Unknown then
            if Config.InstantKey.UserInputType == Enum.UserInputType.Keyboard then
                holdingKey = UserInputService:IsKeyDown(Config.InstantKey)
            elseif Config.InstantKey.UserInputType == Enum.UserInputType.MouseButton1 then
                holdingKey = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
            elseif Config.InstantKey.UserInputType == Enum.UserInputType.MouseButton2 then
                holdingKey = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
            end
        end
        
        if Config.InstantPrompt or holdingKey then 
            for _, prompt in pairs(workspace:GetDescendants()) do 
                if prompt:IsA("ProximityPrompt") then 
                    prompt.HoldDuration = 0 
                end 
            end 
        end
    end
end))

-- [FPS OPTIMIZASYONU: Cache Loop]
table.insert(Connections, task.spawn(function()
    while true do
        if Config.NPC_ESP or Config.CombatSpy then
            NPC_Cache = {}
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("Head") and not Players:GetPlayerFromCharacter(obj) then
                    table.insert(NPC_Cache, obj)
                end
            end
        end
        task.wait(3)
    end
end))

-- =============================================
-- AIMBOT MANTIĞI & TRIGGER BOT
-- =============================================
local LockedTarget = nil
local TriggerToggled = false

-- TRIGGER TOGGLE LOGIC
table.insert(Connections, UserInputService.InputBegan:Connect(function(input)
    if not Config.TriggerHoldMode and input.KeyCode == Config.TriggerKey then
        TriggerToggled = not TriggerToggled
        if TriggerToggled then Notify("TriggerBot", "AÇIK") else Notify("TriggerBot", "KAPALI") end
    end
end))

local function IsVisible(targetPart)
    if not Config.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local result = workspace:Raycast(origin, direction, raycastParams)
    if result and result.Instance then
        return result.Instance:IsDescendantOf(targetPart.Parent)
    end
    return false
end

local function GetClosestPlayer()
    local shortestDistance = Config.AimFOV
    local closestPlayer = nil
    
    local MouseLocation = UserInputService:GetMouseLocation()
    if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
        MouseLocation = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            if Config.TeamCheck and plr.Team == LocalPlayer.Team then continue end
            
            local part = nil
            if Config.AimPart == "Random" then
                local parts = {"Head", "HumanoidRootPart", "Torso", "UpperTorso"}
                for _, pName in pairs(parts) do
                    if plr.Character:FindFirstChild(pName) then part = plr.Character[pName]; break end
                end
            else
                part = plr.Character:FindFirstChild(Config.AimPart) or plr.Character:FindFirstChild("Head")
            end
            
            if part then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local magnitude = (Vector2.new(pos.X, pos.Y) - MouseLocation).Magnitude
                    if magnitude < shortestDistance then
                        if IsVisible(part) then
                            closestPlayer = plr
                            shortestDistance = magnitude
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- [ESP FIX: HIGHLIGHT WATCHDOG]
-- Bu sistem surekli oyuncu uzerinde highlight var mi diye kontrol eder ve yoksa ekler.
table.insert(Connections, task.spawn(function()
    while true do
        task.wait(0.5) -- Her 0.5 saniyede bir kontrol et
        if Config.ESP_Highlight then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    if not p.Character:FindFirstChild("VexelHighlight") then
                        local hl = Instance.new("Highlight", p.Character)
                        hl.Name = "VexelHighlight"
                        hl.FillColor = Color3.fromRGB(115, 0, 255)
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
                    end
                end
            end
        end
    end
end))

-- [ESP FIX: NAME & HEALTH (ANCESTRY CHECK)]
local function ConnectPlayer(p)
    local function CharacterAdded(char)
        -- Karakterin workspace'e tam girmesini bekle
        if not char.Parent then char.AncestryChanged:Wait() end
        
        -- WaitForChild (Timeout 10sn)
        local head = char:WaitForChild("Head", 10)
        local hum = char:WaitForChild("Humanoid", 10)
        if not head or not hum then return end

        -- Nametag & Modern Healthbar
        if Config.ESP_NameTag or Config.ESP_Health then
            if head:FindFirstChild("VexelNameTag") then head.VexelNameTag:Destroy() end
            
            local bg = Instance.new("BillboardGui", head)
            bg.Name = "VexelNameTag"
            bg.Size = UDim2.new(0, 200, 0, 60)
            bg.AlwaysOnTop = true
            
            -- Isim
            local nameLbl = Instance.new("TextLabel", bg)
            nameLbl.Name = "NameLabel"
            nameLbl.Size = UDim2.new(1, 0, 0.6, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text = p.Name
            nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            nameLbl.TextStrokeTransparency = 0.5
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextSize = Config.ESP_NameSize
            nameLbl.Visible = Config.ESP_NameTag
            
            -- Modern Health Bar (Container)
            local barBg = Instance.new("Frame", bg)
            barBg.Name = "HealthBar"
            barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            barBg.BorderSizePixel = 0
            barBg.Visible = Config.ESP_Health
            
            local stroke = Instance.new("UIStroke", barBg)
            stroke.Color = Color3.fromRGB(0, 0, 0)
            stroke.Thickness = 1
            
            local fill = Instance.new("Frame", barBg)
            fill.Name = "Fill"
            fill.Size = UDim2.new(1, 0, 1, 0)
            fill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
            fill.BorderSizePixel = 0
            
            -- Can Değişim Loop'u (Event yerine Loop daha stabil)
            task.spawn(function()
                while char and hum and hum.Health > 0 and bg.Parent do
                    -- [BASİTLEŞTİRİLMİŞ ESP KONUMLANDIRMA]
                    
                    -- İsim Konumu
                    if Config.ESP_NamePos == "Top" then 
                        nameLbl.Position = UDim2.new(0,0,0,-20)
                        bg.StudsOffset = Vector3.new(0, 4, 0)
                    elseif Config.ESP_NamePos == "Bottom" then 
                        nameLbl.Position = UDim2.new(0,0,0,20)
                        bg.StudsOffset = Vector3.new(0, -3, 0)
                    elseif Config.ESP_NamePos == "Left" then 
                        nameLbl.Position = UDim2.new(-0.8,0,0,0)
                        bg.StudsOffset = Vector3.new(-2, 0, 0)
                    elseif Config.ESP_NamePos == "Right" then 
                        nameLbl.Position = UDim2.new(0.8,0,0,0)
                        bg.StudsOffset = Vector3.new(2, 0, 0)
                    end
                    nameLbl.TextSize = Config.ESP_NameSize
                    
                    -- Bar Konumu & Boyutu
                    local barW = Config.ESP_BarSize * 10 
                    local barH = Config.ESP_BarSize
                    barBg.Size = UDim2.new(0, barW, 0, barH)
                    
                    if Config.ESP_BarPos == "Top" then 
                        barBg.Position = UDim2.new(0.5, -barW/2, 0, -30)
                    elseif Config.ESP_BarPos == "Bottom" then 
                        barBg.Position = UDim2.new(0.5, -barW/2, 0, 30)
                    elseif Config.ESP_BarPos == "Left" then 
                        barBg.Position = UDim2.new(0, -barW, 0.5, 0)
                    elseif Config.ESP_BarPos == "Right" then 
                        barBg.Position = UDim2.new(1, 0, 0.5, 0)
                    end
                    
                    local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    TweenService:Create(fill, TweenInfo.new(0.3), {
                        Size = UDim2.new(hp, 0, 1, 0),
                        BackgroundColor3 = Color3.fromRGB(255, 50, 50):Lerp(Color3.fromRGB(0, 255, 100), hp)
                    }):Play()
                    
                    nameLbl.Visible = Config.ESP_NameTag
                    barBg.Visible = Config.ESP_Health
                    
                    task.wait(0.2)
                end
            end)
        end
    end
    if p.Character then CharacterAdded(p.Character) end
    p.CharacterAdded:Connect(CharacterAdded)
end

for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then ConnectPlayer(p) end end
Players.PlayerAdded:Connect(ConnectPlayer)

-- [YENİ: TRACER (Çizgi) FONKSİYONU]
local function UpdateTracer(plr)
    if not DrawingApiSupported then return end
    if not TracerCache[plr] then
         local success, line = pcall(function() return Drawing.new("Line") end)
         if success and line then
             line.Visible = false
             line.Color = Color3.fromRGB(255, 255, 255)
             line.Thickness = 1.5
             line.Transparency = 0.8
             TracerCache[plr] = line
         else
             return
         end
    end

    local line = TracerCache[plr]
    
    if Config.ESP_Tracers and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
        local rootPos = plr.Character.HumanoidRootPart.Position
        local screenPos, onScreen = Camera:WorldToViewportPoint(rootPos)
        
        if onScreen then
            line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            line.To = Vector2.new(screenPos.X, screenPos.Y)
            
            local dist = (LocalPlayer.Character.HumanoidRootPart.Position - rootPos).Magnitude
            if dist <= Config.ESP_MaxDist then
                 line.Visible = true
                 if Config.TeamCheck and plr.Team == LocalPlayer.Team then
                     line.Color = Color3.fromRGB(0, 255, 100)
                 else
                     line.Color = Color3.fromRGB(255, 50, 50)
                 end
            else
                 line.Visible = false
            end
        else
            line.Visible = false
        end
    else
        line.Visible = false
    end
end

-- Tracer Temizliği
Players.PlayerRemoving:Connect(function(p)
    if TracerCache[p] then TracerCache[p]:Remove() TracerCache[p] = nil end
end)

-- MAIN LOOP (RENDERSTEPPED)
table.insert(Connections, RunService.RenderStepped:Connect(function(deltaTime)
    
    -- [TRIGGER BOT LOOP]
    if Config.TriggerBot then
        local shouldShoot = false
        if Config.TriggerHoldMode then
            if UserInputService:IsKeyDown(Config.TriggerKey) then shouldShoot = true end
        else
            if TriggerToggled then shouldShoot = true end
        end
        
        if shouldShoot then
            local mouseParams = RaycastParams.new()
            mouseParams.FilterDescendantsInstances = {LocalPlayer.Character}
            mouseParams.FilterType = Enum.RaycastFilterType.Exclude
            local ray = workspace:Raycast(Camera.CFrame.Position, Camera.CFrame.LookVector * 1000, mouseParams)
            
            if ray and ray.Instance and ray.Instance.Parent:FindFirstChild("Humanoid") then
                local hitPlr = Players:GetPlayerFromCharacter(ray.Instance.Parent)
                if hitPlr and hitPlr ~= LocalPlayer then
                    if not (Config.TeamCheck and hitPlr.Team == LocalPlayer.Team) then
                        mouse1click()
                    end
                end
            end
        end
    end

    -- [PROXIMITY RADAR LOGIC (NEW)]
    if Config.RadarActive then
        local closest = nil
        local dist = 99999
        local closestPlr = nil
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                    local d = (p.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                    if d < dist then dist = d; closest = p.Character.HumanoidRootPart; closestPlr = p end
                end
            end
            
            if closest and closestPlr then
                RadarFrame.Visible = true
                RadarName.Text = closestPlr.Name
                RadarHP.Text = "HP: " .. math.floor(closestPlr.Character.Humanoid.Health) .. "%"
                
                local camCFrame = Camera.CFrame
                local relative = camCFrame:PointToObjectSpace(closest.Position)
                local angle = math.atan2(relative.X, relative.Z)
                RadarArrow.Rotation = math.deg(angle) + 180 
            else
                RadarFrame.Visible = false
            end
        else
            RadarFrame.Visible = false
        end
    else
        RadarFrame.Visible = false
    end

    -- [TRACER UPDATE LOOP]
    if DrawingApiSupported then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then UpdateTracer(p) end
        end
    end

    -- [CFRAME WALK FIX]
    if Config.CFrameWalk and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hum and root and hum.MoveDirection.Magnitude > 0 then
            root.CFrame = root.CFrame + (hum.MoveDirection * Config.CFrameSpeed)
            root.Velocity = Vector3.new(0,0,0)
        end
    end

    -- [AIMBOT LOOP]
    if Config.AimbotOn then
        local isAiming = false
        
        -- [AIMBOT MODE: HOLD VS ALWAYS ON]
        if Config.AimHoldMode then
            if typeof(Config.AimKey) == "EnumItem" then
                if Config.AimKey.EnumType == Enum.UserInputType then
                    isAiming = UserInputService:IsMouseButtonPressed(Config.AimKey)
                elseif Config.AimKey.EnumType == Enum.KeyCode then
                    isAiming = UserInputService:IsKeyDown(Config.AimKey)
                end
            end
        else
            -- Always On Mode
            isAiming = true
        end
        
        if isAiming then
            if not LockedTarget or (Config.StickyAim and (not LockedTarget.Character or not LockedTarget.Character:FindFirstChild("Humanoid") or LockedTarget.Character.Humanoid.Health <= 0)) then
                LockedTarget = GetClosestPlayer()
            elseif not Config.StickyAim then
                LockedTarget = GetClosestPlayer()
            end
            
            if LockedTarget and LockedTarget.Character then
                local aimPart = nil
                if Config.AimPart == "Random" then
                    aimPart = LockedTarget.Character:FindFirstChild("Head") or LockedTarget.Character:FindFirstChild("Torso")
                else
                    aimPart = LockedTarget.Character:FindFirstChild(Config.AimPart)
                end
                
                if aimPart then
                    local predictedPos = aimPart.Position + (aimPart.Velocity * (Config.Prediction / 10))
                    local currentCFrame = Camera.CFrame
                    local targetCFrame = CFrame.new(Camera.CFrame.Position, predictedPos)
                    Camera.CFrame = currentCFrame:Lerp(targetCFrame, Config.AimSmooth)
                end
            end
        else
            LockedTarget = nil
        end
    end

    -- [FIX: OYUNCU İZLEME VE TAKİP DÜZELTMESİ] --
    if SelectedPlr and SelectedPlr.Character and SelectedPlr.Character:FindFirstChild("Humanoid") and SelectedPlr.Character:FindFirstChild("HumanoidRootPart") then
        if Config.Spectating then
            Camera.CameraSubject = SelectedPlr.Character.Humanoid
        end
        if Config.LoopFollow and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetCFrame = SelectedPlr.Character.HumanoidRootPart.CFrame
            LocalPlayer.Character.HumanoidRootPart.CFrame = targetCFrame * CFrame.new(0, 0, Config.FollowDist)
            LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
        end
    else
        if Config.Spectating and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            Camera.CameraSubject = LocalPlayer.Character.Humanoid
        end
    end

    Camera.FieldOfView = Config.CamFOV 
    if Config.InfZoom then LocalPlayer.CameraMaxZoomDistance = 100000 else LocalPlayer.CameraMaxZoomDistance = 128 end
    
    if Config.HUD_Active then
        local fps = math.floor(workspace:GetRealPhysicsFPS())
        local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValueString():match("%d+"))
        FPSLabel.Text = "FPS: " .. tostring(fps)
        PingLabel.Text = "Ping: " .. tostring(ping) .. " ms"
    end
    
    if Config.MonitorActive and SelectedPlr then
        if SelectedPlr.Team then
            MonTeam.Text = "Takım: " .. SelectedPlr.Team.Name
            MonTeam.TextColor3 = SelectedPlr.TeamColor.Color
        else
            MonTeam.Text = "Takım: Yok"
            MonTeam.TextColor3 = Color3.fromRGB(255, 255, 255)
        end

        if SelectedPlr.Character then
            local hum = SelectedPlr.Character:FindFirstChild("Humanoid")
            local root = SelectedPlr.Character:FindFirstChild("HumanoidRootPart")
            if hum then MonHealth.Text = "Can: " .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) end
            local tool = SelectedPlr.Character:FindFirstChildOfClass("Tool")
            if tool then MonTool.Text = "Eşya: " .. tool.Name else MonTool.Text = "Eşya: Yok" end
            if root and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local dist = math.floor((root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
                MonDist.Text = "Mesafe: " .. dist .. "m"
            end
        else
            MonHealth.Text = "Can: Ölü/Yok"
            MonDist.Text = "Mesafe: N/A"
        end
    end

    if Config.AntiRagdoll and LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if root and not root:FindFirstChild("VexelStabilizer") then
            local bg = Instance.new("BodyGyro", root); bg.Name = "VexelStabilizer"; bg.MaxTorque = Vector3.new(400000, 0, 400000); bg.P = 9000; bg.CFrame = CFrame.new()
        end
        if hum then hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false); hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false); hum.PlatformStand = false; hum.Sit = false end
    end

    if Config.AntiVoid and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        if LocalPlayer.Character.HumanoidRootPart.Position.Y < -75 then
            LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 100, 0); LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
        end
    end
    
    if Config.GravityOn then workspace.Gravity = Config.GravityVal end
    
    if Config.Fullbright then
        Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 100000; Lighting.GlobalShadows = false; Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end
    
    if Config.Freecam then
        Camera.CameraType = Enum.CameraType.Scriptable
        local camCFrame = Camera.CFrame; local moveVector = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + Vector3.new(0, 0, -1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector + Vector3.new(0, 0, 1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector + Vector3.new(-1, 0, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + Vector3.new(1, 0, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveVector = moveVector + Vector3.new(0, -1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveVector = moveVector + Vector3.new(0, 1, 0) end
        local mouseDelta = UserInputService:GetMouseDelta(); local sensitivity = 0.5
        local currentRot = Camera.CFrame - Camera.CFrame.Position
        local yaw = CFrame.Angles(0, -math.rad(mouseDelta.X * sensitivity), 0); local pitch = CFrame.Angles(-math.rad(mouseDelta.Y * sensitivity), 0, 0)
        local newRot = yaw * currentRot * pitch; local speed = Config.FreecamSpeed * 50 * deltaTime
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then speed = speed * 2 end
        Camera.CFrame = newRot + newRot:VectorToWorldSpace(moveVector) * speed + Camera.CFrame.Position
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    else
        if not UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then UserInputService.MouseBehavior = Enum.MouseBehavior.Default end
    end

    if LocalPlayer.Character then
        local char = LocalPlayer.Character; local hum = char:FindFirstChild("Humanoid"); local root = char:FindFirstChild("HumanoidRootPart")
        if hum and root then
            if Config.SpeedOn then hum.WalkSpeed = Config.Speed end
            if Config.JumpOn then hum.UseJumpPower = true; hum.JumpPower = Config.Jump end
            if Config.NoSlow then hum.WalkSpeed = math.max(hum.WalkSpeed, 16) end
            if Config.NoclipPlayer then for _,v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end
            if Config.NoclipVehicle and hum.SeatPart then local veh = hum.SeatPart.Parent; for _,v in pairs(veh:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end
            if Config.SafeFall and hum.FloorMaterial == Enum.Material.Air and root.Velocity.Y < -30 then local ray = Ray.new(root.Position, Vector3.new(0, -15, 0)); local hit, pos = workspace:FindPartOnRay(ray, char); if hit then root.Velocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z) end end
            if Config.AntiFling then for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character then for _,v in pairs(p.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end end end
            if Config.AutoJump then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            if Config.AirWalk then local plat = workspace:FindFirstChild("AirPlat") or Instance.new("Part", workspace); plat.Name="AirPlat"; plat.Anchored=true; plat.CanCollide=true; plat.Transparency=1; plat.Size=Vector3.new(5,1,5); plat.Position = root.Position - Vector3.new(0,3.5,0) else if workspace:FindFirstChild("AirPlat") then workspace.AirPlat:Destroy() end end
            if Config.Jesus then local ray = Ray.new(root.Position, Vector3.new(0, -5, 0)); local hit, pos = workspace:FindPartOnRay(ray, char); if hit and hit.Name == "Water" or (hum:GetState() == Enum.HumanoidStateType.Swimming) then local plat = workspace:FindFirstChild("JesusPlat") or Instance.new("Part", workspace); plat.Name="JesusPlat"; plat.Anchored=true; plat.CanCollide=true; plat.Transparency=1; plat.Size=Vector3.new(5,1,5); plat.Position = root.Position - Vector3.new(0,3.5,0) else if workspace:FindFirstChild("JesusPlat") then workspace.JesusPlat:Destroy() end end end
            
            -- [FLY REWORK - INFINITE YIELD STYLE]
            if Config.Fly then
                local bv = root:FindFirstChild("VexelFlyBV") or Instance.new("BodyVelocity", root)
                bv.Name = "VexelFlyBV"
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                
                local bg = root:FindFirstChild("VexelFlyBG") or Instance.new("BodyGyro", root)
                bg.Name = "VexelFlyBG"
                bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                bg.P = 10000
                bg.CFrame = Camera.CFrame 
                
                local camCF = Camera.CFrame
                local velocity = Vector3.new(0, 0, 0)
                
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then velocity = velocity + camCF.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then velocity = velocity - camCF.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then velocity = velocity - camCF.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then velocity = velocity + camCF.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then velocity = velocity + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then velocity = velocity - Vector3.new(0, 1, 0) end
                
                bv.Velocity = velocity * Config.FlySpeed
                hum.PlatformStand = true
            else
                if root:FindFirstChild("VexelFlyBV") then root.VexelFlyBV:Destroy() end
                if root:FindFirstChild("VexelFlyBG") then root.VexelFlyBG:Destroy() end
                hum.PlatformStand = false
            end
            
            if Config.Spider then local ray = Ray.new(root.Position, root.CFrame.LookVector * 2); local hit = workspace:FindPartOnRay(ray, char); if hit and UserInputService:IsKeyDown(Enum.KeyCode.W) then local bv=root:FindFirstChild("SpiderBV") or Instance.new("BodyVelocity", root); bv.Name="SpiderBV"; bv.MaxForce=Vector3.new(0,1e9,0); bv.Velocity=Vector3.new(0,30,0) else if root:FindFirstChild("SpiderBV") then root.SpiderBV:Destroy() end end else if root:FindFirstChild("SpiderBV") then root.SpiderBV:Destroy() end end
            if Config.XRay then for _,o in pairs(workspace:GetDescendants()) do if o:IsA("BasePart") and not o.Parent:FindFirstChild("Humanoid") then o.LocalTransparencyModifier = 0.5 end end end
            
            -- [VEHICLE FLY FIX - INFINITE YIELD STYLE]
            if Config.VehicleFly and hum.SeatPart then
                local veh = hum.SeatPart.Parent
                local rootPart = veh.PrimaryPart or hum.SeatPart
                
                if rootPart then
                    local bv = rootPart:FindFirstChild("VexelVehBV") or Instance.new("BodyVelocity", rootPart)
                    bv.Name = "VexelVehBV"
                    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bv.Velocity = Vector3.new(0,0,0) 
                    
                    local camCF = Camera.CFrame
                    local vel = Vector3.new()
                    
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + camCF.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - camCF.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - camCF.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + camCF.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0, 1, 0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vel = vel - Vector3.new(0, 1, 0) end
                    
                    bv.Velocity = vel * Config.VehFlySpeed
                    
                    local bg = rootPart:FindFirstChild("VexelVehBG") or Instance.new("BodyGyro", rootPart)
                    bg.Name = "VexelVehBG"
                    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                    bg.P = 10000
                    bg.CFrame = camCF
                end
            else
                if hum.SeatPart then
                     local veh = hum.SeatPart.Parent
                     local rootPart = veh.PrimaryPart or hum.SeatPart
                     if rootPart then
                         if rootPart:FindFirstChild("VexelVehBV") then rootPart.VexelVehBV:Destroy() end
                         if rootPart:FindFirstChild("VexelVehBG") then rootPart.VexelVehBG:Destroy() end
                     end
                end
            end
        end
    end
    
    if Config.ShowCoords and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local pos = LocalPlayer.Character.HumanoidRootPart.Position; CoordLabel.Text = "XYZ: " .. math.floor(pos.X) .. ", " .. math.floor(pos.Y) .. ", " .. math.floor(pos.Z)
    end

    if Config.DevInspector and Mouse.Target then
        local obj = Mouse.Target; local className = obj.ClassName; local path = obj:GetFullName(); local props = ""; if obj:IsA("BasePart") then props = props .. "Anchored: " .. tostring(obj.Anchored) .. " | CanCollide: " .. tostring(obj.CanCollide) .. "\n" .. "Mass: " .. math.floor(obj:GetMass()) .. " | Trans: " .. obj.Transparency end; local parentModel = obj.Parent; local hierarchy = "• " .. obj.Name .. " [" .. className .. "]"; if parentModel and not parentModel:IsA("Workspace") then hierarchy = hierarchy .. "\n└ " .. parentModel.Name .. " [" .. parentModel.ClassName .. "]"; if parentModel.Parent and not parentModel.Parent:IsA("Workspace") then hierarchy = hierarchy .. "\n  └ " .. parentModel.Parent.Name end end; InspText.Text = hierarchy .. "\n\n" .. props; currentPath = path
    elseif Config.DevInspector then InspText.Text = "Hedef Yok (Boşluk)"; currentPath = "" end
    
    if Config.ViewDeletable and Mouse.Target and not Mouse.Target:FindFirstChild("DevHighlight") then local hl = Instance.new("Highlight", Mouse.Target); hl.Name = "DevHighlight"; hl.FillColor = Color3.fromRGB(255, 0, 0); hl.OutlineTransparency = 1 end

    if Config.NPC_ESP then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            for _, obj in pairs(NPC_Cache) do
                if obj and obj.Parent and obj:FindFirstChild("Head") and obj:FindFirstChild("Humanoid") and obj.Humanoid.Health > 0 then
                    local dist = (obj.Head.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                    if dist < 300 then
                        if not obj.Head:FindFirstChild("VexelNPC_ESP") then
                            local bg = Instance.new("BillboardGui", obj.Head); bg.Name = "VexelNPC_ESP"; bg.Size = UDim2.new(0, 100, 0, 50); bg.StudsOffset = Vector3.new(0, 2, 0); bg.AlwaysOnTop = true
                            local txt = Instance.new("TextLabel", bg); txt.BackgroundTransparency=1; txt.Size=UDim2.new(1,0,1,0); txt.Font=Enum.Font.GothamBold; txt.TextSize=12; txt.TextColor3=Color3.fromRGB(255,100,100); txt.TextStrokeTransparency=0.5
                            txt.Text = obj.Name .. "\nHP: " .. math.floor(obj.Humanoid.Health)
                        else
                            obj.Head.VexelNPC_ESP.TextLabel.Text = obj.Name .. "\nHP: " .. math.floor(obj.Humanoid.Health)
                        end
                    else
                        if obj.Head:FindFirstChild("VexelNPC_ESP") then obj.Head.VexelNPC_ESP:Destroy() end
                    end
                end
            end
        end
    end
end))

table.insert(Connections, Mouse.Button1Down:Connect(function() if Config.ClickTP and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and LocalPlayer.Character then LocalPlayer.Character:MoveTo(Mouse.Hit.Position) end end))
table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gpe) if gpe then return end if Config.KeyTP and LocalPlayer.Character then local r=LocalPlayer.Character.HumanoidRootPart; if input.KeyCode==Enum.KeyCode.V then r.CFrame=r.CFrame*CFrame.new(0,0,-10) end if input.KeyCode==Enum.KeyCode.B then r.CFrame=r.CFrame*CFrame.new(0,0,10) end end end))

RefreshPlrs()
RefreshTools()