local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local AmmoFrame = require(script.Parent.AmmoFrame)

return function(props)
    return Roact.createElement("ScreenGui", {
        ResetOnSpawn = false,
    }, {
        AmmoFrame = Roact.createElement(AmmoFrame, {
            viewModel = props.viewModel,
        }),
    })
end