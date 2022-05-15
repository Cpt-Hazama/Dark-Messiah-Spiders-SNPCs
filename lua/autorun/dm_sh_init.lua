if(!SLVBase_Fixed) then
	include("slvbase/slvbase.lua")
	if(!SLVBase_Fixed) then return end
end
local addon = "Dark Messiah"
if(SLVBase_Fixed.AddonInitialized(addon)) then return end
if(SERVER) then
	AddCSLuaFile("autorun/dm_sh_init.lua")
	AddCSLuaFile("dm_init/dm_sh_concommands.lua")
	AddCSLuaFile("autorun/slvbase/slvbase.lua")
end
SLVBase_Fixed.AddDerivedAddon(addon,{tag = "Dark Messiah"})
if(SERVER) then
	Add_NPC_Class("CLASS_SPIDER")
end
SLVBase_Fixed.InitLua("dm_init")

local Category = "Dark Messiah"
SLVBase_Fixed.AddNPC(Category,"Spider","npc_spider")
SLVBase_Fixed.AddNPC(Category,"Spider Monster","npc_spider_monster")