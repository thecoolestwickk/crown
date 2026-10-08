-- welds parts together and creates joints for the center hand animation
local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local watchModel = tool:WaitForChild("WatchModel")

local hourHandModel = watchModel:WaitForChild("HourHandModel")
local minuteHandModel = watchModel:WaitForChild("MinuteHandModel")
local centerPin = watchModel:WaitForChild("CenterPin")

local hourRoot = hourHandModel.PrimaryPart or hourHandModel:FindFirstChildWhichIsA("BasePart")
local minuteRoot = minuteHandModel.PrimaryPart or minuteHandModel:FindFirstChildWhichIsA("BasePart")

for _, part in ipairs(tool:GetDescendants()) do
	if part:IsA("BasePart") then
		part.Anchored = false
		part.CanCollide = false

		if part:FindFirstAncestor("HourHandModel") then
			if part ~= hourRoot and hourRoot then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = hourRoot
				weld.Part1 = part
				weld.Parent = hourRoot
			elseif part == hourRoot then
				local joint = Instance.new("Weld")
				joint.Name = "HandJoint"
				joint.Part0 = centerPin
				joint.Part1 = hourRoot
				joint.C0 = CFrame.new() -- Kept clean at center for rotation
				joint.C1 = hourRoot.CFrame:Inverse() * centerPin.CFrame -- Offset moved here
				joint.Parent = hourRoot
			end
		elseif part:FindFirstAncestor("MinuteHandModel") then
			if part ~= minuteRoot and minuteRoot then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = minuteRoot
				weld.Part1 = part
				weld.Parent = minuteRoot
			elseif part == minuteRoot then
				local joint = Instance.new("Weld")
				joint.Name = "HandJoint"
				joint.Part0 = centerPin
				joint.Part1 = minuteRoot
				joint.C0 = CFrame.new() -- Kept clean at center for rotation
				joint.C1 = minuteRoot.CFrame:Inverse() * centerPin.CFrame -- Offset moved here
				joint.Parent = minuteRoot
			end
		else
			if part ~= handle then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = handle
				weld.Part1 = part
				weld.Parent = handle
			end
		end
	end
end
