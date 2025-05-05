local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SETTINGS_FILE = "egg_autocollect_settings.txt"
local running = false

-- Load saved toggle state
pcall(function()
	local state = readfile(SETTINGS_FILE)
	running = (state == "true")
end)

local function SaveSetting(state)
	pcall(function()
		writefile(SETTINGS_FILE, tostring(state))
	end)
end

-- GUI
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "EggCollectorGui"
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 200, 0, 100)
Frame.Position = UDim2.new(0, 50, 0, 50)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.Active = true
Frame.Draggable = true
Frame.Visible = true

local ToggleButton = Instance.new("TextButton", Frame)
ToggleButton.Size = UDim2.new(1, -10, 0, 30)
ToggleButton.Position = UDim2.new(0, 5, 0, 5)
ToggleButton.Text = "Auto Collect: " .. (running and "ON" or "OFF")
ToggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
ToggleButton.TextColor3 = Color3.new(1, 1, 1)

local MinimizeButton = Instance.new("TextButton", Frame)
MinimizeButton.Size = UDim2.new(1, -10, 0, 20)
MinimizeButton.Position = UDim2.new(0, 5, 0, 40)
MinimizeButton.Text = "Minimize"
MinimizeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
MinimizeButton.TextColor3 = Color3.new(1, 1, 1)

local minimized = false

MinimizeButton.MouseButton1Click:Connect(function()
	minimized = not minimized
	ToggleButton.Visible = not minimized
	MinimizeButton.Text = minimized and "Maximize" or "Minimize"
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if not gpe and input.KeyCode == Enum.KeyCode.M then
		Frame.Visible = not Frame.Visible
	end
end)

local function StartCollect()
	task.spawn(function()
		local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local HRP = Character:WaitForChild("HumanoidRootPart")

		for _, part in pairs(workspace:GetDescendants()) do
			if not running then break end

			if part:IsA("MeshPart") and part.Name:lower():match("^egg%s*%d*$") then
				local prompt = part:FindFirstChildOfClass("ProximityPrompt")
				if prompt and prompt.Enabled then
					HRP.CFrame = part.CFrame + Vector3.new(0, 3, 0)
					task.wait(0.3)
					fireproximityprompt(prompt)
					repeat task.wait(0.1) until not prompt.Enabled or not prompt:IsDescendantOf(game)
					task.wait(0.3)
				end
			end
		end

		for _, v in pairs(ReplicatedStorage:WaitForChild("d8L"):GetChildren()) do
			if v:IsA("RemoteEvent") then
				pcall(function()
					v:FireServer()
				end)
			end
		end

		running = false
		ToggleButton.Text = "Auto Collect: OFF"
		SaveSetting(running)
	end)
end

ToggleButton.MouseButton1Click:Connect(function()
	running = not running
	SaveSetting(running)
	ToggleButton.Text = "Auto Collect: " .. (running and "ON" or "OFF")
	if running then
		StartCollect()
	end
end)

-- Auto-start if last session was ON
if running then
	StartCollect()
end
