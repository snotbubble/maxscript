obj = $.mesh
defaultvcfaces obj
for i = 1 to obj.numverts do(
	setvertColor obj i (color 0 0 0)
)
update obj
$.showvertexcolors = true

nv = $.numverts
na = #()
for i = 1 to nv do(
	navt = #()
	edgr = (meshop.getEdgesUsingVert obj i)
	for e in edgr do(
		d = ((meshop.getVertsUsingEdge obj e) as array)
		for v in d do(
			-- format"collecting vert: %\n"v
			if v != i do(
				if finditem navt v == 0 do(
					append navt v
				)
			)
		)
	)
	append na navt
)
seednum = 5
global sd = #()
for i = 1 to seednum do(
	append sd (random 1 nv)
)
for i in sd do(
	setvertcolor obj i (color 255 255 255)
)
update obj
global g = 0
while g < sd.count do(
	nsd = #()
	for i in sd do(	
		obj.selectedVerts = #(i)
		dr = (random 1 na[i].count)
		--format"current vert: %\n"i
		--format"current neighbours: %\n"na[i]
		--format"checking vert: %\n"na[i][dr]
		--format"vert color = %\n\n"(getvertcolor obj na[i][dr])
		fh = 0
		for m = 1 to 6 do(
			try(
				if (getvertcolor obj na[i][dr]) != (color 255 255 255) then(
				fh = na[i][dr]; exit
				)else (dr = (random 1 na[i].count))
			)catch()
		)
		if fh != 0 do(
			try(
				bv = 0
				for t = 1 to na[fh].count do(
					if na[fh][t] != fh do(
						if (getvertcolor obj na[fh][t]) != (color 255 255 255) do(
							bv += 1
						)
					)
				)
				--format"bv = %, of: %\n"bv (na[fh].count - 1)
				if bv == (na[fh].count - 1) do(
					append nsd fh
					setvertcolor obj na[i][dr] (color 255 255 255)
					update obj
				)
			)catch()
		)
	)
	join sd nsd
	-- sd = nsd
	g += 1
	gc()
	format"itteration %, of %\n"g sd.count
)
		
