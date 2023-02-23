--[[
	User input controller
	Handles user input & provides interfaces to capturing it
--]]

local UserInputController = {}

---------------------
-- Roblox Services --
---------------------
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

------------------
-- Dependencies --
------------------
local UserInput;

------------
-- Events --
------------
local InputSchemaChanged;
local DoubleTapped;

-------------
-- Defines --
-------------
local LocalPlayer = Players.LocalPlayer
local InputButtonsUI = script.InputButtons_UI:Clone()
InputButtonsUI.Enabled = false
InputButtonsUI.Parent = LocalPlayer.PlayerGui
local CurrentInputSchema = "MouseAndKeyboard"
local CurrentInputType = UserInputService:GetLastInputType()
local Touch_TappedOnce = false
local Touch_DoubleTap_ThreadID = ""

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper functions
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
local function DetermineDeviceFromInputType(InputType)
	if string.find(InputType.Name,"Mouse") ~= nil then
		return "Mouse"
	elseif string.find(InputType.Name,"Gamepad") ~= nil then
		return "Gamepad"
	elseif InputType.Name == "Touch" then
		return "TouchScreen"
	elseif InputType.Name == "Keyboard" then
		return "Keyboard"
	else
		return "Unknown"
	end
end

local function DetermineInputSchemaFromInputType(InputType)
	local InputSchema = "MouseAndKeyboard"

	if DetermineDeviceFromInputType(InputType) == "Mouse" then
		InputSchema = "MouseAndKeyboard"
	elseif DetermineDeviceFromInputType(InputType) == "Gamepad" then
		InputSchema = "Gamepad"
	elseif DetermineDeviceFromInputType(InputType) == "TouchScreen" then
		InputSchema = "TouchScreen"
	elseif DetermineDeviceFromInputType(InputType) == "Keyboard" then
		if UserInputService.GamepadEnabled then
			InputSchema = "GamepadAndKeyboard"
		elseif UserInputService.TouchEnabled then
			InputSchema = "TouchAndKeyboard"
		end
	end

	return InputSchema
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- API Methods
----------------------------------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @Name : RegisterTouchButton
-- @Description : Creates & returns an on-screen button that can be used to emulate input for contextactionservice actions
-- @Params : string "ActionName" - The name of the action that the button is for
--           function "InputCallback" - The function that is called when the button is pressed & let go
--           OPTIONAL string "Title" - The text that displays on the button
--           OPTIONAL string "IconID" - The ID of the icon that is shown on the button
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
function UserInputController:RegisterTouchButton(ActionName,InputCallback,Title,IconID)
	local NewButton = InputButtonsUI.BaseButton:Clone()
	NewButton.Name = ActionName
	NewButton.ActionTitle.Text = Title or ""
	NewButton.ActionIcon.Image = "rbxassetid://" .. (IconID or "")
	NewButton.Visible = true
	NewButton.Parent = InputButtonsUI

	NewButton.MouseButton1Down:connect(function()
		-- selene: allow(undefined_variable)
		InputCallback(_,Enum.UserInputState.Begin)
	end)
	NewButton.MouseButton1Up:connect(function()
		-- selene: allow(undefined_variable)
		InputCallback(_,Enum.UserInputState.End)
	end)

	return NewButton
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @Name : GetCurrentInputSchema
-- @Description : Returns the name of the current input schema
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
function UserInputController:GetCurrentInputSchema()
	return CurrentInputSchema
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @Name : GetCurrentInputDevice
-- @Description : Returns the type of device the user is currently giving input on
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
function UserInputController:GetCurrentInputDevice()
	return CurrentInputType
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @Name : GetInputCapturer
-- @Description : Returns a new instance of an input capturer
-- @Params : string "InputType" - The type of input to get the capturer of. E.g. Keyboard
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
function UserInputController:GetInputCapturer(InputType)
	return UserInput[InputType].new()
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @Name : Init
-- @Description : Called when the Controller module is first loaded.
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
function UserInputController:Init()
	InputSchemaChanged = self:RegisterControllerClientEvent("InputSchemaChanged")
	DoubleTapped = self:RegisterControllerClientEvent("DoubleTapped")
	UserInput = self:GetModule("UserInput")

	CurrentInputSchema = DetermineInputSchemaFromInputType(UserInputService:GetLastInputType())
	if CurrentInputSchema == "TouchScreen" or CurrentInputSchema == "TouchAndKeyboard" then
		InputButtonsUI.Enabled = true
	else
		InputButtonsUI.Enabled = false
	end

	self:DebugLog("[User Input Controller] Initialized!")
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @Name : Start
-- @Description : Called after all Controllers are loaded.
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
function UserInputController:Start()
	self:DebugLog("[User Input Controller] Started!")

	local TouchInputListener = self:GetInputCapturer("Touch")
	
	UserInputService.LastInputTypeChanged:connect(function(InputType)
		CurrentInputType = InputType

		CurrentInputSchema = DetermineInputSchemaFromInputType(InputType)

		if CurrentInputSchema == "TouchScreen" or CurrentInputSchema == "TouchAndKeyboard" then
			InputButtonsUI.Enabled = true
		else
			InputButtonsUI.Enabled = false
		end
		InputSchemaChanged:Fire(CurrentInputSchema)
	end)

	TouchInputListener.TouchTapInWorld:Connect(function(TapPosition)
		if Touch_TappedOnce then
			DoubleTapped:Fire(TapPosition)
		else
			local ThisThreadID = HttpService:GenerateGUID(false)
			Touch_DoubleTap_ThreadID = ThisThreadID
			Touch_TappedOnce = true

			task.delay(0.15,function()
				if Touch_DoubleTap_ThreadID == ThisThreadID then
					Touch_TappedOnce = false
				end
			end)
		end
	end)
end

return UserInputController