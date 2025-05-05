local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SETTINGS_FILE = "egg_autocollect_settings.txt"
local FILTER_FILE = "egg_filter.txt"

local running = pcall(function() return readfile(SETTINGS_FILE) == "true" end) and readfile(SETTINGS_FILE) == "true"
local eggFilter = pcall(function() return readfile(FILTER_FILE) end) and readfile(FILTER_FILE) or "All"

-- Load and wait for Rayfield
local Rayfield = nil
pcall(function()
	Rayfield = loadstring(game:HttpGet('https://sirius.menu/sirius'))()
end)
repeat task.wait() until Rayfield and Rayfield.CreateWindow

local Window = Rayfield:CreateWindow({
	Name = "Egg Collector",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = nil,
		FileName = "EggSettings"
	}
})

local MainTab = Window:CreateTab("Main")
local Toggle, Dropdown

local function SaveSetting(state)
	pcall(function()
		writefile(SETTINGS_FILE, tostring(state))
	end)
end

local function SaveFilter(value)
	pcall(function()
		writefile(FILTER_FILE, value)
	end)
end

local function IsMatchingEgg(part)
	if eggFilter == "All" then return true end
	local folder = part:FindFirstAncestorWhichIsA("Folder")
	return folder and folder.Name:lower():find(eggFilter:lower())
end

local function StartCollect()
	task.spawn(function()
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

		if running then
			for _, v in pairs(ReplicatedStorage:WaitForChild("d8L"):GetChildren()) do
				if v:IsA("RemoteEvent") then
					pcall(function()
						v:FireServer()
					end)
				end
			end
		end

		running = false
		SaveSetting(false)
		if Toggle then Toggle:Set(false) end
	end)
end

Toggle = MainTab:CreateToggle({
	Name = "Auto Collect + Reconnect",
	CurrentValue = running,
	Flag = "AutoCollect",
	Callback = function(Value)
		running = Value
		SaveSetting(Value)
		if Value then StartCollect() end
	end,
})

Dropdown = MainTab:CreateDropdown({
	Name = "Egg Type Filter",
	Options = { "All", "common", "rare", "legendary", "event" },
	CurrentOption = eggFilter,
	Flag = "EggFilter",
	Callback = function(Option)
		eggFilter = Option
		SaveFilter(Option)
	end,
})

if running then StartCollect() end
