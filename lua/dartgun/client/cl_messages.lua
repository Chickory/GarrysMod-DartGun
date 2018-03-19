// Client side net message

net.Receive("DartGun_DartType", function(len)
	local ColD = net.ReadString() // Color Dart Type
	local Dart = net.ReadString() // Dart Type
	
	// Chat Message
	chat.AddText(Color(170,170,170), "Dart type changed to ", string.ToColor(ColD), Dart)
	
	// Chat Sound
	chat.PlaySound()
end)

hook.Add("HUDPaint", "WarnLocalPlyMute", function()
	if (LocalPlayer():GetNWInt("fon_muteness") == 1) then
		draw.DrawText("You have been muted!", "Trebuchet24", ScrW() * 0.5, (ScrH() * 0.25)-80, Color(0, 150, 255, 255), TEXT_ALIGN_CENTER)
	end
end)