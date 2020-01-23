moda = 0

fn getstack obj = (
	mods = #()
	for i = 1 to obj.modifiers.count do(
		append mods obj.modifiers[i]
	)
	return mods
)

fn putstack obj mods = (
	for i = mods.count to 1 by -1 do(
		addmodifier obj mods[i]
	)
)


rollout ramfacing "amfacing" width:88 height:264
(
	radioButtons faceorvertex "" pos:[8,8] width:52 height:32 labels:#("face", "vertex")

	button screen "from screen" pos:[8,144] width:72 height:16
	button rb "select" pos:[8,192] width:72 height:16
	button btz "Z" pos:[8,96] width:16 height:16
	button bty "Y" pos:[8,72] width:16 height:16
	button btx "X" pos:[8,48] width:16 height:16
	
	spinner vz "" pos:[32,96] width:48 height:16 range:[-1,1,0] scale:0.1
	spinner vy "" pos:[32,72] width:48 height:16 range:[-1,1,0] scale:0.1
	spinner vx "" pos:[32,48] width:48 height:16 range:[-1,1,1] scale:0.1
	spinner th "" pos:[32,120] width:48 height:16 range:[0.01,0.99,0.01] scale:0.01
	
	label lbl4 "Th" pos:[8,120] width:16 height:16 
	
	checkbox dovcol "+colour" pos:[8,240] width:64 height:16
	checkbox dorepl "replace" pos:[8,216] width:64 height:16 checked:true
	checkbox doabs "abs" pos:[8,168] width:40 height:16 checked:true

	
	
	on btx pressed do(
		vx.value = 1
		vy.value = 0
		vz.value = 0
	)
	on bty pressed do(
		vx.value = 0
		vy.value = 1
		vz.value = 0
	)
	on btz pressed do(
		vx.value = 0
		vy.value = 0
		vz.value = 1
	)	
	on screen pressed do(
		vd = ((Inverse(getViewTM())).row3)
		vx.value = vd[1]
		vy.value = vd[2]
		vz.value = vd[3]	
	)
	on rb pressed do(
		moda = 0
		for obj in selection do(
			if classof obj == editable_mesh do(
				pobj = snapshot obj
				if faceorvertex.state == 1 then(
					bf = #{1..(pobj.numfaces)}
					for f = 1 to bf.count where bf[f] == true do(
						vn = (getfacenormal pobj f)
						dt = (dot [(vx.value),(vy.value),(vz.value)] vn)
						if doabs.checked then(
							if (abs(dt))  <= (1 - th.value) do(bf[f] = false)
						)else(
							if dt <= (1 - th.value) do(bf[f] = false)
						)
					)
					if dorepl.state == false do(
						fs = getfaceselection obj
						join bf fs
					)
					select obj
					addmodifier obj (mesh_select())
					max modify mode
					setfaceselection obj 1 bf
					if dovcol.checked do(
						if obj.modifiers.count == 0 do(
							defaultVCFaces obj
							for i = 1 to obj.numverts do(setvertcolor obj i (color 0.0 0.0 0.0))
							for i = 1 to bf.count where bf[i] == true do(
								fv = getface obj i
								for v = 1 to 3 do(setvertcolor  obj fv[v] (color 255.0 255.0 255.0))
							)
							update obj
							obj.showvertexcolors = true
						)
					)
					subobjectlevel = 3
					delete pobj
				)else(
					bf = #{1..(pobj.numverts)}
					for f = 1 to bf.count where bf[f] == true do(
						vn = (getnormal pobj f)
						dt = (dot [(vx.value),(vy.value),(vz.value)] vn)
						if doabs.checked then(
							if (abs(dt))  <= (1 - th.value) do(bf[f] = false)
						)else(
							if dt <= (1 - th.value) do(bf[f] = false)
						)
					)
					if dorepl.state == false do(
						fs = getvertselection obj
						join bf fs
					)
					if dovcol.checked do(
						if obj.modifiers.count == 0 do(
							defaultVCFaces  obj
							for i = 1 to obj.numverts do(setvertcolor obj i (color 0.0 0.0 0.0))
							for i = 1 to bf.count where bf[i] == true do(
								setvertcolor obj i (color 255.0 255.0 255.0)
							)
							update obj
							obj.showvertexcolors = true
						)
					)
					select obj
					addmodifier obj (mesh_select())
					max modify mode
					setvertselection obj 1 bf
					subobjectlevel = 1
					delete pobj		
				)
			)
		)
	)
)

createdialog ramfacing
