/*
aligns a point to a face.
can bake the position over time.
alignment uses face edge and face normal;
deforming faces may result in unexpected results.
remembers point-target relationships for quick
re-baking. can batch re-bake.
by c.p.brown. 2008~2009.
*/
(
apos = [0,0,0]
pp = #()
apoint  = 0
pfidx = 0
global lampr_targ = 0
global lampers = #()
thekennel = [356,182]
grlampr = 0

fn sortbynamefast n1 n2 = (
	case (n1.name > n2.name) of(
		true: 1
		false: -1
	)
)

fn pillow anum pad = (
	-- pads anum by pad*zeroes, returns snum as a string.
	snum = ""
	case (anum < 0) of(
		true: (anum = (0 - anum); snum = (anum as string); while snum.count < pad do(snum = ("0" + snum)); snum = ("-" + snum))
		false: (snum = (anum as string); while snum.count < pad do(snum = ("0" + snum)))
	)
	return snum
)

function striplastnums str = (
	astr = str
	nn = (trimright astr "1234567890")
	fp = ""
	if nn.count != str.count do(
		stl = (nn.count)
		if stl != 0 do(
			fp = (replace str 1 stl "")
		)
	)
	return #(nn, fp)
)

function repnumberedname objs txt = (
	format"objs = %\n"objs
	format"name = %\n"txt
	-- onames = (for i on objs collect i.name)
	nf = 0
	pl = 0
	nxn = 1
	stxt = (striplastnums txt)[1]
	oc = objs.count
	for i = 1 to objects.count do(
		if (objects[i].name)[1] == stxt[1] do(
			atn = (striplastnums objects[i].name)
			if atn[1] == stxt do(
				format"% = %, number = %\n"stxt atn[1] atn[2]
				if atn[2] != "" then(
					ig = (atn[2] as integer)
					if ig >= nxn then(nxn = (ig + 1))else()
				)else(nxn = 1)
			)
		)
	)
	format"nxn = %\n"nxn
	plen = ((oc + nxn) as string).count
	for i = 1 to objs.count do(
		objs[i].name = (stxt + (pillow nxn plen))
		nxn += 1
	)
)

function lampr_alignpointtoface obj lmp fc amode vnum fz = (

	if lmp != 0 or lmp != undefined then(
		pp = #()
		zz = (normalize(getFaceNormal obj fc))
		--format"zz = %\n"(normalize(getFaceNormal obj fc))
		apos = [0,0,0]
		avert = (getFace obj fc)
		pp[1] = obj.verts[(avert[1])].pos
		apos += pp[1]
		pp[2] = obj.verts[(avert[2])].pos
		apos += pp[2]
		pp[3] = obj.verts[(avert[3])].pos
		apos += pp[3]
		apos = (apos / 3)
		edg = 1
		edir = 0
		case edg of(
			1: (edir = (normalize (pp[1] - pp[2]) ) )
			2: (edir = (normalize (pp[2] - pp[3]) ) )
			3: (edir = (normalize (pp[3] - pp[1]) ) )
		)
		xx = normalize(cross zz edir)
		yy = normalize(cross xx zz)
		if fz == 0 then(
			lmp.transform = matrix3 xx yy zz [0,0,0]
		)else(
			lmp.transform = matrix3 xx yy -zz [0,0,0]
		)
		case amode of(
			1: (lmp.pos = apos)
			2: (lmp.pos = pp[vnum])
		)
	)
)

fn lampr_setbuffs pp tn fnum pmode vnum flz = (
	setuserprop pp ("lampr") tn
	setuserprop pp ("lampr_face") fnum
	setuserprop pp ("lampr_mode") pmode
	setuserprop pp ("lampr_corner") vnum
	setuserprop pp ("lampr_flipz") flz
)

fn lampr_selectlampr arollout idx = (
	try( arollout.fidx.value = ((getuserprop lampers[idx] ("lampr_face")) as integer) )catch()
	try( arollout.posmode.state = ((getuserprop lampers[idx] ("lampr_mode")) as integer) )catch()
	try( arollout.gcorner.value = ((getuserprop lampers[idx] ("lampr_corner")) as integer) )catch()
	try( arollout.flipz.value = ((getuserprop lampers[idx] ("lampr_flipz")) as integer)  )catch()
	arollout.lampername.text = lampers[idx].name
	apoint = lampers[idx]
	format"current point = %\n"apoint
)

fn lampr_populatelamperlist arollout targname selme = (
	lampers = #()
	for i in objects do(
		fnum = (getuserprop i ("lampr"))
		if fnum == targname do(
			append lampers i
		)
	)
	if lampers.count != 0 then(
		qsort lampers sortbynamefast
		tmpa = #(); for i in lampers do(append tmpa i.name)
		arollout.lamperlist.items = tmpa
		if selme != "" then(
			for i = 1 to arollout.lamperlist.items.count do(
				if arollout.lamperlist.items[i] == selme do(
					arollout.lamperlist.selection = i
					lampr_selectlampr arollout i
					exit
				)
			)
		)else(
			arollout.lamperlist.selection = 1
			lampr_selectlampr arollout 1
		)
	)else()
)
fn startstroke = (
	thepainterinterface.undostart()
	barys = [0,0,0]
	fidx = 0
	amhit = thepainterinterface.gettesthit mouse.pos

	if amhit == true do(
		thepainterinterface.getcustomhitfacedata &barys &fidx lampr_targ
		pfidx = fidx
		if pfidx != 0 do(
			flz = 0; if grlampr.flipz.state == true do(flz = 1)
			grlampr.fidx.value = pfidx
			lampr_alignpointtoface lampr_targ apoint grlampr.fidx.value grlampr.posmode.state grlampr.gcorner.value flz
			lampr_setbuffs apoint lampr_targ.name grlampr.fidx.value grlampr.posmode.state grlampr.gcorner.value flz
		)
		thepainterinterface.endpaintsession()
	)
)
fn paintstroke = ()
fn endstroke = (thepainterinterface.undoaccept())
fn cancelstroke = (thepainterinterface.undocancel())
fn systemend = (thepainterinterface.endpaintsession())

fn meshFilter obj = (classof obj.baseobject == editable_mesh)

rollout rlampr "lampr" width:584 height:168
(
	pickbutton glamper_targ "lamper_target" pos:[8,12] width:328 height:20 filter:meshFilter
	listbox lamperlist "" pos:[8,80] width:328 height:3
	spinner fidx "" pos:[504,24] width:64 height:16 enabled:false range:[1,1000000,1] type:#integer scale:1
	label lbl1 "face #:" pos:[464,24] width:40 height:16
	radiobuttons posmode "" pos:[352,64] width:77 height:32 enabled:false labels:#("face center", "face corner") default:1 columns:1
	spinner gcorner "" pos:[504,64] width:64 height:16 enabled:false range:[1,3,1] type:#integer scale:1
	label lbl2 "vertex #:" pos:[456,64] width:48 height:16
	button redbutton "bake" pos:[352,124] width:108 height:20 enabled:false
	progressBar progbar "" pos:[360,208] width:108 height:20
	GroupBox grp1 "" pos:[344,8] width:232 height:144
	button startvpselect "pick face..." pos:[352,24] width:104 height:20 enabled:false
	label lbl3 "set position to:" pos:[352,48] width:72 height:16
	button bigredbutton "bake all" pos:[460,124] width:108 height:20 enabled:false
	label lbl7 "attached points" pos:[8,64] width:80 height:16
	button newlamper "new" pos:[296,128] width:40 height:20 enabled:false
	edittext lampername "" pos:[4,128] width:284 height:20 enabled:false
	checkbutton doobjaspt "use object as point" pos:[8,40] width:112 height:16
	pickbutton pickpt "lampr_point" pos:[128,40] width:208 height:16
	checkbox flipz "flip z" pos:[352,104] width:48 height:16

	on rlampr open do( grlampr = rlampr )
	on glamper_targ picked obj do(

		lampr_targ = obj
		format"lamper_targ = %\n"lampr_targ
		glamper_targ.text = obj.name

		lampr_populatelamperlist rlampr obj.name ""
		if lampers.count == 0 do(
			lampers = #()
			if doobjaspt.checked then(
				if pickpt.object != undefined do(
					apoint = pickpt.object
				)
			)else(
				apoint = point	name:"fx_atch_point"
				repnumberedname #(apoint) ("Fx_Atch_" + lampr_targ.name)
				append lampers apoint
			)
			lamperlist.items = #(apoint.name)
			lamperlist.selection = 1
			lampername.text = apoint.name
			flz = 0; if flipz.state == true do(flz = 1)
			lampr_setbuffs apoint lampr_targ.name fidx.value posmode.state gcorner.value flz
			lampr_alignpointtoface lampr_targ apoint fidx.value posmode.state gcorner.value	flz
		)
		startvpselect.enabled = true
		redbutton.enabled = true
		bigredbutton.enabled = true
		fidx.enabled = true
		posmode.enabled = true
		gcorner.enabled = true
		newlamper.enabled = true
		lampername.enabled = true
	)
	on pickpt picked obj do(
		pickpt.text = obj.name
	)
	on startvpselect pressed do(
		if (thepainterinterface.inpaintmode() != true) then(
			thepainterinterface.scriptfunctions startstroke paintstroke endstroke cancelstroke systemend
			nodelist = lampr_targ
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

	on lamperlist selected idx do(
		lampr_selectlampr rlampr idx
	)
	on lamperlist doubleclicked idx do(
		lampr_selectlampr rlampr idx
		clearselection()
		select apoint
	)
	on newlamper pressed do(
		if doobjaspt.checked then(
			if pickpt.object != undefined do(
				apoint = pickpt.object
			)
		)else(
			apoint = point	name:"fx_atch_point"
			repnumberedname #(apoint) ("Fx_Atch_" + lampr_targ.name)
		)
		format"new poiont name = %\n"apoint.name
		flz = 0; if flipz.state == true do(flz = 1)
		lampr_setbuffs apoint lampr_targ.name fidx.value posmode.state gcorner.value flz
		lampr_alignpointtoface lampr_targ apoint fidx.value posmode.state gcorner.value	flz
		lampr_populatelamperlist rlampr lampr_targ.name apoint.name
	)
	on fidx changed val do(
		flz = 0; if flipz.state == true do(flz = 1)
		lampr_alignpointtoface lampr_targ apoint fidx.value posmode.state gcorner.value flz
		lampr_setbuffs apoint lampr_targ.name fidx.value posmode.state gcorner.value flz
	)
	on posmode changed state do(
		flz = 0; if flipz.state == true do(flz = 1)
		case state of(
			1: (apoint.pos = apos)
			2: (apoint.pos = pp[gcorner.value])
		)
		lampr_setbuffs apoint lampr_targ.name fidx.value posmode.state gcorner.value flz
	)
	on gcorner changed val do(
		flz = 0; if flipz.state == true do(flz = 1)
		case posmode.state of(
			1: (apoint.pos = apos)
			2: (apoint.pos = pp[val])
		)
		lampr_setbuffs apoint lampr_targ.name fidx.value posmode.state gcorner.value flz
	)
	on flipz changed val do(
		flz = 0; if flipz.state == true do(flz = 1)
		lampr_alignpointtoface lampr_targ apoint fidx.value posmode.state gcorner.value flz
		lampr_setbuffs apoint lampr_targ.name fidx.value posmode.state gcorner.value flz
	)
	on redbutton pressed do(
		flz = 0; if flipz.state == true do(flz = 1)
		deletekeys apoint
		progbar.pos = redbutton.pos
		for t = animationrange.start to animationrange.end do(
			with animate on(
				at time t(
					lampr_alignpointtoface lampr_targ apoint fidx.value posmode.state gcorner.value flz
					progbar.value = 100.*(t - animationrange.start)/(animationrange.end - animationrange.start)
				)
			)
		)
		progbar.value = 0
		progbar.pos = thekennel
	)
	on bigredbutton pressed do(
		progbar.pos = bigredbutton.pos
		for i = 1 to lampers.count do(
			tpoint = lampers[i]
			format"getting data from: %\n"tpoint
			deletekeys apoint
			try( fnum = ((getuserprop tpoint ("lampr_face")) as integer) )catch(fnum = 0)
			try( pmode = ((getuserprop tpoint ("lampr_mode")) as integer) )catch(pmode = 0)
			try( vnum = ((getuserprop tpoint ("lampr_corner")) as integer) )catch(vnum = 0)
			try( flz = ((getuserprop tpoint ("lampr_flipz")) as integer) )catch(flz = 0)
			format"found data: fnum = %, pmode = %, vnum = %.\n"fnum pmode vnum
			for t = animationrange.start to animationrange.end do(
				with animate on(
					at time t(
						lampr_alignpointtoface lampr_targ tpoint fnum pmode vnum flz
						progbar.value = 100.*(t - animationrange.start)/(animationrange.end - animationrange.start)
					)
				)
			)
			progbar.value = 0
		)
		progbar.pos = thekennel
	)
)
createdialog rlampr
)


