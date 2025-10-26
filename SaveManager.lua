local httpService = game:GetService("HttpService")

local SaveManager = {} do
    SaveManager.Folder = "FluentScriptHub/specific-game"
    SaveManager.Ignore = {}

    SaveManager.Parser = {
        Toggle = {
            Save = function(idx, object)
                return { type = "Toggle", idx = idx, value = object.Value }
            end,
            Load = function(idx, data)
                if SaveManager.Options[idx] then
                    SaveManager.Options[idx]:SetValue(data.value)
                end
            end,
        },
        Slider = {
            Save = function(idx, object)
                return { type = "Slider", idx = idx, value = object.Value }
            end,
            Load = function(idx, data)
                if SaveManager.Options[idx] then
                    SaveManager.Options[idx]:SetValue(data.value)
                end
            end,
        },
        Dropdown = {
            Save = function(idx, object)
                return { type = "Dropdown", idx = idx, value = object.Value, multi = object.Multi }
            end,
            Load = function(idx, data)
                if SaveManager.Options[idx] then
                    SaveManager.Options[idx]:SetValue(data.value)
                end
            end,
        },
        Colorpicker = {
            Save = function(idx, object)
                return { type = "Colorpicker", idx = idx, value = object.Value:ToHex(), transparency = object.Transparency }
            end,
            Load = function(idx, data)
                if SaveManager.Options[idx] then
                    SaveManager.Options[idx]:SetValueRGB(Color3.fromHex(data.value), data.transparency)
                end
            end,
        },
        Keybind = {
            Save = function(idx, object)
                return { type = "Keybind", idx = idx, mode = object.Mode, key = object.Value }
            end,
            Load = function(idx, data)
                if SaveManager.Options[idx] then
                    SaveManager.Options[idx]:SetValue(data.key, data.mode)
                end
            end,
        },
        Input = {
            Save = function(idx, object)
                return { type = "Input", idx = idx, text = object.Value }
            end,
            Load = function(idx, data)
                if SaveManager.Options[idx] and type(data.text) == "string" then
                    SaveManager.Options[idx]:SetValue(data.text)
                end
            end,
        },
    }

    -- ตั้งค่า Ignore index
    function SaveManager:SetIgnoreIndexes(list)
        for _, key in next, list do
            self.Ignore[key] = true
        end
    end

    -- ตั้งค่า Folder
    function SaveManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end

    -- สร้าง Folder ถ้ายังไม่มี
    function SaveManager:BuildFolderTree()
        local paths = {
            self.Folder,
            self.Folder .. "/settings"
        }
        for i = 1, #paths do
            if not isfolder(paths[i]) then
                makefolder(paths[i])
            end
        end
    end

    -- ตั้ง Library ของ Fluent
    function SaveManager:SetLibrary(library)
        self.Library = library
        self.Options = library.Options
    end

    -- Save Config
    function SaveManager:Save(name)
        if not name then return false, "No config name" end
        local fullPath = self.Folder .. "/settings/" .. name .. ".json"

        local data = { objects = {} }
        for idx, option in next, SaveManager.Options do
            if not self.Parser[option.Type] then continue end
            if self.Ignore[idx] then continue end
            table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
        end

        local success, encoded = pcall(httpService.JSONEncode, httpService, data)
        if not success then return false, "JSON encode failed" end

        writefile(fullPath, encoded)
        return true
    end

    -- Load Config
    function SaveManager:Load(name)
        if not name then return false, "No config name" end
        local file = self.Folder .. "/settings/" .. name .. ".json"
        if not isfile(file) then return false, "File not found" end

        local success, decoded = pcall(httpService.JSONDecode, httpService, readfile(file))
        if not success then return false, "JSON decode error" end

        for _, optionData in next, decoded.objects do
            if self.Parser[optionData.type] then
                task.spawn(function()
                    self.Parser[optionData.type].Load(optionData.idx, optionData)
                end)
            end
        end

        return true
    end

    -- โหลด Autoload Config
    function SaveManager:LoadAutoloadConfig()
        local autoFile = self.Folder .. "/settings/autoload.txt"
        if isfile(autoFile) then
            local name = readfile(autoFile)
            local success, err = self:Load(name)
            if not success then
                return self.Library:Notify({
                    Title = "Interface",
                    Content = "Config loader",
                    SubContent = "Failed to autoload: " .. err,
                    Duration = 7
                })
            end
            self.Library:Notify({
                Title = "Interface",
                Content = "Config loader",
                SubContent = string.format("Autoloaded config %q", name),
                Duration = 7
            })
        end
    end

    -- สร้าง Section Config ใน Tab Settings
    function SaveManager:BuildConfigSection(tab)
        assert(self.Library, "Library not set")
        local section = tab:AddSection("Configuration")

        section:AddInput("SaveManager_ConfigName", { Title = "Config name" })
        section:AddDropdown("SaveManager_ConfigList", { Title = "Config list", Values = self:RefreshConfigList(), AllowNull = true })

        section:AddButton({
            Title = "Create config",
            Callback = function()
                local name = SaveManager.Options.SaveManager_ConfigName.Value
                if name:gsub(" ", "") == "" then
                    return self.Library:Notify({ Title = "Interface", Content = "Config loader", SubContent = "Invalid name", Duration = 7 })
                end
                local success, err = self:Save(name)
                if not success then
                    return self.Library:Notify({ Title = "Interface", Content = "Config loader", SubContent = "Save failed: "..err, Duration = 7 })
                end
                self.Library:Notify({ Title = "Interface", Content = "Config loader", SubContent = "Created config: "..name, Duration = 7 })
                SaveManager.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
                SaveManager.Options.SaveManager_ConfigList:SetValue(nil)
            end
        })

        section:AddButton({
            Title = "Load config",
            Callback = function()
                local name = SaveManager.Options.SaveManager_ConfigList.Value
                local success, err = self:Load(name)
                if not success then
                    return self.Library:Notify({ Title = "Interface", Content = "Config loader", SubContent = "Load failed: "..err, Duration = 7 })
                end
                self.Library:Notify({ Title = "Interface", Content = "Config loader", SubContent = "Loaded config: "..name, Duration = 7 })
            end
        })

        section:AddButton({
            Title = "Overwrite config",
            Callback = function()
                local name = SaveManager.Options.SaveManager_ConfigList.Value
                local success, err = self:Save(name)
                if not success then
                    return self.Library:Notify({ Title = "Interface", Content = "Config loader", SubContent = "Overwrite failed: "..err, Duration = 7 })
                end
                self.Library:Notify({ Title = "Interface", Content = "Config loader", SubContent = "Overwrote config: "..name, Duration = 7 })
            end
        })

        section:AddButton({
            Title = "Refresh list",
            Callback = function()
                SaveManager.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
                SaveManager.Options.SaveManager_ConfigList:SetValue(nil)
            end
        })

        local AutoloadButton
        AutoloadButton = section:AddButton({
            Title = "Set as autoload",
            Description = "Current autoload config: none",
            Callback = function()
                local name = SaveManager.Options.SaveManager_ConfigList.Value
                writefile(self.Folder .. "/settings/autoload.txt", name)
                AutoloadButton:SetDesc("Current autoload config: "..name)
                self.Library:Notify({ Title = "Interface", Content = "Config loader", SubContent = "Set "..name.." to autoload", Duration = 7 })
            end
        })

        if isfile(self.Folder .. "/settings/autoload.txt") then
            local name = readfile(self.Folder .. "/settings/autoload.txt")
            AutoloadButton:SetDesc("Current autoload config: "..name)
        end

        self:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName" })
    end

    -- ดึง list ของ config
    function SaveManager:RefreshConfigList()
        local list = listfiles(self.Folder .. "/settings")
        local out = {}
        for _, file in ipairs(list) do
            if file:sub(-5) == ".json" then
                local name = file:match("[^/\\]+%.json$")
                name = name:gsub("%.json$", "")
                if name ~= "options" then table.insert(out, name) end
            end
        end
        return out
    end

    -- Ignore default theme settings
    function SaveManager:IgnoreThemeSettings()
        self:SetIgnoreIndexes({ "InterfaceTheme", "AcrylicToggle", "TransparentToggle", "MenuKeybind" })
    end

    SaveManager:BuildFolderTree()
end

return SaveManager
