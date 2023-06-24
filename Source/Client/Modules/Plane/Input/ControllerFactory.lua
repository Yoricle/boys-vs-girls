local UserInputService = game:GetService("UserInputService")

local function getInputType()
	if UserInputService.GamepadEnabled then
		return "Gamepad"
	elseif UserInputService.TouchEnabled then
		return "Touch"
	else
		return "Keyboard"
	end
end

print(getInputType())
local controller = require(script.Parent[getInputType().."Controller"])

return controller.new()