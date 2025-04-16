local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

local Drawings = {
    ESP = {},
    Tracers = {},
    Boxes = {},
    Healthbars = {},
    Names = {},
    Distances = {},
    Snaplines = {},
    Skeleton = {},
    AimFOV = {
        Circle = nil,
        Crosshair = nil,
        Arrow = nil
    }
}

local Colors = {
    Enemy = Color3.fromRGB(255, 25, 25),
    Ally = Color3.fromRGB(25, 255, 25),
    Neutral = Color3.fromRGB(255, 255, 255),
    Selected = Color3.fromRGB(255, 210, 0),
    Health = Color3.fromRGB(0, 255, 0),
    Distance = Color3.fromRGB(200, 200, 200),
    Rainbow = nil,
    FOV = Color3.fromRGB(255, 255, 255)
}

local Highlights = {}

local Settings = {
    Enabled = false,
    TeamCheck = false,
    ShowTeam = false,
    VisibilityCheck = true,
    BoxESP = false,
    BoxStyle = "Corner",
    BoxOutline = true,
    BoxFilled = false,
    BoxFillTransparency = 0.5,
    BoxThickness = 1,
    TracerESP = false,
    TracerOrigin = "Bottom",
    TracerStyle = "Line",
    TracerThickness = 1,
    HealthESP = false,
    HealthStyle = "Bar",
    HealthBarSide = "Left",
    HealthTextSuffix = "HP",
    NameESP = false,
    NameMode = "DisplayName",
    ShowDistance = true,
    DistanceUnit = "studs",
    TextSize = 14,
    TextFont = 2,
    RainbowSpeed = 1,
    MaxDistance = 1000,
    RefreshRate = 1/144,
    Snaplines = false,
    SnaplineStyle = "Straight",
    RainbowEnabled = false,
    RainbowBoxes = false,
    RainbowTracers = false,
    RainbowText = false,
    RainbowFOV = false,
    ChamsEnabled = false,
    ChamsOutlineColor = Color3.fromRGB(255, 255, 255),
    ChamsFillColor = Color3.fromRGB(255, 0, 0),
    ChamsOccludedColor = Color3.fromRGB(150, 0, 0),
    ChamsTransparency = 0.5,
    ChamsOutlineTransparency = 0,
    ChamsOutlineThickness = 0.1,
    SkeletonESP = false,
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    SkeletonThickness = 1.5,
    SkeletonTransparency = 1,
    FlyEnabled = false,
    FlySpeed = 50,
    AimBotEnabled = false,
    AimBotTeamCheck = true,
    AimBotAimTeam = false,
    AimBotFOV = 50,
    AimBotFOVShape = "Circle",
    AimBotFOVThickness = 1,
    AimBotTargetPart = "Head",
    AimBotSmoothness = 0.1,
    SilentAimEnabled = false,
    SilentAimHitChance = 100,
    SilentAimFOV = 50,
    SilentAimTargetPart = "Head",
    TriggerBotEnabled = false,
    TriggerBotDelay = 0.1,
    SpeedHackEnabled = false,
    SpeedHackValue = 50,
    NoClipEnabled = false,
    AutoFarmEnabled = false,
    AutoFarmRadius = 100,
    AutoFarmTarget = "All"
}

local flying = false
local bodyVelocity
local bodyGyro
local aimTarget = nil
local noClipConnection
local speedConnection

local function toggleFly(state)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local rootPart = character.HumanoidRootPart
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    if state then
        humanoid.PlatformStand = true
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Parent = rootPart

        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bodyGyro.CFrame = rootPart.CFrame
        bodyGyro.Parent = rootPart

        while flying and rootPart and humanoid do
            local camera = workspace.CurrentCamera
            local moveDirection = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end

            if moveDirection.Magnitude > 0 then
                moveDirection = moveDirection.Unit
                bodyVelocity.Velocity = moveDirection * Settings.FlySpeed
            else
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end

            bodyGyro.CFrame = CFrame.new(Vector3.new(0, 0, 0), camera.CFrame.LookVector)
            wait()
        end
    else
        if bodyVelocity then bodyVelocity:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end
        if humanoid then humanoid.PlatformStand = false end
    end
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    
    local box = {
        TopLeft = Drawing.new("Line"),
        TopRight = Drawing.new("Line"),
        BottomLeft = Drawing.new("Line"),
        BottomRight = Drawing.new("Line"),
        Left = Drawing.new("Line"),
        Right = Drawing.new("Line"),
        Top = Drawing.new("Line"),
        Bottom = Drawing.new("Line")
    }
    
    for _, line in pairs(box) do
        line.Visible = false
        line.Color = Colors.Enemy
        line.Thickness = Settings.BoxThickness
    end
    
    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = Colors.Enemy
    tracer.Thickness = Settings.TracerThickness
    
    local healthBar = {
        Outline = Drawing.new("Square"),
        Fill = Drawing.new("Square"),
        Text = Drawing.new("Text")
    }
    
    for _, obj in pairs(healthBar) do
        obj.Visible = false
        if obj == healthBar.Fill then
            obj.Color = Colors.Health
            obj.Filled = true
        elseif obj == healthBar.Text then
            obj.Center = true
            obj.Size = Settings.TextSize
            obj.Color = Colors.Health
            obj.Font = Settings.TextFont
        end
    end
    
    local info = {
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text")
    }
    
    for _, text in pairs(info) do
        text.Visible = false
        text.Center = true
        text.Size = Settings.TextSize
        text.Color = Colors.Enemy
        text.Font = Settings.TextFont
        text.Outline = true
    end
    
    local snapline = Drawing.new("Line")
    snapline.Visible = false
    snapline.Color = Colors.Enemy
    snapline.Thickness = 1
    
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Settings.ChamsFillColor
    highlight.OutlineColor = Settings.ChamsOutlineColor
    highlight.FillTransparency = Settings.ChamsTransparency
    highlight.OutlineTransparency = Settings.ChamsOutlineTransparency
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = Settings.ChamsEnabled
    
    Highlights[player] = highlight
    
    local skeleton = {
        Head = Drawing.new("Line"),
        Neck = Drawing.new("Line"),
        UpperSpine = Drawing.new("Line"),
        LowerSpine = Drawing.new("Line"),
        LeftShoulder = Drawing.new("Line"),
        LeftUpperArm = Drawing.new("Line"),
        LeftLowerArm = Drawing.new("Line"),
        LeftHand = Drawing.new("Line"),
        RightShoulder = Drawing.new("Line"),
        RightUpperArm = Drawing.new("Line"),
        RightLowerArm = Drawing.new("Line"),
        RightHand = Drawing.new("Line"),
        LeftHip = Drawing.new("Line"),
        LeftUpperLeg = Drawing.new("Line"),
        LeftLowerLeg = Drawing.new("Line"),
        LeftFoot = Drawing.new("Line"),
        RightHip = Drawing.new("Line"),
        RightUpperLeg = Drawing.new("Line"),
        RightLowerLeg = Drawing.new("Line"),
        RightFoot = Drawing.new("Line")
    }
    
    for _, line in pairs(skeleton) do
        line.Visible = false
        line.Color = Settings.SkeletonColor
        line.Thickness = Settings.SkeletonThickness
        line.Transparency = Settings.SkeletonTransparency
    end
    
    Drawings.Skeleton[player] = skeleton
    Drawings.ESP[player] = {
        Box = box,
        Tracer = tracer,
        HealthBar = healthBar,
        Info = info,
        Snapline = snapline
    }
end

local function RemoveESP(player)
    local esp = Drawings.ESP[player]
    if esp then
        for _, obj in pairs(esp.Box) do obj:Remove() end
        esp.Tracer:Remove()
        for _, obj in pairs(esp.HealthBar) do obj:Remove() end
        for _, obj in pairs(esp.Info) do obj:Remove() end
        esp.Snapline:Remove()
        Drawings.ESP[player] = nil
    end
    
    local highlight = Highlights[player]
    if highlight then
        highlight:Destroy()
        Highlights[player] = nil
    end
    
    local skeleton = Drawings.Skeleton[player]
    if skeleton then
        for _, line in pairs(skeleton) do
            line:Remove()
        end
        Drawings.Skeleton[player] = nil
    end
end

local function GetPlayerColor(player)
    if Settings.RainbowEnabled then
        if Settings.RainbowBoxes and Settings.BoxESP then return Colors.Rainbow end
        if Settings.RainbowTracers and Settings.TracerESP then return Colors.Rainbow end
        if Settings.RainbowText and (Settings.NameESP or Settings.HealthESP) then return Colors.Rainbow end
    end
    return player.Team == LocalPlayer.Team and Colors.Ally or Colors.Enemy
end

local function GetTracerOrigin()
    local origin = Settings.TracerOrigin
    if origin == "Bottom" then
        return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
    elseif origin == "Top" then
        return Vector2.new(Camera.ViewportSize.X/2, 0)
    elseif origin == "Mouse" then
        return UserInputService:GetMouseLocation()
    else
        return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    end
end

local function UpdateESP(player)
    if not Settings.Enabled then return end
    
    local esp = Drawings.ESP[player]
    if not esp then return end
    
    local character = player.Character
    if not character then 
        for _, obj in pairs(esp.Box) do obj.Visible = false end
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do
                line.Visible = false
            end
        end
        return 
    end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then 
        for _, obj in pairs(esp.Box) do obj.Visible = false end
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do
                line.Visible = false
            end
        end
        return 
    end
    
    local _, isOnScreen = Camera:WorldToViewportPoint(rootPart.Position)
    if not isOnScreen then
        for _, obj in pairs(esp.Box) do obj.Visible = false end
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do
                line.Visible = false
            end
        end
        return
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        for _, obj in pairs(esp.Box) do obj.Visible = false end
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do
                line.Visible = false
            end
        end
        return
    end
    
    local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
    
    if not onScreen or distance > Settings.MaxDistance then
        for _, obj in pairs(esp.Box) do obj.Visible = false end
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        return
    end
    
    if Settings.TeamCheck and player.Team == LocalPlayer.Team and not Settings.ShowTeam then
        for _, obj in pairs(esp.Box) do obj.Visible = false end
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        return
    end
    
    local color = GetPlayerColor(player)
    local size = character:GetExtentsSize()
    local cf = rootPart.CFrame
    
    local top, top_onscreen = Camera:WorldToViewportPoint(cf * CFrame.new(0, size.Y/2, 0).Position)
    local bottom, bottom_onscreen = Camera:WorldToViewportPoint(cf * CFrame.new(0, -size.Y/2, 0).Position)
    
    if not top_onscreen or not bottom_onscreen then
        for _, obj in pairs(esp.Box) do obj.Visible = false end
        return
    end
    
    local screenSize = bottom.Y - top.Y
    local boxWidth = screenSize * 0.65
    local boxPosition = Vector2.new(top.X - boxWidth/2, top.Y)
    local boxSize = Vector2.new(boxWidth, screenSize)
    
    for _, obj in pairs(esp.Box) do
        obj.Visible = false
    end
    
    if Settings.BoxESP then
        if Settings.BoxStyle == "ThreeD" then
            local front = {
                TL = Camera:WorldToViewportPoint((cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2)).Position),
                TR = Camera:WorldToViewportPoint((cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2)).Position),
                BL = Camera:WorldToViewportPoint((cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2)).Position),
                BR = Camera:WorldToViewportPoint((cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2)).Position)
            }
            
            local back = {
                TL = Camera:WorldToViewportPoint((cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2)).Position),
                TR = Camera:WorldToViewportPoint((cf * CFrame.new(size.X/2, size.Y/2, size.Z/2)).Position),
                BL = Camera:WorldToViewportPoint((cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2)).Position),
                BR = Camera:WorldToViewportPoint((cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2)).Position)
            }
            
            if not (front.TL.Z > 0 and front.TR.Z > 0 and front.BL.Z > 0 and front.BR.Z > 0 and
                   back.TL.Z > 0 and back.TR.Z > 0 and back.BL.Z > 0 and back.BR.Z > 0) then
                for _, obj in pairs(esp.Box) do obj.Visible = false end
                return
            end
            
            local function toVector2(v3) return Vector2.new(v3.X, v3.Y) end
            front.TL, front.TR = toVector2(front.TL), toVector2(front.TR)
            front.BL, front.BR = toVector2(front.BL), toVector2(front.BR)
            back.TL, back.TR = toVector2(back.TL), toVector2(back.TR)
            back.BL, back.BR = toVector2(back.BL), toVector2(back.BR)
            
            esp.Box.TopLeft.From = front.TL
            esp.Box.TopLeft.To = front.TR
            esp.Box.TopLeft.Visible = true
            
            esp.Box.TopRight.From = front.TR
            esp.Box.TopRight.To = front.BR
            esp.Box.TopRight.Visible = true
            
            esp.Box.BottomLeft.From = front.BL
            esp.Box.BottomLeft.To = front.BR
            esp.Box.BottomLeft.Visible = true
            
            esp.Box.BottomRight.From = front.TL
            esp.Box.BottomRight.To = front.BL
            esp.Box.BottomRight.Visible = true
            
            esp.Box.Left.From = back.TL
            esp.Box.Left.To = back.TR
            esp.Box.Left.Visible = true
            
            esp.Box.Right.From = back.TR
            esp.Box.Right.To = back.BR
            esp.Box.Right.Visible = true
            
            esp.Box.Top.From = back.BL
            esp.Box.Top.To = back.BR
            esp.Box.Top.Visible = true
            
            esp.Box.Bottom.From = back.TL
            esp.Box.Bottom.To = back.BL
            esp.Box.Bottom.Visible = true
            
            local function drawConnectingLine(from, to, visible)
                local line = Drawing.new("Line")
                line.Visible = visible
                line.Color = color
                line.Thickness = Settings.BoxThickness
                line.From = from
                line.To = to
                return line
            end
            
            local connectors = {
                drawConnectingLine(front.TL, back.TL, true),
                drawConnectingLine(front.TR, back.TR, true),
                drawConnectingLine(front.BL, back.BL, true),
                drawConnectingLine(front.BR, back.BR, true)
            }
            
            task.spawn(function()
                task.wait()
                for _, line in ipairs(connectors) do
                    line:Remove()
                end
            end)
            
        elseif Settings.BoxStyle == "Corner" then
            local cornerSize = boxWidth * 0.2
            
            esp.Box.TopLeft.From = boxPosition
            esp.Box.TopLeft.To = boxPosition + Vector2.new(cornerSize, 0)
            esp.Box.TopLeft.Visible = true
            
            esp.Box.TopRight.From = boxPosition + Vector2.new(boxSize.X, 0)
            esp.Box.TopRight.To = boxPosition + Vector2.new(boxSize.X - cornerSize, 0)
            esp.Box.TopRight.Visible = true
            
            esp.Box.BottomLeft.From = boxPosition + Vector2.new(0, boxSize.Y)
            esp.Box.BottomLeft.To = boxPosition + Vector2.new(cornerSize, boxSize.Y)
            esp.Box.BottomLeft.Visible = true
            
            esp.Box.BottomRight.From = boxPosition + Vector2.new(boxSize.X, boxSize.Y)
            esp.Box.BottomRight.To = boxPosition + Vector2.new(boxSize.X - cornerSize, boxSize.Y)
            esp.Box.BottomRight.Visible = true
            
            esp.Box.Left.From = boxPosition
            esp.Box.Left.To = boxPosition + Vector2.new(0, cornerSize)
            esp.Box.Left.Visible = true
            
            esp.Box.Right.From = boxPosition + Vector2.new(boxSize.X, 0)
            esp.Box.Right.To = boxPosition + Vector2.new(boxSize.X, cornerSize)
            esp.Box.Right.Visible = true
            
            esp.Box.Top.From = boxPosition + Vector2.new(0, boxSize.Y)
            esp.Box.Top.To = boxPosition + Vector2.new(0, boxSize.Y - cornerSize)
            esp.Box.Top.Visible = true
            
            esp.Box.Bottom.From = boxPosition + Vector2.new(boxSize.X, boxSize.Y)
            esp.Box.Bottom.To = boxPosition + Vector2.new(boxSize.X, boxSize.Y - cornerSize)
            esp.Box.Bottom.Visible = true
            
        else
            esp.Box.Left.From = boxPosition
            esp.Box.Left.To = boxPosition + Vector2.new(0, boxSize.Y)
            esp.Box.Left.Visible = true
            
            esp.Box.Right.From = boxPosition + Vector2.new(boxSize.X, 0)
            esp.Box.Right.To = boxPosition + Vector2.new(boxSize.X, boxSize.Y)
            esp.Box.Right.Visible = true
            
            esp.Box.Top.From = boxPosition
            esp.Box.Top.To = boxPosition + Vector2.new(boxSize.X, 0)
            esp.Box.Top.Visible = true
            
            esp.Box.Bottom.From = boxPosition + Vector2.new(0, boxSize.Y)
            esp.Box.Bottom.To = boxPosition + Vector2.new(boxSize.X, boxSize.Y)
            esp.Box.Bottom.Visible = true
            
            esp.Box.TopLeft.Visible = false
            esp.Box.TopRight.Visible = false
            esp.Box.BottomLeft.Visible = false
            esp.Box.BottomRight.Visible = false
        end
        
        for _, obj in pairs(esp.Box) do
            if obj.Visible then
                obj.Color = color
                obj.Thickness = Settings.BoxThickness
            end
        end
    end
    
    if Settings.TracerESP then
        esp.Tracer.From = GetTracerOrigin()
        esp.Tracer.To = Vector2.new(pos.X, pos.Y)
        esp.Tracer.Color = color
        esp.Tracer.Visible = true
    else
        esp.Tracer.Visible = false
    end
    
    if Settings.HealthESP then
        local health = humanoid.Health
        local maxHealth = humanoid.MaxHealth
        local healthPercent = health/maxHealth
        
        local barHeight = screenSize * 0.8
        local barWidth = 4
        local barPos = Vector2.new(
            boxPosition.X - barWidth - 2,
            boxPosition.Y + (screenSize - barHeight)/2
        )
        
        esp.HealthBar.Outline.Size = Vector2.new(barWidth, barHeight)
        esp.HealthBar.Outline.Position = barPos
        esp.HealthBar.Outline.Visible = true
        
        esp.HealthBar.Fill.Size = Vector2.new(barWidth - 2, barHeight * healthPercent)
        esp.HealthBar.Fill.Position = Vector2.new(barPos.X + 1, barPos.Y + barHeight * (1-healthPercent))
        esp.HealthBar.Fill.Color = Color3.fromRGB(255 - (255 * healthPercent), 255 * healthPercent, 0)
        esp.HealthBar.Fill.Visible = true
        
        if Settings.HealthStyle == "Both" or Settings.HealthStyle == "Text" then
            esp.HealthBar.Text.Text = math.floor(health) .. Settings.HealthTextSuffix
            esp.HealthBar.Text.Position = Vector2.new(barPos.X + barWidth + 2, barPos.Y + barHeight/2)
            esp.HealthBar.Text.Visible = true
        else
            esp.HealthBar.Text.Visible = false
        end
    else
        for _, obj in pairs(esp.HealthBar) do
            obj.Visible = false
        end
    end
    
    if Settings.NameESP then
        esp.Info.Name.Text = player.DisplayName
        esp.Info.Name.Position = Vector2.new(
            boxPosition.X + boxWidth/2,
            boxPosition.Y - 20
        )
        esp.Info.Name.Color = color
        esp.Info.Name.Visible = true
    else
        esp.Info.Name.Visible = false
    end
    
    if Settings.Snaplines then
        esp.Snapline.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
        esp.Snapline.To = Vector2.new(pos.X, pos.Y)
        esp.Snapline.Color = color
        esp.Snapline.Visible = true
    else
        esp.Snapline.Visible = false
    end
    
    local highlight = Highlights[player]
    if highlight then
        if Settings.ChamsEnabled and character then
            highlight.Parent = character
            highlight.FillColor = Settings.ChamsFillColor
            highlight.OutlineColor = Settings.ChamsOutlineColor
            highlight.FillTransparency = Settings.ChamsTransparency
            highlight.OutlineTransparency = Settings.ChamsOutlineTransparency
            highlight.Enabled = true
        else
            highlight.Enabled = false
        end
    end
    
    if Settings.SkeletonESP then
        local function getBonePositions(character)
            if not character then return nil end
            
            local bones = {
                Head = character:FindFirstChild("Head"),
                UpperTorso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"),
                LowerTorso = character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso"),
                RootPart = character:FindFirstChild("HumanoidRootPart"),
                LeftUpperArm = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm"),
                LeftLowerArm = character:FindFirstChild("LeftLowerArm") or character:FindFirstChild("Left Arm"),
                LeftHand = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm"),
                RightUpperArm = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm"),
                RightLowerArm = character:FindFirstChild("RightLowerArm") or character:FindFirstChild("Right Arm"),
                RightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"),
                LeftUpperLeg = character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg"),
                LeftLowerLeg = character:FindFirstChild("LeftLowerLeg") or character:FindFirstChild("Left Leg"),
                LeftFoot = character:FindFirstChild("LeftFoot") or character:FindFirstChild("Left Leg"),
                RightUpperLeg = character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg"),
                RightLowerLeg = character:FindFirstChild("RightLowerLeg") or character:FindFirstChild("Right Leg"),
                RightFoot = character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg")
            }
            
            if not (bones.Head and bones.UpperTorso) then return nil end
            
            return bones
        end
        
        local function drawBone(from, to, line)
            if not from or not to then 
                line.Visible = false
                return 
            end
            
            local fromPos = (from.CFrame * CFrame.new(0, 0, 0)).Position
            local toPos = (to.CFrame * CFrame.new(0, 0, 0)).Position
            
            local fromScreen, fromVisible = Camera:WorldToViewportPoint(fromPos)
            local toScreen, toVisible = Camera:WorldToViewportPoint(toPos)
            
            if not (fromVisible and toVisible) or fromScreen.Z < 0 or toScreen.Z < 0 then
                line.Visible = false
                return
            end
            
            local screenBounds = Camera.ViewportSize
            if fromScreen.X < 0 or fromScreen.X > screenBounds.X or
               fromScreen.Y < 0 or fromScreen.Y > screenBounds.Y or
               toScreen.X < 0 or toScreen.X > screenBounds.X or
               toScreen.Y < 0 or toScreen.Y > screenBounds.Y then
                line.Visible = false
                return
            end
            
            line.From = Vector2.new(fromScreen.X, fromScreen.Y)
            line.To = Vector2.new(toScreen.X, toScreen.Y)
            line.Color = Settings.SkeletonColor
            line.Thickness = Settings.SkeletonThickness
            line.Transparency = Settings.SkeletonTransparency
            line.Visible = true
        end
        
        local bones = getBonePositions(character)
        if bones then
            local skeleton = Drawings.Skeleton[player]
            if skeleton then
                drawBone(bones.Head, bones.UpperTorso, skeleton.Head)
                drawBone(bones.UpperTorso, bones.LowerTorso, skeleton.UpperSpine)
                drawBone(bones.UpperTorso, bones.LeftUpperArm, skeleton.LeftShoulder)
                drawBone(bones.LeftUpperArm, bones.LeftLowerArm, skeleton.LeftUpperArm)
                drawBone(bones.LeftLowerArm, bones.LeftHand, skeleton.LeftLowerArm)
                drawBone(bones.UpperTorso, bones.RightUpperArm, skeleton.RightShoulder)
                drawBone(bones.RightUpperArm, bones.RightLowerArm, skeleton.RightUpperArm)
                drawBone(bones.RightLowerArm, bones.RightHand, skeleton.RightLowerArm)
                drawBone(bones.LowerTorso, bones.LeftUpperLeg, skeleton.LeftHip)
                drawBone(bones.LeftUpperLeg, bones.LeftLowerLeg, skeleton.LeftUpperLeg)
                drawBone(bones.LeftLowerLeg, bones.LeftFoot, skeleton.LeftLowerLeg)
                drawBone(bones.LowerTorso, bones.RightUpperLeg, skeleton.RightHip)
                drawBone(bones.RightUpperLeg, bones.RightLowerLeg, skeleton.RightUpperLeg)
                drawBone(bones.RightLowerLeg, bones.RightFoot, skeleton.RightLowerLeg)
            end
        end
    else
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do
                line.Visible = false
            end
        end
    end
end

local function DisableESP()
    for _, player in ipairs(Players:GetPlayers()) do
        local esp = Drawings.ESP[player]
        if esp then
            for _, obj in pairs(esp.Box) do obj.Visible = false end
            esp.Tracer.Visible = false
            for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
            for _, obj in pairs(esp.Info) do obj.Visible = false end
            esp.Snapline.Visible = false
        end
        
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do
                line.Visible = false
            end
        end
    end
end

local function CleanupESP()
    for _, player in ipairs(Players:GetPlayers()) do
        RemoveESP(player)
    end
    Drawings.ESP = {}
    Drawings.Skeleton = {}
    Highlights = {}
    if Drawings.AimFOV.Circle then
        Drawings.AimFOV.Circle:Remove()
        Drawings.AimFOV.Circle = nil
    end
    if Drawings.AimFOV.Crosshair then
        for _, line in ipairs(Drawings.AimFOV.Crosshair) do
            line:Remove()
        end
        Drawings.AimFOV.Crosshair = nil
    end
    if Drawings.AimFOV.Arrow then
        for _, line in ipairs(Drawings.AimFOV.Arrow) do
            line:Remove()
        end
        Drawings.AimFOV.Arrow = nil
    end
end

local function GetClosestPlayerInFOV(fov, teamCheck, aimTeam)
    local closestPlayer = nil
    local closestDistance = math.huge
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end

        local humanoid = player.Character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end

        local targetPart = player.Character:FindFirstChild(Settings.AimBotTargetPart)
        if not targetPart then continue end

        if teamCheck and player.Team == LocalPlayer.Team and not aimTeam then continue end

        local partPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then continue end

        local screenPos = Vector2.new(partPos.X, partPos.Y)
        local distance = (screenPos - mousePos).Magnitude

        if distance <= fov and distance < closestDistance then
            closestDistance = distance
            closestPlayer = player
        end
    end

    return closestPlayer
end

local function UpdateAimBot()
    if not Settings.AimBotEnabled then
        aimTarget = nil
        return
    end

    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        aimTarget = nil
        return
    end

    aimTarget = GetClosestPlayerInFOV(Settings.AimBotFOV, Settings.AimBotTeamCheck, Settings.AimBotAimTeam)
    if not aimTarget then return end

    local targetPart = aimTarget.Character:FindFirstChild(Settings.AimBotTargetPart)
    if not targetPart then return end

    local targetPos = Camera:WorldToViewportPoint(targetPart.Position)
    local mousePos = UserInputService:GetMouseLocation()
    local newPos = mousePos + (Vector2.new(targetPos.X, targetPos.Y) - mousePos) * Settings.AimBotSmoothness

    mousemoverel((newPos.X - mousePos.X) * 0.3, (newPos.Y - mousePos.Y) * 0.3)
end

local function GetSilentAimTarget()
    if not Settings.SilentAimEnabled then return nil end
    if math.random(1, 100) > Settings.SilentAimHitChance then return nil end
    return GetClosestPlayerInFOV(Settings.SilentAimFOV, Settings.AimBotTeamCheck, Settings.AimBotAimTeam)
end

local function UpdateFOVShape()
    local mousePos = UserInputService:GetMouseLocation()
    local color = Settings.RainbowFOV and Colors.Rainbow or Colors.FOV

    if Drawings.AimFOV.Circle then
        Drawings.AimFOV.Circle.Visible = false
    end
    if Drawings.AimFOV.Crosshair then
        for _, line in ipairs(Drawings.AimFOV.Crosshair) do
            line.Visible = false
        end
    end
    if Drawings.AimFOV.Arrow then
        for _, line in ipairs(Drawings.AimFOV.Arrow) do
            line.Visible = false
        end
    end

    if not Settings.AimBotEnabled then return end

    if Settings.AimBotFOVShape == "Circle" then
        if not Drawings.AimFOV.Circle then
            Drawings.AimFOV.Circle = Drawing.new("Circle")
            Drawings.AimFOV.Circle.Thickness = Settings.AimBotFOVThickness
            Drawings.AimFOV.Circle.NumSides = 64
        end
        Drawings.AimFOV.Circle.Radius = Settings.AimBotFOV
        Drawings.AimFOV.Circle.Position = mousePos
        Drawings.AimFOV.Circle.Color = color
        Drawings.AimFOV.Circle.Visible = true
        Drawings.AimFOV.Circle.Thickness = Settings.AimBotFOVThickness

    elseif Settings.AimBotFOVShape == "Crosshair" then
        if not Drawings.AimFOV.Crosshair then
            Drawings.AimFOV.Crosshair = {
                Top = Drawing.new("Line"),
                Bottom = Drawing.new("Line"),
                Left = Drawing.new("Line"),
                Right = Drawing.new("Line")
            }
            for _, line in pairs(Drawings.AimFOV.Crosshair) do
                line.Thickness = Settings.AimBotFOVThickness
            end
        end

        local length = Settings.AimBotFOV / 2
        Drawings.AimFOV.Crosshair.Top.From = mousePos + Vector2.new(0, -length)
        Drawings.AimFOV.Crosshair.Top.To = mousePos + Vector2.new(0, -length / 2)
        Drawings.AimFOV.Crosshair.Bottom.From = mousePos + Vector2.new(0, length / 2)
        Drawings.AimFOV.Crosshair.Bottom.To = mousePos + Vector2.new(0, length)
        Drawings.AimFOV.Crosshair.Left.From = mousePos + Vector2.new(-length, 0)
        Drawings.AimFOV.Crosshair.Left.To = mousePos + Vector2.new(-length / 2, 0)
        Drawings.AimFOV.Crosshair.Right.From = mousePos + Vector2.new(length / 2, 0)
        Drawings.AimFOV.Crosshair.Right.To = mousePos + Vector2.new(length, 0)

        for _, line in pairs(Drawings.AimFOV.Crosshair) do
            line.Color = color
            line.Visible = true
            line.Thickness = Settings.AimBotFOVThickness
        end

    elseif Settings.AimBotFOVShape == "Arrow" then
        if not Drawings.AimFOV.Arrow then
            Drawings.AimFOV.Arrow = {
                Line1 = Drawing.new("Line"),
                Line2 = Drawing.new("Line"),
                Line3 = Drawing.new("Line"),
                Line4 = Drawing.new("Line")
            }
            for _, line in pairs(Drawings.AimFOV.Arrow) do
                line.Thickness = Settings.AimBotFOVThickness
            end
        end

        local size = Settings.AimBotFOV
        Drawings.AimFOV.Arrow.Line1.From = mousePos + Vector2.new(-size / 2, size / 2)
        Drawings.AimFOV.Arrow.Line1.To = mousePos + Vector2.new(0, -size / 2)
        Drawings.AimFOV.Arrow.Line2.From = mousePos + Vector2.new(0, -size / 2)
        Drawings.AimFOV.Arrow.Line2.To = mousePos + Vector2.new(size / 2, size / 2)
        Drawings.AimFOV.Arrow.Line3.From = mousePos + Vector2.new(-size / 4, size / 4)
        Drawings.AimFOV.Arrow.Line3.To = mousePos + Vector2.new(0, -size / 2)
        Drawings.AimFOV.Arrow.Line4.From = mousePos + Vector2.new(size / 4, size / 4)
        Drawings.AimFOV.Arrow.Line4.To = mousePos + Vector2.new(0, -size / 2)

        for _, line in pairs(Drawings.AimFOV.Arrow) do
            line.Color = color
            line.Visible = true
            line.Thickness = Settings.AimBotFOVThickness
        end
    end
end

local function ToggleNoClip(state)
    if state then
        noClipConnection = RunService.Stepped:Connect(function()
            local character = LocalPlayer.Character
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if noClipConnection then
            noClipConnection:Disconnect()
            noClipConnection = nil
        end
    end
end

local function ToggleSpeedHack(state)
    if state then
        speedConnection = RunService.Heartbeat:Connect(function()
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("Humanoid") then
                character.Humanoid.WalkSpeed = Settings.SpeedHackValue
            end
        end)
    else
        if speedConnection then
            speedConnection:Disconnect()
            speedConnection = nil
        end
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.WalkSpeed = 16
        end
    end
end

local function AutoFarm()
    if not Settings.AutoFarmEnabled then return end
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local rootPart = character.HumanoidRootPart

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end
        local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
        if not targetRoot then continue end

        local distance = (rootPart.Position - targetRoot.Position).Magnitude
        if distance <= Settings.AutoFarmRadius then
            local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = targetRoot.CFrame})
            tween:Play()
            break
        end
    end
end

local function UpdateTriggerBot()
    if not Settings.TriggerBotEnabled then return end
    local mousePos = UserInputService:GetMouseLocation()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        local targetPart = player.Character:FindFirstChild(Settings.AimBotTargetPart)
        if not targetPart then continue end

        local partPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then continue end

        local screenPos = Vector2.new(partPos.X, partPos.Y)
        local distance = (screenPos - mousePos).Magnitude
        if distance <= 10 then
            task.wait(Settings.TriggerBotDelay)
            mouse1click()
            break
        end
    end
end

local Window = Fluent:CreateWindow({
    Title = "Nova Universal Made By ThinhDev",
    SubTitle = "Version 2.0",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    ESP = Window:AddTab({ Title = "ESP", Icon = "eye" }),
    AimBot = Window:AddTab({ Title = "AimBot", Icon = "target" }),
    Features = Window:AddTab({ Title = "Features", Icon = "zap" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Config = Window:AddTab({ Title = "Config", Icon = "save" })
}

do
    local MainSection = Tabs.ESP:AddSection("Main ESP")
    
    local EnabledToggle = MainSection:AddToggle("Enabled", {
        Title = "Enable ESP",
        Default = false
    })
    EnabledToggle:OnChanged(function()
        Settings.Enabled = EnabledToggle.Value
        if not Settings.Enabled then
            CleanupESP()
        else
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    CreateESP(player)
                end
            end
        end
    end)
    
    local TeamCheckToggle = MainSection:AddToggle("TeamCheck", {
        Title = "Team Check",
        Default = false
    })
    TeamCheckToggle:OnChanged(function()
        Settings.TeamCheck = TeamCheckToggle.Value
    end)
    
    local ShowTeamToggle = MainSection:AddToggle("ShowTeam", {
        Title = "Show Team",
        Default = false
    })
    ShowTeamToggle:OnChanged(function()
        Settings.ShowTeam = ShowTeamToggle.Value
    end)
    
    local BoxSection = Tabs.ESP:AddSection("Box ESP")
    
    local BoxESPToggle = BoxSection:AddToggle("BoxESP", {
        Title = "Box ESP",
        Default = false
    })
    BoxESPToggle:OnChanged(function()
        Settings.BoxESP = BoxESPToggle.Value
    end)
    
    local BoxStyleDropdown = BoxSection:AddDropdown("BoxStyle", {
        Title = "Box Style",
        Values = {"Corner", "Full", "ThreeD"},
        Default = "Corner"
    })
    BoxStyleDropdown:OnChanged(function(Value)
        Settings.BoxStyle = Value
    end)
    
    local TracerSection = Tabs.ESP:AddSection("Tracer ESP")
    
    local TracerESPToggle = TracerSection:AddToggle("TracerESP", {
        Title = "Tracer ESP",
        Default = false
    })
    TracerESPToggle:OnChanged(function()
        Settings.TracerESP = TracerESPToggle.Value
    end)
    
    local TracerOriginDropdown = TracerSection:AddDropdown("TracerOrigin", {
        Title = "Tracer Origin",
        Values = {"Bottom", "Top", "Mouse", "Center"},
        Default = "Bottom"
    })
    TracerOriginDropdown:OnChanged(function(Value)
        Settings.TracerOrigin = Value
    end)
    
    local ChamsSection = Tabs.ESP:AddSection("Chams")
    
    local ChamsToggle = ChamsSection:AddToggle("ChamsEnabled", {
        Title = "Enable Chams",
        Default = false
    })
    ChamsToggle:OnChanged(function()
        Settings.ChamsEnabled = ChamsToggle.Value
    end)
    
    local ChamsFillColor = ChamsSection:AddColorpicker("ChamsFillColor", {
        Title = "Fill Color",
        Default = Settings.ChamsFillColor
    })
    ChamsFillColor:OnChanged(function(Value)
        Settings.ChamsFillColor = Value
    end)
    
    local ChamsOccludedColor = ChamsSection:AddColorpicker("ChamsOccludedColor", {
        Title = "Occluded Color",
        Default = Settings.ChamsOccludedColor
    })
    ChamsOccludedColor:OnChanged(function(Value)
        Settings.ChamsOccludedColor = Value
    end)
    
    local ChamsOutlineColor = ChamsSection:AddColorpicker("ChamsOutlineColor", {
        Title = "Outline Color",
        Default = Settings.ChamsOutlineColor
    })
    ChamsOutlineColor:OnChanged(function(Value)
        Settings.ChamsOutlineColor = Value
    end)
    
    local ChamsTransparency = ChamsSection:AddSlider("ChamsTransparency", {
        Title = "Fill Transparency",
        Default = 0.5,
        Min = 0,
        Max = 1,
        Rounding = 2
    })
    ChamsTransparency:OnChanged(function(Value)
        Settings.ChamsTransparency = Value
    end)
    
    local ChamsOutlineTransparency = ChamsSection:AddSlider("ChamsOutlineTransparency", {
        Title = "Outline Transparency",
        Default = 0,
        Min = 0,
        Max = 1,
        Rounding = 2
    })
    ChamsOutlineTransparency:OnChanged(function(Value)
        Settings.ChamsOutlineTransparency = Value
    end)
    
    local ChamsOutlineThickness = ChamsSection:AddSlider("ChamsOutlineThickness", {
        Title = "Outline Thickness",
        Default = 0.1,
        Min = 0,
        Max = 1,
        Rounding = 2
    })
    ChamsOutlineThickness:OnChanged(function(Value)
        Settings.ChamsOutlineThickness = Value
    end)
    
    local HealthSection = Tabs.ESP:AddSection("Health ESP")
    
    local HealthESPToggle = HealthSection:AddToggle("HealthESP", {
        Title = "Health Bar",
        Default = false
    })
    HealthESPToggle:OnChanged(function()
        Settings.HealthESP = HealthESPToggle.Value
    end)
    
    local HealthStyleDropdown = HealthSection:AddDropdown("HealthStyle", {
        Title = "Health Style",
        Values = {"Bar", "Text", "Both"},
        Default = "Bar"
    })
    HealthStyleDropdown:OnChanged(function(Value)
        Settings.HealthStyle = Value
    end)
    
    local SkeletonSection = Tabs.ESP:AddSection("Skeleton ESP")
    
    local SkeletonESPToggle = SkeletonSection:AddToggle("SkeletonESP", {
        Title = "Skeleton ESP",
        Default = false
    })
    SkeletonESPToggle:OnChanged(function()
        Settings.SkeletonESP = SkeletonESPToggle.Value
    end)
    
    local SkeletonColor = SkeletonSection:AddColorpicker("SkeletonColor", {
        Title = "Skeleton Color",
        Default = Settings.SkeletonColor
    })
    SkeletonColor:OnChanged(function(Value)
        Settings.SkeletonColor = Value
        for _, player in ipairs(Players:GetPlayers()) do
            local skeleton = Drawings.Skeleton[player]
            if skeleton then
                for _, line in pairs(skeleton) do
                    line.Color = Value
                end
            end
        end
    end)
    
    local SkeletonThickness = SkeletonSection:AddSlider("SkeletonThickness", {
        Title = "Line Thickness",
        Default = 1,
        Min = 1,
        Max = 3,
        Rounding = 1
    })
    SkeletonThickness:OnChanged(function(Value)
        Settings.SkeletonThickness = Value
        for _, player in ipairs(Players:GetPlayers()) do
            local skeleton = Drawings.Skeleton[player]
            if skeleton then
                for _, line in pairs(skeleton) do
                    line.Thickness = Value
                end
            end
        end
    end)
    
    local SkeletonTransparency = SkeletonSection:AddSlider("SkeletonTransparency", {
        Title = "Transparency",
        Default = 1,
        Min = 0,
        Max = 1,
        Rounding = 2
    })
    SkeletonTransparency:OnChanged(function(Value)
        Settings.SkeletonTransparency = Value
        for _, player in ipairs(Players:GetPlayers()) do
            local skeleton = Drawings.Skeleton[player]
            if skeleton then
                for _, line in pairs(skeleton) do
                    line.Transparency = Value
                end
            end
        end
    end)
end

do
    local AimBotSection = Tabs.AimBot:AddSection("AimBot Settings")
    
    local AimBotToggle = AimBotSection:AddToggle("AimBotEnabled", {
        Title = "Enable AimBot",
        Default = false
    })
    AimBotToggle:OnChanged(function()
        Settings.AimBotEnabled = AimBotToggle.Value
    end)
    
    local AimBotTeamCheckToggle = AimBotSection:AddToggle("AimBotTeamCheck", {
        Title = "Team Check (Ignore Team)",
        Default = true
    })
    AimBotTeamCheckToggle:OnChanged(function()
        Settings.AimBotTeamCheck = AimBotTeamCheckToggle.Value
    end)
    
    local AimBotAimTeamToggle = AimBotSection:AddToggle("AimBotAimTeam", {
        Title = "AimBot Team (If Team Check Off)",
        Default = false
    })
    AimBotAimTeamToggle:OnChanged(function()
        Settings.AimBotAimTeam = AimBotAimTeamToggle.Value
    end)
    
    local AimBotFOVSlider = AimBotSection:AddSlider("AimBotFOV", {
        Title = "FOV Radius",
        Default = 50,
        Min = 10,
        Max = 500,
        Rounding = 0
    })
    AimBotFOVSlider:OnChanged(function(Value)
        Settings.AimBotFOV = Value
    end)
    
    local AimBotFOVShapeDropdown = AimBotSection:AddDropdown("AimBotFOVShape", {
        Title = "FOV Shape",
        Values = {"Circle", "Crosshair", "Arrow"},
        Default = "Circle"
    })
    AimBotFOVShapeDropdown:OnChanged(function(Value)
        Settings.AimBotFOVShape = Value
    end)
    
    local AimBotFOVThicknessSlider = AimBotSection:AddSlider("AimBotFOVThickness", {
        Title = "FOV Thickness",
        Default = 1,
        Min = 1,
        Max = 5,
        Rounding = 0
    })
    AimBotFOVThicknessSlider:OnChanged(function(Value)
        Settings.AimBotFOVThickness = Value
    end)
    
    local AimBotFOVColorPicker = AimBotSection:AddColorpicker("AimBotFOVColor", {
        Title = "FOV Color",
        Default = Colors.FOV
    })
    AimBotFOVColorPicker:OnChanged(function(Value)
        Colors.FOV = Value
    end)
    
    local AimBotFOVRainbowToggle = AimBotSection:AddToggle("AimBotFOVRainbow", {
        Title = "Rainbow FOV",
        Default = false
    })
    AimBotFOVRainbowToggle:OnChanged(function()
        Settings.RainbowFOV = AimBotFOVRainbowToggle.Value
    end)
    
    local AimBotTargetPartDropdown = AimBotSection:AddDropdown("AimBotTargetPart", {
        Title = "Target Part",
        Values = {"Head", "UpperTorso", "Torso"},
        Default = "Head"
    })
    AimBotTargetPartDropdown:OnChanged(function(Value)
        Settings.AimBotTargetPart = Value
    end)
    
    local AimBotSmoothnessSlider = AimBotSection:AddSlider("AimBotSmoothness", {
        Title = "Smoothness",
        Default = 0.1,
        Min = 0.05,
        Max = 1,
        Rounding = 2
    })
    AimBotSmoothnessSlider:OnChanged(function(Value)
        Settings.AimBotSmoothness = Value
    end)
    
    local AimBotInstruction = AimBotSection:AddParagraph({
        Title = "AimBot Controls",
        Content = "Hold Right Mouse Button to activate AimBot"
    })

    local SilentAimSection = Tabs.AimBot:AddSection("Silent Aim Settings")
    
    local SilentAimToggle = SilentAimSection:AddToggle("SilentAimEnabled", {
        Title = "Enable Silent Aim",
        Default = false
    })
    SilentAimToggle:OnChanged(function()
        Settings.SilentAimEnabled = SilentAimToggle.Value
    end)
    
    local SilentAimFOVSlider = SilentAimSection:AddSlider("SilentAimFOV", {
        Title = "FOV Radius",
        Default = 50,
        Min = 10,
        Max = 500,
        Rounding = 0
    })
    SilentAimFOVSlider:OnChanged(function(Value)
        Settings.SilentAimFOV = Value
    end)
    
    local SilentAimHitChanceSlider = SilentAimSection:AddSlider("SilentAimHitChance", {
        Title = "Hit Chance (%)",
        Default = 100,
        Min = 0,
        Max = 100,
        Rounding = 0
    })
    SilentAimHitChanceSlider:OnChanged(function(Value)
        Settings.SilentAimHitChance = Value
    end)
    
    local SilentAimTargetPartDropdown = SilentAimSection:AddDropdown("SilentAimTargetPart", {
        Title = "Target Part",
        Values = {"Head", "UpperTorso", "Torso"},
        Default = "Head"
    })
    SilentAimTargetPartDropdown:OnChanged(function(Value)
        Settings.SilentAimTargetPart = Value
    end)

    local TriggerBotSection = Tabs.AimBot:AddSection("TriggerBot Settings")
    
    local TriggerBotToggle = TriggerBotSection:AddToggle("TriggerBotEnabled", {
        Title = "Enable TriggerBot",
        Default = false
    })
    TriggerBotToggle:OnChanged(function()
        Settings.TriggerBotEnabled = TriggerBotToggle.Value
    end)
    
    local TriggerBotDelaySlider = TriggerBotSection:AddSlider("TriggerBotDelay", {
        Title = "Trigger Delay (s)",
        Default = 0.1,
        Min = 0,
        Max = 1,
        Rounding = 2
    })
    TriggerBotDelaySlider:OnChanged(function(Value)
        Settings.TriggerBotDelay = Value
    end)
end

do
    local FlySection = Tabs.Features:AddSection("Fly")
    
    local FlyToggle = FlySection:AddToggle("FlyEnabled", {
        Title = "Enable Fly",
        Default = false
    })
    FlyToggle:OnChanged(function()
        Settings.FlyEnabled = FlyToggle.Value
        flying = Settings.FlyEnabled
        toggleFly(Settings.FlyEnabled)
    end)
    
    local FlySpeedSlider = FlySection:AddSlider("FlySpeed", {
        Title = "Fly Speed",
        Default = 50,
        Min = 10,
        Max = 200,
        Rounding = 0
    })
    FlySpeedSlider:OnChanged(function(Value)
        Settings.FlySpeed = Value
    end)
    
    local FlyInstruction = FlySection:AddParagraph({
        Title = "Fly Controls",
        Content = "WASD to move, Space to go up, Shift to go down"
    })

    local SpeedHackSection = Tabs.Features:AddSection("Speed Hack")
    
    local SpeedHackToggle = SpeedHackSection:AddToggle("SpeedHackEnabled", {
        Title = "Enable Speed Hack",
        Default = false
    })
    SpeedHackToggle:OnChanged(function()
        Settings.SpeedHackEnabled = SpeedHackToggle.Value
        ToggleSpeedHack(Settings.SpeedHackEnabled)
    end)
    
    local SpeedHackValueSlider = SpeedHackSection:AddSlider("SpeedHackValue", {
        Title = "Speed Value",
        Default = 50,
        Min = 16,
        Max = 200,
        Rounding = 0
    })
    SpeedHackValueSlider:OnChanged(function(Value)
        Settings.SpeedHackValue = Value
    end)

    local NoClipSection = Tabs.Features:AddSection("NoClip")
    
    local NoClipToggle = NoClipSection:AddToggle("NoClipEnabled", {
        Title = "Enable NoClip",
        Default = false
    })
    NoClipToggle:OnChanged(function()
        Settings.NoClipEnabled = NoClipToggle.Value
        ToggleNoClip(Settings.NoClipEnabled)
    end)

    local AutoFarmSection = Tabs.Features:AddSection("Auto Farm")
    
    local AutoFarmToggle = AutoFarmSection:AddToggle("AutoFarmEnabled", {
        Title = "Enable Auto Farm",
        Default = false
    })
    AutoFarmToggle:OnChanged(function()
        Settings.AutoFarmEnabled = AutoFarmToggle.Value
    end)
    
    local AutoFarmRadiusSlider = AutoFarmSection:AddSlider("AutoFarmRadius", {
        Title = "Farm Radius",
        Default = 100,
        Min = 10,
        Max = 500,
        Rounding = 0
    })
    AutoFarmRadiusSlider:OnChanged(function(Value)
        Settings.AutoFarmRadius = Value
    end)
    
    local AutoFarmTargetDropdown = AutoFarmSection:AddDropdown("AutoFarmTarget", {
        Title = "Target",
        Values = {"All", "Enemies", "Team"},
        Default = "All"
    })
    AutoFarmTargetDropdown:OnChanged(function(Value)
        Settings.AutoFarmTarget = Value
    end)
end

do
    local ColorsSection = Tabs.Settings:AddSection("Colors")
    
    local EnemyColor = ColorsSection:AddColorpicker("EnemyColor", {
        Title = "Enemy Color",
        Default = Colors.Enemy
    })
    EnemyColor:OnChanged(function(Value)
        Colors.Enemy = Value
    end)
    
    local AllyColor = ColorsSection:AddColorpicker("AllyColor", {
        Title = "Ally Color",
        Default = Colors.Ally
    })
    AllyColor:OnChanged(function(Value)
        Colors.Ally = Value
    end)
    
    local HealthColor = ColorsSection:AddColorpicker("HealthColor", {
        Title = "Health Bar Color",
        Default = Colors.Health
    })
    HealthColor:OnChanged(function(Value)
        Colors.Health = Value
    end)
    
    local BoxSection = Tabs.Settings:AddSection("Box Settings")
    
    local BoxThickness = BoxSection:AddSlider("BoxThickness", {
        Title = "Box Thickness",
        Default = 1,
        Min = 1,
        Max = 5,
        Rounding = 1
    })
    BoxThickness:OnChanged(function(Value)
        Settings.BoxThickness = Value
    end)
    
    local BoxTransparency = BoxSection:AddSlider("BoxTransparency", {
        Title = "Box Transparency",
        Default = 1,
        Min = 0,
        Max = 1,
        Rounding = 2
    })
    BoxTransparency:OnChanged(function(Value)
        Settings.BoxFillTransparency = Value
    end)
    
    local ESPSection = Tabs.Settings:AddSection("ESP Settings")
    
    local MaxDistance = ESPSection:AddSlider("MaxDistance", {
        Title = "Max Distance",
        Default = 1000,
        Min = 100,
        Max = 5000,
        Rounding = 0
    })
    MaxDistance:OnChanged(function(Value)
        Settings.MaxDistance = Value
    end)
    
    local TextSize = ESPSection:AddSlider("TextSize", {
        Title = "Text Size",
        Default = 14,
        Min = 10,
        Max = 24,
        Rounding = 0
    })
    TextSize:OnChanged(function(Value)
        Settings.TextSize = Value
    end)
    
    local HealthTextFormat = ESPSection:AddDropdown("HealthTextFormat", {
        Title = "Health Format",
        Values = {"Number", "Percentage", "Both"},
        Default = "Number"
    })
    HealthTextFormat:OnChanged(function(Value)
        Settings.HealthTextFormat = Value
    end)
    
    local EffectsSection = Tabs.Settings:AddSection("Effects")
    
    local RainbowToggle = EffectsSection:AddToggle("RainbowEnabled", {
        Title = "Rainbow Mode",
        Default = false
    })
    RainbowToggle:OnChanged(function()
        Settings.RainbowEnabled = RainbowToggle.Value
    end)
    
    local RainbowSpeed = EffectsSection:AddSlider("RainbowSpeed", {
        Title = "Rainbow Speed",
        Default = 1,
        Min = 0.1,
        Max = 5,
        Rounding = 1
    })
    RainbowSpeed:OnChanged(function(Value)
        Settings.RainbowSpeed = Value
    end)
    
    local RainbowOptions = EffectsSection:AddDropdown("RainbowParts", {
        Title = "Rainbow Parts",
        Values = {"All", "Box Only", "Tracers Only", "Text Only"},
        Default = "All",
        Multi = false
    })
    RainbowOptions:OnChanged(function(Value)
        if Value == "All" then
            Settings.RainbowBoxes = true
            Settings.RainbowTracers = true
            Settings.RainbowText = true
        elseif Value == "Box Only" then
            Settings.RainbowBoxes = true
            Settings.RainbowTracers = false
            Settings.RainbowText = false
        elseif Value == "Tracers Only" then
            Settings.RainbowBoxes = false
            Settings.RainbowTracers = true
            Settings.RainbowText = false
        elseif Value == "Text Only" then
            Settings.RainbowBoxes = false
            Settings.RainbowTracers = false
            Settings.RainbowText = true
        end
    end)
    
    local PerformanceSection = Tabs.Settings:AddSection("Performance")
    
    local RefreshRate = PerformanceSection:AddSlider("RefreshRate", {
        Title = "Refresh Rate",
        Default = 144,
        Min = 1,
        Max = 144,
        Rounding = 0
    })
    RefreshRate:OnChanged(function(Value)
        Settings.RefreshRate = 1/Value
    end)
end

do
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({})
    InterfaceManager:SetFolder("NovaUniversal")
    SaveManager:SetFolder("NovaUniversal/configs")
    
    InterfaceManager:BuildInterfaceSection(Tabs.Config)
    SaveManager:BuildConfigSection(Tabs.Config)
    
    local UnloadSection = Tabs.Config:AddSection("Unload")
    
    local UnloadButton = UnloadSection:AddButton({
        Title = "Unload Script",
        Description = "Completely remove the script",
        Callback = function()
            CleanupESP()
            for _, connection in pairs(getconnections(RunService.RenderStepped)) do
                connection:Disconnect()
            end
            Window:Destroy()
            Drawings = nil
            Settings = nil
            for k, v in pairs(getfenv(1)) do
                getfenv(1)[k] = nil
            end
        end
    })
end

task.spawn(function()
    while task.wait(0.1) do
        Colors.Rainbow = Color3.fromHSV(tick() * Settings.RainbowSpeed % 1, 1, 1)
    end
end)

local lastUpdate = 0
RunService.RenderStepped:Connect(function()
    UpdateAimBot()
    UpdateFOVShape()
    UpdateTriggerBot()
    AutoFarm()

    if not Settings.Enabled then 
        DisableESP()
        return 
    end
    
    local currentTime = tick()
    if currentTime - lastUpdate >= Settings.RefreshRate then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if not Drawings.ESP[player] then
                    CreateESP(player)
                end
                UpdateESP(player)
            end
        end
        lastUpdate = currentTime
    end
end)

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end

Window:SelectTab(1)

Fluent:Notify({
    Title = "Nova Universal",
    Content = "Made By ThinhDev Version 2.0 Loaded Successfully!",
    Duration = 5
})