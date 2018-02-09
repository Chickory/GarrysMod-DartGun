// DartGun Config Table----------------------------------------------------------------------
DartGun = {}

//-------------------------------------------------------------------------------------------
include("sh_config.lua")

if SERVER then
	AddCSLuaFile()
	AddCSLuaFile("sh_config.lua")
	AddCSLuaFile("dartgun/client/cl_messages.lua")
	include("dartgun/server/sv_messages.lua")
	include("dartgun/forcedownloads.lua")
else
	include("dartgun/client/cl_messages.lua")
end
//-------------------------------------------------------------------------------------------