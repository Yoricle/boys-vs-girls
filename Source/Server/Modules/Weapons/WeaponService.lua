local ReplicatedStorage = game:GetService('ReplicatedStorage')


local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)

local Component = require(ReplicatedStorage.Packages.Component)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local WeaponService = Knit.CreateService {
    Name = "WeaponService",
    Client = {},
}


function WeaponService:KnitStart()
    
end


function WeaponService:KnitInit()
    
end


return WeaponService
