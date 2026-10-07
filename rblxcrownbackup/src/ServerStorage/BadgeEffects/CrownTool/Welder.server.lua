local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local crownModel = tool:WaitForChild("CrownModel")

-- Weld all child components of the crown to the tool handle automatically
for _, part in ipairs(crownModel:GetDescendants()) do
	if part:IsA("BasePart") then
		part.Anchored = false
		part.CanCollide = false

		-- Create a structural weld constraint
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = part
		weld.Parent = handle
	end
end
