local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local screenGui = script.Parent
local container = screenGui:WaitForChild("AbilityContainer")

local AbilityFired = ReplicatedStorage:WaitForChild("CrownEvents"):WaitForChild("AbilityFired")
local activeMoves = {}

-- DYNAMIC SCANNER: Finds whatever you named your labels without freezing [1]
local Ability_Labels = {}
local ToolName_Label = nil

local function mapLayoutObjects()
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("TextLabel") then
			local lowerName = string.lower(child.Name)
			if string.find(lowerName, "tool") then
				ToolName_Label = child
			elseif string.find(lowerName, "1") or string.find(lowerName, "one") then
				Ability_Labels["1"] = child
			elseif string.find(lowerName, "2") or string.find(lowerName, "two") then
				Ability_Labels["2"] = child
			elseif string.find(lowerName, "3") or string.find(lowerName, "three") then
				Ability_Labels["3"] = child
			elseif string.find(lowerName, "4") or string.find(lowerName, "four") then
				Ability_Labels["4"] = child
			end
		end
	end
end

mapLayoutObjects()

local Cooldown_Bars = {}

local function injectBarsNatively()
	for slotId, textLabel in pairs(Ability_Labels) do
		if Cooldown_Bars[slotId] then continue end

		textLabel.BackgroundTransparency = 0
		textLabel.TextXAlignment = Enum.TextXAlignment.Center

		local bar = Instance.new("Frame")
		bar.Name = "DynamicCooldownBar"
		bar.Size = UDim2.new(1, 0, 0, 5)
		bar.Position = UDim2.new(0, 0, 1, -5)
		bar.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
		bar.BorderSizePixel = 0
		bar.Visible = false
		bar.ZIndex = textLabel.ZIndex + 1
		bar.Parent = textLabel

		Cooldown_Bars[slotId] = bar
	end
end

injectBarsNatively()

-- Securely clear visibility settings at runtime startup
for _, textLabel in pairs(Ability_Labels) do
	textLabel.Visible = false
end
if ToolName_Label then
	ToolName_Label.Visible = false
end

AbilityFired.OnClientEvent:Connect(function(actionType, p1, p2)

	if actionType == "Load" then
		activeMoves = p1

		if ToolName_Label then
			local foundToolName = nil
			for _, data in pairs(activeMoves) do
				if data.ToolIdentity then foundToolName = data.ToolIdentity break end
			end

			if foundToolName then
				ToolName_Label.Text = foundToolName
				ToolName_Label.Visible = true
			else
				ToolName_Label.Visible = false
			end
		end

		for id, textLabel in pairs(Ability_Labels) do
			local moveData = activeMoves[tstring(id)] or activeMoves[id]

			if moveData then
				textLabel.Text = "[" .. tostring(moveData.Key) .. "] " .. tostring(moveData.Name)
				textLabel.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
				textLabel.Visible = true
			else
				textLabel.Visible = false
			end
		end

	elseif actionType == "Clear" then
		for id, textLabel in pairs(Ability_Labels) do 
			textLabel.Visible = false 
			textLabel.Text = "Ability" .. id 
		end
		activeMoves = {}
		if ToolName_Label then ToolName_Label.Visible = false end

	elseif actionType == "CD" then
		local slotId = tostring(p1)
		local textLabel = Ability_Labels[slotId]
		local bar = Cooldown_Bars[slotId]
		if not textLabel or not textLabel.Visible or not bar then return end

		local moveData = activeMoves[slotId]
		if not moveData then return end

		bar.Size = UDim2.new(1, 0, 0, 5)
		bar.Visible = true

		local tween = TweenService:Create(bar, TweenInfo.new(moveData.Cooldown, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 5)})
		tween:Play()

		tween.Completed:Connect(function()
			bar.Visible = false
			local flash = TweenService:Create(textLabel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
			flash:Play()
			flash.Completed:Connect(function()
				TweenService:Create(textLabel, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 25, 35)}):Play()
			end)
		end)

	elseif actionType == "Fail" then
		local slotId = tostring(p1)
		local textLabel = Ability_Labels[slotId]
		if textLabel and textLabel.Visible then
			local flash = TweenService:Create(textLabel, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(185, 35, 35)})
			flash:Play()
			flash.Completed:Connect(function()
				TweenService:Create(textLabel, TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(20, 25, 35)}):Play()
			end)
		end
	end
end)

function tstring(val) return tostring(val) end
