local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local Settings = {
    Target = nil,
    LoopFollow = false,
    FollowDist = 5,
    Fly = false,
    FlySpeed = 50,
    FlyKey = Enum.KeyCode.F,
    Freecam = false,
    FreecamSpeed = 1,
    FreecamKey = Enum.KeyCode.P,
    Spectating = false,
    Noclip = false,
    ESP = false,
    Chams = false,
    MonitorVisible = false,
    ChatLogVisible = false,
    ClickTP = false,
    WalkSpeed = 16,
    JumpPower = 50,
    Minimized = false,
    InfiniteZoom = false,
    AntiRagdoll = false,
    ClickDelete = false
}

local FreecamPos = Vector3.new()
local FreecamRot = Vector2.new()

if CoreGui:FindFirstChild("VexelFinalUI") then
    CoreGui.VexelFinalUI:Destroy()
end

local Theme = {
    Main = Color3.fromRGB(20, 20, 25),
    Header = Color3.fromRGB(30, 30, 35),
    Accent = Color3.fromRGB(160, 30, 255),
    Text = Color3.fromRGB(255, 255, 255),
    Gray = Color3.fromRGB(150, 150, 150),
    Input = Color3.fromRGB(40, 40, 45),
    Green = Color3.fromRGB(50, 220, 100),
    Red = Color3.fromRGB(220, 50, 50),
    Blue = Color3.fromRGB(50, 150, 255),
    Orange = Color3.fromRGB(255, 170, 0)
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VexelFinalUI"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local function MakeCorner(obj, r) local c=Instance.new("UICorner",obj); c.CornerRadius=UDim.new(0,r); return c end
local function MakeStroke(obj, color, thick) local s=Instance.new("UIStroke",obj); s.Color=color; s.Thickness=thick; return s end

local MonitorFrame = Instance.new("Frame")
MonitorFrame.Name = "MonitorFrame"
MonitorFrame.Parent = ScreenGui
MonitorFrame.BackgroundColor3 = Theme.Main
MonitorFrame.Position = UDim2.new(0.8, 0, 0.4, 0)
MonitorFrame.Size = UDim2.new(0, 200, 0, 140)
MonitorFrame.Visible = false
MakeCorner(MonitorFrame, 8)
MakeStroke(MonitorFrame, Theme.Accent, 2)

local MonHeader = Instance.new("Frame", MonitorFrame)
MonHeader.BackgroundColor3 = Theme.Header
MonHeader.Size = UDim2.new(1, 0, 0, 25)
MakeCorner(MonHeader, 8)

local MonTitle = Instance.new("TextLabel", MonHeader)
MonTitle.Text = "HEDEF BİLGİSİ"
MonTitle.Size = UDim2.new(1, 0, 1, 0)
MonTitle.BackgroundTransparency = 1
MonTitle.TextColor3 = Theme.Accent
MonTitle.Font = Enum.Font.GothamBlack
MonTitle.TextSize = 12

local function AddMonLine(y, txt)
    local L = Instance.new("TextLabel", MonitorFrame)
    L.Position = UDim2.new(0, 10, 0, y)
    L.Size = UDim2.new(1, -20, 0, 20)
    L.BackgroundTransparency = 1
    L.TextColor3 = Theme.Text
    L.Font = Enum.Font.GothamBold
    L.TextSize = 13
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.Text = txt
    return L
end

local MonName = AddMonLine(35, "İsim: Yok")
local MonHP = AddMonLine(60, "Can: -")
local MonDist = AddMonLine(85, "Mesafe: -")
local MonTool = AddMonLine(110, "Eşya: -")

local Md, Mds, Msp
MonHeader.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then Md=true; Mds=i.Position; Msp=MonitorFrame.Position end end)
UserInputService.InputChanged:Connect(function(i) if Md and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-Mds; MonitorFrame.Position=UDim2.new(Msp.X.Scale,Msp.X.Offset+d.X,Msp.Y.Scale,Msp.Y.Offset+d.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then Md=false end end)

local ChatFrame = Instance.new("Frame")
ChatFrame.Name = "ChatLogFrame"
ChatFrame.Parent = ScreenGui
ChatFrame.BackgroundColor3 = Theme.Main
ChatFrame.Position = UDim2.new(0.02, 0, 0.4, 0)
ChatFrame.Size = UDim2.new(0, 300, 0, 250)
ChatFrame.Visible = false
MakeCorner(ChatFrame, 8)
MakeStroke(ChatFrame, Theme.Accent, 2)

local ChatHeader = Instance.new("Frame", ChatFrame)
ChatHeader.BackgroundColor3 = Theme.Header
ChatHeader.Size = UDim2.new(1, 0, 0, 25)
MakeCorner(ChatHeader, 8)

local ChatTitle = Instance.new("TextLabel", ChatHeader)
ChatTitle.Text = "CHAT GEÇMİŞİ"
ChatTitle.Size = UDim2.new(1, 0, 1, 0)
ChatTitle.BackgroundTransparency = 1
ChatTitle.TextColor3 = Theme.Accent
ChatTitle.Font = Enum.Font.GothamBlack
ChatTitle.TextSize = 13

local ChatScroll = Instance.new("ScrollingFrame", ChatFrame)
ChatScroll.Size = UDim2.new(1, -10, 1, -30)
ChatScroll.Position = UDim2.new(0, 5, 0, 30)
ChatScroll.BackgroundTransparency = 1
ChatScroll.ScrollBarThickness = 3
ChatScroll.ScrollBarImageColor3 = Theme.Accent
ChatScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ChatScroll.CanvasSize = UDim2.new(0,0,0,0)

local ChatList = Instance.new("UIListLayout", ChatScroll)
ChatList.Padding = UDim.new(0, 4)
ChatList.SortOrder = Enum.SortOrder.LayoutOrder

local Cd, Cds, Csp
ChatHeader.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then Cd=true; Cds=i.Position; Csp=ChatFrame.Position end end)
UserInputService.InputChanged:Connect(function(i) if Cd and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-Cds; ChatFrame.Position=UDim2.new(Csp.X.Scale,Csp.X.Offset+d.X,Csp.Y.Scale,Csp.Y.Offset+d.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then Cd=false end end)

local function AddLog(msg, player)
    local L = Instance.new("TextLabel", ChatScroll)
    L.Size = UDim2.new(1, 0, 0, 20)
    L.BackgroundTransparency = 1
    L.TextColor3 = Theme.Text
    L.Font = Enum.Font.GothamBold
    L.TextSize = 14
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.TextWrapped = true
    L.AutomaticSize = Enum.AutomaticSize.Y
    L.RichText = true
    
    local timeStr = os.date("%H:%M")
    local pName = player and player.Name or "System"
    local pColor = "rgb(255,255,255)"
    
    if player and player.TeamColor then
        local c = player.TeamColor.Color
        pColor = string.format("rgb(%d,%d,%d)", c.R*255, c.G*255, c.B*255)
    end

    L.Text = string.format("<font color='rgb(180,180,180)'>[%s]</font> <font color='%s'>%s:</font> %s", timeStr, pColor, pName, msg)
    
    if #ChatScroll:GetChildren() > 50 then
        for i, v in ipairs(ChatScroll:GetChildren()) do
            if v:IsA("TextLabel") then v:Destroy(); break end
        end
    end
    ChatScroll.CanvasPosition = Vector2.new(0, 99999)
end

task.spawn(function()
    if ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") then
        ReplicatedStorage.DefaultChatSystemChatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(data)
            local p = Players:GetPlayerByUserId(data.FromSpeakerUserId)
            if p then AddLog(data.Message, p) end
        end)
    end
    TextChatService.MessageReceived:Connect(function(params)
        local p = Players:GetPlayerByUserId(params.TextSource.UserId)
        if p then AddLog(params.Text, p) end
    end)
end)

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Theme.Main
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -250)
MainFrame.Size = UDim2.new(0, 320, 0, 520)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MakeCorner(MainFrame, 10)
MakeStroke(MainFrame, Theme.Accent, 2)

MainFrame.Size = UDim2.new(0, 320, 0, 0)
TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Size = UDim2.new(0, 320, 0, 520)}):Play()

local Header = Instance.new("Frame", MainFrame)
Header.BackgroundColor3 = Theme.Header
Header.Size = UDim2.new(1, 0, 0, 40)
MakeCorner(Header, 10)
local HeaderFix = Instance.new("Frame", Header); HeaderFix.BorderSizePixel=0; HeaderFix.BackgroundColor3=Theme.Header; HeaderFix.Size=UDim2.new(1,0,0,10); HeaderFix.Position=UDim2.new(0,0,1,-10)

local TitleLbl = Instance.new("TextLabel", Header)
TitleLbl.Text = "Vexel Control Menu"
TitleLbl.RichText = true
TitleLbl.Size = UDim2.new(1, -75, 1, 0)
TitleLbl.Position = UDim2.new(0, 15, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.TextColor3 = Theme.Text
TitleLbl.Font = Enum.Font.GothamBlack
TitleLbl.TextSize = 16
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -35, 0.5, -12.5)
CloseBtn.BackgroundColor3 = Theme.Red
CloseBtn.Text = ""
MakeCorner(CloseBtn, 6)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local MinBtn = Instance.new("TextButton", Header)
MinBtn.Size = UDim2.new(0, 25, 0, 25)
MinBtn.Position = UDim2.new(1, -70, 0.5, -12.5)
MinBtn.BackgroundColor3 = Theme.Orange
MinBtn.Text = ""
MakeCorner(MinBtn, 6)

local Container = Instance.new("ScrollingFrame", MainFrame)
Container.Size = UDim2.new(1, 0, 1, -45)
Container.Position = UDim2.new(0, 0, 0, 45)
Container.BackgroundTransparency = 1
Container.ScrollBarThickness = 3
Container.ScrollBarImageColor3 = Theme.Accent
Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
Container.CanvasSize = UDim2.new(0,0,0,0)

MinBtn.MouseButton1Click:Connect(function()
    Settings.Minimized = not Settings.Minimized
    if Settings.Minimized then
        TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 320, 0, 40)}):Play()
        Container.Visible = false
    else
        TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 320, 0, 520)}):Play()
        Container.Visible = true
    end
end)

local Drag, DragS, StartP
Header.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then Drag=true; DragS=i.Position; StartP=MainFrame.Position end end)
UserInputService.InputChanged:Connect(function(i) if Drag and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-DragS; MainFrame.Position=UDim2.new(StartP.X.Scale,StartP.X.Offset+d.X,StartP.Y.Scale,StartP.Y.Offset+d.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then Drag=false end end)

local UIList = Instance.new("UIListLayout", Container)
UIList.Padding = UDim.new(0, 8)
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIList.SortOrder = Enum.SortOrder.LayoutOrder
local UIPad = Instance.new("UIPadding", Container); UIPad.PaddingTop=UDim.new(0,5); UIPad.PaddingBottom=UDim.new(0,20)

local function AddInput(ph)
    local F = Instance.new("Frame", Container); F.Size=UDim2.new(0.9,0,0,40); F.BackgroundColor3=Theme.Input; MakeCorner(F,8)
    local B = Instance.new("TextBox", F); B.Size=UDim2.new(1,-20,1,0); B.Position=UDim2.new(0,10,0,0); B.BackgroundTransparency=1
    B.Text=""; B.PlaceholderText=ph; B.TextColor3=Theme.Text; B.PlaceholderColor3=Theme.Gray; B.Font=Enum.Font.GothamBold; B.TextSize=14; B.TextXAlignment=Enum.TextXAlignment.Left
    local S = MakeStroke(F, Color3.fromRGB(50,50,50), 1)
    B.Focused:Connect(function() S.Color = Theme.Accent end); B.FocusLost:Connect(function() S.Color = Color3.fromRGB(50,50,50) end)
    return B
end

local function AddButton(text, color, cb)
    local B = Instance.new("TextButton", Container)
    B.Size = UDim2.new(0.9, 0, 0, 35)
    B.BackgroundColor3 = color or Theme.Header
    B.Text = text; B.TextColor3 = Theme.Text; B.Font = Enum.Font.GothamBold; B.TextSize = 14; B.AutoButtonColor = false; MakeCorner(B, 8)
    local S = MakeStroke(B, Color3.fromRGB(50,50,50), 1)
    B.MouseEnter:Connect(function() TweenService:Create(B, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Input}):Play() end)
    B.MouseLeave:Connect(function() TweenService:Create(B, TweenInfo.new(0.2), {BackgroundColor3 = color or Theme.Header}):Play() end)
    B.MouseButton1Click:Connect(function() TweenService:Create(S, TweenInfo.new(0.1), {Color = Theme.Text}):Play(); task.wait(0.1); TweenService:Create(S, TweenInfo.new(0.1), {Color = Color3.fromRGB(50,50,50)}):Play(); cb() end)
    return B
end

local function AddToggle(text, cb)
    local B = Instance.new("TextButton", Container); B.Size = UDim2.new(0.9, 0, 0, 40); B.BackgroundColor3 = Theme.Header; B.Text = ""; B.AutoButtonColor = false; MakeCorner(B, 8)
    local L = Instance.new("TextLabel", B); L.Text = text; L.Size = UDim2.new(0.7,0,1,0); L.Position=UDim2.new(0,15,0,0); L.BackgroundTransparency=1; L.TextColor3 = Theme.Text; L.Font=Enum.Font.GothamBold; L.TextSize=14; L.TextXAlignment=Enum.TextXAlignment.Left
    local Box = Instance.new("Frame", B); Box.Size = UDim2.new(0, 40, 0, 20); Box.Position=UDim2.new(1,-50,0.5,-10); Box.BackgroundColor3=Theme.Input; MakeCorner(Box, 20)
    local Dot = Instance.new("Frame", Box); Dot.Size = UDim2.new(0, 16, 0, 16); Dot.Position=UDim2.new(0,2,0.5,-8); Dot.BackgroundColor3=Theme.Gray; MakeCorner(Dot, 20)
    local state = false
    B.MouseButton1Click:Connect(function() state = not state
        if state then TweenService:Create(Box, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play(); TweenService:Create(Dot, TweenInfo.new(0.2), {Position = UDim2.new(1,-18,0.5,-8), BackgroundColor3 = Theme.Text}):Play()
        else TweenService:Create(Box, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Input}):Play(); TweenService:Create(Dot, TweenInfo.new(0.2), {Position = UDim2.new(0,2,0.5,-8), BackgroundColor3 = Theme.Gray}):Play() end
        cb(state)
    end)
    return B
end

local function AddSlider(text, min, max, default, cb)
    local F = Instance.new("Frame", Container); F.Size=UDim2.new(0.9,0,0,50); F.BackgroundTransparency=1
    local L = Instance.new("TextLabel", F); L.Text=text..": "..default; L.Size=UDim2.new(1,0,0,20); L.BackgroundTransparency=1; L.TextColor3=Theme.Gray; L.Font=Enum.Font.Gotham; L.TextSize=12; L.TextXAlignment=Enum.TextXAlignment.Left
    local Bar = Instance.new("Frame", F); Bar.Size=UDim2.new(1,0,0,6); Bar.Position=UDim2.new(0,0,0,25); Bar.BackgroundColor3=Theme.Input; MakeCorner(Bar,3)
    local Fill = Instance.new("Frame", Bar); Fill.Size=UDim2.new((default-min)/(max-min),0,1,0); Fill.BackgroundColor3=Theme.Accent; MakeCorner(Fill,3)
    local Trig = Instance.new("TextButton", Bar); Trig.Size=UDim2.new(1,0,1,0); Trig.BackgroundTransparency=1; Trig.Text=""
    local dragging = false
    Trig.MouseButton1Down:Connect(function() dragging=true end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
        local pos = math.clamp((i.Position.X - Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X, 0, 1); local val = math.floor(min + ((max-min)*pos)); TweenService:Create(Fill, TweenInfo.new(0.1), {Size = UDim2.new(pos,0,1,0)}):Play(); L.Text = text..": "..val; cb(val)
    end end)
end

local function AddSection(txt)
    local L = Instance.new("TextLabel", Container); L.Size=UDim2.new(0.9,0,0,20); L.BackgroundTransparency=1; L.Text=txt; L.TextColor3=Theme.Accent; L.Font=Enum.Font.GothamBlack; L.TextSize=12; L.TextXAlignment=Enum.TextXAlignment.Left
    local Line = Instance.new("Frame", L); Line.Size=UDim2.new(1,0,0,1); Line.Position=UDim2.new(0,0,1,0); Line.BackgroundColor3=Theme.Accent; Line.BorderSizePixel=0
end

AddSection("HEDEF SEÇİMİ")
local PInput = AddInput("Oyuncu Adı (Kısaltılabilir)")

local function FindPlayer(str)
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #str) == str:lower() or p.DisplayName:lower():sub(1, #str) == str:lower() then return p end
    end
    return nil
end

AddButton("Oyuncuyu Seç", Theme.Header, function()
    local p = FindPlayer(PInput.Text)
    if p then Settings.Target = p; PInput.Text = p.Name; PInput.TextColor3 = Theme.Green else Settings.Target = nil; PInput.Text = "BULUNAMADI"; PInput.TextColor3 = Theme.Red; task.wait(1); PInput.Text = ""; PInput.TextColor3 = Theme.Text end
end)

AddButton("Yanına Işınlan (TP)", Theme.Header, function()
    if Settings.Target and Settings.Target.Character and Settings.Target.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then
        LocalPlayer.Character.HumanoidRootPart.CFrame = Settings.Target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
    end
end)

AddSection("SERVER & CHAT & FREECAM")
AddButton("Server Hop (Başka Sunucu)", Theme.Red, function()
    local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    for _, s in pairs(servers.data) do
        if s.playing ~= s.maxPlayers then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
            break
        end
    end
end)

AddButton("Rejoin (Yeniden Bağlan)", Theme.Accent, function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)

AddToggle("Chat Logger (Log Paneli)", function(v) Settings.ChatLogVisible = v; ChatFrame.Visible = v end)

AddToggle("Freecam [P]", function(v)
    Settings.Freecam = v
    if v then
        Camera.CameraType = Enum.CameraType.Scriptable
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.Anchored = true
            FreecamPos = Camera.CFrame.Position
            local rx, ry, rz = Camera.CFrame:ToEulerAnglesYXZ()
            FreecamRot = Vector2.new(rx, ry)
        end
    else
        Camera.CameraType = Enum.CameraType.Custom
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.Anchored = false
        end
    end
end)
AddSlider("Freecam Hızı", 0.1, 5, 1, function(v) Settings.FreecamSpeed = v end)

AddSection("GÖRSEL & TAKİP")
AddToggle("Monitörü Aç/Kapat", function(v) Settings.MonitorVisible = v; MonitorFrame.Visible = v end)
AddToggle("Loop Follow (Takip)", function(v) Settings.LoopFollow = v end)
AddSlider("Takip Mesafesi", 1, 50, 5, function(v) Settings.FollowDist = v end)
AddToggle("Spectate (Kalıcı İzle)", function(v) Settings.Spectating = v; if not v and LocalPlayer.Character then Camera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid") end end)

AddToggle("Infinite Zoom (Sınırsız)", function(v) 
    Settings.InfiniteZoom = v
    if not v then LocalPlayer.CameraMaxZoomDistance = 128 end
end)

AddSection("ESP & GÖRÜŞ")
AddToggle("ESP (İsim & Mesafe)", function(v) 
    Settings.ESP = v
    if not v then 
        for _, p in pairs(Players:GetPlayers()) do 
            if p.Character and p.Character:FindFirstChild("VexelESP") then p.Character.VexelESP:Destroy() end 
        end 
    end 
end)

AddToggle("Chams (Parlak Karakter)", function(v)
    Settings.Chams = v
    if not v then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("VexelCham") then p.Character.VexelCham:Destroy() end
        end
    end
end)

AddSection("KARAKTER & İŞLEVSEL")
AddToggle("Anti-Ragdoll (Düşme Önle)", function(v) Settings.AntiRagdoll = v end)

AddToggle("Click Delete (CTRL+Tık)", function(v) Settings.ClickDelete = v end)

local FlyToggle = AddToggle("Uçuş (Fly) [F]", function(v) 
    Settings.Fly = v
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    
    if v then
        if root and hum then
            local bv = Instance.new("BodyVelocity")
            bv.Name = "VexelFlyBV"
            bv.Parent = root
            bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            bv.Velocity = Vector3.new(0,0,0)
            
            local bg = Instance.new("BodyGyro")
            bg.Name = "VexelFlyBG"
            bg.Parent = root
            bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            bg.P = 10000
            
            hum.PlatformStand = true
        end
    else
        if root then
            if root:FindFirstChild("VexelFlyBV") then root.VexelFlyBV:Destroy() end
            if root:FindFirstChild("VexelFlyBG") then root.VexelFlyBG:Destroy() end
        end
        if hum then hum.PlatformStand = false end
    end
end)

AddSlider("Uçuş Hızı", 10, 300, 50, function(v) Settings.FlySpeed = v end)
AddToggle("Noclip (Duvar Geç)", function(v) Settings.Noclip = v end)
AddButton("Fling (Troll Fırlat)", Theme.Red, function()
    if Settings.Target and Settings.Target.Character and LocalPlayer.Character then
        local T = Settings.Target.Character:FindFirstChild("HumanoidRootPart")
        local M = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if T and M then
            local oldPos = M.CFrame
            local bv = Instance.new("BodyVelocity", M); bv.MaxForce=Vector3.new(math.huge,math.huge,math.huge); bv.Velocity=Vector3.zero
            local bav = Instance.new("BodyAngularVelocity", M); bav.MaxTorque=Vector3.new(math.huge,math.huge,math.huge); bav.AngularVelocity=Vector3.new(0,10000,0)
            local t = tick()
            local con; con = RunService.RenderStepped:Connect(function()
                if tick()-t > 1.5 or not Settings.Target.Character then con:Disconnect(); bv:Destroy(); bav:Destroy(); M.CFrame = oldPos; M.Velocity=Vector3.zero; M.RotVelocity=Vector3.zero else M.CFrame = T.CFrame end
            end)
        end
    end
end)
AddToggle("CTRL + Tık Işınlan", function(v) Settings.ClickTP = v end)

UserInputService.InputChanged:Connect(function(input, gpe)
    if Settings.Freecam and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = UserInputService:GetMouseDelta()
        local sensitivity = 0.005
        FreecamRot = FreecamRot - Vector2.new(delta.Y, delta.X) * sensitivity
        FreecamRot = Vector2.new(math.clamp(FreecamRot.X, -1.5, 1.5), FreecamRot.Y)
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        local camRot = CFrame.fromEulerAnglesYXZ(FreecamRot.X, FreecamRot.Y, 0)
        local speed = Settings.FreecamSpeed * 1.5
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then speed = speed * 3 end
        local move = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0, 0, -1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0, 0, 1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-1, 0, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new(1, 0, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.E) then move = move + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then move = move + Vector3.new(0, -1, 0) end
        FreecamPos = FreecamPos + (camRot:VectorToWorldSpace(move) * speed)
        Camera.CFrame = CFrame.new(FreecamPos) * camRot
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if Settings.InfiniteZoom then
        LocalPlayer.CameraMaxZoomDistance = 9e9
    end

    if Settings.Fly and LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local bv = root:FindFirstChild("VexelFlyBV")
            local bg = root:FindFirstChild("VexelFlyBG")
            if bv and bg then
                bg.CFrame = Camera.CFrame
                local vel = Vector3.new(0,0,0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vel = vel - Vector3.new(0,1,0) end
                bv.Velocity = vel * Settings.FlySpeed
            end
        end
    end
    
    if Settings.Spectating and Settings.Target and Settings.Target.Character then
        local hum = Settings.Target.Character:FindFirstChild("Humanoid")
        if hum then Camera.CameraSubject = hum end
    elseif Settings.Spectating then end
    
    if Settings.Noclip and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end end
    end

    if Settings.AntiRagdoll and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        if hum.PlatformStand then hum.PlatformStand = false end
        if hum:GetState() == Enum.HumanoidStateType.Ragdoll or hum:GetState() == Enum.HumanoidStateType.FallingDown then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if Settings.LoopFollow and Settings.Target and Settings.Target.Character and LocalPlayer.Character then
        local tRoot = Settings.Target.Character:FindFirstChild("HumanoidRootPart")
        local mRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if tRoot and mRoot then mRoot.CFrame = tRoot.CFrame * CFrame.new(0, 2, Settings.FollowDist); mRoot.AssemblyLinearVelocity = Vector3.zero end
    end
    
    if Settings.MonitorVisible and Settings.Target then
        local char = Settings.Target.Character
        if char then
            MonName.Text = "İsim: " .. Settings.Target.Name
            local hum = char:FindFirstChild("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            local tool = char:FindFirstChildOfClass("Tool")
            if hum then MonHP.Text = "Can: " .. math.floor(hum.Health) .. "%" else MonHP.Text = "Can: 0%" end
            if tool then MonTool.Text = "Eşya: " .. tool.Name else MonTool.Text = "Eşya: Yok" end
            if root and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local d = math.floor((root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
                MonDist.Text = "Mesafe: " .. d .. "m"
            else MonDist.Text = "Mesafe: -" end
        else MonName.Text = "İsim: " .. Settings.Target.Name .. " (Yok)"; MonHP.Text = "Can: Ölü/Spawn" end
    else if not Settings.Target then MonName.Text = "Hedef Seçilmedi" end end
    
    if Settings.ESP or Settings.Chams then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                if Settings.ESP then
                    if p.Character:FindFirstChild("VexelESP") then
                        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        local tRoot = p.Character:FindFirstChild("HumanoidRootPart")
                        local distTxt = ""
                        if root and tRoot then distTxt = " [" .. math.floor((root.Position - tRoot.Position).Magnitude) .. "m]" end
                        p.Character.VexelESP.TextLabel.Text = p.Name .. distTxt
                    else
                        local bg = Instance.new("BillboardGui", p.Character)
                        bg.Name = "VexelESP"; bg.Size=UDim2.new(0,200,0,50); bg.StudsOffset=Vector3.new(0,3,0); bg.AlwaysOnTop=true
                        local t = Instance.new("TextLabel", bg); t.Size=UDim2.new(1,0,1,0); t.BackgroundTransparency=1; t.Text=p.Name; t.TextColor3=Theme.Accent; t.Font=Enum.Font.GothamBold; t.TextSize=13; t.TextStrokeTransparency=0.5
                    end
                elseif p.Character:FindFirstChild("VexelESP") then
                    p.Character.VexelESP:Destroy()
                end
                
                if Settings.Chams then
                    if not p.Character:FindFirstChild("VexelCham") then
                        local hl = Instance.new("Highlight", p.Character); hl.Name="VexelCham"; hl.FillColor=Theme.Accent; hl.OutlineColor=Color3.new(1,1,1); hl.FillTransparency=0.5; hl.OutlineTransparency=0
                    end
                elseif p.Character:FindFirstChild("VexelCham") then
                    p.Character.VexelCham:Destroy()
                end
            end
        end
    end
end)

Mouse.Button1Down:Connect(function() 
    if Settings.ClickTP and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and Mouse.Target and LocalPlayer.Character then 
        local r=LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if r then r.CFrame=CFrame.new(Mouse.Hit.Position+Vector3.new(0,3,0)) end 
    end 
    
    if Settings.ClickDelete and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and Mouse.Target then
        Mouse.Target:Destroy()
    end
end)

UserInputService.InputBegan:Connect(function(i, g) 
    if i.KeyCode == Enum.KeyCode.F1 then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end

    if not g then
        if i.KeyCode == Settings.FlyKey then 
            Settings.Fly = not Settings.Fly
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if Settings.Fly then
                if root and hum then
                    local bv = Instance.new("BodyVelocity"); bv.Name="VexelFlyBV"; bv.Parent=root; bv.MaxForce=Vector3.new(1e9,1e9,1e9); bv.Velocity=Vector3.new(0,0,0)
                    local bg = Instance.new("BodyGyro"); bg.Name="VexelFlyBG"; bg.Parent=root; bg.MaxTorque=Vector3.new(1e9,1e9,1e9); bg.P=10000
                    hum.PlatformStand=true
                end
            else
                if root then if root:FindFirstChild("VexelFlyBV") then root.VexelFlyBV:Destroy() end; if root:FindFirstChild("VexelFlyBG") then root.VexelFlyBG:Destroy() end end
                if hum then hum.PlatformStand=false end
            end
        end
        if i.KeyCode == Settings.FreecamKey then
            Settings.Freecam = not Settings.Freecam
            if Settings.Freecam then
                Camera.CameraType = Enum.CameraType.Scriptable
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.Anchored = true
                    FreecamPos = Camera.CFrame.Position
                    local rx, ry, rz = Camera.CFrame:ToEulerAnglesYXZ()
                    FreecamRot = Vector2.new(rx, ry)
                end
            else
                Camera.CameraType = Enum.CameraType.Custom
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.Anchored = false
                end
            end
        end
    end 
end)

LocalPlayer.CharacterAdded:Connect(function() Settings.Fly=false; Settings.LoopFollow=false; Settings.Noclip=false; Settings.Freecam=false; Camera.CameraType=Enum.CameraType.Custom; if Settings.Spectating and Settings.Target then else Camera.CameraSubject=LocalPlayer.Character:WaitForChild("Humanoid") end end)

print("VEXEL CONTROL MENU LOADED")
