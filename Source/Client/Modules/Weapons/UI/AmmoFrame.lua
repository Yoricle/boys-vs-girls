local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local Flipper = require(ReplicatedStorage.Packages.Flipper)
local RoactFlipper = require(ReplicatedStorage.Packages.RoactFlipper)

local AmmoFrame = Roact.Component:extend("AmmoFrame")

function AmmoFrame:init()
    self:setState({
        ammo = self.props.viewModel.ammo,
        clip = self.props.viewModel.clip,
    })

    --self._ammoMotor = Flipper.SingleMotor.new(self.state.ammo)
    --self._binding = RoactFlipper.getBinding(self._ammoMotor)
end

function AmmoFrame:didMount()
    self.props.viewModel.updated:Connect(function(viewModel)
        self:setState({
            ammo = viewModel.ammo,
            clip = viewModel.clip
        })
    end)
end

function AmmoFrame:render()
    return Roact.createElement("Frame", {
        Name = "Backpack",
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,1,0),
        Position = UDim2.new(0,0,0,0),

    },{
        Hotbar = Roact.createElement("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0,655,0,70),
            Position = UDim2.new(0.5,-328,1,-70),
        },{
            Label = Roact.createElement("TextLabel", {
                BackgroundColor3 = Color3.fromRGB(31, 31, 31),
                BackgroundTransparency = 0.5,
                Position = UDim2.new(0.425, 0, -0.5, 0),
                Size = UDim2.new(0.15, 0, 0.05, 0),
                SizeConstraint = Enum.SizeConstraint.RelativeXX,
                TextColor3 = Color3.fromRGB(255,255,255),
                TextScaled = true,
                Text = tostring(self.state.ammo) .. "/" .. tostring(self.state.clip)
            })
        })
    })
end

return AmmoFrame