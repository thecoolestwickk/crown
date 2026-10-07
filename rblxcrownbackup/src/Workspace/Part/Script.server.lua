portal = script.Parent

portal.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = game.Players:GetPlayerFromCharacter(character)

	if player and _G.BadgeInventoryHandler then
		-- Award the crown badge (and instantly move the Crown tool to their backpack!)
		_G.BadgeInventoryHandler.AwardBadgeAndItem(player, 4172131274029184)
	end
end)
