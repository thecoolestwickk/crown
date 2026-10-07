local RunService = game:GetService("RunService")
local tool = script.Parent
local watchActivatedEvent = tool:WaitForChild("WatchActivated")
local watchModel = tool:WaitForChild("WatchModel")

local hourHandModel = watchModel:WaitForChild("HourHandModel")
local minuteHandModel = watchModel:WaitForChild("MinuteHandModel")
local centerPin = watchModel:WaitForChild("CenterPin")

local COOLDOWN_DURATION = 3
local BOOST_DURATION = 15
local SPIN_CLOCKWISE = false -- Set to true to reverse direction

local lastUsedTime = 0
local isActive = false

local hourAngle = 0
local minuteAngle = 0

local hourRoot = hourHandModel.PrimaryPart or hourHandModel:FindFirstChildWhichIsA("BasePart")
local minuteRoot = minuteHandModel.PrimaryPart or minuteHandModel:FindFirstChildWhichIsA("BasePart")

local hourJoint = hourRoot:WaitForChild("HandJoint")
local minuteJoint = minuteRoot:WaitForChild("HandJoint")

tool.Activated:Connect(function()
	local currentTime = os.clock()

	if isActive or (currentTime - lastUsedTime < COOLDOWN_DURATION) then
		return
	end

	isActive = true
	lastUsedTime = currentTime
	watchActivatedEvent:FireServer()

	if _G.ShowLocalHint then
		_G.ShowLocalHint("time is of the essence! your speed has been doubled for 15 seconds.", {
			duration = 3,
			textcolor = Color3.fromRGB(255, 202, 79),
			wavy = true
		})
	end
	
	
	task.delay(BOOST_DURATION - 2.9, function()
		isActive = false
	end)
end)

RunService.RenderStepped:Connect(function(deltaTime)
	if not tool.Parent:IsA("Backpack") and tool.Parent:FindFirstChild("Humanoid") then
		if isActive then
			local hourStep = deltaTime * 120
			local minuteStep = deltaTime * 720

			if SPIN_CLOCKWISE then
				hourAngle = (hourAngle + hourStep) % 360
				minuteAngle = (minuteAngle + minuteStep) % 360
			else
				hourAngle = (hourAngle - hourStep) % 360
				minuteAngle = (minuteAngle - minuteStep) % 360
			end
		end

		-- Rotates perfectly around the CenterPin axis
		hourJoint.C0 = CFrame.Angles(math.rad(hourAngle), 0, 0)
		minuteJoint.C0 = CFrame.Angles(math.rad(minuteAngle), 0, 0)
	end
end)

tool.Unequipped:Connect(function()
	isActive = false
end)

