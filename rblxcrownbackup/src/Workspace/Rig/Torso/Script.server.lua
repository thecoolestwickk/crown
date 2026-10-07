local Part = script.Parent
local npcModel = script.Parent.Parent 

-- FIX 1: Safely locate the ClickDetector object inside the part container
local clickDetector = Part:WaitForChild("ClickDetector")

local NPC_NAME = "wickk"
local debounce = false

-- ============================================================================
-- 📑 HIGHLY READABLE, UNIQUE DIALOGUE TREE FORMATTING
-- ============================================================================
local MyUniqueDialogueTree = {
	Text = "wsg bro",
	Choices = {"nothin much twin", "yup"},
	Next = {
		["yup"] = {
			Text = "??? ok i guess",
			Choices = {} -- Table empty = ends dialogue
		},
		["nothin much twin"] = {
			Text = "lmao ok",
			Choices = {"yeah"},
			Next = {
				["yeah"] = {
					Text = "ok this is awkard;; goodbye",
					Choices = {}
				}
			}
		}
	}
}

-- ============================================================================
-- RUNTIME TRIGGER BINDING (Switched from Touched to MouseClick)
-- ============================================================================
-- FIX 2: MouseClick events automatically provide the clicking Player object directly!
clickDetector.MouseClick:Connect(function(player)
	if player and not debounce then
		debounce = true

		-- Pass your unique tree layout dictionary configuration down to the runner engine
		_G.TriggerNpcDialogue(player, NPC_NAME, npcModel, MyUniqueDialogueTree)

		task.wait(1) -- Reduced cooldown for smoother click reactivity
		debounce = false
	end
end)
