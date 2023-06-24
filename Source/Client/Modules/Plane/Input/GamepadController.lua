local GamepadController = {}

local UserInputService = game:GetService("UserInputService")

function GamepadController.new()
	local this={}
	this.pos=Vector3.new()
	
	UserInputService.InputChanged:Connect(function(input)
		if input.KeyCode==Enum.KeyCode.Thumbstick1 then
			this.pos=input.Position
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Thumbstick1 then
			this.pos=Vector3.new()
		end
	end)
	
	function this:CreateLookPoint(origin_cframe)
		local look = origin_cframe.p+origin_cframe.lookVector*10
		look=look+Vector3.new(0,-this.pos.Y,0)*5
		look=look+Vector3.new(this.pos.X,0,this.pos.X)*5*origin_cframe.rightVector
		return look
	end
	return this
end

return GamepadController
