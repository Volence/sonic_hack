	dc.w	Plant_Idle - Pitcher_Plant_Badnik_Animate
	dc.w	Poison_Bullet - Pitcher_Plant_Badnik_Animate
	dc.w	Plant_Shooting - Pitcher_Plant_Badnik_Animate
Plant_Idle:	dc.b	$0F, 00, $FF       ;Idle. Or would be, but Buzzer moves. $0F is the speed. $00 is the frame number.
Poison_Bullet:	dc.b	$03, $05, $FF  ;Bullets.
Plant_Shooting:	dc.b	$09, $01, $02, $03, $04, $01, $FE, 1 ;Shooting animation.