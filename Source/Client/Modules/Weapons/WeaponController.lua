local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.Roact)

-- viewmodels
local AmmoViewModel = require(script.Parent.UI.AmmoViewModel)

-- inputs
local PreferredInput = require(ReplicatedStorage.Packages.Input).PreferredInput
local Keyboard = require(ReplicatedStorage.Packages.Input).Keyboard

local Player = Players.LocalPlayer

--ui
local AmmoGui = require(script.Parent.UI.AmmoGui)
local gun = require(script.Parent.Gun)

local WeaponController = Knit.CreateController { Name = "WeaponController" }


function WeaponController:KnitStart()
    self.input = PreferredInput.Observe(function(input)
		-- Fires immediately & any time the preferred input changes
		print(input)
--[[
		if input == "Keyboard" then
			Keyboard.KeyDown:Connect(function(key)
				print("Key pressed", key)
			end)
		
			Keyboard.KeyUp:Connect(function(key)
				print("Key released", key)		if input == "Keyboard" then
			Keyboard.KeyDown:Connect(function(key)
				print("Key pressed", key)
			end)
		
			Keyboard.KeyUp:Connect(function(key)
				print("Key released", key)
			end)
		end
			end)
		end
]]

	end)
end

function WeaponController:MountAmmoUI(viewModel, weapon) -- when weapon equipped, call this in component
    local ammo = Roact.createElement(AmmoGui, {
        viewModel = viewModel,
    })

    self.handle = Roact.mount(ammo, Player.PlayerGui, "ammo")
end

function WeaponController:setAmmo()
    
end

function WeaponController:UnmountAmmoUI(viewModel)
    Roact.unmount(self.handle)
end


function WeaponController:KnitInit()

end


return WeaponController
