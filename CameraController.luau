-- use this at starterplayerscripts
-- disable EnableMouseLockOption in starterplayer

  local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")

	local player = Players.LocalPlayer
	local camera = workspace.CurrentCamera
	local playerGui = player:WaitForChild("PlayerGui")

	-- settings
	local ROTATION_SMOOTHING = 0.15
	local BOB_ENABLED = true

	player.CameraMaxZoomDistance = 128
	player.CameraMinZoomDistance = 0.5

	-- state
	local shiftLockEnabled = false
	local character, humanoid, hrp, head
	local diedConnection = nil
	local characterToken = 0

	local currentAimOffset = 0
	local currentAimOffsetY = 0
	local targetAimOffsetDistance = 1.5
	local targetAimOffsetDistanceY = 0.5
	local aimOffsetSmoothing = 8

	-- camera bob state (descriptive names)
	local bobOscX, bobOscY = 0, 0              -- oscillation offsets
	local rollFromMouse = 0                     -- mouse-delta-based roll
	local bobAmplitude = 0                      -- bob amplitude
	local pitchBob = 0                          -- pitch bobbing
	local lateralSway = 0                       -- lateral camera sway
	local bobFrequency, bobIntensity = 10, 10   -- bob freq/intensity
	local currentTiltAmount = 0

	--  shiftlock dot
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ShiftLockDotGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	screenGui.IgnoreGuiInset = true

	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 4, 0, 4)
	dot.Position = UDim2.new(0.5, 0, 0.5, 0)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	dot.BackgroundTransparency = 0.45
	dot.BorderSizePixel = 0
	dot.Visible = false
	dot.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = dot

	local function lerp(a, b, t)
		return a + (b - a) * t
	end

	-- shiftlock toggle
	local function setShiftLock(enabled)
		shiftLockEnabled = enabled
		dot.Visible = enabled
		UserInputService.MouseIconEnabled = not enabled
		UserInputService.MouseBehavior = enabled and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
			setShiftLock(not shiftLockEnabled)
		end
	end)

	-- character setup
	local function onCharacterAdded(newCharacter)
		characterToken += 1
		local token = characterToken

		-- drop the old character first so the render loop never touches stale parts
		character, humanoid, hrp, head = nil, nil, nil, nil
		if diedConnection then
			diedConnection:Disconnect()
			diedConnection = nil
		end

		-- the client can receive the character before its children replicate, so wait for them
		local newHumanoid = newCharacter:WaitForChild("Humanoid", 10)
		local newRoot = newCharacter:WaitForChild("HumanoidRootPart", 10)
		local newHead = newCharacter:WaitForChild("Head", 10)
		if token ~= characterToken or not newHumanoid or not newRoot or not newHead then return end

		character, humanoid, hrp, head = newCharacter, newHumanoid, newRoot, newHead
		camera.CameraSubject = head

		diedConnection = humanoid.Died:Connect(function()
			setShiftLock(false)
		end)
	end

	local function onCharacterRemoving()
		characterToken += 1
		if diedConnection then
			diedConnection:Disconnect()
			diedConnection = nil
		end
		humanoid = nil
		hrp = nil
		head = nil
	end

	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)
	player.CharacterRemoving:Connect(onCharacterRemoving)

	-- renderstepped 
	RunService.RenderStepped:Connect(function(dt)
		if not humanoid or humanoid.Health <= 0 or not hrp or not hrp.Parent then return end

		-- the default camera script resets the subject on every respawn, so keep it on the head
		if camera.CameraSubject ~= head then
			camera.CameraSubject = head
		end

		local scaledDt = dt * 60
		local time = os.clock()

		-- 1. shiftlock turning
		if shiftLockEnabled then
			local _, camYaw = camera.CFrame:ToOrientation()
			local currentCFrame = CFrame.new(Vector3.zero, hrp.CFrame.LookVector)
			local targetCFrame = CFrame.fromOrientation(0, camYaw, 0)
			local alpha = 1 - math.exp(-ROTATION_SMOOTHING * 60 * dt)
			local smoothed = currentCFrame:Lerp(targetCFrame, alpha)
			hrp.CFrame = CFrame.new(hrp.Position) * smoothed
		end

		-- 2. camera tilt + camera bobbing
		if BOB_ENABLED then
			local velocity = hrp.AssemblyLinearVelocity
			local rootMagnitude = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
			local calcRootMagnitude = math.min(rootMagnitude, 50)
			local localMove = hrp.CFrame:VectorToObjectSpace(velocity)
			local targetTiltAmount = math.clamp(localMove.X / 20, -1, 1)
			currentTiltAmount = lerp(currentTiltAmount, targetTiltAmount, 0.1 * scaledDt)
			local tiltAngle = math.rad(-currentTiltAmount * 5)

			if scaledDt > 3 then
				bobOscX, bobOscY = 0, 0
			else
				-- smooth organic variation via math.noise (replaces per-frame math.random)
				local freqX = 12.5 + math.noise(time * 0.3) * 1.5
				local freqY = 7.5 + math.noise(time * 0.3, 50) * 1.5
				local ampX = 0.0625 + math.noise(time * 0.2, 100) * 0.0375
				local ampY = 0.03 + math.noise(time * 0.2, 200) * 0.02

				bobOscX = lerp(bobOscX, math.cos(time * 0.5 * freqX) * ampX * scaledDt, 0.05 * scaledDt)
				bobOscY = lerp(bobOscY, math.cos(time * 0.5 * freqY) * ampY * scaledDt, 0.05 * scaledDt)
			end

			camera.CFrame = camera.CFrame
				* CFrame.fromEulerAnglesXYZ(0, 0, math.rad(rollFromMouse))
				* CFrame.fromEulerAnglesXYZ(math.rad(bobAmplitude * scaledDt), math.rad(pitchBob * scaledDt), lateralSway)
				* CFrame.Angles(0, 0, math.rad(bobAmplitude * scaledDt * (calcRootMagnitude / 5)))
				* CFrame.fromEulerAnglesXYZ(math.rad(bobOscX), math.rad(bobOscY), math.rad(bobOscY * 10))
				* CFrame.Angles(0, 0, tiltAngle)

			local isAiming = player:GetAttribute("IsAiming") == true
			local targetOffset = isAiming and targetAimOffsetDistance or 0
			currentAimOffset += (targetOffset - currentAimOffset) * math.clamp(aimOffsetSmoothing * dt, 0, 1)

			local targetOffsetY = isAiming and targetAimOffsetDistanceY or 0
			currentAimOffsetY += (targetOffsetY - currentAimOffsetY) * math.clamp(aimOffsetSmoothing * dt, 0, 1)

			camera.CFrame = camera.CFrame * CFrame.new(currentAimOffset, currentAimOffsetY, 0)

			lateralSway = math.clamp(lerp(lateralSway, -camera.CFrame:VectorToObjectSpace(velocity / math.max(humanoid.WalkSpeed, 0.01)).X * 0.08, 0.1 * scaledDt), -0.35, 0.2)
			rollFromMouse = lerp(rollFromMouse, math.clamp(UserInputService:GetMouseDelta().X, -5, 5), 0.25 * scaledDt)
			bobAmplitude = lerp(bobAmplitude, math.sin(time * bobFrequency) / 5 * math.min(1, bobIntensity / 10), 0.25 * scaledDt)

			if rootMagnitude > 1 then
				pitchBob = lerp(pitchBob, math.cos(time * 0.5 * math.floor(bobFrequency)) * (bobFrequency / 200), 0.25 * scaledDt)
			else
				pitchBob = lerp(pitchBob, 0, 0.05 * scaledDt)
			end

			if rootMagnitude > 12 then
				bobFrequency, bobIntensity = 20, 18
			elseif rootMagnitude > 0.1 then
				bobFrequency, bobIntensity = 12, 14
			else
				bobIntensity = 0
			end
		end
	end)
