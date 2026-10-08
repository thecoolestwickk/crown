-- define paths
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DialogueNetwork = ReplicatedStorage:WaitForChild("CrownEvents"):WaitForChild("DialogueNetwork")

local playerSelectionSignal = {}

-- function to run a dialogue tree in an npc's script
local function runDialogueTree(player, npcName, npcModel, uniqueTree)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.WalkSpeed = 0 end -- freeze player while talking to an npc

	local currentNode = uniqueTree

	while currentNode do
		DialogueNetwork:FireClient(player, npcName, currentNode.Text, npcModel, currentNode.Choices)

		playerSelectionSignal[player] = nil
		repeat task.wait() until playerSelectionSignal[player] ~= nil
		local choiceIndex = playerSelectionSignal[player]

		if choiceIndex > 0 and currentNode.Choices and currentNode.Choices[choiceIndex] then
			local chosenText = currentNode.Choices[choiceIndex]
			if currentNode.Next and currentNode.Next[chosenText] then
				currentNode = currentNode.Next[chosenText]
			else
				currentNode = nil
			end
		else
			if currentNode.Next and currentNode.Next.Text then
				currentNode = currentNode.Next
			else
				currentNode = nil
			end
		end
	end

	if humanoid then humanoid.WalkSpeed = 16 end -- restore movement speed
end

DialogueNetwork.OnServerEvent:Connect(function(player, choiceIndex)
	playerSelectionSignal[player] = choiceIndex
end)

-- global function to call a dialogue tree from any npc
_G.TriggerNpcDialogue = function(player, npcName, npcModel, uniqueTree)
	runDialogueTree(player, npcName, npcModel, uniqueTree)
end
