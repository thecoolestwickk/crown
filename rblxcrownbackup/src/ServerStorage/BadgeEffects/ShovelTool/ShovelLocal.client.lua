local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local tool = script.Parent
local shovelDiggedEvent = tool:WaitForChild("ShovelDigged")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local tor = character:WaitForChild("Torso", 5) or character:WaitForChild("UpperTorso", 5)

local isDigging = false
local TWEEN_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true) -- Auto-reverses

tool.Activated:Connect(function()
	if isDigging then return end
	isDigging = true

	-- Refresh character elements dynamically
	character = player.Character
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then isDigging = false return end

	-- Locate the arm joint structure (Supports both classic R6 and modern R15)
	local rightShoulder = character:FindFirstChild("Right Shoulder", true) or character:FindFirstChild("RightShoulder", true)

	if rightShoulder then
		local originalC0 = rightShoulder.C0
		-- Rotates hand downward towards the ground plane
		local digAngle = CFrame.Angles(0, 0, math.rad(-45)) 

		local digTween = TweenService:Create(rightShoulder, TWEEN_INFO, {C0 = originalC0 * digAngle})
		digTween:Play()

		-- Synchronize server transaction right at the peak impact of the swing
		task.wait(0.18)
		shovelDiggedEvent:FireServer()

		digTween.Completed:Wait()
		rightShoulder.C0 = originalC0
	else
		-- Fallback fire if player joints aren't loaded cleanly
		shovelDiggedEvent:FireServer()
	end

	task.wait(0.2) -- Small post-dig cooldown
	isDigging = false
end)
