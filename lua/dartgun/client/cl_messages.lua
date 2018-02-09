// Client side net message

net.Receive("DartGun_DartType", function(len)
	local ColD = net.ReadString() // Color Dart Type
	local Dart = net.ReadString() // Dart Type
	
	// Chat Message
	chat.AddText(Color(170,170,170), "Dart type changed to ", string.ToColor(ColD), Dart)
	
	// Chat Sound
	chat.PlaySound()
end)