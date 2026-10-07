local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CrownEvents = ReplicatedStorage:WaitForChild("CrownEvents")
local AbilityFired = CrownEvents:WaitForChild("AbilityFired")

AbilityFired.OnServerEvent:Connect(function(player, actionType, payload)
	if actionType == "EquipLoadout" then
		AbilityFired:FireClient(player, "Load", payload)
	elseif actionType == "ClearLoadout" then
		AbilityFired:FireClient(player, "Clear")
	elseif actionType == "TriggerCooldown" then
		AbilityFired:FireClient(player, "CD", payload)
	elseif actionType == "TriggerFailFlash" then
		AbilityFired:FireClient(player, "Fail", payload)
	end
end)
