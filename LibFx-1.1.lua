--[[
Name: LibFx-1.1
Author: Cargor (xconstruct@gmail.com)
Dependencies: LibStub
License: GPL 2
Description: Animations! And these actually work ... unlike Blizz' ones
]]

local MAJOR, MINOR = "LibFx-1.1", 1
local LibFx = LibStub:NewLibrary(MAJOR, MINOR)

if not LibFx then return end

local ramps, anims, running = {}, {}, {}
local numRunning = 0


--[[*****************************
	LibFx:RegisterAnimation(name, func, startFunc)
	Registers a new animation for use within LibFx
	-	name = Name of animation
	-	get = Function for getting the initial value
	-	set = Function for setting the value
*******************************]]
function LibFx.RegisterAnimation(name, get, set)
	if(not anims[name]) then
		anims[name] = {Get = get, Set = set}
		return anims[name]
	end
end

function LibFx.GetAnimationByName(name)
	return anims[name]
end

function LibFx.AnimationsIterator()
	return pairs(anims)
end

--[[*****************************
	LibFx:RegisterRamp(name, func)
	Registers a new ramp for use within LibFx
	-	name = Name of ramp
	-	func = Function which returns the value to use
*******************************]]
function LibFx.RegisterRamp(name, func)
	if(not ramps[name]) then ramps[name] = func end
end

function LibFx.GetRampByName(name)
	return ramps[name]
end

function LibFx.RampIterator()
	return pairs(ramps)
end

--[[*****************************
	LibFx.New(fx)
	Creates a new fx-object
	-	fx = table holding options
*******************************]]
local mt = {
__index = LibFx,
__call = function(self, ...) self:Start() end,
}
function LibFx.New(fx)
	assert(fx, MAJOR..": No fx-table specified")
	fx = setmetatable(fx, mt)
	if(type(fx.anim) == "string") then fx.anim = anims[fx.anim] end
	assert(fx.anim, MAJOR..": Animation not specified")
	if(type(fx.ramp) == "string") then fx.ramp = ramps[fx.ramp] end
	if(not fx.ramp) then fx.ramp = ramps["Linear"] end
	assert(fx.ramp, MAJOR..": Ramp not specified")
	if(not fx.frame) then fx.frame = frame end
	assert(fx.frame, MAJOR..": Frame not specified")
	if(not fx.duration) then fx.duration = 1 end
	return fx
end

--[[*****************************
	LibFx:Start()
	Starts an existing Fx
*******************************]]
function LibFx.Start(fx)
	if(not fx or running[fx]) then return end
	fx.anim.Get(fx)
	fx.runTime = 0
	if(numRunning == 0) then LibFx.Updater:Show() end
	running[fx] = true
	numRunning = numRunning + 1
	if(fx.onStart) then fx.onStart(fx.frame, fx) end
end

--[[*****************************
	LibFx:Stop()
	Ends an existing Fx
*******************************]]
function LibFx.Stop(fx)
	if(not fx or not running[fx]) then return end

	numRunning = numRunning - 1
	running[fx] = nil
	if(fx.onComplete) then fx.onComplete(fx.frame, fx) end
	if(numRunning == 0) then LibFx.Updater:Hide() end
end

--[[*****************************
	LibFx:IsRunning()
	Returns wether the fx is currently running
*******************************]]
function LibFx.IsRunning(fx)
	return running[fx]
end

--[[*****************************
	Private functions
*******************************]]

local updateFrame = CreateFrame"Frame"
function updateFrame:Update(elapsed)
	for fx, _ in pairs(running) do
		fx.runTime = fx.runTime + elapsed
		local progress = min(fx.runTime/fx.duration, 1)
		fx.progress = fx.ramp and fx.ramp(progress) or progress
		fx.anim.Set(fx)
		if(fx.runTime > fx.duration) then
			fx:Stop()
		end
	end
end
updateFrame:SetScript("OnUpdate", updateFrame.Update)
updateFrame:Hide()
LibFx.Updater = updateFrame



--[[*****************************
	Default functions
*******************************]]
LibFx.RegisterRamp("Smooth", function(percent) return 1/(1+2.7^(-percent*12+6)) end)

LibFx.RegisterAnimation("Alpha", function(fx)
	fx.start = fx.frame:GetAlpha()
	fx.diff = fx.finish - fx.start
end, function(fx)
	fx.frame:SetAlpha(fx.start + fx.diff * fx.progress)
end)

LibFx.RegisterAnimation("Scale", function(fx)
	fx.start = fx.frame:GetScale()
	fx.diff = fx.finish - fx.start
end, function(fx)
	fx.frame:SetScale(fx.start + fx.diff * fx.progress)
end)

LibFx.RegisterAnimation("Height", function(fx)
	fx.start = fx.frame:GetHeight()
	fx.diff = fx.finish - fx.start
end, function(fx)
	fx.frame:SetHeight(fx.start + fx.diff * fx.progress)
end)

LibFx.RegisterAnimation("Width", function(fx)
	fx.start = fx.frame:SetWidth()
	fx.diff = fx.finish - fx.start
end, function(fx)
	fx.frame:GetWidth(fx.start + fx.diff * fx.progress)
end)

LibFx.RegisterAnimation("Translate", function(fx)
	local p = fx.p or {}
	fx.p = p
	p[1], p[2], p[3], p[4], p[5] = fx.frame:GetPoint()
end, function(fx)
	local frame, p = fx.frame, fx.p
	local x = p[4] + (fx.xOffset or 0) * fx.progress
	local y = p[5] + (fx.yOffset or 0) * fx.progress
	frame:ClearAllPoints()
	frame:SetPoint(p[1], p[2], p[3], x, y)
end)