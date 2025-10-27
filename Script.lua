local Workspace = game:GetService("Workspace");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ContentProvider = game:GetService("ContentProvider");
local RunService = game:GetService("RunService");
local Teams = game:GetService("Teams");
local Lighting = game:GetService("Lighting");
local Players = game:GetService("Players");
local TeleportService = game:GetService("TeleportService");
local HttpService = game:GetService("HttpService");
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait();
local Camera = Workspace.CurrentCamera or Workspace:WaitForChild("CurrentCamera");
local ScriptModule = {};
ScriptModule.Init = function(Fluent, SaveManager, InterfaceManager)
	local startTime = tick();
	while not Camera do
		task.wait(0.1);
		Camera = Workspace.CurrentCamera;
		if ((tick() - startTime) > 5) then
			warn("[Westbound.win] CurrentCamera not found!");
			return;
		end
	end
	print("[Westbound.win] 📸 CurrentCamera ready!");
	do
		print("[Westbound.win] 🕐 Preloading game assets...");
		local assetsToLoad = {};
		local function addIfRelevant(obj)
			if (obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("Sound") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") or obj:IsA("Part") or obj:IsA("Accessory") or obj:IsA("Mesh") or obj:IsA("SpecialMesh") or obj:IsA("ImageLabel") or obj:IsA("ImageButton")) then
				table.insert(assetsToLoad, obj);
			end
		end
		for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
			addIfRelevant(obj);
		end
		for _, obj in ipairs(Workspace:GetChildren()) do
			if (obj:IsA("Model") or obj:IsA("Folder")) then
				addIfRelevant(obj);
			end
		end
		if (#assetsToLoad > 0) then
			local ok, err = pcall(function()
				ContentProvider:PreloadAsync(assetsToLoad);
			end);
			if not ok then
				warn("[Westbound.win] PreloadAsync failed:", err);
			end
		end
		print("[Westbound.win] ✅ Preload finished.");
	end
	local Window = Fluent:CreateWindow({Title="Westbound.win",SubTitle="by Arshenxr",TabWidth=160,Size=UDim2.fromOffset(580, 460),Acrylic=true,Theme="Dark",MinimizeKey=Enum.KeyCode.LeftControl});
	local Tabs = {Visuals=Window:AddTab({Title="Visuals"}),ModAndAssist=Window:AddTab({Title="Mod & Assist"}),Misc=Window:AddTab({Title="Miscellaneous"}),Settings=Window:AddTab({Title="Settings",Icon="settings"})};
	local FullBrightEnabled = false;
	local OldLighting = {};
	local lightingChangedConn;
	local FullBrightSection = Tabs.Misc:AddSection("Full Bright");
	local FullBrightToggle = FullBrightSection:AddToggle("FullBrightToggle", {Title="Full Bright",Default=false});
	local AmbientPicker = FullBrightSection:AddColorpicker("AmbientColor", {Title="Ambient Color",Default=Color3.fromRGB(255, 255, 255)});
	local function applyFullBright()
		Lighting.Brightness = 2;
		Lighting.ClockTime = 14;
		Lighting.FogEnd = 100000;
		Lighting.GlobalShadows = false;
		if FullBrightEnabled then
			Lighting.Ambient = AmbientPicker.Value;
		end
	end
	FullBrightToggle:OnChanged(function(enabled)
		FullBrightEnabled = enabled;
		if enabled then
			OldLighting = {Brightness=Lighting.Brightness,ClockTime=Lighting.ClockTime,FogEnd=Lighting.FogEnd,GlobalShadows=Lighting.GlobalShadows,Ambient=Lighting.Ambient};
			applyFullBright();
			if lightingChangedConn then
				lightingChangedConn:Disconnect();
			end
			lightingChangedConn = Lighting.Changed:Connect(function(prop)
				if (FullBrightEnabled and table.find({"Brightness","ClockTime","FogEnd","GlobalShadows","Ambient"}, prop)) then
					applyFullBright();
				end
			end);
		else
			if lightingChangedConn then
				lightingChangedConn:Disconnect();
			end
			for k, v in pairs(OldLighting) do
				pcall(function()
					Lighting[k] = v;
				end);
			end
		end
	end);
	AmbientPicker:OnChanged(function()
		if FullBrightEnabled then
			Lighting.Ambient = AmbientPicker.Value;
		end
	end);
	local ESPSection = Tabs.Visuals:AddSection("ESP Legendary Animals");
	local ESPToggle = ESPSection:AddToggle("ESP_Toggle", {Title="Enable ESP",Default=false});
	local ESPColorPicker = ESPSection:AddColorpicker("ESP_Color", {Title="ESP Color",Default=Color3.fromRGB(255, 255, 255)});
	local ESPSettings = {Enabled=ESPToggle.Value,Color=ESPColorPicker.Value};
	ESPToggle:OnChanged(function(v)
		ESPSettings.Enabled = v;
	end);
	ESPColorPicker:OnChanged(function(c)
		ESPSettings.Color = c;
	end);
	local targetNames = {"legendarydirewolf","legendarybison","legendarygrizzlybear","legendaryblackbear","legendarywolf","legendarymoosebull","direwolf"};
	local customNames = {legendarydirewolf="Legendary Direwolf",legendarybison="Legendary Bison",legendarygrizzlybear="Legendary Grizzly Bear",legendaryblackbear="Legendary Black Bear",legendarywolf="Legendary Wolf",legendarymoosebull="Legendary Moose Bull",direwolf="Direwolf"};
	local function getCustomName(model)
		local lower = model.Name:lower();
		for key, display in pairs(customNames) do
			if lower:find(key) then
				return display;
			end
		end
		return model.Name;
	end
	local espCache = {};
	local function isTargetModel(model)
		local lower = model.Name:lower();
		for _, t in ipairs(targetNames) do
			if lower:find(t) then
				return true;
			end
		end
		return false;
	end
	local function getAdornee(model)
		return model:FindFirstChild("Head") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart");
	end
	local function createESP(model)
		if espCache[model] then
			return;
		end
		local adornee = getAdornee(model);
		if not adornee then
			return;
		end
		local billboard = Instance.new("BillboardGui");
		billboard.Name = "ESP_Billboard";
		billboard.Adornee = adornee;
		billboard.Size = UDim2.new(0, 150, 0, 40);
		billboard.StudsOffset = Vector3.new(0, 2.5, 0);
		billboard.AlwaysOnTop = true;
		billboard.ResetOnSpawn = false;
		billboard.Enabled = ESPSettings.Enabled;
		billboard.Parent = Workspace;
		local label = Instance.new("TextLabel");
		label.Size = UDim2.new(1, 0, 1, 0);
		label.BackgroundTransparency = 1;
		label.Text = getCustomName(model);
		label.TextColor3 = ESPSettings.Color;
		label.TextStrokeTransparency = 0.5;
		label.TextSize = 18;
		label.Font = Enum.Font.SourceSansBold;
		label.Parent = billboard;
		espCache[model] = {gui=billboard,label=label};
	end
	local function updateESP()
		for model, data in pairs(espCache) do
			if (not model or not model.Parent) then
				data.gui:Destroy();
				espCache[model] = nil;
			else
				data.gui.Enabled = ESPSettings.Enabled;
				data.label.Text = getCustomName(model);
				data.label.TextColor3 = ESPSettings.Color;
			end
		end
	end
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if (obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and isTargetModel(obj)) then
			createESP(obj);
		end
	end
	RunService.RenderStepped:Connect(updateESP);
	Workspace.DescendantAdded:Connect(function(obj)
		if (obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and isTargetModel(obj)) then
			createESP(obj);
		end
	end);
	local ServerSection = Tabs.Misc:AddSection("Server");
	local function confirmDialog(title, action)
		Window:Dialog({Title=title,Content="Are you sure you want to proceed?",Buttons={{Title="Confirm",Callback=action},{Title="Cancel"}}});
	end
	local function serverButton(title, callback)
		ServerSection:AddButton({Title=title,Callback=callback});
	end
	serverButton("Rejoin Server", function()
		confirmDialog("Rejoin Server", function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer);
		end);
	end);
	serverButton("Hop to Full Server", function()
		confirmDialog("Hop to Full Server", function()
			local success, response = pcall(function()
				return game:HttpGet(("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100"):format(game.PlaceId));
			end);
			if success then
				local data = HttpService:JSONDecode(response);
				for _, server in ipairs(data.data) do
					if ((server.playing < server.maxPlayers) and (server.id ~= game.JobId)) then
						return TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer);
					end
				end
			end
		end);
	end);
	serverButton("Hop to Small Server", function()
		confirmDialog("Hop to Small Server", function()
			local success, response = pcall(function()
				return game:HttpGet(("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId));
			end);
			if success then
				local data = HttpService:JSONDecode(response);
				for _, server in ipairs(data.data) do
					if ((server.playing < server.maxPlayers) and (server.id ~= game.JobId)) then
						return TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer);
					end
				end
			end
		end);
	end);
	local TeamSection = Tabs.Misc:AddSection("Team");
	TeamSection:AddButton({Title="Become Outlaws",Callback=function()
		if Teams:FindFirstChild("Outlaws") then
			LocalPlayer.Team = Teams.Outlaws;
		end
	end});
	TeamSection:AddButton({Title="Become Cowboys",Callback=function()
		if Teams:FindFirstChild("Cowboys") then
			LocalPlayer.Team = Teams.Cowboys;
		end
	end});
	local AutoHealSection = Tabs.ModAndAssist:AddSection("Auto Heal");
	local AutoHealToggle = AutoHealSection:AddToggle("AutoHealToggle", {Title="Auto Heal",Default=false});
	local HealDebounce, PrevHealth = false, 0;
	AutoHealToggle:OnChanged(function(v)
		getgenv().AutoHeal = v;
	end);
	task.spawn(function()
		while task.wait(0.2) do
			if getgenv().AutoHeal then
				local Char = LocalPlayer.Character;
				if Char then
					local Hum = Char:FindFirstChildOfClass("Humanoid");
					if (Hum and (Hum.Health < 30) and (Hum.Health < PrevHealth) and not HealDebounce) then
						HealDebounce = true;
						local Potion = LocalPlayer.Backpack:FindFirstChild("Health Potion") or Char:FindFirstChild("Health Potion");
						if (Potion and Potion:FindFirstChild("DrinkPotion")) then
							pcall(function()
								Potion.DrinkPotion:InvokeServer();
							end);
						end
						task.wait(0.2);
						HealDebounce = false;
					end
					PrevHealth = (Hum and Hum.Health) or 0;
				end
			end
		end
	end);
	SaveManager:SetLibrary(Fluent);
	InterfaceManager:SetLibrary(Fluent);
	SaveManager:IgnoreThemeSettings();
	InterfaceManager:SetFolder("FluentScriptHub");
	SaveManager:SetFolder("FluentScriptHub/specific-game");
	pcall(function()
		SaveManager:LoadAutoloadConfig();
	end);
	InterfaceManager:BuildInterfaceSection(Tabs.Settings);
	SaveManager:BuildConfigSection(Tabs.Settings);
	Window:SelectTab(1);
	Fluent:Notify({Title="Westbound.win",Content="Successfully Loaded!",Duration=5});
end;
return ScriptModule;
