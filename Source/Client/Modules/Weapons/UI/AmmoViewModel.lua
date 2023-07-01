local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ViewModel = require(ReplicatedStorage.RoactComponents.ViewModel)

local AmmoViewModel = {}
AmmoViewModel.__index = AmmoViewModel
AmmoViewModel.className = "AmmoViewModel"
setmetatable(AmmoViewModel, ViewModel)

function AmmoViewModel.new(Instance): table
    local self = ViewModel.new()
    
    print("ViewModel loaded")
    self.ammo = Instance:GetAttribute("Clip") -- changes with the attribute on the gun
    self.clip = Instance:GetAttribute("Clip")

    return setmetatable(self, AmmoViewModel)
end

function AmmoViewModel:setClip(newValue: any)
    self.clip = newValue
    self:update()
end

function AmmoViewModel:setAmmo(newValue: any)
    self.ammo = newValue
    self:update()
end

function AmmoViewModel:addAmmo(newValue: any)
    self.ammo = self.ammo + newValue
    self:update()
end

function AmmoViewModel:reduceAmmo(newValue: any)
    self.ammo = self.ammo - newValue
    self:update()
end

function AmmoViewModel:Destroy()
    getmetatable(AmmoViewModel).Destroy(self)
end

return AmmoViewModel
