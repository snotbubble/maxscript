/*
selects backfacing verts.
can use the animationrange.
optional vertex colour paint.
tip: to preserve the mesh, use in combination with vol-select (vertex colours) 
and deletemesh. make sure 'copy/paste stack' and 'paint vertex colour' are switched on.
occlusion is *very* slow. go grab a coffee if it seems to freeze up.
by c.p.brown. 2008~2009.
*/

c = 0
m = 0
th = 0.5
dm = #()
moda = #()

fn sortbyval s1 s2 = (
	if s1>s2 then 1
	else if s1<s2 then -1
	else 0
)

fn findinarray k t = (
	ret = 0
	for i = 1 to t.count do(
		if t[i]	 == k do(ret = i; exit)
	)
	return ret
)

fn getstack obj = (
	mods = #()
	for i = 1 to obj.modifiers.count do(
		append mods obj.modifiers[i]
	)
	return mods
)

fn putstack obj mods = (
	for i = mods.count to 1 by -1 do(
		modpanel.addmodtoselection mods[i] ui:on	
		-- addmodifier obj mods[i]
	)
)

fn camflt obj = (
	superclassof obj == camera
)

fn meshflt obj = (
	classof obj == editable_mesh
)

rollout rbfc "bfc" width:280 height:416
(
	pickbutton getcam "pick camera" pos:[8,16] width:264 height:24  filter:camflt
	pickbutton getMsh "pick mesh" pos:[8,48] width:264 height:24 filter:meshflt
	
	radiobuttons faceorvert "" pos:[24,104] width:163 height:16 labels:#("faces", "verts (faster)") default:2 columns:2

	spinner thv "" pos:[184,128] width:56 height:16 range:[-1,1,0] scale:0.1
	label lbl1 "back to front threshold  (-1 to 1)" pos:[24,128] width:150 height:16
	
	checkbox chqanim "use animationrange" pos:[24,152] width:120 height:16 checked:false
	checkbox chqvc "paint vertex colours" pos:[24,200] width:120 height:16 checked:false enabled:false
	checkbox chqnostack "use base mesh (temporarily removes the stack)" pos:[24,168] width:248 height:16 checked:false
	checkbox usestack "use modified object (appends a meshselect)" pos:[24,184] width:240 height:16 checked:true
	
	button rb "ok" pos:[8,344] width:264 height:24 enabled:false
	progressBar progbar "" pos:[8,376] width:264 height:8
	progressBar bprogbar "" pos:[8,392] width:264 height:8
	checkbox getunseen "unseen by camera" pos:[24,248] width:112 height:16 checked:true
	checkbox getbackfacing "backfacing from camera" pos:[24,264] width:136 height:16 checked:true
	checkbox getoccluded "occluded (very slow)" pos:[24,280] width:176 height:16
	GroupBox grp1 "select" pos:[8,224] width:264 height:112
	GroupBox grp2 "options" pos:[8,80] width:264 height:144
	label lbl2 "grid" pos:[24,304] width:24 height:16
	spinner gs "" pos:[48,304] width:48 height:16 enabled:false range:[2,100,10] type:#integer scale:1
	spinner thtol "" pos:[208,304] width:48 height:16 enabled:false range:[0.001,1,0.001] scale:0.001
	spinner bi "" pos:[128,304] width:48 height:16 enabled:false range:[0.001,10,0.001] scale:0.001
	label lbl3 "bias" pos:[104,304] width:24 height:16
	label lbl4 "tol" pos:[184,304] width:16 height:16

	on rbfc open do(
		if selection.count != 0 do(
			if classof selection[1] == editable_mesh do(
				m = selection[1]; getmsh.object = m; getmsh.text = m.name; if c != 0 do(rb.enabled = true)
			)
		)
		if cameras.count != 0 do(
			c = cameras[1]; getcam.object = c; getcam.text = c.name; if m != 0 do(rb.enabled = true)
		)
	)
	on getcam picked obj do(c = obj; getcam.text = c.name; if m != 0 do(rb.enabled = true))
	on getmsh picked obj do(m = obj; getmsh.text = m.name; if c != 0 do(rb.enabled = true))
	on usestack changed val do(chqnostack.state = (not val); if val == true then(chqvc.state = false; chqvc.enabled = false)else(chqvc.enabled = true))
	on chqnostack changed val do(usestack.state = (not val); if usestack.state == true then(chqvc.state = false; chqvc.enabled = false)else(chqvc.enabled = true))
	on chqvc changed val do(if usestack.state == true then chqvc.state = false)
	on getoccluded changed val do(
		gs.enabled = val
		bi.enabled = val
		thtol.enabled = val
	)
	on rb pressed do(
		-- disablesceneredraw()
		max display mode
		dm = #()
		broken = 0
		halt = 0
		vba = #{}
		if usestack.checked then(
		)else(
			if chqnostack.checked do(
				moda = getstack m
				while m.modifiers.count > 0 do(deletemodifier m m.modifiers.count)	
			)
			if chqnostack.state == false and m.modifiers.count != 0 then(messagebox"modifiers are present, please use copy/paste stack or collpase the mesh."; broken = 1)
		)
		if broken == 0 do(
			if usestack.state == false do(
				if chqvc.checked do(
					defaultVCFaces m
					for f = 1 to m.verts.count do(setvertcolor m f (color 0.0 0.0 0.0))
					update m
				)
			)
			
			if faceorvert.state == 2 then(for i = 1 to m.numverts do(append vba i))else(for i = 1 to m.faces.count do(append vba i))
			startf = currenttime
			endf = currenttime
			if chqanim.checked do(startf = animationrange.start; endf = animationrange.end)
			ma = 0
			for g = startf to endf do(
				if usestack.checked then(m = snapshot getmsh.object; m.name = "bfc_deleteme"; m.transform = getmsh.object.transform)		
				slidertime = g
				--at time g(
				if halt == 0 do(
					p = c.pos
					d = normalize(c.dir)
					t = (c.fov / 2.0)

					if getunseen.checked do(
						-- if getbackfacing.checked or getoccluded.checked do(
							if faceorvert.state == 2 then(
								for f = 1 to vba.count where vba[f] == true do(
									vd = (normalize (p - (m.verts[f]).pos))
									dt = acos(dot d vd)
									if dt < t do (vba[f] = false)
									if dt > ma do(ma = dt)
								)
							)else(
								for f = 1 to vba.count where vba[f] == true do(
									fv = getface m f
									e = 0
									for v = 1 to 3 do(
										apos = m.verts[(fv[v])].pos
										fd = normalize (p - apos)
										dt = acos(dot d fd)
										if dt < t do(e += 1)
										if dt > ma do(ma = dt)
									)
									if e == 3 do(vba[f] = false)
								)					
							)
						-- )
					)

					if getbackfacing.checked do(
						un = true
						if getunseen.checked do(un = (not un))
						if faceorvert.state == 2 then(
							for f = 1 to vba.count where vba[f] == un do(
								--vd = (normalize (p - (m.verts[f]).pos))
								vn = (getnormal m f)
								dt = (dot d vn)
								co = (dt < thv.value)
								if getunseen.checked do(co = (not co))
								if co then (
									-- format"backfacing vert: %\n"f
									if usestack.state == false do (
										-- format"working on the basemesh\n"
										if chqvc.checked do(
											dtc = (-dt * 255)
											-- format"painting: %\n"dtc
											if dtc > (getvertcolor m f).r do(
												setvertcolor m f (color dtc dtc dtc)
												-- format"set vert color: %\n"dtc
											)
										)
									)
								)else(vba[f] = (not un))
								if keyboard.escPressed == true do(halt = 1; exit)
								progbar.value = 100.*f/m.numverts
								pl = (((100.*f/m.numverts) / 100.0) * 255.0)
								progbar.color = (color 128.0 pl pl)
							)
						)else(
							for f = 1 to vba.count where vba[f] == un do(
								fv = getface m f
								apos = ((m.verts[(fv[1])].pos + m.verts[(fv[2])].pos + m.verts[(fv[3])].pos) / 3)
								fd = normalize (p - apos)
								vn = (getfacenormal m f)
								dt = (dot d vn)
								co = (dt < thv.value)
								if getunseen.checked do(co = (not co))
								if co then (
									dt = (dot fd vn)
									if usestack.state == false do (
										if chqvc.checked do(
											dtc = (-dt * 255)
											if dtc > (getvertcolor m fv[1]).r do(setvertcolor m fv[1] (color dtc dtc dtc))
											if dtc > (getvertcolor m fv[2]).r do(setvertcolor m fv[2] (color dtc dtc dtc))
											if dtc > (getvertcolor m fv[3]).r do(setvertcolor m fv[3] (color dtc dtc dtc))
										)
									)
								)else(vba[f] = (not un))
								if keyboard.escPressed == true do(halt = 1; exit)
								pl = (((100.*f/m.faces.count) / 100.0) * 255.0)
								progbar.color = (color pl pl 128.0)							
								progbar.value = 100.*f/m.faces.count
							)						
						)
					)
					
					if getoccluded.checked do(
						un = true
						if getunseen.checked or getbackfacing.checked do(un = (not un))					
						rm = RayMeshGridIntersect()
						rm.Initialize gs.value
						rm.addNode m
						rm.buildGrid()
						if faceorvert.state == 2 then(
							i = 0
							for f = 1 to vba.count where vba[f] == un do(
								pp = (m.verts[f]).pos
								vd = (normalize (p - pp))
								-- dt = (dot d vd)
								-- if dt > t do (
									i = (rm.intersectSegment (pp + (vd + bi.value)) p true)
									co = (i > 0)
									if co do(
										vba[f] = (not un)
										if usestack.state == false do (
											if chqvc.checked do(
												dtc = 255.0
												if dtc > (getvertcolor m f).r do(setvertcolor m f (color dtc dtc dtc))
											)
										)
									)
								-- )
								if keyboard.escPressed == true do(halt = 1; exit)
								progbar.value = 100.*f/m.numverts
								pl = (((100.*f/m.numverts) / 100.0) * 255.0)
								progbar.color = (color 128.0 pl pl)								
							)
						)else(
							i = 0
							for f = 1 to vba.count where vba[f] == un do(
								fv = getface m f
								e = 0
								for v = 1 to 3 do(
									pp = (m.verts[(fv[v])]).pos
									vd = (normalize (p - pp))
									-- dt = (dot d vd)
									-- if dt > t do (
										i = (rm.intersectSegment (pp + (vd + bi.value)) p true)
										co = (i > 0)
										if co do(
											if (rm.getHitDist i) > thtol.value do(
												e += 1
												if usestack.state == false do (
													if chqvc.checked do(
														dtc = 255.0
														if dtc > (getvertcolor m fv[v]).r do(setvertcolor m fv[v] (color dtc dtc dtc))
													)
												)
											)
										)
									-- )
								)
								if e == 3 do(vba[f] = (not un))
								if keyboard.escPressed == true do(halt = 1; exit)
								progbar.value = 100.*f/m.faces.count
								pl = (((100.*f/m.faces.count) / 100.0) * 255.0)
								progbar.color = (color 128.0 pl pl)								
							)					
						)
						if un == true do(for i = 1 to vba.count do(vba[i] = (not vba[i])))
						rm = 0
					)				
				)
				if chqvc.checked do(update m)
				bprogbar.value = 100.*(g - startf)/(endf - startf)
				if usestack.checked then(delete $bfc_deleteme)
				gc()				
			)
			format"maximum angle detected: %\n"ma
			progbar.value = 0.0
			bprogbar.value = 0.0
			if halt == 0 do(
				select getmsh.object
				max modify mode
				if usestack.checked then(
					addmodifier getmsh.object (mesh_select())
					case faceorvert.state of(
						1: (setfaceselection getmsh.object 1 vba; subobjectlevel = 3)
						2: (setvertselection getmsh.object 1 vba; subobjectlevel = 1)
					)				
				)else(
					
					-- if chqvc.checked do(
						if m.modifiers.count == 0 do(
						-- format"selecting in baseobject...\n"
							case faceorvert.state of(
								1: (setfaceselection getmsh.object vba; subobjectlevel = 3)
								2: (setvertselection getmsh.object vba; subobjectlevel = 1)
							)
						)
					-- )
					if chqnostack.checked do(putstack m moda)
				)
			)
			vba = 0
			progbar.value = 0.0
			bprogbar.value = 0.0
			m = getmsh.object
		)
	)
)
createdialog rbfc
