local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Plane = require(script.Parent.Plane)

-- constants

local PlaneController = Knit.CreateController { Name = "PlaneController" }

function PlaneController:KnitInit()
    print("PlaneController Initialized")
end

function PlaneController:KnitStart()

end

function PlaneController:ConfirmOwnership()
    -- check player that is trying to enter is the owner
    -- if there isn't an owner, set an owner
end

function PlaneController:CheckTeamColour()
    
end

function PlaneController:PlaneControlsReady()


end


return PlaneController
