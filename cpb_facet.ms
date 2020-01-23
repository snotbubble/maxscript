--keywords: facet, planar, smooth
/*
makes rounded objects more angular.
useful for making debris and modifying terrain.
by c.p.brown. 2009.
*/

opv = #()
m = 0

rollout rfacet "facet" width:120 height:144
(
	spinner fval "" pos:[56,8] width:56 height:16 range:[2,100,3] type:#integer scale:1
	label lbl1 "detail" pos:[8,8] width:40 height:16
	button doit "go" pos:[8,80] width:104 height:24
	button undoit "reset" pos:[8,112] width:104 height:24 enabled:false
	progressBar progbar "ProgressBar" pos:[-500,80] width:104 height:24	
	spinner dth "" pos:[56,32] width:56 height:16 range:[0.01,1000,0.5] type:#float scale:0.1

	label lbl2 "maxdist" pos:[8,32] width:40 height:16
	radioButtons forv "" pos:[8,56] width:114 height:16 labels:#("faces", "verts") columns:2
	
	on rfacet open do(
		if classof selection[1] == editable_mesh and selection[1].modifiers.count == 0 then(
			m = selection[1]
			for i = 1 to m.numverts do(append opv m.verts[i].pos)	
		)
	)
	on doit pressed do(
		if classof selection[1] == editable_mesh and selection[1].modifiers.count == 0 then(
			faceorverts = (forv.state - 1)
			undoit.enabled = true
			progbar.pos.x = 8
			if m == 0 or m != selection[1] do(opv = #(); for i = 1 to selection[1].numverts do(append opv selection[1].verts[i].pos))
			m = selection[1]
			
				nv = m.numverts
				nf = m.numfaces
				
			rp = for i = 1 to nv collect m.verts[i].pos
			
			n = #(#(),#(),#())
			g = #()
			tfacet = #(#())
			granules = (fval.value as float)
			
			if faceorverts == 1 then(cc = nv)else(cc = nf)
			for v = 1 to cc do(
				if faceorverts == 1 do(nn = (normalize (getnormal m v)))
				if faceorverts == 0 do(nn = (normalize (getfacenormal m v)))
				append n[1] nn[1]
				append n[2] nn[2]
				append n[3] nn[3]
			)
			maxx = (((amax n[1]) + 1.0) / 2.0)
			maxy = (((amax n[2]) + 1.0) / 2.0)
			maxz = (((amax n[3]) + 1.0) / 2.0)
			for i = 1 to n[1].count do(
				ox = ((n[1][i] + 1.0) / 2.0)
				gx = (((ox / maxx) * granules) as integer)

				oy = ((n[2][i] + 1.0) / 2.0)
				gy = (((oy / maxy) * granules) as integer)

				oz = ((n[3][i] + 1.0) / 2.0)
				gz = (((oz / maxz) * granules) as integer)
				
				--format"g=%\n"[gx,gy,gz]
				append g [gx,gy,gz]
			)

			gcl = #()

			for i = 1 to g.count do(
				gcol = (color ((g[i][1] / granules) * 255.0) ((g[i][2] / granules) * 255.0) ((g[i][3] / granules) * 255.0))
				--setvertcolor m i gcol
				append gcl gcol
			)

			facets = #()


			tagged = #(); for i = 1 to cc do(append tagged false)
			for i = 1 to cc where tagged[i] == false do(
				--format"tagged[%] = %\n"i tagged[i]
				facet = #(i)
				tagged[i] = true
				j = 0
				while j <= facet.count do(
					if faceorverts == 1 then(
						ea = meshop.getedgesusingvert m facet
						ev = meshop.getvertsusingedge m ea
					)else(
						fv = meshop.getvertsusingface m facet
						ev = meshop.getfacesusingvert m fv						
					)
					for v in ev where tagged[v] == false do(
						--format"[%] : % == % : %\n"v gcl[v] gcl[i] (gcl[v] == gcl[i])
						if gcl[v] == gcl[i] do(
							if finditem facet v == 0 do(
								append facet v
								tagged[v] = true
							)
						)
					)
					if keyboard.escPressed == true do(exit)
					j += 1
				)
				if facet.count != 0 do(
					--format"facet=%\n"facet
					append facets facet
				)
				progbar.value = 100.*i/cc
			)
			undo "facet" on(
				for v in facets do(
					if faceorverts == 1 then(
						meshop.makevertsplanar m v
						for u in v do(
							while (distance m.verts[u].pos rp[u]) > dth.value do(
								m.verts[u].pos = ((m.verts[u].pos + rp[u]) / 2.0)
								if keyboard.escPressed == true do(exit)
							)
						)
					)else(
						meshop.makefacesplanar m v
						for fs in v do(
							fv = getface m fs
							for u = 1 to 3 do(
								while (distance m.verts[(fv[u])].pos rp[(fv[u])]) > dth.value do(
									m.verts[(fv[u])].pos = ((m.verts[(fv[u])].pos + rp[(fv[u])]) / 2.0)
									if keyboard.escPressed == true do(exit)
								)
							)
						)
					)
				)
				update m
				addmodifier m (smooth())
				m.modifiers[1].autosmooth = true
				m.modifiers[1].threshold = 20.0
				collapsestack m
				converttomesh m
			)
			progbar.value = 0.0
			progbar.pos.x -= 500
		)else(messagebox"not a collapsed editable mesh")
	)
	on undoit pressed do(
		if opv.count != 0 and m == selection[1] and m.modifiers.count == 0 do(
			try( for i = 1 to m.numverts do(m.verts[i].pos = opv[i]) )catch(messagebox"restore failed, the topology is probably different")
			update m
			addmodifier m (smooth())
			m.modifiers[1].autosmooth = true
			m.modifiers[1].threshold = 45.0
			collapsestack m
			converttomesh m			
		)
	)
)
createdialog rfacet

	
	