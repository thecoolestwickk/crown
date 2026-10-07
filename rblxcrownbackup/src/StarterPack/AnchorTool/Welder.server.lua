local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local anchorModel = tool:WaitForChild("AnchorModel")

for _, part in ipairs(anchorModel:GetDescendants()) do
	if part:IsA("BasePart") and part ~= handle then
		part.CanCollide = false
		part.Massless = true

		local weld = part:FindFirstChild("ModelWeld") or Instance.new("WeldConstraint")
		weld.Name = "ModelWeld"
		weld.Part0 = handle
		weld.Part1 = part
		weld.Parent = part

		part.Anchored = false
	end
end
