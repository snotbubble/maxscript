/*
lazy-arse-parameter-editor.
a rollout for all int, bool and float params
available for selected objects.

idea: Andrew Melnychuk Oseen.
code: c.p.brown, 2007~2009.
*/
prp = #(#(), #(), #())
global oprp = #(#(), #())
for i in selection do(
  
	for p in (getPropNames i) do(
		if finditem prp[1] (p as string) == 0 do(
			append prp[1] (p as string)
			append prp[2] (getproperty i p)
			append prp[3] (classof (getproperty i p))
		)
	)
	append oprp[1] i.name
	append oprp[2] prp
	prp = #(#(), #(), #())
)
format"oprp=%\n"oprp

global aro = (createfile (scriptspath + "testRollout" + ".ms"))

for r = 1 to oprp[1].count do (
	format"rollout % \"%\" (\n" ("roll" + (r as string)) oprp[1][r] to:aro
	format"rollout % \"%\" (\n" ("roll" + (r as string)) oprp[1][r]
	for i = 1 to oprp[2][r][1].count do(
		format"classof i =%\n"(classof oprp[2][r][3][i])
		case (oprp[2][r][3][i]) of(
			float: (format"spinner spn_% \"%\" range:[0, 1000, %] fieldwidth:60\n"i oprp[2][r][1][i] oprp[2][r][2][i] to:aro) 
			integer: (format"spinner spn_% \"%\" range:[0, 1000, %] fieldwidth:60\n"i oprp[2][r][1][i] oprp[2][r][2][i] to:aro) 
			booleanclass: (format"checkbox chq_% \"%\" checked:% width:120\n"i oprp[2][r][1][i] oprp[2][r][2][i] to:aro) 
		)
	)
	
	for i = 1 to oprp[2][r][1].count do (
		case (oprp[2][r][3][i]) of(
			float: (format"on spn_% changed val do(  $'%'.% = val )\n"i oprp[1][r] oprp[2][r][1][i] to:aro) 
			integer: (format"on spn_% changed val do(  $'%'.% = val )\n"i oprp[1][r] oprp[2][r][1][i] to:aro) 
			booleanclass: (format"on chq_% changed val do(  $'%'.% = val )\n"i oprp[1][r] oprp[2][r][1][i] to:aro) 
		)
	)
	format")\n" to:aro
)

close aro

global arollout = filein (scriptspath + "testRollout" + ".ms")


--createdialog tester 600
aflt = newrolloutfloater "params" 200 600
for r = 1 to oprp[1].count do(
	execute("addrollout " + ("roll" + (r as string)) + " aflt")
)
