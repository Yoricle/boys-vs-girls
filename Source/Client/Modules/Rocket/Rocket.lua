local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ComponentExtensions = ReplicatedStorage.ComponentExtensions
local Component = require(ReplicatedStorage.Packages.Component)

local TroveAdder = require(ComponentExtensions.TroveAdder)

local comms = require(ReplicatedStorage.Packages.Comm)
local Knit = require(ReplicatedStorage.Packages.Knit)

local ClientComm = comms.ClientComm

--[[
    This is the classic roblox rocket, I want to control a few things through this object component table

]]
-- constants
local COOLDOWN = 5;

local MOUSE_ICON = 'rbxasset://textures/GunCursor.png'
local RELOADING_ICON = 'rbxasset://textures/GunWaitCursor.png'


local Rocket = Component.new({ Tag = "Rocket", Extensions = {TroveAdder} })

function Rocket:Construct()
    self.Handle = self.Instance.Handle -- fetching the handle and tagging the tool instance

    self.reloadSound = self.Handle:WaitForChild("ReloadSound")
    self.equipSound = self.Handle:WaitForChild("Equip")

    self.comms = ClientComm.new(self.Instance) -- attaches event to the tool object
    self.rocketEvent = self.comms:GetSignal("RocketEvent")

    self.baseRocket = nil
    self.myModel = nil
    self.myPlayer = nil
    self.rocketClone = nil
    self.Mouse = nil
end

function Rocket:Start()
    self:Equipped()
    self:Unequipped()
    self:ActivateRocket()

    self.Instance.Changed:Connect(function(property)
        if property == "Enabled" then
            self:UpdateIcon()
        end
    end)
end

function Rocket:UpdateIcon()
    self.Mouse.Icon = self.Instance.Enabled and MOUSE_ICON or RELOADING_ICON
end

function Rocket:Equipped()
    self.Instance.Equipped:Connect(function(mouse)
        self.Mouse = mouse
        self.myModel = self.Instance.Parent
        self.myPlayer = Players:GetPlayerFromCharacter(self.myModel)
    
        self.equipSound:Play()
        self:UpdateIcon()
    end)
end

function Rocket:Unequipped()
    self.Instance.Unequipped:Connect(function()
        self.reloadSound:Stop()
    end)
end

function Rocket:ActivateRocket()
    self.Instance.Activated:Connect(function()
        task.wait(0) --TODO: Remove when Mouse.Hit and Humanoid.TargetPoint update properly on iPad
        if self.Instance.Enabled and self.myModel and self.myModel:FindFirstChild('Humanoid') and self.myModel.Humanoid.Health > 0 then
            self.Instance.Enabled = false

            -- fire event via comms
            
            self.rocketEvent:Fire(Knit.Player.Character.Humanoid.TargetPoint)

            self.reloadSound:Play()

            task.wait(COOLDOWN)

            -- Stop the reloading sound if it hasn't already finished
            self.reloadSound:Stop()

            self.Instance.Enabled = true
        end
    end)
end

function Rocket:Stop()
    self._trove:Destroy()
end

return Rocket