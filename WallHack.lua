--[[

	Wall Hack Module [westbound.pro] by Exunys © CC0 1.0 Universal (2023)
	https://github.com/Exunys

]]

--// Cache

local select, next, tostring, pcall, getgenv, mathfloor, mathabs, stringgsub, stringmatch, wait = select, next, tostring, pcall, getgenv, math.floor, math.abs, string.gsub, string.match, task.wait
local Vector2new, Vector3new, Vector3zero, CFramenew, Drawingnew, WorldToViewportPoint = Vector2.new, Vector3.new, Vector3.zero, CFrame.new, Drawing.new

--// Launching checks

if not getgenv().AirTeam_westboundpro or not getgenv().AirTeam_westboundpro.WallHack then return end

--// Services

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// Environment

local CrosshairParts, WrappedPlayers = {
	LeftLine = Drawingnew("Line"),
	RightLine = Drawingnew("Line"),
	TopLine = Drawingnew("Line"),
	BottomLine = Drawingnew("Line"),
	CenterDot = Drawingnew("Circle")
}, {}

--// Core Functions

WorldToViewportPoint = function(...)
	return Camera.WorldToViewportPoint(Camera, ...)
end

local function GetEnv()
	return getgenv().AirTeam_westboundpro.WallHack
end

local function GetPlayerTable(Player)
	for _, v in next, WrappedPlayers do
		if v.Name == Player.Name then
			return v
		end
	end
end

local function AssignRigType(Player)
	local PlayerTable = GetPlayerTable(Player)

	repeat wait(0) until Player.Character

	if Player.Character:FindFirstChild("Torso") and not Player.Character:FindFirstChild("LowerTorso") then
		PlayerTable.RigType = "R6"
	elseif Player.Character:FindFirstChild("LowerTorso") and not Player.Character:FindFirstChild("Torso") then
		PlayerTable.RigType = "R15"
	else
		repeat AssignRigType(Player) until PlayerTable.RigType
	end
end

local function InitChecks(Player)
	local PlayerTable = GetPlayerTable(Player)

	PlayerTable.Connections.UpdateChecks = RunService.RenderStepped:Connect(function()
		if Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") then
			if GetEnv().Settings.AliveCheck then
				PlayerTable.Checks.Alive = Player.Character:FindFirstChildOfClass("Humanoid").Health > 0
			else
				PlayerTable.Checks.Alive = true
			end

			if GetEnv().Settings.TeamCheck then
				PlayerTable.Checks.Team = Player.TeamColor ~= LocalPlayer.TeamColor
			else
				PlayerTable.Checks.Team = true
			end
		else
			PlayerTable.Checks.Alive = false
			PlayerTable.Checks.Team = false
		end
	end)
end

--// Visuals

local Visuals = {
	AddESP_Animal = function(Animal)
		local AnimalTable = {
			Name = Animal.Name,
			ESP = Drawingnew("Text"),
			Connections = {}
		}

		AnimalTable.Connections.ESP = RunService.RenderStepped:Connect(function()
			if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and workspace.Animals:FindFirstChild(AnimalTable.Name) and Animal:FindFirstChildOfClass("Humanoid") and Animal:FindFirstChild("HumanoidRootPart") and Animal:FindFirstChild("Head") and GetEnv().Settings.Enabled and GetEnv().Settings.Animals then
				local Vector, OnScreen = WorldToViewportPoint(Animal.Head.Position)

				if OnScreen then
					AnimalTable.ESP.Visible = GetEnv().Settings.Animals

					if AnimalTable.ESP.Visible then
						AnimalTable.ESP.Center = true
						AnimalTable.ESP.Size = GetEnv().Visuals.ESPSettings.TextSize
						AnimalTable.ESP.Outline = GetEnv().Visuals.ESPSettings.Outline
						AnimalTable.ESP.OutlineColor = GetEnv().Visuals.ESPSettings.OutlineColor
						AnimalTable.ESP.Color = GetEnv().Visuals.ESPSettings.TextColor
						AnimalTable.ESP.Transparency = GetEnv().Visuals.ESPSettings.TextTransparency
						AnimalTable.ESP.Font = GetEnv().Visuals.ESPSettings.TextFont

						AnimalTable.ESP.Position = Vector2new(Vector.X, Vector.Y - 25)

						local Parts, Content = {
							Health = "("..tostring(mathfloor(Animal.Humanoid.Health))..")",
							Distance = "["..tostring(mathfloor(((Animal.HumanoidRootPart.Position or Vector3zero) - (LocalPlayer.Character.HumanoidRootPart.Position or Vector3zero)).Magnitude)).."]",
							Name = stringgsub(stringmatch(Animal.Name, "(.+){"), "(%l)(%u)", function(...)
								return select(1, ...).." "..select(2, ...)
							end)
						}, ""

						if GetEnv().Visuals.ESPSettings.DisplayName then
							Content = Parts.Name..Content
						end

						if GetEnv().Visuals.ESPSettings.DisplayHealth then
							Content = Parts.Health..(GetEnv().Visuals.ESPSettings.DisplayName and " " or "")..Content
						end

						if GetEnv().Visuals.ESPSettings.DisplayDistance then
							Content = Content.." "..Parts.Distance
						end

						AnimalTable.ESP.Text = Content
					end
				else
					AnimalTable.ESP.Visible = false
				end
			else
				AnimalTable.ESP.Visible = false
			end

			if not workspace.Animals:FindFirstChild(AnimalTable.Name) then
				AnimalTable.Connections.ESP:Disconnect()
				AnimalTable.ESP:Remove()
			end
		end)
	end,

	AddESP = function(Player)
		local PlayerTable = GetPlayerTable(Player)

		PlayerTable.ESP = Drawingnew("Text")

		PlayerTable.Connections.ESP = RunService.RenderStepped:Connect(function()
			if LocalPlayer.Character and Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character:FindFirstChild("Head") and GetEnv().Settings.Enabled then
				local Vector, OnScreen = WorldToViewportPoint(Player.Character.Head.Position)

				PlayerTable.ESP.Visible = GetEnv().Visuals.ESPSettings.Enabled

				if OnScreen and GetEnv().Visuals.ESPSettings.Enabled then
					PlayerTable.ESP.Visible = PlayerTable.Checks.Alive and PlayerTable.Checks.Team and true or false

					if PlayerTable.ESP.Visible then
						PlayerTable.ESP.Center = true
						PlayerTable.ESP.Size = GetEnv().Visuals.ESPSettings.TextSize
						PlayerTable.ESP.Outline = GetEnv().Visuals.ESPSettings.Outline
						PlayerTable.ESP.OutlineColor = GetEnv().Visuals.ESPSettings.OutlineColor
						PlayerTable.ESP.Color = GetEnv().Visuals.ESPSettings.TextColor
						PlayerTable.ESP.Transparency = GetEnv().Visuals.ESPSettings.TextTransparency
						PlayerTable.ESP.Font = GetEnv().Visuals.ESPSettings.TextFont

						PlayerTable.ESP.Position = Vector2new(Vector.X, Vector.Y - 25)

						local Parts, Content = {
							Health = "("..tostring(mathfloor(Player.Character.Humanoid.Health))..")",
							Distance = "["..tostring(mathfloor(((Player.Character.HumanoidRootPart.Position or Vector3zero) - (LocalPlayer.Character.HumanoidRootPart.Position or Vector3zero)).Magnitude)).."]",
							Name = Player.DisplayName == Player.Name and Player.Name or Player.DisplayName.." {"..Player.Name.."}"
						}, ""

						if GetEnv().Visuals.ESPSettings.DisplayName then
							Content = Parts.Name..Content
						end

						if GetEnv().Visuals.ESPSettings.DisplayHealth then
							Content = Parts.Health..(GetEnv().Visuals.ESPSettings.DisplayName and " " or "")..Content
						end

						if GetEnv().Visuals.ESPSettings.DisplayDistance then
							Content = Content.." "..Parts.Distance
						end

						PlayerTable.ESP.Text = Content
					end
				else
					PlayerTable.ESP.Visible = false
				end
			else
				PlayerTable.ESP.Visible = false
			end
		end)
	end,

	AddTracer = function(Player)
		local PlayerTable = GetPlayerTable(Player)

		PlayerTable.Tracer = Drawingnew("Line")

		PlayerTable.Connections.Tracer = RunService.RenderStepped:Connect(function()
			if Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") and Player.Character:FindFirstChild("HumanoidRootPart") and GetEnv().Settings.Enabled then
				local HRPCFrame, HRPSize = Player.Character.HumanoidRootPart.CFrame, Player.Character.HumanoidRootPart.Size
				local Vector, OnScreen = WorldToViewportPoint(HRPCFrame * CFramenew(0, -HRPSize.Y, 0).Position)

				if OnScreen and GetEnv().Visuals.TracersSettings.Enabled then
					if GetEnv().Visuals.TracersSettings.Enabled then
						PlayerTable.Tracer.Visible = PlayerTable.Checks.Alive and PlayerTable.Checks.Team and true or false

						if PlayerTable.Tracer.Visible then
							PlayerTable.Tracer.Thickness = GetEnv().Visuals.TracersSettings.Thickness
							PlayerTable.Tracer.Color = GetEnv().Visuals.TracersSettings.Color
							PlayerTable.Tracer.Transparency = GetEnv().Visuals.TracersSettings.Transparency

							PlayerTable.Tracer.To = Vector2new(Vector.X, Vector.Y)

							if GetEnv().Visuals.TracersSettings.Type == 1 then
								PlayerTable.Tracer.From = Vector2new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
							elseif GetEnv().Visuals.TracersSettings.Type == 2 then
								PlayerTable.Tracer.From = Vector2new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
							elseif GetEnv().Visuals.TracersSettings.Type == 3 then
								PlayerTable.Tracer.From = Vector2new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
							else
								PlayerTable.Tracer.From = Vector2new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
							end
						end
					end
				else
					PlayerTable.Tracer.Visible = false
				end
			else
				PlayerTable.Tracer.Visible = false
			end
		end)
	end,

	AddBox = function(Player)
		local PlayerTable = GetPlayerTable(Player)

		PlayerTable.Box.Square = Drawingnew("Square")

		PlayerTable.Box.TopLeftLine = Drawingnew("Line")
		PlayerTable.Box.TopLeftLine = Drawingnew("Line")
		PlayerTable.Box.TopRightLine = Drawingnew("Line")
		PlayerTable.Box.BottomLeftLine = Drawingnew("Line")
		PlayerTable.Box.BottomRightLine = Drawingnew("Line")

		local function Visibility(Bool)
			if GetEnv().Visuals.BoxSettings.Type == 1 then
				PlayerTable.Box.Square.Visible = not Bool

				PlayerTable.Box.TopLeftLine.Visible = Bool
				PlayerTable.Box.TopRightLine.Visible = Bool
				PlayerTable.Box.BottomLeftLine.Visible = Bool
				PlayerTable.Box.BottomRightLine.Visible = Bool
			elseif GetEnv().Visuals.BoxSettings.Type == 2 then
				PlayerTable.Box.Square.Visible = Bool

				PlayerTable.Box.TopLeftLine.Visible = not Bool
				PlayerTable.Box.TopRightLine.Visible = not Bool
				PlayerTable.Box.BottomLeftLine.Visible = not Bool
				PlayerTable.Box.BottomRightLine.Visible = not Bool
			end
		end

		local function Visibility2(Bool)
			PlayerTable.Box.Square.Visible = Bool

			PlayerTable.Box.TopLeftLine.Visible = Bool
			PlayerTable.Box.TopRightLine.Visible = Bool
			PlayerTable.Box.BottomLeftLine.Visible = Bool
			PlayerTable.Box.BottomRightLine.Visible = Bool
		end

		PlayerTable.Connections.Box = RunService.RenderStepped:Connect(function()
			if Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character:FindFirstChild("Head") and GetEnv().Settings.Enabled then
				local Vector, OnScreen = WorldToViewportPoint(Player.Character.HumanoidRootPart.Position)

				local HRPCFrame, HRPSize = Player.Character.HumanoidRootPart.CFrame, Player.Character.HumanoidRootPart.Size * GetEnv().Visuals.BoxSettings.Increase

				local TopLeftPosition = WorldToViewportPoint(HRPCFrame * CFramenew(HRPSize.X,  HRPSize.Y, 0).Position)
				local TopRightPosition = WorldToViewportPoint(HRPCFrame * CFramenew(-HRPSize.X,  HRPSize.Y, 0).Position)
				local BottomLeftPosition = WorldToViewportPoint(HRPCFrame * CFramenew(HRPSize.X, -HRPSize.Y, 0).Position)
				local BottomRightPosition = WorldToViewportPoint(HRPCFrame * CFramenew(-HRPSize.X, -HRPSize.Y, 0).Position)

				local HeadOffset = WorldToViewportPoint(Player.Character.Head.Position + Vector3new(0, 0.5, 0))
				local LegsOffset = WorldToViewportPoint(Player.Character.HumanoidRootPart.Position - Vector3new(0, 3, 0))

				Visibility(GetEnv().Visuals.BoxSettings.Enabled)

				if OnScreen and GetEnv().Visuals.BoxSettings.Enabled then
					if PlayerTable.Checks.Alive and PlayerTable.Checks.Team then
						Visibility(true)
					else
						Visibility2(false)
					end

					if PlayerTable.Box.Square.Visible and not PlayerTable.Box.TopLeftLine.Visible and not PlayerTable.Box.TopRightLine.Visible and not PlayerTable.Box.BottomLeftLine.Visible and not PlayerTable.Box.BottomRightLine.Visible then
						PlayerTable.Box.Square.Thickness = GetEnv().Visuals.BoxSettings.Thickness
						PlayerTable.Box.Square.Color = GetEnv().Visuals.BoxSettings.Color
						PlayerTable.Box.Square.Transparency = GetEnv().Visuals.BoxSettings.Transparency
						PlayerTable.Box.Square.Filled = GetEnv().Visuals.BoxSettings.Filled

						PlayerTable.Box.Square.Size = Vector2new(2000 / Vector.Z, HeadOffset.Y - LegsOffset.Y)
						PlayerTable.Box.Square.Position = Vector2new(Vector.X - PlayerTable.Box.Square.Size.X / 2, Vector.Y - PlayerTable.Box.Square.Size.Y / 2)
					elseif not PlayerTable.Box.Square.Visible and PlayerTable.Box.TopLeftLine.Visible and PlayerTable.Box.TopRightLine.Visible and PlayerTable.Box.BottomLeftLine.Visible and PlayerTable.Box.BottomRightLine.Visible then
						PlayerTable.Box.TopLeftLine.Thickness = GetEnv().Visuals.BoxSettings.Thickness
						PlayerTable.Box.TopLeftLine.Transparency = GetEnv().Visuals.BoxSettings.Transparency
						PlayerTable.Box.TopLeftLine.Color = GetEnv().Visuals.BoxSettings.Color

						PlayerTable.Box.TopRightLine.Thickness = GetEnv().Visuals.BoxSettings.Thickness
						PlayerTable.Box.TopRightLine.Transparency = GetEnv().Visuals.BoxSettings.Transparency
						PlayerTable.Box.TopRightLine.Color = GetEnv().Visuals.BoxSettings.Color

						PlayerTable.Box.BottomLeftLine.Thickness = GetEnv().Visuals.BoxSettings.Thickness
						PlayerTable.Box.BottomLeftLine.Transparency = GetEnv().Visuals.BoxSettings.Transparency
						PlayerTable.Box.BottomLeftLine.Color = GetEnv().Visuals.BoxSettings.Color

						PlayerTable.Box.BottomRightLine.Thickness = GetEnv().Visuals.BoxSettings.Thickness
						PlayerTable.Box.BottomRightLine.Transparency = GetEnv().Visuals.BoxSettings.Transparency
						PlayerTable.Box.BottomRightLine.Color = GetEnv().Visuals.BoxSettings.Color

						PlayerTable.Box.TopLeftLine.From = Vector2new(TopLeftPosition.X, TopLeftPosition.Y)
						PlayerTable.Box.TopLeftLine.To = Vector2new(TopRightPosition.X, TopRightPosition.Y)

						PlayerTable.Box.TopRightLine.From = Vector2new(TopRightPosition.X, TopRightPosition.Y)
						PlayerTable.Box.TopRightLine.To = Vector2new(BottomRightPosition.X, BottomRightPosition.Y)

						PlayerTable.Box.BottomLeftLine.From = Vector2new(BottomLeftPosition.X, BottomLeftPosition.Y)
						PlayerTable.Box.BottomLeftLine.To = Vector2new(TopLeftPosition.X, TopLeftPosition.Y)

						PlayerTable.Box.BottomRightLine.From = Vector2new(BottomRightPosition.X, BottomRightPosition.Y)
						PlayerTable.Box.BottomRightLine.To = Vector2new(BottomLeftPosition.X, BottomLeftPosition.Y)
					end
				else
					Visibility2(false)
				end
			else
				Visibility2(false)
			end
		end)
	end,

	AddHeadDot = function(Player)
		local PlayerTable = GetPlayerTable(Player)

		PlayerTable.HeadDot = Drawingnew("Circle")

		PlayerTable.Connections.HeadDot = RunService.RenderStepped:Connect(function()
			if Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") and Player.Character:FindFirstChild("Head") and GetEnv().Settings.Enabled then
				local Vector, OnScreen = WorldToViewportPoint(Player.Character.Head.Position)

				PlayerTable.HeadDot.Visible = GetEnv().Visuals.HeadDotSettings.Enabled

				if OnScreen and GetEnv().Visuals.HeadDotSettings.Enabled then
					if GetEnv().Visuals.HeadDotSettings.Enabled then
						PlayerTable.HeadDot.Visible = PlayerTable.Checks.Alive and PlayerTable.Checks.Team and true or false

						if PlayerTable.HeadDot.Visible then
							PlayerTable.HeadDot.Thickness = GetEnv().Visuals.HeadDotSettings.Thickness
							PlayerTable.HeadDot.Color = GetEnv().Visuals.HeadDotSettings.Color
							PlayerTable.HeadDot.Transparency = GetEnv().Visuals.HeadDotSettings.Transparency
							PlayerTable.HeadDot.NumSides = GetEnv().Visuals.HeadDotSettings.Sides
							PlayerTable.HeadDot.Filled = GetEnv().Visuals.HeadDotSettings.Filled
							PlayerTable.HeadDot.Position = Vector2new(Vector.X, Vector.Y)

							local Top, Bottom = WorldToViewportPoint((Player.Character.Head.CFrame * CFramenew(0, Player.Character.Head.Size.Y / 2, 0)).Position), WorldToViewportPoint((Player.Character.Head.CFrame * CFramenew(0, -Player.Character.Head.Size.Y / 2, 0)).Position)
							PlayerTable.HeadDot.Radius = mathabs((Top - Bottom).Y) - 3
						end
					end
				else
					PlayerTable.HeadDot.Visible = false
				end
			else
				PlayerTable.HeadDot.Visible = false
			end
		end)
	end,

	AddCrosshair = function()
		local AxisX, AxisY = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2

		RunService.RenderStepped:Connect(function()
			if GetEnv().Crosshair.Settings.Enabled then
				if GetEnv().Crosshair.Settings.Type == 1 then
					AxisX, AxisY = UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y
				elseif GetEnv().Crosshair.Settings.Type == 2 then
					AxisX, AxisY = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
				else
					GetEnv().Crosshair.Settings.Type = 1
				end
			end
		end)

		RunService.RenderStepped:Connect(function()
			if GetEnv().Crosshair.Settings.Enabled then

				--// Left Line

				CrosshairParts.LeftLine.Visible = GetEnv().Crosshair.Settings.Enabled and GetEnv().Settings.Enabled
				CrosshairParts.LeftLine.Color = GetEnv().Crosshair.Settings.Color
				CrosshairParts.LeftLine.Thickness = GetEnv().Crosshair.Settings.Thickness
				CrosshairParts.LeftLine.Transparency = GetEnv().Crosshair.Settings.Transparency

				CrosshairParts.LeftLine.From = Vector2new(AxisX + GetEnv().Crosshair.Settings.GapSize, AxisY)
				CrosshairParts.LeftLine.To = Vector2new(AxisX + GetEnv().Crosshair.Settings.Size + GetEnv().Crosshair.Settings.GapSize, AxisY)

				--// Right Line

				CrosshairParts.RightLine.Visible = GetEnv().Settings.Enabled
				CrosshairParts.RightLine.Color = GetEnv().Crosshair.Settings.Color
				CrosshairParts.RightLine.Thickness = GetEnv().Crosshair.Settings.Thickness
				CrosshairParts.RightLine.Transparency = GetEnv().Crosshair.Settings.Transparency

				CrosshairParts.RightLine.From = Vector2new(AxisX - GetEnv().Crosshair.Settings.GapSize, AxisY)
				CrosshairParts.RightLine.To = Vector2new(AxisX - GetEnv().Crosshair.Settings.Size - GetEnv().Crosshair.Settings.GapSize, AxisY)

				--// Top Line

				CrosshairParts.TopLine.Visible = GetEnv().Settings.Enabled
				CrosshairParts.TopLine.Color = GetEnv().Crosshair.Settings.Color
				CrosshairParts.TopLine.Thickness = GetEnv().Crosshair.Settings.Thickness
				CrosshairParts.TopLine.Transparency = GetEnv().Crosshair.Settings.Transparency

				CrosshairParts.TopLine.From = Vector2new(AxisX, AxisY + GetEnv().Crosshair.Settings.GapSize)
				CrosshairParts.TopLine.To = Vector2new(AxisX, AxisY + GetEnv().Crosshair.Settings.Size + GetEnv().Crosshair.Settings.GapSize)

				--// Bottom Line

				CrosshairParts.BottomLine.Visible = GetEnv().Settings.Enabled
				CrosshairParts.BottomLine.Color = GetEnv().Crosshair.Settings.Color
				CrosshairParts.BottomLine.Thickness = GetEnv().Crosshair.Settings.Thickness
				CrosshairParts.BottomLine.Transparency = GetEnv().Crosshair.Settings.Transparency

				CrosshairParts.BottomLine.From = Vector2new(AxisX, AxisY - GetEnv().Crosshair.Settings.GapSize)
				CrosshairParts.BottomLine.To = Vector2new(AxisX, AxisY - GetEnv().Crosshair.Settings.Size - GetEnv().Crosshair.Settings.GapSize)

				--// Center Dot

				CrosshairParts.CenterDot.Visible = GetEnv().Settings.Enabled and GetEnv().Crosshair.Settings.CenterDot
				CrosshairParts.CenterDot.Color = GetEnv().Crosshair.Settings.CenterDotColor
				CrosshairParts.CenterDot.Radius = GetEnv().Crosshair.Settings.CenterDotSize
				CrosshairParts.CenterDot.Transparency = GetEnv().Crosshair.Settings.CenterDotTransparency
				CrosshairParts.CenterDot.Filled = GetEnv().Crosshair.Settings.CenterDotFilled
				CrosshairParts.CenterDot.Thickness = GetEnv().Crosshair.Settings.CenterDotThickness

				CrosshairParts.CenterDot.Position = Vector2new(AxisX, AxisY)
			else
				CrosshairParts.LeftLine.Visible = false
				CrosshairParts.RightLine.Visible = false
				CrosshairParts.TopLine.Visible = false
				CrosshairParts.BottomLine.Visible = false
				CrosshairParts.CenterDot.Visible = false
			end
		end)
	end
}

--// Functions

local function Wrap(Player)
	if not GetPlayerTable(Player) then
		local Table, Value = nil, {Name = Player.Name, RigType = nil, Checks = {Alive = true, Team = true}, Connections = {}, ESP = nil, Tracer = nil, HeadDot = nil, Box = {Square = nil, TopLeftLine = nil, TopRightLine = nil, BottomLeftLine = nil, BottomRightLine = nil}, Chams = {}}

		for _, v in next, WrappedPlayers do
			if v[1] == Player.Name then
				Table = v
			end
		end

		if not Table then
			WrappedPlayers[#WrappedPlayers + 1] = Value
			AssignRigType(Player)
			InitChecks(Player)

			Visuals.AddESP(Player)
			Visuals.AddTracer(Player)
			Visuals.AddBox(Player)
			Visuals.AddHeadDot(Player)
		end
	end
end

local function UnWrap(Player)
	local Table, Index = nil, nil

	for i, v in next, WrappedPlayers do
		if v.Name == Player.Name then
			Table, Index = v, i
		end
	end

	if Table then
		for _, v in next, Table.Connections do
			v:Disconnect()
		end

		pcall(function()
			Table.ESP:Remove()
			Table.Tracer:Remove()
			Table.HeadDot:Remove()
		end)

		for _, v in next, Table.Box do
			if type(v.Remove) == "function" then
				v:Remove()
			end
		end

		for _, v in next, Table.Chams do
			for _, v2 in next, v do
				if type(v2.Remove) == "function" then
					v2:Remove()
				end
			end
		end

		WrappedPlayers[Index] = nil
	end
end

local function Load()
	Visuals.AddCrosshair()

	workspace.Animals.ChildAdded:Connect(Visuals.AddESP_Animal)
	Players.PlayerAdded:Connect(Wrap)
	Players.PlayerRemoving:Connect(UnWrap)

	for _, v in next, workspace.Animals:GetChildren() do
		if v:IsA("Model") and v:WaitForChild("Humanoid", 1 / 0) then
			Visuals.AddESP_Animal(v)
		end
	end

	RunService.RenderStepped:Connect(function()
		for _, v in next, Players:GetPlayers() do
			if v ~= LocalPlayer then
				Wrap(v)
			end
		end

		wait(10)
	end)
end

--// Main

Load()
