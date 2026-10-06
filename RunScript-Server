-- use this in serverscriptservice
-- you dont have to necessarily use this, the runscript-client will run without this
-- its for checks and stuff

  local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local sprintEvent = ReplicatedStorage:WaitForChild("SprintEvent", 10)
	if not sprintEvent then
		warn("[SprintHandler] SprintEvent not found in ReplicatedStorage, sprinting is disabled")
		return
	end

	local WALK_SPEED = 16
	local RUN_SPEED = 28

	local function onSprint(player, isSprinting)
		if typeof(isSprinting) ~= "boolean" then return end

		local character = player.Character
		if not character then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return end

		humanoid.WalkSpeed = isSprinting and RUN_SPEED or WALK_SPEED
	end

	sprintEvent.OnServerEvent:Connect(onSprint)

	local function resetSpeed(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = WALK_SPEED
		end
	end

	local function onPlayerAdded(player)
		player.CharacterAdded:Connect(resetSpeed)
		if player.Character then
			resetSpeed(player.Character)
		end
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
