-- use this in starterplayerscripts
-- use this with the roblox provided mouselock. if you use this with my cameracontroller, there will be a slight camera shakes.

  local RunService = game:GetService('RunService')
	local Players = game:GetService('Players')

	local PlayersTable = {}
	local Connections = {}

	--Customizable Settings

	local RangeOfMotion = 45
	local RangeOfMotionTorso = 90 - RangeOfMotion
	local RangeOfMotionXZ = RangeOfMotion/140
	local LerpSpeed = 0.005

	--Main Code

	RangeOfMotion = math.rad(RangeOfMotion)
	RangeOfMotionTorso = math.rad(RangeOfMotionTorso)

	local OriginalC0s = {}

	local function calculate(dt, hrp, humanoid, torso, orig)
		local rootJointOrig = orig.RootJoint
		local neckOrig = orig.Neck
		local rightHipOrig = orig.RightHip
		local leftHipOrig = orig.LeftHip

		if not rootJointOrig or not neckOrig or not rightHipOrig or not leftHipOrig then return end

		local DirectionOfMovement = hrp.CFrame:VectorToObjectSpace(hrp.AssemblyLinearVelocity)
		local walkSpeed = math.max(humanoid.WalkSpeed, 0.01)
		DirectionOfMovement = Vector3.new(
			math.clamp(DirectionOfMovement.X / walkSpeed, -1.5, 1.5),
			0,
			math.clamp(DirectionOfMovement.Z / walkSpeed, -1.5, 1.5)
		)

		local XResult = (DirectionOfMovement.X * (RangeOfMotion - (math.abs(DirectionOfMovement.Z) * (RangeOfMotion / 2))))
		local XResultTorso = (DirectionOfMovement.X * (RangeOfMotionTorso - (math.abs(DirectionOfMovement.Z) * (RangeOfMotionTorso / 2))))
		local XResultXZ = (DirectionOfMovement.X * (RangeOfMotionXZ - (math.abs(DirectionOfMovement.Z) * (RangeOfMotionXZ / 2))))

		if DirectionOfMovement.Z > 0.1 then
			XResult *= -1
			XResultTorso *= -1
			XResultXZ *= -1
		end

		local rootJoint = hrp:FindFirstChild('RootJoint')
		local neck = torso:FindFirstChild('Neck')
		local rightHip = torso:FindFirstChild('Right Hip')
		local leftHip = torso:FindFirstChild('Left Hip')

		if not rootJoint or not neck or not rightHip or not leftHip then return end

		local RightHipResult = rightHipOrig * CFrame.new(-XResultXZ, 0, 0) * CFrame.Angles(0, -XResult, 0)
		local LeftHipResult = leftHipOrig * CFrame.new(-XResultXZ, 0, 0) * CFrame.Angles(0, -XResult, 0)
		local RootJointResult = rootJointOrig * CFrame.Angles(0, 0, -XResultTorso)
		local NeckResult = neckOrig * CFrame.Angles(0, 0, XResultTorso)

		local LerpTime = 1 - LerpSpeed ^ dt

		rightHip.C0 = rightHip.C0:Lerp(RightHipResult, LerpTime)
		leftHip.C0 = leftHip.C0:Lerp(LeftHipResult, LerpTime)
		rootJoint.C0 = rootJoint.C0:Lerp(RootJointResult, LerpTime)
		neck.C0 = neck.C0:Lerp(NeckResult, LerpTime)
	end

	local function onPlayerAdded(player)
		local function onCharacterAdded(character)
			-- characters arrive before their children replicate, so wait for the rig
			local hrp = character:WaitForChild('HumanoidRootPart', 10)
			local humanoid = character:WaitForChild('Humanoid', 10)
			local torso = character:WaitForChild('Torso', 10)

			if not hrp or not humanoid or not torso then return end

			local rootJoint = hrp:WaitForChild('RootJoint', 10)
			local neck = torso:WaitForChild('Neck', 10)
			local rightHip = torso:WaitForChild('Right Hip', 10)
			local leftHip = torso:WaitForChild('Left Hip', 10)

			if not rootJoint or not neck or not rightHip or not leftHip then return end

			-- the character may have been replaced while we were waiting
			if player.Character ~= character then return end

			OriginalC0s[player] = {
				RootJoint = rootJoint.C0,
				Neck = neck.C0,
				RightHip = rightHip.C0,
				LeftHip = leftHip.C0,
			}
			PlayersTable[player] = true
		end

		local function onCharacterRemoving()
			PlayersTable[player] = nil
			OriginalC0s[player] = nil
		end

		if player.Character then
			task.spawn(onCharacterAdded, player.Character)
		end
		Connections[player] = {}
		Connections[player].CharacterAdded = player.CharacterAdded:Connect(onCharacterAdded)
		Connections[player].CharacterRemoving = player.CharacterRemoving:Connect(onCharacterRemoving)
	end

	local function onPlayerRemoving(player)
		PlayersTable[player] = nil
		OriginalC0s[player] = nil
		if Connections[player] then
			for _, conn in pairs(Connections[player]) do
				conn:Disconnect()
			end
			Connections[player] = nil
		end
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	RunService.RenderStepped:Connect(function(dt)
		for player in pairs(PlayersTable) do
			local character = player.Character
			if not character then continue end

			local hrp = character:FindFirstChild('HumanoidRootPart')
			local humanoid = character:FindFirstChildOfClass('Humanoid')
			local torso = character:FindFirstChild('Torso')

			if not hrp or not humanoid or not torso then continue end
			if humanoid.Health <= 0 then continue end

			local orig = OriginalC0s[player]
			if not orig then continue end

			calculate(dt, hrp, humanoid, torso, orig)
		end
	end)
