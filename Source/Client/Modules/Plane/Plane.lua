local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- component extensions
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local OnlyLocalPlayer = require(ReplicatedStorage.ComponentExtensions.OnlyLocalPlayer)

local Component = require(ReplicatedStorage.Packages.Component)
local Input = require(ReplicatedStorage.Packages.Input)
local Knit = require(ReplicatedStorage.Packages.Knit)

-- comms
local comm = require(ReplicatedStorage.Packages.Comm)
local ClientComm = comm.ClientComm

-- input
local controller = require(script.parent.Input.ControllerFactory)

local MAX_SPEED = 50;

local Plane = Component.new({ Tag = "Plane", Extensions = {TroveAdder} })

--[[
    if a player that already owns a plane tries to regenerate a plane, they shouldn't be allowed and should be informed
    if player has destroyed their plane, they should be allowed to regenerate a new plane
    if another player has a plane but you don't, you should be able to regenerate a plane
    if you've gotten out of your plane but it hasn't been destroyed, you shouldn't be allowed to regenerate the plane and should be informed
]]

function Plane:Construct()
    -- children of the plane
    self._comm = ClientComm.new(self.Instance)
    self.dropBomb = self._comm:GetSignal("DropBomb")
    self.fireRocket = self._comm:GetSignal("FireRocket")

    self._engine = self.Instance.Engine
    self._vehicleSeat = self.Instance.VehicleSeat
    self._mouse = Knit.Player:GetMouse()
end

function Plane:Start()
    self.Instance:GetAttributeChangedSignal("Active"):Connect(function(...)
        local att = self.Instance:GetAttribute("Active")

        -- you have to get in first for it to activate, so the heartbeat will be available to disconnect

        if not att then
            self.hearbeat:Disconnect()
            self.hearbeat = nil
            self.gyro:Destroy()
            self.velocity:Destroy()
            self._mouse.Icon = "rbxasset://SystemCursors/Arrow"
            return
        end
        -- This will run first when a player gets in the aircraft
        self:InitiateMovers()
        self:StartAircraft()
        self._mouse.Icon = "rbxasset://textures\\GunCursor.png"
    end)
end

function Plane:CheckTeamColour()
    
end

function Plane:InitiateMovers()
    self.gyro = self._engine:FindFirstChild("BodyGyro") or Instance.new("BodyGyro", self._engine)
    self.velocity = self._engine:FindFirstChild("BodyVelocity") or Instance.new("BodyVelocity", self._engine)

    self.gyro.cframe = CFrame.new(self._engine.Position, self._engine.Position + self._engine.CFrame.lookVector + Vector3.new(0, 0.1, 0))
	self.gyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
	
	self.velocity.MaxForce=Vector3.new(1e6, 1e6, 1e6)
end

function Plane:StartAircraft()
    local att = self.Instance:GetAttribute("Active")
    print(self._mouse)
    self.hearbeat = RunService.Heartbeat:Connect(function(dt)
        self.velocity.Velocity = self._engine.CFrame.lookVector * MAX_SPEED
        self.gyro.CFrame = CFrame.new(self._engine.Position, controller:CreateLookPoint(self._engine.CFrame, att))
    end)
end

function Plane:GetEngineActive()
    return self.Instance:GetAttribute("Active") -- returns true or false
end

function Plane:FireRocket(...)
    self.fireRocket:Fire(...) -- pass whatever..
end

function Plane:DropBombs(...) -- use input handling to control bomb drop
    self.dropBomb:Fire(...)
end

function Plane:FireMachineGun()
    
end

function Plane:PlaneClaimed() -- This should be server-sided
    
end

function Plane:PlaneUnclaimed()
    
end

function Plane:Stop()
    print(self.Instance.Name .. " has been cleaned")
    if self.velocity then self.velocity:Destroy() end
    if self.gyro then self.gyro:Destroy() end
    self._trove:Destroy()
end

return Plane