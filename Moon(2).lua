local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Moon = {
    ESPRole = false,
    ESPGun = false,
    AntiFling = false,
    Noclip = false,
    ESPMurderer = true,
    ESPSheriff = true,
    ESPInnocent = false,
    ESPDistance = 500,
    ESPFillTransparency = 0.6,
    ESPOutlineTransparency = 0.1,
    ESPObjects = {},
    Connections = {},
    RoleColors = {
        Murderer = Color3.fromRGB(255, 50, 50),
        Sheriff = Color3.fromRGB(50, 150, 255),
        Innocent = Color3.fromRGB(50, 255, 100),
        Unknown = Color3.fromRGB(150, 150, 150)
    }
}

local function SafeConnect(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(Moon.Connections, conn)
    return conn
end

local function DisconnectAll()
    for _, conn in ipairs(Moon.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Moon.Connections = {}
end

local function GetRole(plr)
    local char = plr.Character
    if not char then return "Unknown" end
    local backpack = plr:FindFirstChild("Backpack")
    local knife = char:FindFirstChild("Knife") or (backpack and backpack:FindFirstChild("Knife"))
    local gun = char:FindFirstChild("Gun") or (backpack and backpack:FindFirstChild("Gun"))
    if knife then return "Murderer" end
    if gun then return "Sheriff" end
    return "Innocent"
end

local function ShouldShowRole(role)
    if role == "Murderer" then return Moon.ESPMurderer end
    if role == "Sheriff" then return Moon.ESPSheriff end
    if role == "Innocent" then return Moon.ESPInnocent end
    return false
end

local function GetRoleColor2(role)
    if role == "Murderer" then return Color3.fromRGB(200, 0, 0) end
    if role == "Sheriff" then return Color3.fromRGB(0, 100, 200) end
    if role == "Innocent" then return Color3.fromRGB(0, 200, 50) end
    return Color3.fromRGB(100, 100, 100)
end

local function IsInDistance(target)
    if not Player.Character then return false end
    local myRoot = Player.Character:FindFirstChild("HumanoidRootPart")
    local targetRoot = target:FindFirstChild("HumanoidRootPart")
    if not myRoot or not targetRoot then return false end
    return (myRoot.Position - targetRoot.Position).Magnitude <= Moon.ESPDistance
end

local function CreateESP(target, color1, color2)
    if Moon.ESPObjects[target] then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "MoonESP"
    highlight.FillColor = color1
    highlight.FillTransparency = Moon.ESPFillTransparency
    highlight.OutlineColor = color2
    highlight.OutlineTransparency = Moon.ESPOutlineTransparency
    highlight.Parent = target

    Moon.ESPObjects[target] = {Highlight = highlight}

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not target or not target.Parent then
            pcall(function() highlight:Destroy() end)
            Moon.ESPObjects[target] = nil
            if conn then conn:Disconnect() end
        end
    end)
end

local function RemoveESP(target)
    local objs = Moon.ESPObjects[target]
    if objs then
        pcall(function() objs.Highlight:Destroy() end)
        Moon.ESPObjects[target] = nil
    end
end

local function ClearESP()
    for target, _ in pairs(Moon.ESPObjects) do
        RemoveESP(target)
    end
end

local function UpdateESPRole()
    if not Moon.ESPRole then
        ClearESP()
        return
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == Player then continue end
        local char = plr.Character
        if not char then continue end

        local role = GetRole(plr)
        local shouldShow = ShouldShowRole(role) and IsInDistance(char)

        if shouldShow then
            local color1 = Moon.RoleColors[role]
            local color2 = GetRoleColor2(role)
            if Moon.ESPObjects[char] then
                Moon.ESPObjects[char].Highlight.FillColor = color1
                Moon.ESPObjects[char].Highlight.OutlineColor = color2
            else
                CreateESP(char, color1, color2)
            end
        else
            RemoveESP(char)
        end
    end
end

local function GetGunDrop()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            local name = obj.Name:lower()
            if name:find("gun") or name:find("revolver") then
                if obj.Parent then
                    local parentName = obj.Parent.Name:lower()
                    if parentName:find("drop") or parentName:find("workspace") then
                        return obj
                    end
                end
            end
        end
    end
    return nil
end

local function UpdateESPGun()
    if not Moon.ESPGun then return end
    local gun = GetGunDrop()
    if gun and not Moon.ESPObjects[gun] then
        CreateESP(gun, Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 140, 0))
    end
end

local function AntiFlingFunc()
    if not Moon.AntiFling then return end
    local char = Player.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.AssemblyLinearVelocity = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
            part.RotVelocity = Vector3.zero
        end
    end
end

local function NoclipFunc()
    if not Moon.Noclip then return end
    local char = Player.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

local function RestoreCollision()
    local char = Player.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
end

SafeConnect(RunService.Heartbeat, function()
    if Moon.AntiFling then AntiFlingFunc() end
    if Moon.Noclip then NoclipFunc() end
end)

SafeConnect(RunService.RenderStepped, function()
    if Moon.ESPRole then UpdateESPRole() end
    if Moon.ESPGun then UpdateESPGun() end
end)

Players.PlayerRemoving:Connect(function(plr)
    local char = plr.Character
    if char then RemoveESP(char) end
end)

local Window = WindUI:CreateWindow({
    Title = "Moon",
    Icon = "rbxassetid://129635775698757",
    Folder = "MoonHub",
    Size = UDim2.fromOffset(520, 420),
    MinSize = Vector2.new(480, 350),
    MaxSize = Vector2.new(700, 600),
    ToggleKey = Enum.KeyCode.RightShift,
    Transparent = true,
    Resizable = true,
    OpenButton = {
        Title = "Moon",
        CornerRadius = UDim.new(1, 0),
        Draggable = true,
        OnlyMobile = false,
        Color = ColorSequence.new(
            Color3.fromHex("#2563EB"),
            Color3.fromHex("#1E40AF")
        ),
    },
})

Window:Tag({
    Title = "v1.0",
    Icon = "moon",
    Color = Color3.fromHex("#1c1c1c"),
    Border = true,
})

local VisualsTab = Window:Tab({
    Title = "Visuals",
    Icon = "eye",
})

local ESPSection = VisualsTab:Section({
    Title = "ESP Settings",
    Box = true,
    Opened = true,
})

ESPSection:Toggle({
    Title = "ESP Role",
    Desc = "Show player roles",
    Flag = "ESPRole",
    Value = false,
    Callback = function(v)
        Moon.ESPRole = v
        if not v then ClearESP() end
    end
})

ESPSection:Toggle({
    Title = "ESP Gun Drop",
    Desc = "Show dropped gun",
    Flag = "ESPGun",
    Value = false,
    Callback = function(v)
        Moon.ESPGun = v
    end
})

ESPSection:Toggle({
    Title = "Show Murderer",
    Desc = "Highlight murderer",
    Flag = "ESPMurderer",
    Value = true,
    Callback = function(v)
        Moon.ESPMurderer = v
    end
})

ESPSection:Toggle({
    Title = "Show Sheriff",
    Desc = "Highlight sheriff",
    Flag = "ESPSheriff",
    Value = true,
    Callback = function(v)
        Moon.ESPSheriff = v
    end
})

ESPSection:Toggle({
    Title = "Show Innocent",
    Desc = "Highlight innocents",
    Flag = "ESPInnocent",
    Value = false,
    Callback = function(v)
        Moon.ESPInnocent = v
    end
})

ESPSection:Slider({
    Title = "ESP Distance",
    Desc = "Max distance to show ESP",
    Step = 10,
    Value = {
        Min = 50,
        Max = 1000,
        Default = 500,
    },
    Flag = "ESPDistance",
    Callback = function(v)
        Moon.ESPDistance = v
    end
})

ESPSection:Slider({
    Title = "Fill Transparency",
    Desc = "ESP fill opacity",
    Step = 0.05,
    Value = {
        Min = 0,
        Max = 1,
        Default = 0.6,
    },
    Flag = "ESPFillTransparency",
    Callback = function(v)
        Moon.ESPFillTransparency = v
        for _, objs in pairs(Moon.ESPObjects) do
            if objs.Highlight then
                objs.Highlight.FillTransparency = v
            end
        end
    end
})

ESPSection:Slider({
    Title = "Outline Transparency",
    Desc = "ESP outline opacity",
    Step = 0.05,
    Value = {
        Min = 0,
        Max = 1,
        Default = 0.1,
    },
    Flag = "ESPOutlineTransparency",
    Callback = function(v)
        Moon.ESPOutlineTransparency = v
        for _, objs in pairs(Moon.ESPObjects) do
            if objs.Highlight then
                objs.Highlight.OutlineTransparency = v
            end
        end
    end
})

ESPSection:Colorpicker({
    Title = "Murderer Color",
    Desc = "ESP color for murderer",
    Default = Moon.RoleColors.Murderer,
    Flag = "MurdererColor",
    Callback = function(color)
        Moon.RoleColors.Murderer = color
    end
})

ESPSection:Colorpicker({
    Title = "Sheriff Color",
    Desc = "ESP color for sheriff",
    Default = Moon.RoleColors.Sheriff,
    Flag = "SheriffColor",
    Callback = function(color)
        Moon.RoleColors.Sheriff = color
    end
})

ESPSection:Colorpicker({
    Title = "Innocent Color",
    Desc = "ESP color for innocent",
    Default = Moon.RoleColors.Innocent,
    Flag = "InnocentColor",
    Callback = function(color)
        Moon.RoleColors.Innocent = color
    end
})

VisualsTab:Button({
    Title = "Clear ESP",
    Desc = "Remove all ESP highlights",
    Callback = function()
        ClearESP()
        Moon.ESPRole = false
        Moon.ESPGun = false
        WindUI:Notify({
            Title = "Moon",
            Content = "ESP cleared",
            Duration = 2,
        })
    end
})

local MiscTab = Window:Tab({
    Title = "Misc",
    Icon = "ghost",
})

local MovementSection = MiscTab:Section({
    Title = "Movement",
    Box = true,
    Opened = true,
})

MovementSection:Toggle({
    Title = "Anti Fling",
    Desc = "Prevent being flung",
    Flag = "AntiFling",
    Value = false,
    Callback = function(v)
        Moon.AntiFling = v
    end
})

MovementSection:Toggle({
    Title = "Noclip",
    Desc = "Walk through walls",
    Flag = "Noclip",
    Value = false,
    Callback = function(v)
        Moon.Noclip = v
        if not v then RestoreCollision() end
    end
})

local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings",
})

SettingsTab:Keybind({
    Title = "Toggle UI Key",
    Desc = "Key to open/close menu",
    Value = "RightShift",
    Flag = "ToggleKey",
    Callback = function(v)
        Window:SetToggleKey(Enum.KeyCode[v])
    end
})

SettingsTab:Button({
    Title = "Destroy UI",
    Desc = "Close the menu",
    Callback = function()
        ClearESP()
        DisconnectAll()
        Window:Destroy()
    end
})

local ConfigManager = Window.ConfigManager
local DefaultConfig = ConfigManager:CreateConfig("default")

SettingsTab:Button({
    Title = "Save Config",
    Callback = function()
        DefaultConfig:Save()
        WindUI:Notify({
            Title = "Moon",
            Content = "Config saved",
            Duration = 2,
        })
    end
})

SettingsTab:Button({
    Title = "Load Config",
    Callback = function()
        DefaultConfig:Load()
        WindUI:Notify({
            Title = "Moon",
            Content = "Config loaded",
            Duration = 2,
        })
    end
})

SettingsTab:Paragraph({
    Title = "Moon v1.0",
    Desc = "Script for Murder Mystery 2",
    Color = "Blue",
})

WindUI:Notify({
    Title = "Moon",
    Content = "Script loaded successfully",
    Duration = 3,
})

return Moon
