--local LightFrame = CreateFrame("FRAME",Minimap,"MinimapLightFrame")
--LightFrame:SetAllPoints()
local name,self = ...

local lines_tap = {"%s got tapped.", "%s got tapped, sorry.", "%s got tapped... Too bad."}
local lines_coords = {"%s is located at %s, %s.", "%s has spawned at %s, %s.", "%s lurks at %s, %s."}
local lines_coords_same = {"%s is still at %s, %s.", "%s hasn't moved from %s, %s.", "%s still resides at %s, %s."}
local lines_full = {"waiting for a whack","still looking healthy","oblivious to its doom","looking bored","happy as a lark","looking lively","whistling a happy tune","twiddling their thumbs"}
local lines_hp = {"at %d%% health","%d%% healthy","getting whacked to %d%% health","with %d%% health to go"}
local lines_ttl = {", should die in %ds",", won't last more than %ds",", has about in %ds to live",", life expectancy: %ds"}
local lines_dead = {"%s is dead. RIP.", "%s is now an ex-monster.", "%s is no more.", "%s is down for the count.", "%s is now, unfortunately, deceased.","%s is dead, Jim.","%s is down.","%s is out of the game."}

local function rand(arr)
	return arr[random(#arr)]
end

local lastrares={}
local ttl={}
local function RareAnnounce()
	local name=UnitName("target")
	if not name then print("No target.") return end
	local recently=GetTime()-(lastrares[name] or 0)<60*5
	if UnitIsDead("target") then
		SendChatMessage(rand(lines_dead):format(name),"CHANNEL",7,1)
		lastrares[name]=nil
	elseif UnitClassification("target"):find("rare") then
		if UnitIsTapDenied("target") then
			SendChatMessage(rand(lines_tap):format(name),"CHANNEL",7,1)
		else
			local map=C_Map.GetBestMapForUnit("player")
			local co=C_Map.GetPlayerMapPosition(map,"player")
			local mp=UiMapPoint.CreateFromCoordinates(map,co.x,co.y)
			C_Map.SetUserWaypoint(mp)
			local hp = UnitHealth("target") / UnitHealthMax("target") * 100
			local linefullhp = hp==100 and lines_full or lines_hp
			local ttl = ttl[name] and ttl[name].ttl
			local ttlline = ttl and rand(lines_ttl):format(ttl) or ""
			--SendChatMessage(rand(recently and lines_coords_same or lines_coords):format(name,co.x*100,co.y*100,rand(linefullhp):format(hp) .. ttlline),"CHANNEL",7,1)
			local pin = C_Map.GetUserWaypointHyperlink()
			SendChatMessage(rand(recently and lines_coords_same or lines_coords):format(name,pin,rand(linefullhp):format(hp) .. ttlline),"CHANNEL",7,1)
			C_Map.ClearUserWaypoint()
			lastrares[name]=GetTime()
		end
	else
		print(name.." is not a rare.")
	end
end

local interval=0.2
local t=0
local lasttarget
local function onupdate(f,elapsed)
	t=t+elapsed  if t<interval then return end  t=0
	if true or UnitClassification("target"):find("rare") then
		local name=UnitName("target")  if not name then return end
		local hp = UnitHealth("target") / (UnitHealthMax("target") or 1)  if hp<0.01 or hp>0.99 then ttl[name]=nil return end
		if not ttl[name] or GetTime()-ttl[name].start>3*60 then
			ttl[name]={start=GetTime(),hp=hp}
			--print("Started counting TTL for "..name)
			return
		end
		local time=GetTime()-ttl[name].start  -- fight time
		local hplost = ttl[name].hp - hp
		local hpsec = hplost/time
		local remain = hp/hpsec
		ttl[name].ttl = remain
	end
end
F = CreateFrame("FRAME","RareAnnounceFrame")
F:SetScript("OnUpdate",onupdate)


SLASH_RARE1 = "/rare"
function SlashCmdList.RARE(text)  RareAnnounce()  end

