local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local SETTINGS_FILE = "egg_autocollect_settings.txt"
local running = pcall(function() return readfile(SETTINGS_FILE) == "true" end) and readfile(SETTINGS_FILE) == "true"
local function SaveSetting(v) pcall(function() writefile(SETTINGS_FILE, tostring(v)) end) end

local Toggle
local StatusLabel

local function CollectEggs()
	local HRP = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	HRP = HRP:WaitForChild("HumanoidRootPart")

	while true do
		local found = false
		for _, part in pairs(workspace:GetDescendants()) do
			if part:IsA("MeshPart") and part.Name:lower():match("^egg%s*%d*$") then
				local prompt
				for _, d in pairs(part:GetDescendants()) do
					if d:IsA("ProximityPrompt") then
						prompt = d
						break
					end
				end
				if prompt and prompt.Enabled then
					found = true
					HRP.CFrame = part.CFrame + Vector3.new(0, 3, 0)
					task.wait(0.3)
					fireproximityprompt(prompt)
					repeat task.wait(0.1) until not prompt.Enabled or not prompt:IsDescendantOf(game)
					task.wait(0.3)
				end
			end
		end
		if not found then break end
	end
end

local function TeleportAndCollect()
	local zones = {
		"LOBBY", "NINJA_VILLAGE", "GREEN_PLANET", "SHIBUYA_STATION",
		"TITANS_CITY", "DIMENSIONAL_FORTRESS", "CANDY_ISLAND", "SOLO_CITY", "EMINENCE_LOOKOUT"
	}
	for _, zone in ipairs(zones) do
		if not running then break end
		StatusLabel.Text = "Status: Teleporting to " .. zone
		local args = {zone}
		local tp = ReplicatedStorage:WaitForChild("d8L"):WaitForChild("781d4ddc-e915-4b41-b2ff-a51cec5a69be")
		tp:FireServer(unpack(args))
		task.wait(5)
		StatusLabel.Text = "Status: Collecting Eggs..."
		CollectEggs()
	end

	if running then
		StatusLabel.Text = "Status: Reconnecting..."
		for _, v in pairs(ReplicatedStorage:WaitForChild("d8L"):GetChildren()) do
			if v:IsA("RemoteEvent") then
				pcall(function() v:FireServer() end)
			end
		end
	end

	StatusLabel.Text = "Status: Done"
	Toggle.Text = "Auto Collect: FINISHED"
end

-- GUI Setup
local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
gui.Name = "EggCollectorUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 280, 0, 150)
frame.Position = UDim2.new(0, 50, 0, 50)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", frame).Color = Color3.fromRGB(0, 255, 0)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -30, 0, 30)
title.Position = UDim2.new(0, 10, 0, 5)
title.Text = "🟢 Egg Collector"
title.TextColor3 = Color3.fromRGB(0, 255, 0)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left

local close = Instance.new("TextButton", frame)
close.Size = UDim2.new(0, 20, 0, 20)
close.Position = UDim2.new(1, -25, 0, 5)
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255, 0, 0)
close.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
close.Font = Enum.Font.GothamBold
close.TextSize = 14
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 5)
close.MouseButton1Click:Connect(function() gui.Enabled = false end)

Toggle = Instance.new("TextButton", frame)
Toggle.Size = UDim2.new(1, -40, 0, 30)
Toggle.Position = UDim2.new(0, 20, 0, 40)
Toggle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Toggle.TextColor3 = Color3.new(1, 1, 1)
Toggle.Text = running and "Auto Collect: ON" or "Auto Collect: OFF"
Toggle.Font = Enum.Font.Gotham
Toggle.TextSize = 14
Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0, 6)
Toggle.MouseButton1Click:Connect(function()
	running = not running
	Toggle.Text = running and "Auto Collect: ON" or "Auto Collect: OFF"
	SaveSetting(running)
	if running then TeleportAndCollect() end
end)

StatusLabel = Instance.new("TextLabel", frame)
StatusLabel.Size = UDim2.new(1, -40, 0, 20)
StatusLabel.Position = UDim2.new(0, 20, 0, 80)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 14
StatusLabel.Text = "Status: Idle"
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

local note = Instance.new("TextLabel", frame)
note.Size = UDim2.new(1, -40, 0, 30)
note.Position = UDim2.new(0, 20, 0, 100)
note.Text = "M = toggle GUI  |  Reconnect finishes Infinite Tower"
note.TextColor3 = Color3.fromRGB(0, 255, 0)
note.BackgroundTransparency = 1
note.Font = Enum.Font.Gotham
note.TextSize = 12
note.TextWrapped = true
note.TextXAlignment = Enum.TextXAlignment.Left

UserInputService.InputBegan:Connect(function(input, gpe)
	if not gpe and input.KeyCode == Enum.KeyCode.M then
		gui.Enabled = not gui.Enabled
	end
end)

if running then TeleportAndCollect() end
