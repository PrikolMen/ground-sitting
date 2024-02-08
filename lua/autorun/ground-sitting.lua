local addonName = "Ground Sitting"
local PLAYER, ENTITY = FindMetaTable("Player"), FindMetaTable("Entity")
local isSittingOnGround = nil
do
	local GetNW2Bool = ENTITY.GetNW2Bool
	isSittingOnGround = function(self)
		return GetNW2Bool(self, addonName)
	end
	PLAYER.IsSittingOnGround = isSittingOnGround
end
do
	local GetButtons, SetButtons, SetSideSpeed, SetForwardSpeed, SetUpSpeed
	do
		local _obj_0 = FindMetaTable("CMoveData")
		GetButtons, SetButtons, SetSideSpeed, SetForwardSpeed, SetUpSpeed = _obj_0.GetButtons, _obj_0.SetButtons, _obj_0.SetSideSpeed, _obj_0.SetForwardSpeed, _obj_0.SetUpSpeed
	end
	local GetMoveType, IsOnGround = ENTITY.GetMoveType, ENTITY.IsOnGround
	local Alive, InVehicle = PLAYER.Alive, PLAYER.InVehicle
	local bor, band, bxor
	do
		local _obj_0 = bit
		bor, band, bxor = _obj_0.bor, _obj_0.band, _obj_0.bxor
	end
	local MOVETYPE_WALK = MOVETYPE_WALK
	local IN_SPEED = IN_SPEED
	local IN_JUMP = IN_JUMP
	local IN_DUCK = IN_DUCK
	local IN_DUCK_WITH_JUMP = bor(IN_JUMP, IN_DUCK)
	hook.Add("SetupMove", addonName, function(self, mv)
		if not isSittingOnGround(self) then
			return
		end
		if SERVER and (not Alive(self) or GetMoveType(self) ~= MOVETYPE_WALK or InVehicle(self) or not IsOnGround(self)) then
			self:RequestSittingOnGround(false)
			return
		end
		local buttons = GetButtons(mv)
		if band(buttons, IN_DUCK) == IN_DUCK then
			buttons = bxor(bor(buttons, IN_SPEED), IN_SPEED)
		else
			SetForwardSpeed(mv, 0)
			SetSideSpeed(mv, 0)
			SetUpSpeed(mv, 0)
		end
		return SetButtons(mv, bxor(bor(buttons, IN_DUCK_WITH_JUMP), IN_JUMP))
	end)
end
do
	local Length2DSqr = FindMetaTable("Vector").Length2DSqr
	local ACT_HL2MP_IDLE = ACT_HL2MP_IDLE
	local LookupSequence = ENTITY.LookupSequence
	hook.Add("CalcMainActivity", addonName, function(self, velocity)
		if isSittingOnGround(self) and Length2DSqr(velocity) < 1 then
			return ACT_HL2MP_IDLE, LookupSequence(self, "pose_ducking_02")
		end
	end)
end
if not SERVER then
	return
end
do
	local TraceLine = util.TraceLine
	local trace = { }
	hook.Add("PlayerGroundSit", addonName, function(self, reqested)
		if not reqested then
			return
		end
		if not (self:Crouching() and self:IsOnGround()) then
			return false
		end
		trace.start = self:GetShootPos()
		trace.endpos = trace.start + self:GetAimVector() * 72
		trace.filter = self
		local traceResult = TraceLine(trace)
		if not traceResult.Hit then
			return false
		end
		if self:EyeAngles()[1] < 80 then
			return false
		end
	end)
end
do
	local Call = hook.Call
	PLAYER.RequestSittingOnGround = function(self, reqested, force)
		if isSittingOnGround(self) == reqested then
			return false
		end
		if not force and Call("PlayerGroundSit", nil, self, reqested) == false then
			return false
		end
		self:SetNW2Bool(addonName, reqested)
		self.m_bNextGroundSit = CurTime() + 1
		return true
	end
end
hook.Add("KeyPress", addonName, function(self, key)
	if IN_USE == key then
		return self:RequestSittingOnGround(true)
	elseif IN_JUMP == key then
		return self:RequestSittingOnGround(false)
	end
end)
return concommand.Add("ground_sit", function(self)
	if (self.m_bNextGroundSit or 0) > CurTime() then
		return
	end
	return self:RequestSittingOnGround(not isSittingOnGround(self))
end)
