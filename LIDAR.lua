local LIDAR = {}

local Player = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LidarParticles = workspace.LidarParticles
local Camera = workspace.CurrentCamera

-- // CONSTANTS //
local LIDAR_RANGE = 500
local MIN_RANGE = 5
local SCAN_CONE_ANGLE = 25
local RAYS_PER_FRAME = 4
local PARTICLE_LIFETIME = 45
local PARTICLE_FADE_TIME = 8
local SCAN_INTERVAL = 0.03
local HASH_CELL_SIZE = 2

local PARTICLE_SIZE = 0.05
local PARTICLE_BRIGHTNESS = 0.1

local possiblePartColors = {
	Color3.new(0.8, 1, 0.7),
	Color3.new(0.9, 0.6, 1),
	Color3.new(1, 0.4, 0.4),
	Color3.new(0.9, 1, 0.5),
	Color3.new(0.6, 1, 0.6),
	Color3.new(0.6, 0.6, 1),
	Color3.new(1, 0.6, 1),
	Color3.new(1, 0.9, 0.),
	Color3.new(1, 0.7, 0.6),
}

local assignedColorCache = {}
local activeParticles = {}
local scanConnection = nil
local lastScanTime = 0


if not workspace:FindFirstChild("LidarParticles") then
	local newLidarFolder = Instance.new("Folder")
	newLidarFolder.Name = "LidarParticles"
	newLidarFolder.Parent = workspace
end

-- // Raycast Params //
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.FilterDescendantsInstances = {Player.Character, workspace.LidarParticles}

-- // Chooses a color based off of PossiblePartColors with slight variation //
function LIDAR.ChooseParticleColor(object)
	if assignedColorCache[object] then
		return assignedColorCache[object]
	end
	
	
	local randomColor = possiblePartColors[math.random(#possiblePartColors)]
	
	-- // Slight variation to the constant color //
	local variation = 0.1
	local rVariation = (math.random() - 0.5) * variation
	local gVariation = (math.random() - 0.5) * variation
	local bVariation = (math.random() - 0.5) * variation
	
	local finalColor = Color3.new(
		math.clamp(randomColor.R + rVariation, 0, 1),
		math.clamp(randomColor.G + gVariation, 0, 1),
		math.clamp(randomColor.B + bVariation, 0, 1)
	)
	
	-- // Particles on the same object will appear the same color //
	assignedColorCache[object] = finalColor
	return finalColor
end

-- // Creates a new LIDAR particle //
function LIDAR.CreateParticle(raycastResult, distance)
	local adorneeColor = LIDAR.ChooseParticleColor(raycastResult.Instance)

	-- // Create the transparent object //
	local newParticle = Instance.new("Part")
	newParticle.Name = "LidarObject"
	newParticle.Size = Vector3.new(PARTICLE_SIZE, PARTICLE_SIZE, PARTICLE_SIZE)
	newParticle.Anchored = true
	newParticle.Transparency = 1
	newParticle.CanCollide = false
	newParticle.CFrame = CFrame.new(raycastResult.Position)

	-- // Create the LIDAR visual particle //
	local newAdornment = script.SphereHandleAdornment:Clone()
	newAdornment.Adornee = newParticle
	newAdornment.Color3 = adorneeColor
	newAdornment.Radius = PARTICLE_SIZE * 2
	newAdornment.Transparency = 0.1
	newAdornment.Parent = newParticle

	-- // Slight glow to every particle //
	local pointLight = Instance.new("PointLight")
	pointLight.Color = adorneeColor
	pointLight.Brightness = PARTICLE_BRIGHTNESS
	pointLight.Range = 1
	pointLight.Parent = newParticle

	newParticle.Parent = workspace.LidarParticles

	table.insert(activeParticles, {
		particle = newParticle,
		createdTime = tick()
	})
end

-- // Spatial hashing for collision detection //
local spatialHash = {}

function LIDAR.GetHashKey(position)
	local x = math.floor(position.X / HASH_CELL_SIZE)
	local y = math.floor(position.Y / HASH_CELL_SIZE)
	local z = math.floor(position.Z / HASH_CELL_SIZE)
	
	return string.format("%d,%d,%d", x, y, z)
end

function LIDAR.IsParticleNearby(position)
	local key = LIDAR.GetHashKey(position)
	local nearbyKeys = {
		key,
		LIDAR.GetHashKey(position + Vector3.new(HASH_CELL_SIZE, 0, 0)),
		LIDAR.GetHashKey(position - Vector3.new(HASH_CELL_SIZE, 0, 0)),
		LIDAR.GetHashKey(position + Vector3.new(0, HASH_CELL_SIZE, 0)),
		LIDAR.GetHashKey(position - Vector3.new(0, HASH_CELL_SIZE, 0)),
		LIDAR.GetHashKey(position + Vector3.new(0, 0, HASH_CELL_SIZE)),
		LIDAR.GetHashKey(position - Vector3.new(0, 0, HASH_CELL_SIZE)),
	}

	for _, checkKey in ipairs(nearbyKeys) do
		if spatialHash[checkKey] then
			for _, particlePos in ipairs(spatialHash[checkKey]) do
				if (particlePos - position).Magnitude < 1.5 then
					return true
				end
			end
		end
	end

	return false
end

function LIDAR.AddToSpatialHash(position)
	local key = LIDAR.GetHashKey(position)
	
	if not spatialHash[key] then
		spatialHash[key] = {}
	end
	
	table.insert(spatialHash[key], position)
end

-- // Clean up old particles //
function LIDAR.CleanupParticles()
	local currentTime = tick()
	for i = #activeParticles, 1, -1 do
		local particleData = activeParticles[i]
		if currentTime - particleData.createdTime > PARTICLE_LIFETIME then
			-- // Remove the spatial hash //
			local position = particleData.particle.Position
			local key = LIDAR.GetHashKey(position)
			if spatialHash[key] then
				for j = #spatialHash[key], 1, -1 do
					if (spatialHash[key][j] - position).Magnitude < 0.1 then
						table.remove(spatialHash[key], j)
						break
					end
				end
			end

			-- // Fade the particle out //
			local adornment = particleData.particle:FindFirstChild("SphereHandleAdornment")
			local light = particleData.particle:FindFirstChild("PointLight")

			if adornment then
				local fadeInfo = TweenInfo.new(PARTICLE_FADE_TIME, Enum.EasingStyle.Quad)
				local fadeTween = TweenService:Create(adornment, fadeInfo, {Transparency = 1})
				if light then
					TweenService:Create(light, fadeInfo, {Brightness = 0}):Play()
				end
				fadeTween:Play()
				fadeTween.Completed:Connect(function()
					particleData.particle:Destroy()
				end)
			else
				particleData.particle:Destroy()
			end

			table.remove(activeParticles, i)
		end
	end
end

-- // Scanning pattern //
function LIDAR.GetOrganicScanDirection(baseDirection, spread)
	-- // Noise simulation //
	local time = tick()
	local noiseX = math.sin(time * 0.7) * 0.3 + math.sin(time * 1.3) * 0.2 + math.sin(time * 2.1) * 0.1
	local noiseY = math.sin(time * 0.9) * 0.3 + math.sin(time * 1.7) * 0.2 + math.sin(time * 2.3) * 0.1

	-- // Random offsets //
	local theta = math.random() * math.pi * 2
	local phi = math.acos(1 - 2 * math.random())

	-- // Apply spread //
	local spreadX = math.sin(phi) * math.cos(theta) * spread + noiseX * spread * 0.5
	local spreadY = math.sin(phi) * math.sin(theta) * spread + noiseY * spread * 0.5
	local spreadZ = math.cos(phi) * spread * 0.5

	return baseDirection + Vector3.new(spreadX, spreadY, spreadZ)
end

-- // Continuous scanning //
function LIDAR.StartContinuousScan()
	if scanConnection then
		scanConnection:Disconnect()
	end

	scanConnection = RunService.Heartbeat:Connect(function()
		local currentTime = tick()
		
		if currentTime - lastScanTime < SCAN_INTERVAL then
			return
		end
		lastScanTime = currentTime

		if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then
			return
		end

		local CameraCFrame = Camera.CFrame
		local startPos = CameraCFrame.Position
		local baseDirection = CameraCFrame.LookVector

		-- // Cast multiple rays/frame //
		for i = 1, RAYS_PER_FRAME do
			-- // Range changes to make it more random //
			local rangeMultiplier = 0.3 + math.random() * 0.7
			local currentRange = MIN_RANGE + (LIDAR_RANGE - MIN_RANGE) * rangeMultiplier

			local spread = math.tan(math.rad(SCAN_CONE_ANGLE))
			local direction = LIDAR.GetOrganicScanDirection(baseDirection * currentRange, spread * currentRange)

			-- // LIDAR racyast //
			local raycastResult = workspace:Raycast(startPos, direction, raycastParams)

			if raycastResult and raycastResult.Instance:IsA("BasePart") then
				local distance = (raycastResult.Position - startPos).Magnitude

				-- // Check if particles are nearby //
				if not LIDAR.IsParticleNearby(raycastResult.Position) then
					LIDAR.CreateParticle(raycastResult, distance)
					LIDAR.AddToSpatialHash(raycastResult.Position)
				end
			end
		end

		-- // Randomly clean up old particles //
		if math.random(1, 60) == 1 then
			LIDAR.CleanupParticles()
		end
	end)
end

-- // Used to stop continuous scans //
function LIDAR.StopScan()
	if scanConnection then
		scanConnection:Disconnect()
		scanConnection = nil
	end
end

-- // Clear all LIDAR particles //
function LIDAR.ClearAllParticles()
	for _, child in pairs(workspace.LidarParticles:GetChildren()) do
		if child.Name == "LidarObject" then
			child:Destroy()
		end
	end
	activeParticles = {}
	assignedColorCache = {}
	spatialHash = {}
end

return LIDAR
