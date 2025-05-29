-- // This code is meant to be a local script inside a tool that the character uses //
-- // The character can press and hold the tool to start a continuous scan //

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LIDARModule = require(ReplicatedStorage.Modules.LIDAR)
local tool = script.Parent

tool.Activated:Connect(function()
	LIDARModule.StartContinuousScan()
end)

tool.Deactivated:Connect(function()
	LIDARModule.StopScan()
end)
