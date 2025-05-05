local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local SETTINGS_FILE = "egg_autocollect_settings.txt"
local FILTER_FILE = "egg_filter.txt"

local running = pcall(function() return readfile(SETTINGS_FILE) == "true" end) and readfile(SETTINGS_FILE) == "true"
local eggFilter = pcall(function() return readfile(FILTER_FILE) end) and readfile(FILTER_FILE) or "All"

local function SaveSetting(value) pcall(function() writefile(SETTINGS_FILE, tostring(value)) end) end
local function SaveFilter(value) pcall(function() writefile(FILTER_FILE, value) end) end

local Toggle
local function IsMatchingEgg(part)
	if eggFilter == "All" then return true end
	local folder = part:FindFirstAncestorWhichIsA("Folder")
	return folder and folder.Name:lower():find(eggFilter:lower())
end

local function CollectEggs()
	local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local HRP = Character:WaitForChild("HumanoidRootPart")

	local eggs = {}
	for _, part in pairs(workspace:GetDescendants()) do
		if part:IsA("MeshPart") and part.Name:lower():match("^egg%s*%d*$") and IsMatchingEgg(part) then
			local prompt = part:FindFirstChildOfClass("ProximityPrompt")
			if prompt and prompt.Enabled then
				table.insert(eggs, {Part = part, Prompt = prompt})
			end
		end
	end

	for _, data in ipairs(eggs) do
		if not running then break end
		local part, prompt = data.Part, data.Prompt
		HRP.CFrame = part.CFrame + Vector3.new(0, 3, 0)
		task.wait(0.3)
		fireproximityprompt(prompt)
		repeat task.wait(0.1) until not prompt.Enabled or not prompt:IsDescendantOf(game)
		task.wait(0.3)
	end
end

local function TeleportAndCollect()
	local zones = {
		"LOBBY", "NINJA_VILLAGE", "GREEN_PLANET", "SHIBUYA_STATION",
		"TITANS_CITY", "DIMENSIONAL_FORTRESS", "CANDY_ISLAND", "SOLO_CITY", "EMINENCE_LOOKOUT"
	}

	for _, zone in ipairs(zones) do
		if not running then break end
		local args = {zone}
		local tp = ReplicatedStorage:WaitForChild("d8L"):WaitForChild("781d4ddc-e915-4b41-b2ff-a51cec5a69be")
		tp:FireServer(unpack(args))
		task.wait(5) -- wait for map to load
		CollectEggs()
	end

	if running then
		for _, v in pairs(ReplicatedStorage:WaitForChild("d8L"):GetChildren()) do
			if v:IsA("RemoteEvent") then
				pcall(function() v:FireServer() end)
			end
		end
	end

	Toggle.Text = "Auto Collect: FINISHED"
end

-- GUI Setup
local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
gui.Name = "EggCollectorUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 240, 0, 140)
frame.Position = UDim2.new(0, 50, 0, 50)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.Active = true
frame.Draggable = true

Toggle = Instance.new("TextButton", frame)
Toggle.Size = UDim2.new(1, -20, 0, 30)
Toggle.Position = UDim2.new(0, 10, 0, 10)
Toggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
Toggle.TextColor3 = Color3.new(1, 1, 1)
Toggle.Text = running and "Auto Collect: ON" or "Auto Collect: OFF"

local Label = Instance.new("TextLabel", frame)
Label.Size = UDim2.new(1, -20, 0, 20)
Label.Position = UDim2.new(0, 10, 0, 50)
Label.BackgroundTransparency = 1
Label.TextColor3 = Color3.new(1, 1, 1)
Label.Text = "Egg Type Filter:"

local Dropdown = Instance.new("TextButton", frame)
Dropdown.Size = UDim2.new(1, -20, 0, 25)
Dropdown.Position = UDim2.new(0, 10, 0, 75)
Dropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Dropdown.TextColor3 = Color3.new(1, 1, 1)
Dropdown.Text = "Selected: " .. eggFilter

local Options = { "All", "common", "rare", "legendary", "event" }
local showingOptions = false
local optionButtons = {}

Dropdown.MouseButton1Click:Connect(function()
	if showingOptions then
		for _, btn in ipairs(optionButtons) do btn:Destroy() end
		optionButtons = {}
		showingOptions = false
	else
		for i, option in ipairs(Options) do
			local btn = Instance.new("TextButton", frame)
			btn.Size = UDim2.new(1, -20, 0, 20)
			btn.Position = UDim2.new(0, 10, 0, 105 + (i - 1) * 22)
			btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			btn.TextColor3 = Color3.new(1, 1, 1)
			btn.Text = option
			btn.MouseButton1Click:Connect(function()
				eggFilter = option
				Dropdown.Text = "Selected: " .. option
				SaveFilter(option)
				for _, b in ipairs(optionButtons) do b:Destroy() end
				optionButtons = {}
				showingOptions = false
			end)
			table.insert(optionButtons, btn)
		end
		showingOptions = true
	end
end)

Toggle.MouseButton1Click:Connect(function()
	running = not running
	Toggle.Text = running and "Auto Collect: ON" or "Auto Collect: OFF"
	SaveSetting(running)
	if running then TeleportAndCollect() end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if not gpe and input.KeyCode == Enum.KeyCode.M then
		gui.Enabled = not gui.Enabled
	end
end)

if running then TeleportAndCollect() end
