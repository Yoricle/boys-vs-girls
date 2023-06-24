local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")

local ComponentExtensions = ReplicatedStorage.ComponentExtensions
local Component = require(ReplicatedStorage.Packages.Component)

local TroveAdder = require(ComponentExtensions.TroveAdder)

local comms = require(ReplicatedStorage.Packages.Comm)
local Knit = require(ReplicatedStorage.Packages.Knit)

local ServerComm = comms.ServerComm

local COOLDOWN = 5 -- Seconds until tool can be used again

-- How far away from the handle does the user have to click for
-- the rocket to allow killing of the user themself.
local CLOSE_SHOT_DISTANCE = 10

-- RocketPropulsion Fields
local TARGET_RADIUS = 5
local MAX_SPEED = 250
local MAX_TORQUE = Vector3.new(4e6, 4e6, 0)
local MAX_THRUST = 50000
local THRUST_P = 500
local THRUST_D = 50000

local TARGET_OVERSHOOT_DISTANCE = 10000000

-- Rocket Fields
local ROCKET_MESH_ID = 'http://www.roblox.com/asset/?id=94690081'
local ROCKET_MESH_SCALE = Vector3.new(2.5, 2.5, 2)
local ROCKET_PART_SIZE = Vector3.new(1, 1, 4)

local Rocket = Component.new({ Tag = "Rocket", Extensions = {TroveAdder} })

function Rocket:Construct()
    self.Handle = self.Instance.Handle -- fetching the handle and tagging the tool instance

    self.comms = ServerComm.new(self.Instance) -- attaches event to the tool object
    self.rocketEvent = self.comms:CreateSignal("RocketEvent")
end

function Rocket:FireRocket(player, direction)
    
end

function Rocket:Start()
    self.rocketEvent:Connect(function(player, direction)
        local rocket = self:MakeRocket()
	
	-- Pick a target
	local targetPosition = direction
		
		-- Maybe set the "closeShot" flag
		print("CloseShot: ", (targetPosition - self.Handle.Position).magnitude)
		if (targetPosition - self.Handle.Position).magnitude < CLOSE_SHOT_DISTANCE then
			rocket.closeShot.Value = true
		end

		-- Position the rocket clone
		local spawnPosition = self.Handle.Position + (self.Handle.CFrame.lookVector * (self.Handle.Size.Z / 2))
		rocket.CFrame = CFrame.new(spawnPosition, targetPosition) --NOTE: This must be done before assigning Parent
		rocket.Parent = workspace

		-- Assign target and launch!
		local rocketPropulsion = rocket:FindFirstChild('RocketPropulsion')
	if rocketPropulsion then
		Debris:AddItem(rocket, 30)
			local direction = (targetPosition - rocket.Position).unit
			rocketPropulsion.TargetOffset = rocket.Position + (direction * TARGET_OVERSHOOT_DISTANCE)
			rocketPropulsion:Fire()
		end

		-- Prepare the next rocket to be fired
		--RocketClone = rocket:Clone()

    end)
end

function Rocket:MakeRocket()
    local MyModel = self.Instance.Parent
	local MyPlayer = game.Players:GetPlayerFromCharacter(MyModel)

	
	-- Set up the rocket part
	local rocket = Instance.new('Part')
	rocket.Name = 'Rocket'
	rocket.FormFactor = Enum.FormFactor.Custom --NOTE: This must be done before changing Size
	rocket.Size = ROCKET_PART_SIZE
	rocket.CanCollide = false
	rocket.BottomSurface = Enum.SurfaceType.Smooth
	rocket.TopSurface = Enum.SurfaceType.Smooth
    
	-- Add the mesh
	local mesh = Instance.new('SpecialMesh', rocket)
	mesh.MeshId = ROCKET_MESH_ID
	mesh.Scale = ROCKET_MESH_SCALE
	mesh.TextureId = self.Handle.Mesh.TextureId

	local creatorTag = Instance.new('ObjectValue', rocket)
	creatorTag.Name = 'creator' --NOTE: Must be called 'creator' for website stats
	creatorTag.Value = MyPlayer
	local nameTag = Instance.new('StringValue', creatorTag)
	nameTag.Name = 'weaponName'
	nameTag.Value = self.Instance.Name
	local iconTag = Instance.new('StringValue', creatorTag)
	iconTag.Name = 'weaponIcon'
	iconTag.Value = self.Instance.TextureId
	-- Add the propulsion
	local rocketPropulsion = Instance.new('RocketPropulsion', rocket)
	rocketPropulsion.CartoonFactor = 1
	rocketPropulsion.TargetRadius = TARGET_RADIUS
	rocketPropulsion.MaxSpeed = MAX_SPEED
	rocketPropulsion.MaxTorque = MAX_TORQUE
	rocketPropulsion.MaxThrust = MAX_THRUST
	rocketPropulsion.ThrustP = THRUST_P
	rocketPropulsion.ThrustD = THRUST_D

	-- Clone the sounds
	local swooshSoundClone = self.Handle.Swoosh:Clone()
	swooshSoundClone.Parent = rocket
	local boomSoundClone = self.Handle.Boom:Clone()
	boomSoundClone.PlayOnRemove = true
	boomSoundClone.Parent = rocket

	-- Attach creator tags
	
	
	-- The "close shot" tag. True if the rocket should be able to kill the
	-- creator.
	local closeShot = Instance.new('BoolValue', rocket)
	closeShot.Name = 'closeShot'
	closeShot.Value = false


    CollectionService:AddTag(rocket, "missile")

	-- Finally, clone the rocket script and enable it
	local rocketScriptClone = self.Handle.Rocket:Clone()
	rocketScriptClone.Parent = rocket
	rocketScriptClone.Disabled = false

	return rocket
end

function Rocket:Stop()

end

return Rocket