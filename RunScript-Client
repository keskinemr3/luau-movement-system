-- use this in starterplayerscripts
-- this is the client side, server side is mainly checks and stuff.

  local UserInputService = game:GetService("UserInputService")
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local player = Players.LocalPlayer

	local sprintEvent = ReplicatedStorage:WaitForChild("SprintEvent", 10)
	if not sprintEvent then
		warn("[RunScript] SprintEvent not found in ReplicatedStorage, sprint won't sync to the server")
	end

	local WALK_SPEED = 16
	local RUN_SPEED = 28
	local RUN_ANIM_ID = "rbxassetid://0" -- add a run animation

	local isShiftHeld = false
	local character = nil
	local humanoid = nil
	local runTrack = nil
	local characterToken = 0

	-- only per-character connections live here. the input listeners further down
	-- stay connected for the whole session so sprinting keeps working after a respawn.
	local characterConnections = {}

	local function isBlocked()
		if not character then return true end
		-- no sprinting while sliding or ragdolled
		if character:GetAttribute("Sliding") then return true end
		local ragdoll = character:FindFirstChild("IsRagdoll")
		return ragdoll ~= nil and ragdoll.Value == true
	end

	local function updateRunning()
		if not humanoid or not runTrack or humanoid.Health <= 0 then return end

		local isGrounded = (humanoid.FloorMaterial ~= Enum.Material.Air)
		local isMoving = (humanoid.MoveDirection.Magnitude > 0)
		local shouldSprint = isShiftHeld and isGrounded and isMoving and not isBlocked()

		if shouldSprint then
			if humanoid.WalkSpeed < RUN_SPEED then
				humanoid.WalkSpeed = RUN_SPEED
				if sprintEvent then sprintEvent:FireServer(true) end
			end

			if not runTrack.IsPlaying then
				runTrack:Play(0.2)
			end
		else
			if humanoid.WalkSpeed > WALK_SPEED then
				humanoid.WalkSpeed = WALK_SPEED
				if sprintEvent then sprintEvent:FireServer(false) end
			end
			if runTrack.IsPlaying then
				runTrack:Stop(0.2)
			end
		end
	end

	local function clearCharacter()
		for _, conn in ipairs(characterConnections) do
			conn:Disconnect()
		end
		table.clear(characterConnections)
		runTrack = nil
		humanoid = nil
		character = nil
	end

	local function setupCharacter(newCharacter)
		characterToken += 1
		local token = characterToken
		clearCharacter()

		-- the client can receive the character before its children replicate, so wait for them
		local newHumanoid = newCharacter:WaitForChild("Humanoid", 10)
		if token ~= characterToken or not newHumanoid then return end
		local animator = newHumanoid:WaitForChild("Animator", 10)
		if token ~= characterToken or not animator then return end

		character = newCharacter
		humanoid = newHumanoid

		local runAnim = Instance.new("Animation")
		runAnim.AnimationId = RUN_ANIM_ID
		runTrack = animator:LoadAnimation(runAnim)
		runTrack.Priority = Enum.AnimationPriority.Movement
		runTrack.Looped = true

		humanoid.WalkSpeed = WALK_SPEED
		isShiftHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)

		if sprintEvent then sprintEvent:FireServer(false) end

		table.insert(characterConnections, humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(updateRunning))
		table.insert(characterConnections, humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(updateRunning))
		table.insert(characterConnections, character:GetAttributeChangedSignal("Sliding"):Connect(updateRunning))
		table.insert(characterConnections, humanoid.Died:Connect(function()
			if runTrack then runTrack:Stop(0.1) end
		end))

		updateRunning()
	end

	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			isShiftHeld = true
			updateRunning()
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			isShiftHeld = false
			updateRunning()
		end
	end)

	player.CharacterAdded:Connect(setupCharacter)
	player.CharacterRemoving:Connect(clearCharacter)

	if player.Character then
		setupCharacter(player.Character)
	end
