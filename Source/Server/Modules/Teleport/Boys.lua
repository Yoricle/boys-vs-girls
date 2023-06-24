local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Teams = game:GetService("Teams")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)

local Comm = require(ReplicatedStorage.Packages.Comm)

local ServerComm = Comm.ServerComm

local Boys = Component.new({ Tag = "Boys", Extensions = {TroveAdder} })

function Boys:Construct()
    self._tools = ServerStorage.Tools
    self._comm = ServerComm.new(self.Instance)
    self._teleported = self._comm:CreateSignal("Teleport")

    self._trove:Add(self._teleported:Connect(function(player)
        player.Team = Teams.Boys
        
        self:FetchWeapons(player)
    end))
end

function Boys:FetchWeapons(player : Player)
    for _, weapons in pairs(self._tools:GetChildren()) do
        local w = weapons:Clone()
        w.Parent = player.Backpack
    end
end

function Boys:Start()

end

function Boys:Stop()

end

return Boys