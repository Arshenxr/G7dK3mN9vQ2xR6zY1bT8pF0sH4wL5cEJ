-- script.lua
local Module = {}

function Module.Init(Fluent, SaveManager, InterfaceManager, LocalPlayer)
    local RunService = game:GetService("RunService")
    local Teams = game:GetService("Teams")
    local Lighting = game:GetService("Lighting")
    local Workspace = workspace
    local Camera = Workspace.CurrentCamera

    -- Window & Tabs
    local Window = Fluent:CreateWindow({
        Title = "Westbound.win",
        SubTitle = "by Arshenxr",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = true,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl
    })

    local Tabs = {
        Visuals = Window:AddTab({ Title = "Visuals", Icon = "" }),
        ModAndAssist = Window:AddTab({ Title = "Mod&Assist", Icon = "" }),
        Miscellaneous = Window:AddTab({ Title = "Miscellaneous", Icon = "" }),
        Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
    }

    local FirstRun = true

    -- Sections
    local MiscFullBrightSection = Tabs.Miscellaneous:AddSection("Full Bright")
    local MiscTeamSection = Tabs.Miscellaneous:AddSection("Team")
    local MiscServerSection = Tabs.Miscellaneous:AddSection("Server")
    local ESPLegendarySection = Tabs.Visuals:AddSection("ESP Legendary Animals")
    local ModAssistSectionAssist = Tabs.ModAndAssist:AddSection("Assists")
    local ModAssistSectionMods = Tabs.ModAndAssist:AddSection("Mods")

    -- ------------------------------------------------
    -- FullBright
    -- ------------------------------------------------
    local FullBrightEnabled = false
    local OldLighting = {}
    local lightingChangedConn

    local FullBrightToggle = MiscFullBrightSection:AddToggle("FullBrightToggle", { Title = "Full Bright", Default = false })
    local AmbientPicker = MiscFullBrightSection:AddColorpicker("AmbientColor", { Title = "Ambient Color", Default = Color3.fromRGB(255, 255, 255) })

    local function applyFullBright()
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        if FullBrightEnabled then
            Lighting.Ambient = AmbientPicker.Value or Color3.fromRGB(255, 255, 255)
        end
    end

    FullBrightToggle:OnChanged(function(enabled)
        FullBrightEnabled = enabled
        if enabled then
            OldLighting = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                FogEnd = Lighting.FogEnd,
                GlobalShadows = Lighting.GlobalShadows,
                Ambient = Lighting.Ambient
            }
            applyFullBright()
            if lightingChangedConn then lightingChangedConn:Disconnect() end
            lightingChangedConn = Lighting.Changed:Connect(function(prop)
                if FullBrightEnabled and (prop == "Brightness" or prop == "ClockTime" or prop == "FogEnd" or prop == "GlobalShadows" or prop == "Ambient") then
                    applyFullBright()
                end
            end)
        else
            if lightingChangedConn then lightingChangedConn:Disconnect() end
            for k, v in pairs(OldLighting) do pcall(function() Lighting[k] = v end) end
        end
    end)

    AmbientPicker:OnChanged(function()
        if FullBrightEnabled then
            local color = AmbientPicker.Value
            if color then Lighting.Ambient = color end
        end
    end)

    -- ------------------------------------------------
    -- ESP
    -- ------------------------------------------------
    local targetNames = { "legendarydirewolf", "legendarybison", "legendarygrizzlybear", "legendaryblackbear",
        "legendarywolf", "legendarymoosebull", "direwolf" }
    local customNames = {
        legendarydirewolf = { name = "Legendary Direwolf" },
        legendarybison = { name = "Legendary Bison" },
        legendarygrizzlybear = { name = "Legendary Grizzly Bear" },
        legendaryblackbear = { name = "Legendary Black Bear" },
        legendarywolf = { name = "Legendary Wolf" },
        legendarymoosebull = { name = "Legendary Moose Bull" },
        direwolf = { name = "Direwolf" }
    }
    local customNamesOrdered = { "legendarydirewolf", "legendarybison", "legendarygrizzlybear", "legendaryblackbear",
        "legendarywolf", "legendarymoosebull", "direwolf" }

    local function getCustomName(model)
        local nameLower = model.Name:lower()
        for _, key in ipairs(customNamesOrdered) do
            local value = customNames[key]
            if value and nameLower:find(key) then return value.name end
        end
        return model.Name
    end

    local ESPToggle = ESPLegendarySection:AddToggle("ESP_Toggle", { Title = "Enable ESP", Default = false })
    local ESPColorPicker = ESPLegendarySection:AddColorpicker("ESP_Color", { Title = "ESP Color", Default = Color3.fromRGB(255, 255, 255) })
    local ESPSettings = { espEnabled = ESPToggle.Value, espColor = ESPColorPicker.Value }

    ESPToggle:OnChanged(function(value) ESPSettings.espEnabled = value end)
    ESPColorPicker:OnChanged(function(color) ESPSettings.espColor = color end)

    local espCache = {}
    local running = true

    local function isTargetModel(model)
        if not model then return false end
        local nameLower = model.Name:lower()
        for _, t in ipairs(targetNames) do
            if nameLower:find(t) then return true end
        end
        return false
    end

    local function getAdornee(model)
        return model:FindFirstChild("Head") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    end

    local function createESPForModel(model)
        if espCache[model] then return end
        local adornee = getAdornee(model)
        if not adornee then return end
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Billboard"
        billboard.Adornee = adornee
        billboard.Size = UDim2.new(0, 150, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        billboard.ResetOnSpawn = false
        billboard.Enabled = ESPSettings.espEnabled
        local label = Instance.new("TextLabel", billboard)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = getCustomName(model)
        label.TextColor3 = ESPSettings.espColor
        label.TextStrokeTransparency = 0.5
        label.TextSize = 18
        label.Font = Enum.Font.SourceSansBold
        billboard.Parent = Camera
        espCache[model] = { billboard = billboard, label = label, adornee = adornee }
    end

    local function updateAllESP()
        for model, data in pairs(espCache) do
            if not model or not model.Parent then
                data.billboard:Destroy()
                espCache[model] = nil
            else
                data.billboard.Enabled = ESPSettings.espEnabled
                data.label.Text = getCustomName(model)
                data.label.TextColor3 = ESPSettings.espColor
            end
        end
    end

    local function createAllESP()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and isTargetModel(obj) then
                createESPForModel(obj)
            end
        end
    end

    createAllESP()
    RunService.RenderStepped:Connect(function() if running then updateAllESP() end end)
    Workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and isTargetModel(obj) then
            createESPForModel(obj)
        end
    end)

    -- ------------------------------------------------
    -- Server Buttons
    -- ------------------------------------------------
    local function createServerButton(title, callback)
        MiscServerSection:AddButton({ Title = title, Callback = callback })
    end

    -- ตัวอย่าง: Rejoin / Hop / SmallServer
    createServerButton("Rejoin Server", function()
        Window:Dialog({
            Title = "Rejoin Server",
            Content = "Are you sure you want yo rejoin?",
            Buttons = {
                {
                    Title = "Confirm",
                    Callback = function()
                        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                    end
                },
                { Title = "Denied", Callback = function() end }
            }
        })
    end)

    -- (คุณสามารถเติม Hop Server, Hop SmallServer, Team Buttons, AutoHeal, GunMods, Stamina Mod เช่นเดียวกัน)
    -- ตัวแปร Module.Window, Module.Tabs จะอยู่ที่นี่เพื่อให้เรียกจาก loader ต่อได้

    -- ------------------------------------------------
    -- Final Setup
    -- ------------------------------------------------
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    InterfaceManager:SetFolder("FluentScriptHub")
    SaveManager:SetFolder("FluentScriptHub/specific-game")
    SaveManager:LoadAutoloadConfig()
    InterfaceManager:BuildInterfaceSection(Tabs.Settings)
    SaveManager:BuildConfigSection(Tabs.Settings)
    Window:SelectTab(1)

    if FirstRun then Fluent:Notify({ Title = "Westbound.win", Content = "Success Fully Load!", Duration = 5 }) end

    Module.Window = Window
    Module.Tabs = Tabs
end

return Module
