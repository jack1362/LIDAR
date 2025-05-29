# Lua LiDAR System

This is a performant, realistic LiDAR (Light Detection and Ranging) scanning system built for Roblox Studio with organic scanning patterns, spatial optimization, and visual effects

<div align="center">
  <img src="https://media1.giphy.com/media/v1.Y2lkPTc5MGI3NjExaWE4eXJldzNkb3FmNHBjNmIwZzVkY200a2psajQwd2F4cmE3aHM1aiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/QBLhbx3XmkOvxvt3FN/giphy.gif" alt="3D A* Pathfinding Demo" width="1000" />
  <img src="https://github.com/user-attachments/assets/6b157e49-7931-4a29-85d5-1f40a5b8a9db" width="48%" />
  <img src="https://github.com/user-attachments/assets/f0e8e167-0ec2-4ce8-8eb4-ea4c356bc2df" width="48%" />
</div>



## Features

### **Realistic Scanning**
- **Organic scan patterns** with multi-layered noise simulation
- **Variable range detection**
- **Cone-based scanning** with configurable angle spread

### **Performance Optimized**
- **Spatial hashing** for efficient collision detection
- **Frame-rate independent** scanning
- **Automatic cleanup** of old particles
- **Memory efficient** particle management

### **Visual Excellence**
- **Procedural color variation** for better visuals
- **Glowing particles** with customizable brightness
- **Smooth fade animations** for particle lifecycle

## Information

### Installation

1. **Download** the LiDAR module
2. **Place** it in `ReplicatedStorage.Modules`
3. **Create** a `SphereHandleAdornment` in the module script
4. **Add** a `LidarParticles` folder to workspace (auto-created if missing)

### Basic Usage

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LIDARModule = require(ReplicatedStorage.Modules.LIDAR)

-- Start continuous scanning
LIDARModule.StartContinuousScan()

-- Stop scanning
LIDARModule.StopScan()

-- Clear all particles
LIDARModule.ClearAllParticles()
```

### Tool Integration

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LIDARModule = require(ReplicatedStorage.Modules.LIDAR)
local tool = script.Parent

tool.Activated:Connect(function()
	LIDARModule.StartContinuousScan()
end)

tool.Deactivated:Connect(function()
	LIDARModule.StopScan()
end)
```

## Configuration

Customize the system by modifying these constants:

```lua
-- Scanning Parameters
local LIDAR_RANGE = 500        -- Maximum scan distance
local MIN_RANGE = 5            -- Minimum scan distance  
local SCAN_CONE_ANGLE = 25     -- Cone spread in degrees
local RAYS_PER_FRAME = 4       -- Performance vs density

-- Particle Settings
local PARTICLE_LIFETIME = 45   -- Seconds before fade
local PARTICLE_FADE_TIME = 8   -- Fade animation duration
local PARTICLE_SIZE = 0.05     -- Visual particle size
local PARTICLE_BRIGHTNESS = 0.1 -- Glow intensity

-- Performance
local SCAN_INTERVAL = 0.03     -- Time between scan cycles
local HASH_CELL_SIZE = 2       -- Spatial optimization cell size
```

## Color Customization

The systems color scheme can be configured by changing the color3 values in this tables:

```lua
local possiblePartColors = {
    Color3.new(0.8, 1, 0.7),    -- Soft green
    Color3.new(0.9, 0.6, 1),    -- Light purple  
    Color3.new(1, 0.4, 0.4),    -- Coral red
    Color3.new(0.9, 1, 0.5),    -- Lime yellow
    Color3.new(0.6, 1, 0.6),    -- Mint green
    Color3.new(0.6, 0.6, 1),    -- Sky blue
    Color3.new(1, 0.6, 1),      -- Pink
    Color3.new(1, 0.9, 0.5),    -- Warm yellow
    Color3.new(1, 0.7, 0.6),    -- Peach
}
```

Each object gets a consistent color with slight variation.

## Method Reference

### Core Methods

| Method | Description |
|--------|-------------|
| `StartContinuousScan()` | Begin real-time LiDAR scanning |
| `StopScan()` | Stop the current scan operation |
| `ClearAllParticles()` | Remove all LiDAR particles from workspace |

### Internal Functions

| Function | Purpose |
|----------|---------|
| `CreateParticle(raycastResult, distance)` | Generate a new LiDAR point |
| `ChooseParticleColor(object)` | Assign colors with variation |
| `IsParticleNearby(position)` | Spatial collision detection |
| `GetOrganicScanDirection(baseDirection, spread)` | Generate natural scan patterns |
| `CleanupParticles()` | Memory management for old particles |

## Technical Details

### Spatial Hashing
The system uses a 3D spatial hash grid for O(1) collision detection, preventing particle overlap while maintaining performance.

### Organic Scanning Pattern
Multi-layered noise functions create non-uniform scanning behavior:
```lua
local noiseX = math.sin(time * 0.7) * 0.3 + math.sin(time * 1.3) * 0.2 + math.sin(time * 2.1) * 0.1
local noiseY = math.sin(time * 0.9) * 0.3 + math.sin(time * 1.7) * 0.2 + math.sin(time * 2.3) * 0.1
```

## Usage Examples

### Security Scanner
```lua
-- Continuous area monitoring
LIDARModule.StartContinuousScan()
-- Particles persist for 45 seconds, perfect for surveillance
```

### Archaeological Survey  
```lua  
-- Quick environment mapping
LIDARModule.StartContinuousScan()
task.wait(5) -- Scan for 5 seconds
LIDARModule.StopScan()
-- Particles remain visible for analysis
```

### Interactive Exploration
```lua
-- Player-controlled scanning tool
-- See tool integration example above
```
