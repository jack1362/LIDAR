local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LIDARModule = require(ReplicatedStorage.Modules.LIDAR)
local tool = script.Parent

tool.Activated:Connect(function()
	LIDARModule.StartContinuousScan()
end)

tool.Deactivated:Connect(function()
	LIDARModule.StopScan()
end)
