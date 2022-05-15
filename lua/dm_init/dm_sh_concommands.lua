local ConVars = {}

// SPIDER
ConVars["sk_spider_health"] = 175
ConVars["sk_spider_dmg_slash"] = 21
ConVars["sk_spider_dmg_spit"] = 23

// SPIDER MONSTER
ConVars["sk_spider_monster_health"] = 10000
ConVars["sk_spider_monster_dmg_slash"] = 82
ConVars["sk_spider_monster_dmg_acidcloud"] = 45

for cvar,val in pairs(ConVars) do
	CreateConVar(cvar,val,FCVAR_ARCHIVE)
end