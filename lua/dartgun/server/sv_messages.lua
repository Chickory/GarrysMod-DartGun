// Networking
util.AddNetworkString("DartGun_DartType")

local Ply = FindMetaTable("Player")

function Ply:DartGunChat(ColD, Dart)
	// Server side net message
	net.Start("DartGun_DartType")
		net.WriteString(ColD)
		net.WriteString(Dart)
	net.Send(self)
end