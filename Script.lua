-- ScriptModule.lua
local ScriptModule = {}

function ScriptModule.Init(Fluent, SaveManager, InterfaceManager, LocalPlayer)
    -- Services
    local Workspace = game:GetService("Workspace")
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ContentProvider = game:GetService("ContentProvider")
    local Players = game:GetService("Players")
    local Players = game:GetService("Players")

    local Players = game:GetService("Players")
    local task = task or delay and delay -- compatibility

    -- ===== CONFIG =====
    -- แทนด้วย UserId ของคุณ (เป็นตัวเลข) หรือ username (string)
    local allowedIds = {
        [973799] = true, -- <-- เปลี่ยนเป็น UserId จริง (number)
        -- ["123456789"] = true, -- หรือเก็บเป็น string ก็ได้ (รองรับทั้งสอง)
    }
    local allowedNames = {
        ["wadad"] = true, -- <-- (optional) ใส่ชื่อผู้เล่นเพื่ออนุญาตด้วยชื่อ
    }
    local WAIT_TIMEOUT = 6 -- วินาที รอ LocalPlayer เต็มที่

    -- ===== avoid multiple runs in same session (useful with some executors) =====
    if type(getgenv) == "function" and getgenv().__id_check_done then
        -- already checked this session
        return
    end

    -- ===== wait for LocalPlayer and UserId to be valid =====
    local start = tick()
    local LocalPlayer = Players.LocalPlayer
    if not LocalPlayer then
        LocalPlayer = Players.PlayerAdded:Wait()
    end

    -- wait until Name and UserId available (UserId sometimes 0 briefly)
    while (not LocalPlayer.Name or LocalPlayer.Name == "") or (not LocalPlayer.UserId or LocalPlayer.UserId == 0) do
        if tick() - start > WAIT_TIMEOUT then
            warn("[ID-KICK] Timeout waiting for LocalPlayer identity. Aborting check.")
            break
        end
        task.wait(0.1)
    end

    local name = tostring(LocalPlayer.Name or "Unknown")
    local id = tonumber(LocalPlayer.UserId) or 0

    -- debug prints (ดูใน Output)
    pcall(function()
        print(string.format("[ID-KICK] LocalPlayer found -> Name: %s  UserId: %d", name, id))
    end)

    -- helper: normalize allowed table lookup (support number and string keys)
    local function isAllowedById(u)
        if not u then return false end
        if allowedIds[tonumber(u)] then return true end
        if allowedIds[tostring(u)] then return true end
        return false
    end

    local function isAllowedByName(n)
        if not n then return false end
        if allowedNames[n] then return true end
        if allowedNames[string.lower(n)] then return true end
        return false
    end

    local allowed = false
    if isAllowedById(id) then
        allowed = true
    elseif isAllowedByName(name) then
        allowed = true
    end

    if allowed then
        pcall(function() print("[ID-KICK] Authorized user. continuing...") end)
        if type(getgenv) == "function" then getgenv().__id_check_done = true end
        return
    end

    -- not allowed -> attempt to kick (pcall protects errors)
    pcall(function() print("[ID-KICK] Unauthorized: kicking user ->", name, id) end)

    local kicked = false
    local ok, err = pcall(function()
        LocalPlayer:Kick("Unauthorized user detected. Access denied.")
    end)
    if ok then
        kicked = true
    else
        warn("[ID-KICK] Kick() call failed:", err)
        -- try alternative call style
        pcall(function()
            local kickFunc = LocalPlayer.Kick
            if type(kickFunc) == "function" then
                kickFunc(LocalPlayer, "Unauthorized user detected. Access denied.")
                kicked = true
            end
        end)
    end

    -- Wait briefly to allow kick to process
    task.wait(0.6)

    if kicked then
        -- mark checked to avoid re-run
        if type(getgenv) == "function" then getgenv().__id_check_done = true end
        return
    end
    -- Ensure CurrentCamera is ready
    local Camera = Workspace.CurrentCamera
    -- ถ้า Camera ยังไม่พร้อม ให้รอใน loop เล็ก ๆ
    local startTime = tick()
    while not Camera do
        task.wait(0.1)
        Camera = Workspace.CurrentCamera
        if tick() - startTime > 5 then -- รอไม่เกิน 5 วินาที
            warn("[Westbound.win] CurrentCamera not found!")
            return
        end
    end
    print("[Westbound.win] 📸 CurrentCamera ready!")


    -- Preload game assets
    do
        print("[Westbound.win] 🕐 Preloading game assets...")
        local assetsToLoad = {}
        local function addIfRelevant(obj)
            if obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("Sound") or obj:IsA("MeshPart") or obj:IsA("UnionOperation")
                or obj:IsA("Part") or obj:IsA("Accessory") or obj:IsA("Mesh") or obj:IsA("SpecialMesh") or obj:IsA("ImageLabel")
                or obj:IsA("ImageButton") then
                table.insert(assetsToLoad, obj)
            end
        end
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do addIfRelevant(obj) end
        for _, obj in ipairs(Workspace:GetDescendants()) do addIfRelevant(obj) end
        if #assetsToLoad > 0 then
            local ok, err = pcall(function() ContentProvider:PreloadAsync(assetsToLoad) end)
            if not ok then warn("[Westbound.win] PreloadAsync failed:", err) end
        end
        print("[Westbound.win] ✅ Preload finished.")
    end

    -- Create Window & Tabs
    ScriptModule.Window = Fluent:CreateWindow({
        Title = "Westbound.win",
        SubTitle = "by Arshenxr",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = true,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl
    })
    local Window = ScriptModule.Window

    ScriptModule.Tabs = {
        Visuals = Window:AddTab({ Title = "Visuals", Icon = "" }),
        ModAndAssist = Window:AddTab({ Title = "Mod&Assist", Icon = "" }),
        Miscellaneous = Window:AddTab({ Title = "Miscellaneous", Icon = "" }),
        Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
    }
    local Tabs = ScriptModule.Tabs
    ScriptModule.FirstRun = true

    -- Sections
    local MiscFullBrightSection = Tabs.Miscellaneous:AddSection("Full Bright")
    local MiscTeamSection = Tabs.Miscellaneous:AddSection("Team")
    local MiscServerSection = Tabs.Miscellaneous:AddSection("Server")
    local ESPLegendarySection = Tabs.Visuals:AddSection("ESP Legendary Animals")
    local ModAssistSectionAssist = Tabs.ModAndAssist:AddSection("Assists")
    local ModAssistSectionMods = Tabs.ModAndAssist:AddSection("Mods")

    -- FullBright
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera
    local Teams = game:GetService("Teams")
    local Lighting = game:GetService("Lighting")
    local FullBrightEnabled = false
    local OldLighting = {}
    local lightingChangedConn

    local FullBrightToggle = MiscFullBrightSection:AddToggle("FullBrightToggle",
        { Title = "Full Bright", Default = false })
    local AmbientPicker = MiscFullBrightSection:AddColorpicker("AmbientColor",
        { Title = "Ambient Color", Default = Color3.fromRGB(255, 255, 255) })

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
            if lightingChangedConn then
                lightingChangedConn:Disconnect()
                lightingChangedConn = nil
            end
            lightingChangedConn = Lighting.Changed:Connect(function(prop)
                if FullBrightEnabled and (prop == "Brightness" or prop == "ClockTime" or prop == "FogEnd" or prop == "GlobalShadows" or prop == "Ambient") then
                    applyFullBright()
                end
            end)
        else
            if lightingChangedConn then
                lightingChangedConn:Disconnect()
                lightingChangedConn = nil
            end
            for k, v in pairs(OldLighting) do pcall(function() Lighting[k] = v end) end
        end
    end)

    AmbientPicker:OnChanged(function()
        if FullBrightEnabled then
            local color = AmbientPicker.Value
            if color then Lighting.Ambient = color end
        end
    end)

    -- ESP
    local ESPToggle = ESPLegendarySection:AddToggle("ESP_Toggle", { Title = "Enable ESP", Default = false })
    local ESPColorPicker = ESPLegendarySection:AddColorpicker("ESP_Color",
        { Title = "ESP Color", Default = Color3.fromRGB(255, 255, 255) })
    local ESPSettings = { espEnabled = ESPToggle.Value, espColor = ESPColorPicker.Value }

    ESPToggle:OnChanged(function(value) ESPSettings.espEnabled = value end)
    ESPColorPicker:OnChanged(function(color) ESPSettings.espColor = color end)

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

        -- ตรวจสอบว่า Camera ยังพร้อม
        if not Camera then
            Camera = Workspace.CurrentCamera
            if not Camera then return end
        end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Billboard"
        billboard.Adornee = adornee
        billboard.Size = UDim2.new(0, 150, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        billboard.ResetOnSpawn = false
        billboard.Enabled = ESPSettings.espEnabled

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = getCustomName(model)
        label.TextColor3 = ESPSettings.espColor
        label.TextStrokeTransparency = 0.5
        label.TextSize = 18
        label.Font = Enum.Font.SourceSansBold
        label.Parent = billboard

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

    -- Server Buttons
    local function createServerButton(title, callback)
        MiscServerSection:AddButton({ Title = title, Callback = callback })
    end

    local function createConfirmDialog(title, action)
        Window:Dialog({
            Title = title,
            Content = "Are you sure you want to proceed?",
            Buttons = {
                {
                    Title = "Confirm",
                    Callback = action
                },
                {
                    Title = "Denied",
                    Callback = function() end
                }
            }
        })
    end

    -- Rejoin Server
    createServerButton("Rejoin Server", function()
        createConfirmDialog("Rejoin Server", function()
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
    end)

    -- Hop Server (กรณีเซิฟใหญ่)
    createServerButton("Hop Server", function()
        createConfirmDialog("Hop Server", function()
            local TeleportService = game:GetService("TeleportService")
            local HttpService = game:GetService("HttpService")
            local PlaceId, JobId = game.PlaceId, game.JobId
            local success, response = pcall(function()
                return game:HttpGet("https://games.roblox.com/v1/games/" ..
                    PlaceId .. "/servers/Public?sortOrder=Desc&limit=100")
            end)
            if not success then return end
            local data = HttpService:JSONDecode(response)
            local bestServer = nil
            local highestPlayers = 0
            for _, server in ipairs(data.data) do
                if server.id ~= JobId and server.playing > highestPlayers and server.playing < server.maxPlayers then
                    bestServer = server.id
                    highestPlayers = server.playing
                end
            end
            if bestServer then
                TeleportService:TeleportToPlaceInstance(PlaceId, bestServer, LocalPlayer)
            else
                TeleportService:Teleport(PlaceId, LocalPlayer)
            end
        end)
    end)

    -- Hop SmallServer (กรณีเซิฟเล็ก)
    createServerButton("Hop To SmallServer", function()
        createConfirmDialog("Hop To SmallServer", function()
            local TeleportService = game:GetService("TeleportService")
            local HttpService = game:GetService("HttpService")
            local PlaceId, JobId = game.PlaceId, game.JobId
            local success, response = pcall(function()
                return game:HttpGet("https://games.roblox.com/v1/games/" ..
                    PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
            end)
            if not success then return end
            local data = HttpService:JSONDecode(response)
            local bestServer = nil
            local lowestPlayers = math.huge
            for _, server in ipairs(data.data) do
                if server.id ~= JobId and server.playing < lowestPlayers and server.playing < server.maxPlayers then
                    bestServer = server.id
                    lowestPlayers = server.playing
                end
            end
            if bestServer then
                TeleportService:TeleportToPlaceInstance(PlaceId, bestServer, LocalPlayer)
            else
                TeleportService:Teleport(PlaceId, LocalPlayer)
            end
        end)
    end)

    -- Team Switch
    MiscTeamSection:AddButton({
        Title = "Become Outlaws",
        Callback = function()
            if Teams:FindFirstChild("Outlaws") then LocalPlayer.Team = Teams.Outlaws end
        end
    })
    MiscTeamSection:AddButton({
        Title = "Become Cowboys",
        Callback = function()
            if Teams:FindFirstChild("Cowboys") then LocalPlayer.Team = Teams.Cowboys end
        end
    })

    -- Auto Heal
    local AutoHealToggle = ModAssistSectionAssist:AddToggle("AutoHealToggle", { Title = "Auto Heal", Default = false })
    local HealDebounce = false
    local PrevHealth = 0
    AutoHealToggle:OnChanged(function(value) getgenv().AutoHeal = value end)
    task.spawn(function()
        while task.wait(0.02) do
            if getgenv().AutoHeal then
                local Char = LocalPlayer.Character
                if Char then
                    local Hum = Char:FindFirstChildOfClass("Humanoid")
                    if Hum then
                        if Hum.Health < 30 and Hum.Health < PrevHealth and not HealDebounce then
                            HealDebounce = true
                            PrevHealth = Hum.Health
                            local Potion = LocalPlayer.Backpack:FindFirstChild("Health Potion") or
                                Char:FindFirstChild("Health Potion")
                            if Potion and Potion:FindFirstChild("DrinkPotion") then
                                pcall(function() Potion.DrinkPotion:InvokeServer() end)
                            end
                            task.wait(0.1)
                            HealDebounce = false
                            PrevHealth = Hum.Health
                        else
                            PrevHealth = Hum.Health
                        end
                    end
                end
            end
        end
    end)

    -- Instant Context Action (ICA)
    local ICA_Toggle = ModAssistSectionAssist:AddToggle("InstantContextActionToggle",
        { Title = "Instant Context Action", Default = false })
    local ICA_Hooked = false
    ICA_Toggle:OnChanged(function(value)
        getgenv().InstantContextAction = value
        if not ICA_Hooked then
            ICA_Hooked = true
            for _, v in pairs(getgc(true)) do
                if type(v) == "function" then
                    local info = pcall(function() return getinfo(v) end) and getinfo(v) or nil
                    if info and info.name == "ContextHoldFunc" then
                        local Old; Old = hookfunction(v, function(...)
                            local Arguments = { ... }
                            Arguments[#Arguments] = getgenv().InstantContextAction and 0 or Arguments[#Arguments]
                            return Old(unpack(Arguments))
                        end)
                    end
                end
            end
        end
    end)

    -- Gun Mods
    local GunToggle = ModAssistSectionMods:AddToggle("GunModToggle", { Title = "Enable Gun Mods", Default = false })
    GunToggle:OnChanged(function(value)
        local success, list = pcall(function() return require(game:GetService('ReplicatedStorage').GunScripts.GunStats) end)
        if success and list and value then
            for _, v in pairs(list) do
                pcall(function()
                    v.Spread = 0
                    v.prepTime = 0
                    v.equipTime = 0.1
                    v.MaxShots = math.huge
                    v.ReloadSpeed = 0
                    v.BulletSpeed = 250
                    v.HipFireAccuracy = 0
                    v.ZoomAccuracy = 0
                    v.camShakeResist = 0
                    v.AutoFire = true
                end)
            end
        end
    end)

    -- Infinite Gallop Stamina
    local StaminaToggle = ModAssistSectionMods:AddToggle("InfiniteGallopToggle",
        { Title = "Infinite Gallop Stamina", Default = false })
    local OldIndex
    OldIndex = hookmetamethod(game, "__index", function(Self, Key)
        if not checkcaller() and tostring(Self) == "CurrentStamina" and Key == "Value" then
            if StaminaToggle.Value then return 400 end
        end
        return OldIndex(Self, Key)
    end)

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

    -- Return important objects
    ScriptModule.Window = Window
    ScriptModule.Tabs = Tabs
    ScriptModule.FirstRun = true
end

return ScriptModule
