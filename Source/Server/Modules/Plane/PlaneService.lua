local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Knit = require(ReplicatedStorage.Packages.Knit)

local PlaneService = Knit.CreateService {
    Name = "PlaneService",
    Client = {},
}


function PlaneService:KnitInit()
    
end

function PlaneService:KnitStart()
    print("PlaneService Started")
end

return PlaneService
