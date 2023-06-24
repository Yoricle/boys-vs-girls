local KeyboardController = {}

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")



function KeyboardController.new()
	local controls = {}

	controls.pos = Vector3.new()

	local mouseDown = false
	
	local mouse = game.Players.LocalPlayer:GetMouse()

	mouse.Button1Down:Connect(function()
		mouseDown = true
		while mouseDown do
			controls.pos = mouse.Hit.p
			RunService.Stepped:Wait()
		end
	end)
	
	mouse.Button1Up:Connect(function()
		mouseDown = false
	end)
	
	function controls:CreateLookPoint(origin_cframe)
		if controls.pos == Vector3.new() then
			return origin_cframe.p+origin_cframe.lookVector * 5
		end
		return controls.pos
	end
	return controls
end

return KeyboardController
