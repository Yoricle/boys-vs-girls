local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Knit = require(ReplicatedStorage.Packages.Knit)

local TeleportService = Knit.CreateService {
    Name = "TeleportService",
    Client = {},
}


function TeleportService:KnitStart()
    print("TeleportService Started")
    -- check the player is neutral so they can be assigned a team
    -- give players the weapons when teleporting (with the correct ammo colours)
    -- make sure once player is assigned to team, that they respawn on the chosen team spawn
end


function TeleportService:KnitInit()
    
end


return TeleportService
