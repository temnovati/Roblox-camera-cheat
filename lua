-- Connect ReGui
local ReGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/depthso/Dear-ReGui/refs/heads/main/ReGui.lua'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Camera
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Settings
local AIM_RADIUS = 200
local AIM_PART = "Head"
local ESP_ENABLED = false
local AIMBOT_ENABLED = false
local ESP = {}
local AIM_SMOOTHNESS = 0

-- Esp settings
local Settings = {
    Box = true,
    Name = true,
    Outline = true
}

-- Aimbot
local AimCircle = Drawing.new("Circle")
AimCircle.Radius = AIM_RADIUS
AimCircle.Color = Color3.fromRGB(255, 0, 0)
AimCircle.Thickness = 2
AimCircle.NumSides = 64
AimCircle.Filled = false
AimCircle.Visible = false

-- Status
local StatusText = Drawing.new("Text")
StatusText.Size = 18
StatusText.Color = Color3.fromRGB(255, 0, 0)
StatusText.Outline = true
StatusText.Center = false
StatusText.Font = 2
StatusText.Visible = false

-- ESP create
local function CreateESP(player)
	if player == LocalPlayer then return end

	local Box = Drawing.new("Square")
	Box.Thickness = 1
	Box.Color = Color3.fromRGB(255, 0, 0)
	Box.Filled = false
	Box.Visible = false

	local Line = Drawing.new("Line")
	Line.Thickness = 1
	Line.Color = Color3.fromRGB(255, 0, 0)
	Line.Visible = false

	local Name = Drawing.new("Text")
	Name.Size = 16
	Name.Center = true
	Name.Outline = true
	Name.Color = Color3.fromRGB(255, 0, 0)
	Name.Font = 2
	Name.Visible = false

	ESP[player] = {Box = Box, Line = Line, Name = Name}
end

local function RemoveESP(player)
	if ESP[player] then
		ESP[player].Box:Remove()
		ESP[player].Line:Remove()
		ESP[player].Name:Remove()
		ESP[player] = nil
	end
end

for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

local function GetClosestTarget()
	local closestPlayer = nil
	local closestDist = AIM_RADIUS

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(AIM_PART) then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				local part = player.Character[AIM_PART]
				local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
				if onScreen then
					local dist = (Vector2.new(screenPos.X, screenPos.Y) - (Camera.ViewportSize / 2)).Magnitude
					if dist < closestDist then
						closestDist = dist
						closestPlayer = player
					end
				end
			end
		end
	end

	return closestPlayer
end

RunService.RenderStepped:Connect(function(dt)
	if ESP_ENABLED then
		for player, obj in pairs(ESP) do
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")

			if character and humanoid and humanoid.Health > 0 then
				local parts = {}
				for _, part in ipairs(character:GetDescendants()) do
					if part:IsA("BasePart") then
						table.insert(parts, part)
					end
				end

				if #parts > 0 then
					local minVec = parts[1].Position
					local maxVec = parts[1].Position

					for _, part in ipairs(parts) do
						minVec = Vector3.new(
							math.min(minVec.X, part.Position.X),
							math.min(minVec.Y, part.Position.Y),
							math.min(minVec.Z, part.Position.Z)
						)
						maxVec = Vector3.new(
							math.max(maxVec.X, part.Position.X),
							math.max(maxVec.Y, part.Position.Y),
							math.max(maxVec.Z, part.Position.Z)
						)
					end

					local center = (minVec + maxVec) / 2
					local top = Vector3.new(center.X, maxVec.Y, center.Z)
					local bottom = Vector3.new(center.X, minVec.Y, center.Z)

					local top2D, onScreen1 = Camera:WorldToViewportPoint(top)
					local bottom2D, onScreen2 = Camera:WorldToViewportPoint(bottom)

					if onScreen1 and onScreen2 then
						local height = math.abs(top2D.Y - bottom2D.Y)
						local width = height / 2
						local x = bottom2D.X - width / 2
						local y = top2D.Y

						obj.Box.Size = Vector2.new(width, height)
						obj.Box.Position = Vector2.new(x, y)
						obj.Box.Visible = Settings.Box

						obj.Name.Text = player.Name
						obj.Name.Position = Vector2.new(x + width / 2, y - 15)
						obj.Name.Visible = Settings.Name

						obj.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
						obj.Line.To = Vector2.new(x + width / 2, y + height)
						obj.Line.Visible = Settings.Outline
					else
						obj.Box.Visible = false
						obj.Name.Visible = false
						obj.Line.Visible = false
					end
				end
			else
				obj.Box.Visible = false
				obj.Name.Visible = false
				obj.Line.Visible = false
			end
		end
	end

	-- Aimbot
	if AIMBOT_ENABLED then
		AimCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
		local target = GetClosestTarget()
		if target and target.Character and target.Character:FindFirstChild(AIM_PART) then
			local pos = target.Character[AIM_PART].Position
			local newCFrame = CFrame.new(Camera.CFrame.Position, pos)
			if AIM_SMOOTHNESS > 0 then
				Camera.CFrame = Camera.CFrame:Lerp(newCFrame, dt / (AIM_SMOOTHNESS * 0.05))
			else
				Camera.CFrame = newCFrame
			end
		end
	end

	local text = ""
	if ESP_ENABLED and AIMBOT_ENABLED then text = "ESP & Aimbot ON"
	elseif ESP_ENABLED then text = "ESP ON"
	elseif AIMBOT_ENABLED then text = "Aimbot ON" end

	StatusText.Text = text
	StatusText.Position = Vector2.new(Camera.ViewportSize.X - 160, 10)
	StatusText.Visible = text ~= ""
end)

-- ReGui UI
local window = ReGui:TabsWindow({
	Title = "Camera cheat",
	Size = UDim2.fromOffset(300, 250)
})

local espTab = window:CreateTab({Name="Esp"})
espTab:Checkbox({
	Value = false,
	Label = "Enable ESP",
	Callback = function(_, Value)
		ESP_ENABLED = Value
	end
})
espTab:Checkbox({
	Value = false,
	Label = "Box",
	Callback = function(_, Value)
		Settings.Box = Value
	end
})
espTab:Checkbox({
	Value = false,
	Label = "Name",
	Callback = function(_, Value)
		Settings.Name = Value
	end
})
espTab:Checkbox({
	Value = false,
	Label = "Outline",
	Callback = function(_, Value)
		Settings.Outline = Value
	end
})

local aimbotTab = window:CreateTab({Name="Aimbot"})

local aimcheck = aimbotTab:Checkbox({
	Value = false,
	Label = "Aimbot",
	Callback = function(_, Value)
		AIMBOT_ENABLED = Value
		AimCircle.Visible = Value
	end
})
aimbotTab:DragInt({
	Minimum = 0,
	Maximum = 10,
	Label = "Tween",
	Callback = function(_, value)
		AIM_SMOOTHNESS = value
	end
})

aimbotTab:Keybind({	
	Label = "Toggle aimbot",
	Value = Enum.KeyCode.E,
	Callback = function(self, KeyId)
		aimcheck:Toggle()
	end
})
