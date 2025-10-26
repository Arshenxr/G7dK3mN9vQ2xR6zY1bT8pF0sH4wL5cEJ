-- script.lua (Module)
local Module = {}

local Fluent = _G.Fluent or error("Fluent not loaded")
Module.Window = Fluent:CreateWindow({
    Title = "Westbound.win",
    SubTitle = "by Arshenxr",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

Module.Tabs = {
    Visuals = Module.Window:AddTab({ Title = "Visuals", Icon = "" }),
    ModAndAssist = Module.Window:AddTab({ Title = "Mod&Assist", Icon = "" }),
    Miscellaneous = Module.Window:AddTab({ Title = "Miscellaneous", Icon = "" }),
    Settings = Module.Window:AddTab({ Title = "Settings", Icon = "settings" })
}

Module.FirstRun = true

-- ตัวอย่างฟีเจอร์ FullBright
local Lighting = game:GetService("Lighting")
local FullBrightEnabled = false
local OldLighting = {}
local lightingChangedConn

local MiscFullBrightSection = Module.Tabs.Miscellaneous:AddSection("Full Bright")
local FullBrightToggle = MiscFullBrightSection:AddToggle("FullBrightToggle", { Title = "Full Bright", Default = false })

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
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        lightingChangedConn = Lighting.Changed:Connect(function(prop)
            if FullBrightEnabled and (prop == "Brightness" or prop == "ClockTime" or prop == "FogEnd" or prop == "GlobalShadows" or prop == "Ambient") then
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.FogEnd = 100000
                Lighting.GlobalShadows = false
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

return Module
