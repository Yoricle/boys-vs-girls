local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")


local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)

local TELEPORTER_ENABLED : BoolValue = true

local player = Players.LocalPlayer

local Component = require(ReplicatedStorage.Packages.Component)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Comm = require(ReplicatedStorage.Packages.Comm)

local ClientComm = Comm.ClientComm


local Boys = Component.new({ Tag = "Boys", Extensions = {TroveAdder} })

--[[
    for the individual teleports to teleport you to the game, I'm not using a touched event as I don't want messy debounces and really long code
    and inifective events. Raycast is much easier and more precise to use


    Once player is remove from lobby and is assigned to a team, cancel the thread
]]

function Boys:Construct()
    self._comm = ClientComm.new(self.Instance)
    self._teleported = self._comm:GetSignal("Teleport")

    self._params = RaycastParams.new()

    self._character = player.Character or player.CharacterAdded:Wait()

    self._distance = 12 -- size of button

    self._endPoint = self.Instance.Parent.EndPoint

    print(self._character)
	
	self._lastUpdate = 0
end

function Boys:Start()
    print("Boys teleporter ready!")
    self:StartDetection()
end

function Boys:StartDetection()
    print("Teleport Detection Started")
    self._thread = RunService.RenderStepped:Connect(function(deltaTime)
        self:SetIgnoreList()
        self.originalSize = self.Instance.Size
        self.originalPosition = self.Instance.Position
    
        local Distance = (self._character.PrimaryPart.Position - self.Instance.Position).Magnitude
        local now : number = os.clock()
        local timeBetweenUpdates : number = self.Instance:GetAttribute("Update")
        self:CheckDistance(Distance)
        task.wait()
    end)
end

function Boys:SetIgnoreList()
	local ignoreList = { self.Instance }

	for _, part in pairs(CollectionService:GetTagged("Button")) do
		table.insert(ignoreList, part)
	end

	self._params.FilterDescendantsInstances = ignoreList
end

function Boys:PlayerHasTeleported()
    self._character:PivotTo(self._endPoint:GetPivot())
    self._teleported:Fire()
    self._thread:Disconnect()
end


function Boys:CheckDistance(Distance)
    if Distance <= self._distance then
        --self._pressed:Fire(self.Instance, self.door)  -- tells the server the button has been pressed
        -- teleport player
        self:PlayerHasTeleported()
    else
        --self._unpressed:Fire(self.Instance, self.door)
    end
    self._lastUpdate = os.clock()
end

function Boys:Stop()
    self._trove:Destroy()
    self._thread:Disconnect()
end

return Boys