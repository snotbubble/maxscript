/*
aligns a UV gizmo to a face.
works with a sub-object selection.
by c.p.brown. 2008~2009.
*/
(
pfidx = 0
global grmapface = 0

function bboxfromselectedfaces m fc = (
	minx = 100000
	miny = 100000
	minz = 100000
	maxx = -10000
	maxy = -10000
	maxz = -10000
	for i in fc do(
		-- format"processing face %\n"i	
		v = (getface m i)
		for p = 1 to 3 do(
			vp = m.verts[(v[p])]
			if vp.pos.x < minx do(minx = vp.pos.x)
			if vp.pos.y < miny do(miny = vp.pos.y)
			if vp.pos.z < minz do(minz = vp.pos.z)
			
			if vp.pos.x > maxx do(maxx = vp.pos.x)
			if vp.pos.y > maxy do(maxy = vp.pos.y)
			if vp.pos.z > maxz do(maxz = vp.pos.z)
			-- format"processing vertex %\n"vp	
		)
	)
	midx = (minx + ((maxx - minx) / 2))
	midy = (miny + ((maxy - miny) / 2))
	midz = (minz + ((maxz - minz) / 2))
	-- format"--------------------------bounds = %\n"#([minx, miny, minz],[maxx, maxy, maxz],[midx,midy,midz])	
	return #([minx, miny, minz],[maxx, maxy, maxz],[midx,midy,midz])	
)

function alignpointtoface obj fc edg alm = (
	
	pp = #()
	
	if alm == true then(
		fna = #()
		zz = [0,0,0]
		for i in obj.selectedfaces do(
			append fna (getfacenormal obj i.index)
		)
		for i in fna do(zz[1] = (zz[1] + i[1])); zz[1] = ( (zz[1] / fna.count) )
		for i in fna do(zz[2] = (zz[2] + i[2])); zz[2] = ( (zz[2] / fna.count) )
		for i in fna do(zz[3] = (zz[3] + i[3])); zz[3] = ( (zz[3] / fna.count) )
		zz = (normalize(zz))
		format"average normal = %\n"zz
		fna = 0
	)else(
		zz = (normalize(getFaceNormal obj fc))
		format"facenormal=%\n"zz
	)
	
	-- format"zz = %\n"(normalize(getFaceNormal obj fc))
	
	apos = [0,0,0]
	avert = (getFace obj fc) 
	pp[1] = obj.verts[(avert[1])].pos
	apos += pp[1]
	pp[2] = obj.verts[(avert[2])].pos
	apos += pp[2]
	pp[3] = obj.verts[(avert[3])].pos
	apos += pp[3]
	apos = (apos / 3)
	edir = 0
	case edg of(
		1: (edir = (normalize (pp[1] - pp[2]) ) )
		2: (edir = (normalize (pp[2] - pp[3]) ) )
		3: (edir = (normalize (pp[3] - pp[1]) ) )
	)	

	-- xx = normalize(cross zz obj.dir)
	xx = normalize(cross zz edir)
	yy = normalize(cross xx zz)
	anxf = 0
	if fz == 0 then(
		anxf = matrix3 xx yy zz [0,0,0]
	)else(
		anxf = matrix3 xx yy -zz [0,0,0]
	)
	return #(anxf, apos)
	
)
fn mapface_startstroke = (
	thepainterinterface.undostart()
	barys = [0,0,0]
	fidx = 0
	amhit = thepainterinterface.gettesthit mouse.pos
	
	if amhit == true do(
		thepainterinterface.getcustomhitfacedata &barys &fidx $
		pfidx = fidx	
		grmapface.facesel.text = (pfidx as string)
		thepainterinterface.endpaintsession()
	)
)
fn paintstroke = ()
fn endstroke = (thepainterinterface.undoaccept())
fn cancelstroke = (thepainterinterface.undocancel())
fn systemend = (thepainterinterface.endpaintsession())

rollout rmapface "mapface" width:160 height:280
(
	button domap "map" pos:[8,240] width:144 height:24
	checkbox collapseme "collpase stack" pos:[24,208] width:88 height:14 checked:true
	-- spinner facen "" pos:[72,32] width:56 height:16 range:[0,100,1] type:#integer
	-- label lbl1 "face:" pos:[24,32] width:32 height:16
	button facesel "pick face" pos:[72,32] width:56 height:16
	checkbox avgnorm "use average normal" pos:[24,88] width:112 height:16
	
	spinner edgen "" pos:[72,56] width:56 height:16 range:[1,3,1] type:#integer
	label lbl2 "edge:" pos:[24,56] width:32 height:16
	groupBox grp1 "align" pos:[8,8] width:144 height:104
	groupBox grp2 "scale" pos:[8,120] width:144 height:56
	checkbox squareme "square" pos:[24,144] width:56 height:16
	groupBox grp3 "tidy" pos:[8,184] width:144 height:48

	on rmapface open do(
		grmapface = rmapface
	)
		
	on facesel pressed do(
		if (thepainterinterface.inpaintmode() != true) then(
			thepainterinterface.scriptfunctions mapface_startstroke paintstroke endstroke cancelstroke systemend 	
			nodelist = $
			thepainterinterface.drawnormal = true
			thepainterinterface.drawring = true
			thepainterinterface.drawtrace = false
			thepainterinterface.initializenodes 0 nodelist 
			thepainterinterface.markerenable = false
			thepainterinterface.maxsize = 2
			thepainterinterface.maxstr = 2
			thepainterinterface.mirrorenable = false
			thepainterinterface.pointgatherenable = true
			thepainterinterface.pressureenable = false
			thepainterinterface.startpaintsession()	
			thepainterinterface.treedepth = 2
			thepainterinterface.updateonmouseup = false
			format"picked face: %\n"pfidx
		)else(thepainterinterface.endpaintsession())
	)	
	on domap pressed do(
		if ($.selectedfaces).count != 0 do(
			-- xf = (alignpointtoface $ ($.selectedfaces)[facen.value].index 1 1 0 edgen.value avgnorm.state)
			format"pfidx=%\n"pfidx
			xf = (alignpointtoface $ pfidx edgen.value avgnorm.state)
			amod = uvwmap()
			-- format"\nworld pos=%\n"xf[1]	
			objtm=$.objecttransform
			modpanel.addmodtoselection amod ui:on
			modtm=(getmodcontexttm $ amod)
			amod.gizmo.transform = (xf[1] * (inverse modtm))
			-- amod.gizmo.pos = (xf[2] * ( modtm) * (inverse objtm))
			abb = (bboxfromselectedfaces $ ((getfaceselection $) as array))
			-- format"getting selection center : %\n"abb
			amod.gizmo.pos = (abb[3] * (modtm) * (inverse objtm))
			amod.width = (abb[2][1] - abb[1][1])
			amod.length = (abb[2][2] - abb[1][2])
			if squareme.checked do(if amod.length > amod.width then(amod.width = amod.length)else(amod.length = amod.width))
			if collapseme.checked do(collapsestack $; subobjectlevel = 4)
		)
	)
)
createdialog rmapface
)
