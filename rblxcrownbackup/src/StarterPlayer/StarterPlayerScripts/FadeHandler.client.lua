local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RequestFade = ReplicatedStorage:WaitForChild("CrownEvents"):WaitForChild("RequestFade")
local FadeComplete = ReplicatedStorage:WaitForChild("CrownEvents"):WaitForChild("FadeComplete")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local STEP_SIZE = 0.2
local HOLD_DURATION_PER_STEP = 0.08

RequestFade.OnClientEvent:Connect(function()
	
	-- freeze player during transition
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.WalkSpeed = 0 end
	end

	-- generate the gui and make it cover player ui
	local fadeGui = Instance.new("ScreenGui")
	fadeGui.Name = "TeleportFade"
	fadeGui.IgnoreGuiInset = true
	fadeGui.ResetOnSpawn = false
	fadeGui.Parent = playerGui

	-- create and define frame and its variables
	local fadeFrame = Instance.new("Frame")
	fadeFrame.Size = UDim2.new(1, 0, 1, 0)
	fadeFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	fadeFrame.BackgroundTransparency = 1
	fadeFrame.BorderSizePixel = 0
	fadeFrame.Parent = fadeGui
	
	-- loop through and make the frame more transparent each time
	while fadeFrame.BackgroundTransparency > 0 do
		fadeFrame.BackgroundTransparency -= STEP_SIZE
		task.wait(HOLD_DURATION_PER_STEP)
		if fadeFrame.BackgroundTransparency == 0 then break end
	end

	-- tell server the fade is completed
	FadeComplete:FireServer()
	task.wait(4)
	fadeGui:Destroy()
	player.Character.Humanoid.WalkSpeed = 16
end)
