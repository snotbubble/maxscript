/*
pile7.2.
by c.p.brown. 2009.
Selection-set manager.
Misc scene management functions.
Capture-restore scene state per set.

Use of this script will break your
scenes and cause data loss!
use at your own risk...
otherwise modify at your leisure.

Aknowledgements:
Seung Jae Lee: testing & feedback.
Andrew Melnychuk Oseen: testing & feedback.
Eric Hulser: dynamic RCmenus & many optimisations.
Lukas Lepikovsky: struct trickery.
Steve Caron: optimisations.

BEGIN and END stuff is for folding in Notepad++.
you can download my maxscript editing setup from here:
http://www.snotbubble.com/cpb/MXS/nppp.zip
extract to a new copy of your notepad++ directory,
overwrite when prompted
(it will overwrite your styler config, can't be easily avoided).

Alternatively, I've made a maxscript Lexer for the EControl syntax editor:
http://www.snotbubble.com/cpb/MXS/cpb_080313.lxl
*/

global csl = #()               -- selected objects in object list, as objects. global for external acess.
global currentpilesetname = "" -- 1st selected selection-set name, for external access.
global pile = 0                -- for an instance of thepilestruct
global pilelog = 0             -- log file called pilelog.txt in your scriptspath.
global gsw = 0
global dopilelog = false       -- toggle diagnostic logging to file

struct thepilestruct (
sprp = "",                 -- sort by property: property string
ol = #(),                  -- listed objects, as objects.
sl = #(),                  -- listed selection set names, as strings.
cset = #(),                -- selected sets in the set list, as strings.
pilerollout = 0,           -- the rollout, defined on open.
sof = 1,                   -- sort or filter, used by object property field
pilematlist = #(#(), #()), -- material/material name for material list.
checkstoredmatsonly = 0,   -- check captured mats only?
copyormove = 0,            -- copy or move objs to a set
listtags = true,           -- show selection set list tags and enable data checks
hasdat = #(),              -- selectionset has data or not.
ssl = 0,                   -- the pile selection set UI interface.
xpsx = 0,                  -- expander width.
amresizing = 0,            -- am resizing the selection set list.
mposy = 0,                 -- mouse pos y.
rposy = 0,                 -- old mouse pos.
rslh = 175,                -- old selection-set list height
-- toggles for data capture:
harvestcat = #(true, true, true, true, true, true, true, true, true, true, true, false, true, true, true, true, true, true, true, true, true, false, true, true, true, true, true),

-- stuff for toggles:

allcheck = 0,
isocache = #(),
doflags = false,
dorestoreisol = true,
hrch =false,
qrsh = true,
qratm = true,
qrmult = false,
oflt = "*",
capsync = false,
ifc = false,
ifv = false,
ifm = false,
ifp = false,
dtp = false,
dpc = false,

/*BEGIN Generic functions */

fn pillow anum pad ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.pillow(%, %)\n"tabs anum pad to:pilelog)
	-- pads anum by pad*zeroes, returns snum as a string.
	snum = ""
	case (anum < 0) of(
		true: (anum = (0 - anum); snum = (anum as string); while snum.count < pad do(snum = ("0" + snum)); snum = ("-" + snum))
		false: (snum = (anum as string); while snum.count < pad do(snum = ("0" + snum)))
	)
	return snum
),
fn findinarray k t = (
	ret = 0
	for i = 1 to t.count where ret == 0 do(
		if t[i]	 == k do(ret = i)
	)
	return ret
),
function striplastnums str ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.striplastnums(%)\n"tabs str to:pilelog)
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
),

fn replacestr inPut inPutB anamearray = (
	newname = ""
	anewnamearray= #()
	if inPutB != "" then(
		if input == "" or input == "*" then(
			for n = 1 to anamearray.count do(append anewnamearray inPutB)
			return anewnamearray
		)else(
			retiring = (inPut)
			rc = inPut.count
			for i = 1 to anamearray.count do(
				newname = anamearray[i]
				rp = findstring anamearray[i] inPut
				if rp != undefined then(
					newname = (replace anamearray[i] rp rc inPutB)
					append anewnamearray newname
				)else(
					append anewnamearray anamearray[i]
				)
			)
			return anewnamearray
		)
	)else(format"no replacement string entered.\n"; return #())
),

fn manfindstring2 str pt offs ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.manfindstring2(string=%, position=%, offset=%)\n"tabs str pt offs to:pilelog)
	-- searches a string (str) for a substring (pt) and returns the positions of the substrings, assuming they will be replaced with a  new string of length offs.
	ee = 1
	pa = #()
	for i = 1 to str.count where str[i] == pt[ee] do(
		nomatch = 0
		for q = 1 to (pt.count - 1) where nomatch == 0 do(
			if str[(i + q)] != pt[(q + 1)] do(
				nomatch = 1
			)
		)
		if nomatch == 0 do(
			append pa (i + ((pa.count) * offs))
		)
	)
	return pa
),


function inky tfrm tto objs ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.inky(from=%, to=%, objs.count=%)\n"tabs tfrm tto objs to:pilelog)
	-- replaces all occurences of tfrm with tto in the names of objs.
	sw = timestamp()
	if tfrm != "" do(
		for i = 1 to objs.count do(
			nn = objs[i].name
			posarray = manfindstring2 objs[i].name tfrm (tto.count - tfrm.count) ind
			if posarray.count != 0 do(
				for p = 1 to posarray.count do(
					objs[i].name = (replace objs[i].name posarray[p] tfrm.count tto)
				)
			)
			posarray = 0
		)
	)
	ew = timestamp()
	format"pile.inky: rename took % milliseconds\n"(ew - sw)
),

fn invertarray a c ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.invertarray(array=%, count=%)\n"tabs a c to:pilelog)
	b = #()
	for i = 1 to c do(append b i)
	d = #()
	for i = 1 to b.count where (finditem a b[i]) == 0 do(append d b[i])
	return d
),
function getsetidxfromname aname ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.getsetidxfromname(%)\n"tabs aname to:pilelog)
	nsst = 0
	for i = 1 to selectionsets.count where nsst == 0 do(if (getnamedselsetname i) == aname do(nsst = i))
	return nsst
),

fn sortbyproperty n1 n2 = (
	case ( (execute("$'" + n1.name + "'" + sprp)) > (execute("$'" + n2.name + "'" + sprp)) ) of(
		true: 1
		false: -1
	)
),

fn sortbyname n1 n2 = (
	if n1.name > n2.name then 1
	else if n1.name < n2.name then -1
	else 0
),

fn sortbystring s1 s2 = (
	if s1>s2 then 1
	else if s1<s2 then -1
	else 0
),

fn sortbyval a b = (
	if a>b then 1
	else if a<b then -1
	else 0
),

fn sortbystringinarray v1 v2 a: = (
	if a[v1]>a[v2] then 1
	else if a[v1]<a[v2] then -1
	else 0
),

function renameset nn mpl buffr ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.renameset(%, %, %)\n"tabs nn mpl buffr to:pilelog)
	rt = ""
	snm = #(); for q = 1 to selectionsets.count do(append snm (getnamedselsetname q))
	if (maxVersion())[1] >= 9000 then(
		if buffr.count != 0 do(for i in buffr where (bsearch i snm sortbystring) == undefined do(append snm i))
		plen = 1
		if (bsearch nn snm sortbystring) == undefined then(rt = nn)else(
			g = 1
			while (bsearch (nn + (pillow g mpl ind)) snm sortbystring) != undefined do(g += 1)
			rt = (nn + (pillow g mpl ind))
		)
	)else(
		if buffr.count != 0 do(for i in buffr where (finditem snm i) == 0 do(append snm i))
		plen = 1
		if (finditem snm nn) == 0 then(rt = nn)else(
			g = 1
			while (finditem snm (nn + (pillow g mpl ind))) != 0 do(g += 1)
			rt = (nn + (pillow g mpl ind))
		)
	)
	return rt
),

function repadnames objnames ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.repadnames(name_count=%)\n"tabs objnames.count to:pilelog)
	-- this is a slow function that re-pads all occurences (in the scene) of the same name found in objnames.
	-- this is required from time to time as objects of the same name may not be in sequence from 1, or may have differing number-padding depths.

	cct = 0
	--sw = timestamp()

	ren = #()

	for i = 1 to objnames.count do(
		nxn = 0
		stxt = (striplastnums objnames[i] ind)[1]
		sobjs = (execute("$'" + stxt + "'*")) as array -- refine search to all objects whose name begins with the un-numbered name of objnames[i]
		oc = sobjs.count
		if oc > 1 do(
			for o = 1 to sobjs.count where (striplastnums sobjs[o].name ind)[1] == stxt do(
				if (maxVersion())[1] >= 9000 then(
					appendifunique ren sobjs[o]  -- build the list of objects to rename
				)else(
					if (finditem ren sobjs[o]) == 0 do(append ren sobjs[o] )
				)
			)
		)
		sobjs = 0
	)
	if ren.count > 1 do(
		pilerollout.informations.text = "repadding..."
		plen = ((ren.count as string).count + 1)
		for i = 1 to ren.count do(
			atn = (striplastnums ren[i].name ind)[1]
			ren[i].name = (atn + (pillow i plen ind))
		)
	)
	ren = 0
	--esw = timestamp()
	--format"pile.repadnames: renumbering names took %ms\n\n"(esw - sw)

	gc()
),

function repnumberedname objs txt ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.repnumberedname(object.count=%, new_name=%)\n"tabs objs.count txt to:pilelog)
	nxn = 1
	stxt = (striplastnums txt ind)[1]
	sobjs = (execute("$'" + stxt + "'*")) as array
	oc = objs.count
	for i = 1 to sobjs.count do(
		atn = (striplastnums sobjs[i].name ind)
		if atn[1] == stxt do(
			if atn[2] != "" then(
				ig = (atn[2] as integer)
				if ig >= nxn then(nxn = (ig + 1))else()
			)else(nxn += 1)
		)
	)
	if nxn > 1 or oc > 1 then(
		plen = (((oc + nxn) as string).count + 1)
		for i = 1 to objs.count do(
			objs[i].name = (stxt + (pillow nxn plen ind))
			nxn += 1
		)
	)else(
		for i = 1 to objs.count do(
			objs[i].name = stxt
		)
	)
),

function reptaggedname objs txt ind = (
    -- rename using tags identified by a '%' symbol, they are useful for inserting object-specific information.
	-- the cags can only be used once, and mis-spelling a tag will probably do very bad things to your object names.
	-- sample usage: reptaggedname #($teapot01) test_%n_ 0 -> $test_teapot_01
	pilerollout.progbar.pos.y = pilerollout.informations.pos.y
	pilerollout.progbar.pos.x = pilerollout.informations.pos.x
	pilerollout.informations.pos.x += 68
	pilerollout.informations.text = "renaming..."

	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.reptaggedname(%, %)\n"tabs objs.count txt to:pilelog)

	--sw = timestamp()
	p = findstring txt "%"
	if p != undefined do(
		for i = 1 to objs.count do(
			ptxt = txt
			sp = p
			while sp != undefined do(
				sf = substring ptxt (sp + 1) 1
				if sf == "o" do (ptxt = ( (replace ptxt sp 2 objs[i].name))) -- original object name, numbers and all.
				if sf == "n" do (ptxt =  ( (replace ptxt sp 2 (striplastnums objs[i].name ind)[1]))) -- original object name without numbers.
				if sf == "c" do  (ptxt =  ( (replace ptxt sp 2 ((classof objs[i]) as string) ))) -- class of the object.
				if (maxVersion())[1] >= 9000 then(
					if sf == "a" do (ptxt =  ( (replace ptxt sp 2 (toupper ((classof objs[i]) as string)[1]) ))) -- 1st letter of the object class, uppercase.
					if sf == "s" do (ptxt =  ( (replace ptxt sp 2 (toupper ((superclassof objs[i]) as string)[1]) ))) -- 1st letter of the object superclass, uppercase.
				)else(
					if sf == "a" do (ptxt =  ( (replace ptxt sp 2 ((classof objs[i]) as string)[1] )))
					if sf == "s" do (ptxt =  ( (replace ptxt sp 2 ((superclassof objs[i]) as string)[1] ))) 
				)
				sp = findstring ptxt "%"
			)
			objs[i].name = ptxt
		)
		-- format"FN:repnumberedname rename by key took % milliseconds\n"(ew - sw)
	)
	basenames = #()
	for i = 1 to objs.count do(
		if (maxVersion())[1] >= 9000 then(
			appendifunique basenames objs[i].name
		)else(
			if (finditem basenames objs[i].name) == 0 do(append basenames objs[i].name)
		)
	)
	if basenames.count != 0 do(
		for i = 1 to basenames.count do(
			repadnames #(basenames[i]) ind
			pilerollout.progbar.value = 100.*i/basenames.count
		)
	)

	--esw = timestamp()
	--format"FN:reptaggedname: rename using tags took % milliseconds\n\n"(esw - sw)

	pilerollout.progbar.pos.x = -500
	pilerollout.informations.pos.x -= 68
	pilerollout.informations.text = "ok"
),

function listfilterer afilter alist = (
	returnarray = #()
	for i = 1 to alist.count do(
		if matchpattern alist[i] pattern:(afilter + "*") == true do(
			append returnarray i
		)
	)
	return returnarray
),

function isolateobjs objs ind = (
	hide objects
	unhide objs
),

fn stringstoarray astring = (
	astr = (astring as stringstream)
	anarray = #()
	i = 1
	while not eof astr do(
		anentry = (readdelimitedstring astr ";")
		append anarray (anentry)
		i += 1
	)
	return anarray
),

fn slashfix apath = (
	clientlist = #()
	for i = 1 to apath.count do(if apath[i] == "\\" do(append clientlist i))
	q = 0
	for i in clientlist do(apath = replace apath (i + q) 1 "\\\\"; q += 1)
	return apath
),

function getpfgEventname obj ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.getpfgEventname(object=%, val=%)\n"tabs obj.name to:pilelog)
	-- get pflow group event name
	apos = (findstring obj.name ">") + 1
	astr = ""
	for t = apos to (obj.name).count do(
		astr = astr + (obj.name)[t]
	)
	return astr
),

fn togglepfe anobj aval ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.togglepfe(object=%, val=%)\n"tabs anobj.name aval to:pilelog)
	-- an attempt at toggling PF
	astr = (getpfgEventname anobj ind)
	try(
		execute("$'" + astr + "'.activate " + (aval as string))
	)catch(format"pile.togglepfe: could not evaluate activation state of: %\n"obj.name)
),

function getboolstate objs aparam testname ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.getboolstate(%, %, %)\n"tabs objs.count aparam testname to:pilelog)
	-- are all of object.aparam the same as testname? returns boolean
	-- used for popupmenu checks, which don't support tristate!
	if objs.count != 0 do(
		rt = true
		for i in objs do(
			skipthisone = 0
			if (isproperty i aparam) == true then(
				if aparam == #enabled do(if classof i != light do(skipthisone = 1))
				if skipthisone == 0 then(
					if classof (getproperty i aparam) == name then(
						if (getproperty i aparam) != testname do(rt = false; exit)
					)else(
						if (getproperty i aparam) == false do(rt = false; exit)
					)
				)else(rt = false)
			)else(rt = false)
		)
		return rt
	)
),

function getboolstateofreferenceblock objs asub aparam testname ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.getboolstateofreferenceblock(%, %, %, %)\n"tabs objs.count asub aparam testname to:pilelog)
	-- are all of object[4][asub].aparam the same as testname? returns boolean
	-- used for popupmenu checks, which don't support tristate!
	if objs.count != 0 do(
		rt = true
		for i in objs do(
			skipthisone = 0
			if (isproperty i[4][asub] aparam) == true then(
				if aparam == #enabled do(if classof i != light do(skipthisone = 1))
				if skipthisone == 0 then(
					if classof (getproperty i[4][asub] aparam) == name then(
						if (getproperty i[4][asub] aparam) != testname do(rt = false; exit)
					)else(
						if (getproperty i[4][asub] aparam) == false do(rt = false; exit)
					)
				)else(rt = false)
			)else(rt = false)
		)
		return rt
	)
),

function paramtoggle objs aparam notstate aname ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.paramtoggle(%, %, %, %)\n"tabs objs.count aparam notstate aname to:pilelog)
	if objs.count != 0 do(
		for i in objs do(
			if (isproperty i aparam) == true do(
				if classof aname == name then(
					if notstate == true then(notstate = #none)else(notstate = aname)
					setproperty i aparam notstate
				)else(
					setproperty i aparam (not notstate)
				)
			)
		)
	)
),

function refblockparamtoggle objs asub aparam notstate aname ind= (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.refblockparamtoggle(objs.count=%, asub=%, aparam=%, notstate=%, aname=%)\n"tabs objs.count asub aparam notstate aname to:pilelog)
	if objs.count != 0 do(
		for i in objs do(
			if (isproperty i[4][asub] aparam) == true do(
				if classof aname == name then(
					if notstate == true then(notstate = #none)else(notstate = aname)
					setproperty i[4][asub] aparam notstate
				)else(
					setproperty i[4][asub] aparam (not notstate)
				)
			)
		)
	)
),

function stripundefinedfromsets ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.stripundefinedfromsets()\n"tabs to:pilelog)
	rt = #(); rtn = #()
	for i = 1 to selectionsets.count do(
		for o = 1 to selectionsets[i].count do(
			if selectionsets[i][o] == undefined do(
				format"FN:stripundefinedfromsets: found undefined in %, tagging for rebuilding...\n" selectionsets[i]
				append rtn (getnamedselsetname i)
				append rt #()
				for g = 1 to selectionsets[i].count where selectionsets[i][g] != undefined do(
					append rt[rt.count] selectionsets[i][g]
				)
				exit
			)
		)
	)
	if rt.count != 0 do(
		temparray = #()
		for i = 1 to rt.count do(
			if rt[i].count != 0 then(
				retiring = (getsetidxfromname rtn[i] ind)
				deleteitem selectionsets retiring
				selectionsets[(rtn[i])] = rt[i]
			)else(
				retiring = (getsetidxfromname rtn[i] ind)
				deleteitem selectionsets retiring
				format"FN:stripundefinedfromsets: % contains only undefined, deleting.\n"rtn[i]
			)
		)
	)
	rt = 0; rtn = 0
),

fn insertintoarray a b p = (
	t = #()
	for n = 1 to p do(append t a[n])
	for n in b do(append t n)
	for n = (p + 1) to a.count do(append t a[n])
	return t
),

fn getchildren objs rec ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.getchildren(objs.count=%, recursive=%)\n"tabs objs.count rec to:pilelog)
	ac = #()
	tc = #()
	for i in objs do(
		tc = i.children
		for c in tc do(
			if (finditem ac c) == 0 do(
				append ac c
			)
		)
	)
	if rec == 1 do(
		i = 0
		while ac.count > i do(
			for c in ac do(
				tc = c.children
				for c in tc do(
					if (finditem ac c) == 0 do(
						append ac c
					)
				)
				i += 1
			)
		)
	)
	return ac
),

fn getallparentnum o = (
	g = o
	c = 0
	while g.parent != undefined do(
		c += 1
		g = g.parent
		if keyboard.escPressed == true do(exit)
	)
	return c
),

function getparents objs rec ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.getparents(objs.count=%, recursive=%)\n"tabs objs.count rec to:pilelog)
	parents = #()
	for i in objs do(
		aparent = i.parent
		while aparent != undefined do(
			if finditem parents aparent == 0 do(append parents aparent)
			if rec == 1 then(aparent = aparent.parent)else(aparent = undefined)
		)
	)
	return parents
),

fn getoldestparentinlist o lst = (
	g = o
	c = 0
	while g.parent != undefined do(
		c += 1
		if finditem lst g.parent != 0 then(g = g.parent)else(exit)
		if keyboard.escPressed == true do(exit)
	)
	return #(g, c)
),

function list2h objs flt fltstr = (
-- list objs hierarchially. excludes names that match fltstr.

--start = timeStamp()
g = 0
ar = #(#(), #())
ming = 10000
for i = 1 to objs.count do(
	if objs[i].parent == undefined do(append ar[1] objs[i]; append ar[2] 0)
)
for i = 1 to objs.count do(
	pp = (getoldestparentinlist objs[i] objs)
	if finditem ar[1] pp[1] == 0 do(
		append ar[1] pp[1]; append ar[2] pp[2]
	)
)
g = 0
-- format"starting array = %\n"ar
i = 0
while i < ar[1].count do(
	i += 1
	-- format"checking: %\n"ar[1][i].name
	ch = ar[1][i].children
	if ch.count != 0 do(
		g = ((getallparentnum ar[1][i]) + 1)
		ge = #()
		if flt == 1 then(
			tch = #()
			for k = 1 to ch.count do(
				if (matchpattern ch[k].name pattern:(fltstr  + "*")) == true do(
					if finditem objs ch[k] != 0 do(
						append ge g; append tch ch[k]
					)
				)
			)
			if ge.count != 0 do(
				-- format"found children: %\n"ch
				ar[1] = (insertintoarray ar[1] tch i)
				ar[2] = (insertintoarray ar[2] ge i)
			)
		)else(
			tch = #()
			-- format"% has % parents.\n"ar[1][i].name g
			for k = 1 to ch.count do(
				if finditem objs ch[k] != 0 do(append ge g; append tch ch[k])
			)
			if ge.count != 0 do(
				-- format"found children: %\n"ch
				ar[1] = (insertintoarray ar[1] tch i)
				ar[2] = (insertintoarray ar[2] ge i)
			)
		)
	)
	if keyboard.escPressed == true do(exit)
)
ret = #()
return ar
),

function refreshsprp ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.refreshsprp -- checks the sort field \n"tabs to:pilelog)
	-- tests pilerollout.sortby.text to see if its a sortable property.
	if pilerollout.sortby.text != "" then(
		for i in ol do(
			try(
				pr = execute("$'" + i.name + "'" + pilerollout.sortby.text)
				testr = (pr > pr)
				sprp = pilerollout.sortby.text
			)catch(format"FN: refreshsprp: failed to detect sortable property: %\n"pilerollout.sortby.text; sprp = ""; exit)
		)
	)else(sprp = "")
),

fn detachelements obj ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.detachelements(obj=%)\n"tabs obj.name to:pilelog)
	ret = #()
	while obj.numfaces > 1 do(
		ee = meshop.getElementsUsingFace obj #{(obj.numfaces)}
		huh = meshop.detachFaces obj ee delete:true asmesh:true
		update obj
		bee = editable_mesh()
		bee.mesh = huh
		bee.transform = obj.transform
		update bee
		try(repnumberedname bee obj.name ind)catch(bee.name = (uniquename obj.name))
		if bee.numverts != 0 then(append ret bee)else(delete bee)
		if keyboard.escPressed == true do(exit)
	)
	if obj.material != undefined do(for i in ret do(i.material = obj.material))
	delete obj; return ret
),

fn rendermeapicture resx resy mbl gi shd atm mlt ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.rendermeapicture(%, %, %, %, %, %, %)\n"tabs resx resy mbl gi shd atm mlt to:pilelog)
	arr = getfiles ( (striplastnums (((getdir #preview) + "\\")   + "prv_") ind)[1] + "*" + ".tga" )
	anum = pillow arr.count 4 ind

	qgi = 0
	qgimin = 0
	qgimax = 0
	qmb = 0
	qmbo = 0
	qmbi = 0

	qsmpmin = 0
	qsmpmax = 0

	renderscenedialog.close()
	if gi == false then(
		try(
			qgi = renderers.current.gi_on
			renderers.current.gi_on = false
		)catch()
	)
	else(
		if (hasproperty renderers.current #gi_on) == true do(
			if renderers.current.gi_on == true do(
				qgimin = renderers.current.gi_irradmap_minRate
				qgimax = renderers.current.gi_irradmap_maxRate
				renderers.current.gi_irradmap_minRate = -3
				renderers.current.gi_irradmap_maxRate = -3
				format"pile.rendermeapicture: temporarily set vray irradiance rates to %\n"renderers.current.gi_irradmap_maxRate
			)
		)
	)
	if mbl == false do(
		try(qmb = renderers.current.moblur_on; renderers.current.moblur_on = false)catch(
			qmb = 1
			try(qmbo = renderers.current.objectMotionBlur; renderers.current.objectMotionBlur = false; qmbi = renderers.current.imageMotionBlur; renderers.current.imageMotionBlur = false)catch()
		)
	)

	if (hasproperty renderers.current #adaptiveSubdivision_minRate) == true do(
		qsmpmin = renderers.current.adaptiveSubdivision_minRate
		qsmpmax = renderers.current.adaptiveSubdivision_maxRate
		renderers.current.adaptiveSubdivision_minRate = -2
		renderers.current.adaptiveSubdivision_maxRate = 1
		format"pile.rendermeapicture: temporarily set vray adaptiveSubdivision rates to % %\n"renderers.current.adaptiveSubdivision_minRate renderers.current.adaptiveSubdivision_maxRate
	)
	renderscenedialog.commit()
	render outputfile:(((getdir #preview) + "\\")  + "prv_" + anum + ".tga") outputwidth:(resx) outputheight:(resy) shadows:shd renderatmosphericeffects:atm renderMultiPassEffects:mlt renderElements:false VFB:true useRadiosity:gi

	if (hasproperty renderers.current #adaptiveSubdivision_minRate) == true do(
		renderers.current.adaptiveSubdivision_minRate = qsmpmin
		renderers.current.adaptiveSubdivision_maxRate = qsmpmax
	)
	if qgi != 0 do(
		try(renderers.current.gi_on = qgi)catch()
	)
	if qgimin != 0 do(
		try(
			renderers.current.gi_irradmap_minRate = qgimin
			renderers.current.gi_irradmap_maxRate = qgimax
		)catch()
	)
	if qmb != 0  do(
		try(renderers.current.moblur_on = qmb)catch(
			try(renderers.current.objectMotionBlur = qmbo; renderers.current.imageMotionBlur = qmbi)catch()
		)
	)
),
fn updaterenderelementpaths ind = (
	if querybox"update all renderelement paths and filenames to match the current render output?" beep:true then(
		ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
		if dopilelog == true do(format"%pile.updaterenderelementpaths()\n"tabs to:pilelog)
		renderscenedialog.commit()
		renderscenedialog.close()
		apath = (getfilenamepath rendoutputfilename)
		basename = (filterstring (getfilenamefile rendoutputfilename) ".")[1]
		format"pile.updaterenderelementpaths: new path = %\n"apath
		if apath != undefined or apath != "" do(
			rr = maxOps.GetCurRenderElementMgr()
			format"pile.updaterenderelementpaths: elements are on : %\n"(rr.GetElementsActive())
			for i = 0 to (rr.NumRenderElements() - 1) do(
				format"pile.updaterenderelementpaths: element : %\n"(rr.GetRenderElement i).elementname
				afile = (basename + "_" + (rr.GetRenderElement i).elementname + "." + (getfilenametype (rr.GetRenderElementFileName i)))
				newpath = (apath + afile)
				rr.SetRenderElementFileName i newpath
				format"    pile.updaterenderelementpaths: renaming: % to: %\n\n"(rr.GetRenderElementFileName i) newpath
			)
		)
		renderscenedialog.open()
	)else()
),
fn assignobjIDs = (
	for i = 1 to objects.count do(objects[i].gbufferChannel = i)
),
fn paintblock pw h perc = (
	clr = for i = 0 to pw collect (color 128.0 128.0 128.0)
	yblock = (mod h 1000)
	xblock = (mod yblock pw * 10 - 2000)
	for i = 1 to clr.count do(
		cr = 128.0
		cg = 128.0
		if ((mod i xblock) > ((xblock / 2.0) as integer)) do(cg = (perc * 128.0) + 128.0)
		cb = (128.0)
		clr[i] = (color cr cg cb)
	)
	scl = #()
	for i = 1 to clr.count do(
		cr = 0.0
		if ((mod i 10) > 4) do(cr = (1 - (cos(i/((clr.count / 2.0)/180.0)) )) * 255.0)
		scl[i] = (color cr cr cr)
	)
	return #(clr, scl)
),

fn localizemypcpaths objs = (
	tmp = ((getdir #maxroot) + "cahce\\")
	if doesfileexist tmp == false do(makedir tmp)
	if doesfileexist tmp == true then(
		ofn = #(#(),#(),#())
		c = 1
		for i in objs where i.modifiers.count >= 1 do(
			for m = 1 to i.modifiers.count where classof i.modifiers[m] == point_cache do(
				afn = i.modifiers[m].filename
				if getfilenamepath afn != tmp do(
					append ofn[1] i
					append ofn[2] m
					append ofn[3] afn
					ps = i.modifiers[m].playbackstart
					pe = i.modifiers[m].playbackend
					pt = i.modifiers[m].playbacktype
					append ofn[4] [ps,pe,pt]
					setuserprop i ("pcpath_" + (m as string)) afn
					setuserprop i ("pcstart_" + (m as string)) (ps as string)
					setuserprop i ("pcend_" + (m as string)) (pe as string)
					setuserprop i ("pctype_" + (m as string)) (pt as string)
				)
			)
			pilerollout.progbar.value = 100.*c/objs.count
			c += 1
		)

		tmp = ((getdir #maxroot) + "cahce\\")
		if doesfileexist tmp == false do(makedir tmp)
		if ofn[1].count != 0 do(
			for i = 1 to ofn[1].count do(
				afile = ((getfilenamefile ofn[3][i]) + (getfilenametype ofn[3][i]))
				tfile = (tmp + afile)
				copyfile ofn[3][i] tfile
				(ofn[1][i]).modifiers[(ofn[2][i])].filename = tfile
				(ofn[1][i]).modifiers[(ofn[2][i])].playbacktype = ofn[4][i][3]
				(ofn[1][i]).modifiers[(ofn[2][i])].playbackstart = ofn[4][i][1]
				(ofn[1][i]).modifiers[(ofn[2][i])].playbackend = ofn[4][i][2]
				pilerollout.progbar.value = 100.*i/ofn[1].count
			)
		)
	)else(messagebox"pile.localizemypcpaths:\ncould not make a cache directory in #maxroot.\nplease check permisssions and disk space.")
),

fn restoremypcpaths objs = (
	c = 1
	for i in objs where i.modifiers.count >= 1 do(
		for m = 1 to i.modifiers.count where classof i.modifiers[m] == point_cache do(
			opath = getuserprop i ("pcpath_" + (m as string))
			ostart = getuserprop i ("pcstart_" + (m as string))
			oend = getuserprop i ("pcend_" + (m as string))
			otype = getuserprop i ("pctype_" + (m as string))
			if opath != undefined do(i.modifiers[m].filename = opath)
			if otype != undefined do(i.modifiers[m].playbacktype = otype)
			if ostart != undefined do(i.modifiers[m].playbackstart = ostart)
			if oend != undefined do(i.modifiers[m].playbackend = oend)
		)
		pilerollout.progbar.value = 100.*c/objs.count
		c += 1
	)
),
fn paddedDelimit strarray padstr padlen delimstr = (
	tmp = #()
	for a = 1 to (strarray.count - 1) do(
		flts = strarray[a]
		maxp = 0
		for i = 1 to (flts.count - 1) do(
			if flts[i].count > maxp do(maxp = flts[i].count)
		)
		for i = 1 to (flts.count) do(
			tlen = maxp + padlen
			for p = (flts[i].count + 1) to tlen do(
				flts[i] = flts[i] + padstr
			)
			flts[i] = (flts[i] + delimstr)
		)
		append tmp flts
	)
	append tmp strarray[strarray.count]
	ret = for i = 1 to tmp[1].count collect ""
	for c = 1 to tmp[1].count do(
		for i = 1 to tmp.count do(
			ret[c] = (ret[c] + tmp[i][c])
		)
	)
	tmp = 0
	return ret
),

function togglemyparticles objs val ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.togglemyparticles(objs.count=%, toggle=%)\n"tabs objs val to:pilelog)
	pilerollout.informations.text = "toggling particles..."
	for i in objs where (isproperty i.baseobject #Enable_Particles) == true do(i.baseobject.Enable_Particles = val)
	for i in objs where classof i == ParticleGroup do(pile.togglepfe i val ind)
	if val == true then(
		for i in objs where (isproperty i.baseobject #Enable_Particles) == true do(po = (getuserprop i "particleon"); if po != undefined do(i.baseobject.Enable_Particles = po))
		for i in objs where classof i == ParticleGroup do(po = (getuserprop i "particleon"); if po != undefined do(pile.togglepfe i po ind))
		for i in objs where classof i == thinking do(po = (getuserprop i "particleon"); if po != undefined do(i[#Dynamic_Master].on = po))
		for i in objs where (isproperty i #viewpercent) == true do(try(i.viewpercent = ((getuserprop i "viewpercent") as integer))catch())
		for i in objs where (isproperty i #Viewport_Particles) == true do(try(i.Viewport_Particles = ((getuserprop i "Viewport_Particles") as integer))catch())
		for i in objs where (isproperty i #viewportcount) == true do(try(i.viewportcount = ((getuserprop i "viewportcount") as integer))catch())
	)else(
		for i in objs where (isproperty i.baseobject #Enable_Particles) == true do(setuserprop i "particleon" i.baseobject.Enable_Particles; i.baseobject.Enable_Particles = false)
		for i in objs where classof i == ParticleGroup do(
			astr = (oile.getpfgEventname i ind); pfeg = execute("$'" + astr + "'.activate")
			if pfeg != undefined do(setuserprop i "particleon" pfeg; pile.togglepfe i false ind)
		)
		for i in objs where classof i == thinking do(setuserprop i "particleon" i[#Dynamic_Master].on; i[#Dynamic_Master].on = false)
		for i in objs where (isproperty i #viewpercent) == true do(if i.viewpercent != 0.0 do( (setuserprop i "viewpercent" (i.viewpercent as string)); i.viewpercent = 0.0))
		for i in objs where (isproperty i #Viewport_Particles) == true do(if i.Viewport_Particles != 0.0 do( (setuserprop i "viewpercent" (i.viewpercent as string)); i.Viewport_Particles = 0.0))
		for i in objs where (isproperty i #viewportcount) == true do(if i.viewportcount != 0.0 do( (setuserprop i "viewpercent" (i.viewpercent as string)); i.viewportcount = 0.0))
	)
	pilerollout.informations.text = "done."
),

function togglemypointcaches objs val ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.togglemypointcaches(objs.count=%, toggle=%)\n"tabs objs.count val to:pilelog)
	pilerollout.informations.text = "toggling pointcaches."
	if val == false then(
		for i in objs where i.modifiers[#point_cache] != undefined do(
			setuserprop i "pointcacheon" i.modifiers[#point_cache].enabled
			i.modifiers[#point_cache].enabled = false
		)
	)else(
		for i in objs where i.modifiers[#point_cache] != undefined do(
			pco = getuserprop i "pointcacheon"
			if pco != undefined do(i.modifiers[#point_cache].enabled  = pco)
		)
	)
	pilerollout.informations.text = "done."
),

/*END generic functions */

/*BEGIN userprops functions */

function propbackwash akey objs ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.propbackwash(%, %)\n"tabs objs.count akey to:pilelog)
	-- add to any selection-set rebuilding functions

	pilerollout.progbar.pos.y = pilerollout.informations.pos.y
	pilerollout.progbar.pos.x = pilerollout.informations.pos.x
	pilerollout.informations.pos.x += 68
	pilerollout.informations.text = "backwashing userproperties..."

	incr = 1
	for i in objs do(
		rawstringarray = #(); nbuffr = #()
		astream = ((getuserpropbuffer i) as stringstream)
		while not eof astream do(
			alin = readline astream
			if alin != "" do(append rawstringarray (alin))
		)
		for k in rawstringarray do(
			tky = (substring k 1 akey.count)
			psk = ("sset_" + akey)
			stky = (substring k 1 psk.count)
			if tky != akey do(
				if stky != psk do(
					append nbuffr k
				)
			)
		)
		anewpropbuffer = ""
		for n in nbuffr do (anewpropbuffer = (anewpropbuffer + n + "\r\n"))
		setuserpropbuffer i anewpropbuffer
		pilerollout.progbar.value = (100.*incr/objs.count)
		incr += 1
	)
	pilerollout.informations.text = "ok."
	pilerollout.progbar.pos.x = -500
	pilerollout.informations.pos.x -= 68
	pilerollout.informations.text = "ok"
),

function pilerenameobjbufferkey akey anewkey objs ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.pilerenameobjbufferkey(%, %, %)\n"tabs objs.count akey anewkey to:pilelog)
	incr = 1
	for i in objs do(
		rawstringarray = #(); nbuffr = #()
		astream = ((getuserpropbuffer i) as stringstream)
		while not eof astream do(
			alin = readline astream
			if alin != "" do(append rawstringarray (alin))
		)
		for k in rawstringarray do(
			tky = (substring k 1 akey.count)
			psk = ("sset_" + akey); npsk = ("sset_" + anewkey)
			stky = (substring k 1 psk.count)
			if tky == akey then(
				nstr = (replace k 1 akey.count anewkey)
				append nbuffr nstr
			)else(
				if stky == psk then(
					nstr = (replace k 1 psk.count npsk)
					append nbuffr nstr
				)else(append nbuffr k)
			)
		)
		anewpropbuffer = ""
		for n in nbuffr do (anewpropbuffer = (anewpropbuffer + n + "\r\n"))
		setuserpropbuffer i anewpropbuffer
		pilerollout.informations.text = ("renaming keys: " + ((100.*incr/objs.count) as string) + "%")
		incr += 1
	)
	pilerollout.informations.text = "ok."
),

function pilerenameobjbuffervalsubstring asub anewsub ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.pilerenameobjbuffervalsubstring(%, %)\n"tabs asub anewsub to:pilelog)
	incr = 1
	asearchpattern = "selectionsets[\"" + asub + "\"]"
	anewpattern = "selectionsets[\"" + anewsub + "\"]"
	nbuffr = #()
	rawstringarray = #()
	for i in objects do(
		astream = ((getuserpropbuffer i) as stringstream)
		while not eof astream do(
			alin = readline astream
			if alin != "" do(append rawstringarray (alin))
		)
		itt = 0
		for k in rawstringarray do(
			inpoint = (findstring k asearchpattern)
			if inpoint != undefined then(
				-- format"pile.pilerenameobjbuffervalsubstring: renaming %.\n"k
				newstr = (replace k inpoint asearchpattern.count anewpattern)
				append nbuffr newstr; itt += 1
				-- format"pile.pilerenameobjbuffervalsubstring: renamed with: %.\n"newstr
			)else(append nbuffr k)
		)
		if itt != 0 do(
			anewpropbuffer = ""
			for n in nbuffr do (anewpropbuffer = (anewpropbuffer + n + "\r\n"))
			setuserpropbuffer i anewpropbuffer
		)
		pilerollout.informations.text = ("renaming references: " + ((100.*incr/objects.count) as string) + "%")
		incr += 1
		nbuffr = #()
		rawstringarray = #()
	)
	pilerollout.informations.text = "ok."
),

/*END userprops functions */

/*BEGIN map functions */



fn backupmymatlib amode ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.backupmymatlib(%)\n"tabs amode to:pilelog)
	amaxnum = 0
	anewname = ""

	if (doesfileexist (maxfilepath + "matlib\\")) == false do(makedir (maxfilepath + "matlib\\"))
	matlibname = (maxfilepath + (getfilenamefile maxfilename) + ".mat")
	if (doesfileexist matlibname) == false do(amode = 1)
	basearray = (striplastnums (getfilenamefile matlibname) ind)
	baseone = basearray[1]
	if basearray[2] != undefined do(amaxnum = (basearray[2] as integer))
	thebackups = getFiles (maxfilepath + "matlib\\" + baseone + "*.mat")
	format"pile.backupmymatlib: parsing matlib: %\n"basearray
	if thebackups.count != 0 do(
		for f in thebackups do(
			asep = (striplastnums (getfilenamefile f) ind)
			format"pile.backupmymatlib: parsing backup: %\n"asep
			if asep[2] != "" do(
				if asep[1] == baseone do(
					if (asep[2] as integer) > amaxnum do amaxnum = (asep[2] as integer)
				)
			)
		)
	)
	anewname = (baseone + (pillow (amaxnum + 1) 2 ind) + ".mat")
	format"pile.backupmymatlib: new backup name: %\n"anewname
	if amode == 0 then(
		copyfile matlibname (maxfilepath + "matlib\\" + anewname)
		saveMaterialLibrary matlibname
	)else(
		saveMaterialLibrary matlibname
		copyfile matlibname (maxfilepath + "matlib\\" + anewname)
	)
	if (doesfileexist (maxfilepath + "matlib\\" + anewname)	) == true then(
		format"pile.backupmymatlib: backup complete. \n\n"
		pilerollout.informations.text = ("ok. backup= \\wip\\" + anewname)
	)else(messagebox"pile.backupmymatlib: backup failed, check permissions and disk space." title:"error")
),

function listmats storedonly ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.listmats(%)\n"tabs storedonly to:pilelog)

	atmparray = #()
	if storedonly == 0 then(
		tmprarray = (getpropnames renderers.current)
		for i = 1 to tmprarray.count do(
			if tmprarray[i] != #notused do(
				if tmprarray[i] != #Brazil_Hook do(
					if (isproperty renderers.current tmprarray[i]) == true do(
						aparam = (getproperty renderers.current tmprarray[i])
						if superclassof aparam == texturemap do(
							format"FN: listmats: found a texturemap in the renderer: %\n"aparam
							if (finditem tmprarray aparam) == 0 do(append atmparray aparam)
						)
					)
				)
			)
		)
		tmprarray = #()
		for i in currentmateriallibrary where (finditem atmparray i) == 0 do(append atmparray i)
		while currentmateriallibrary.count != 0 do(deleteitem currentmateriallibrary  currentmateriallibrary.count)
		for i in meditmaterials where (finditem atmparray i) == 0 do(append atmparray i)
		for i in scenematerials where (finditem atmparray i) == 0 do(append atmparray i)
		for i in currentmateriallibrary where (finditem atmparray i) == 0 do(append atmparray i)
	)else(
		for s in sl do(
			keyname = (s + "_" +  "mat")
			for i in csl do(
				amatname = (getuserprop i keyname)
				amat = undefined
				for m in currentmateriallibrary where ("'" + m.name + "'") == amatname do(amat = m; exit)
				if amat == undefined do(for m in meditmaterials where ("'" + m.name + "'") == amatname do(amat = m; exit))
				if amat == undefined do(for m in scenematerials where ("'" + m.name + "'") == amatname do(amat = m; exit))
				if amat != undefined  do(
					if (finditem atmparray amat) == 0 do(append atmparray amat)
				)
			)
		)
	)
	qsort atmparray sortbyname
	for i in atmparray where (finditem currentmateriallibrary i) == 0 do(append currentmateriallibrary i)
	matarrays = #(#(), #())
	append matarrays[2] "undefined"
	append matarrays[1] undefined
	if (maxVersion())[1] >= 9000 then(
		for i in atmparray where (bsearch i.name matarrays[2] sortbystring) == undefined do(
			append matarrays[2] i.name
			append matarrays[1] i
		)
	)else(
		for i in atmparray where (finditem matarrays[2] i.name) == 0 do(
			append matarrays[2] i.name
			append matarrays[1] i
		)
	)
	append matarrays[2] "multi"
	append matarrays[1] undefined
	atmparray = #()
	return matarrays
),

fn backwashthematlib ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.backwashthematlib()\n"tabs to:pilelog)
	matlibname = (maxfilepath + (getfilenamefile maxfilename) + ".mat")
	if doesfileexist matlibname == true do(
		listmats 0 ind
		backupme = #()
		for i in currentmateriallibrary do(
			aname = i.name
			uq = 0
			for n = 1 to backupme.count where uq == 0 do(
				if aname == backupme[n].name do(uq = 1)
			)
			if uq == 0 do(append backupme i)
		)
		loadMaterialLibrary matlibname
		for i in currentmateriallibrary do(
			aname = i.name
			uq = 0
			for n = 1 to backupme.count where uq == 0 do(
				if aname == backupme[n].name do(uq = 1)
			)
			if uq == 0 do(append backupme i; format"restoring material from the matlib: %\n"aname)
		)
		while currentmateriallibrary.count != 0 do(deleteitem currentmateriallibrary  currentmateriallibrary.count)
		for i in backupme do(append currentmateriallibrary i)
		backupme = 0
	)
),

/*END map functions */

/*BEGIN Data functions */

function getstateofamodifierparam obj aclass nofail ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.getstateofamodifierparam(obj=%, class=%, nofail=%)\n"tabs obj.name aclass nofail to:pilelog)

	-- finds the enabled state of a modifier.
	rt = false
	dort = false
	if nofail == 1 do(dort = true)
	m = 1
	if obj.modifiers.count != 0 do(
		for m = 1 to obj.modifiers.count do(
			if classof obj.modifiers[m] == aclass do(
				dort = true
				aval = obj.modifiers[m].enabled
				if aval == true do(rt = true; exit)
			)
		)
	)
	if dort == true do(return #(rt, m))
),

fn getanabledstate obj ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.getanabledstate(obj=%)\n"tabs obj.name to:pilelog)

	-- messy function to find 'on/off' parameters,
	-- not all cases are handled, add your own as required.
	--acmdstring = ("(maxOps.getNodeByHandle " + (obj.inode.handle as string) + ")." + aparam)
	acmd = ""
	if superclassof obj == helper do(
		if (isproperty obj #isactivated) == true do(
			astr = obj.name
			abool = execute("$'" + astr + "'.isactivated()")
			acmd = ("$'" + astr + "'.activate " + (abool as string))
		)
	)
	if classof obj == ParticleGroup do(
		astr = (getpfgEventname obj ind)
		try(
			abool = execute("$'" + astr + "'.isactivated()")
			acmd = ("$'" + astr + "'.activate " + (abool as string))
		)catch(format"could not evaluate activation state of: %\n"obj.name)
	)
	if superclassof obj == light do(acmd = ("(maxOps.getNodeByHandle " + (obj.inode.handle as string) + ").enabled = " + (obj.enabled as string)))
	if (isproperty obj.baseobject #Enable_Particles) == true do(acmd = ("(maxOps.getNodeByHandle " + (obj.inode.handle as string) + ").baseobject.Enable_Particles = " + (obj.baseobject.Enable_Particles as string)))
	if (isproperty obj #viewpercent) == true do(acmd = ("(maxOps.getNodeByHandle " + (obj.inode.handle as string) + ").viewpercent = " + (obj.viewpercent as string)))
	if (isproperty obj #viewportcount) == true do(acmd = ("(maxOps.getNodeByHandle " + (obj.inode.handle as string) + ").viewportcount = " + (obj.viewpercent as string)))
	if (isproperty obj #Viewport_Particles) == true do(acmd = ("(maxOps.getNodeByHandle " + (obj.inode.handle as string) + ").Viewport_Particles = " + (obj.viewpercent as string)))
	if classof obj == Thinking do(
		format"found TP system, checking dynamicset states...\n"
		if obj[#Dynamic_Master].numsubs > 1 then(
			for s = 5 to (obj[#Dynamic_Master].numsubs) do(
				format"found nested dynamicset: %\n"obj[#Dynamic_Master][s].name
				acmd = (acmd + ("(maxOps.getNodeByHandle " + (obj.inode.handle as string) + ")[#Dynamic_Master][" + (s as string) + "][1].value = " + (obj[#Dynamic_Master][s][1].value as string) + "; "))
				for m = 5 to (obj[#Dynamic_Master][s].numsubs) do(
					if (matchpattern obj[#Dynamic_Master][s][m].name pattern:"DS:*") == true do(
						acmd = (acmd + ("(maxOps.getNodeByHandle " + (obj.inode.handle as string) + ")[#Dynamic_Master][" + (s as string) + "][" + (m as string) + "][1].value = " + (obj[#Dynamic_Master][s][m][1].value as string) + "; "))
						format"pile.getanabledstate: built TP dynamicset.dynamicset.enable command: %\n"acmd
					)
				)
				format"pile.getanabledstate: built TP dynamicset.enable command: %\n"acmd
			)
		)else(
			format"found TP system has only 1 subanim\n"
			for s = 5 to obj[#Dynamic_Master].numsubs do(
				acmd = ("(maxOps.getNodeByHandle " + (obj.inode.handle as string) + ")[#Dynamic_Master][" + (s as string) + "][1].value = " + (obj[#Dynamic_Master][s][1].value as string) + "; ")
				format"pile.getanabledstate: built TP dynamicset.enable command: %\n"acmd
			)
		)
	)
	try(
		if obj.modifiers.count != 0 do(
			apcmod = (getstateofamodifierparam obj Point_Cache_2 0 ind)
			acmd = ("(maxOps.getNodeByHandle " + (obj.inode.handle as string) + ").modifiers[" + (apcmod[2] as string) + "].enabled = " + (apcmod[1] as string) + "; ")
		)
	)catch()

	if obj.modifiers.count != 0 do(
		try(
			apcmod = (getstateofamodifierparam obj TP_PGroupObjectModifier 0 ind)
			acmd = ("(maxOps.getNodeByHandle " + (obj.inode.handle as string) + ").modifiers[" + (apcmod[2] as string) + "].enabled = " + (apcmod[1] as string) + "; ")
		)catch()
	)
	try(
		if (isproperty obj.transform.controller #enabled) == true do(
			axfctrl = (obj.transform.controller.enabled as string)
			acmd = ("$'"+(obj.name)+"'.transform.controller.enabled = " + axfctrl + "; ")
		)
	)catch()
	if (isproperty obj #mpassEnabled) == true do(acmd = ("(maxOps.getNodeByHandle " + (obj.inode.handle as string) + ").mpassEnabled = " + (obj.mpassEnabled as string) + "; "))
	if classof obj == fumeFX do(
		try(
			sfire = (obj.standard.shadefire as string)
			acmd = ("(maxOps.getNodeByHandle " + (obj.inode.handle as string) + ").standard.shadefire = " + sfire)
			ssmoke = (obj.standard.shadesmoke as string)
			acmd = (acmd + "; (maxOps.getNodeByHandle " + (obj.inode.handle as string) + ").standard.shadesmoke = " + ssmoke)
			sfuel = (obj.standard.shadefuel as string)
			acmd = (acmd + "; (maxOps.getNodeByHandle " + (obj.inode.handle as string) + ").standard.shadefuel = " + sfuel)
		)catch()
	)
	return acmd
),

fn pilecapatm = (
	cmdarray = #()
	if numAtmospherics != 0 do(
		for i = 1 to numAtmospherics do(
			cmdstring = ("isactive (getatmospheric " + (i as string) + ")")
			aval = execute(cmdstring)
			append cmdarray ("setactive (getatmospheric " + (i as string) + ") " + (aval as string))
		)
	)
	return cmdarray
),

fn pilecapenv = (
	cmdarray = #()

	if environmentMap != undefined do(
		aval = (environmentMap)
		acmdstring = "environmentMap"
		acmd = ("for i in currentmateriallibrary do(if (i as string) == \"" + (aval as string) + "\" do(" + acmdstring + " = i; exit))")
		append cmdarray acmd
	)
	append cmdarray	("setBackGround " + ((getBackGround()) as string))
	append cmdarray	("ambientColor = " + ((ambientColor) as string))
	append cmdarray	("setUseEnvironmentMap " + ((getUseEnvironmentMap()) as string))
	return cmdarray
),

fn pilecapeff = (
	cmdarray = #()
	if numeffects != 0 do(
		for i = 1 to numeffects do(
			cmdstring = ("isactive (geteffect " + (i as string) + ")")
			aval = execute(cmdstring)
			append cmdarray ("setactive (geteffect " + (i as string) + ") " + (aval as string))
		)
	)
	return cmdarray
),

fn gathercommon = (
	-- gathering the common renderer params:
	commonarray = #(#(), #())
	append commonarray[1] ("renderer")
	append commonarray[1] ("getRendImageAspect()")
	append commonarray[1] ("renderDisplacements")
	append commonarray[1] ("renderEffects")
	append commonarray[1] ("renderHeight")
	append commonarray[1] ("renderPixelAspect")
	append commonarray[1] ("rendSimplifyAreaLights")
	append commonarray[1] ("renderWidth")
	append commonarray[1] ("skipRenderedFrames")
	append commonarray[1] ("rendTimeType")
	append commonarray[1] ("rendStart")
	append commonarray[1] ("rendEnd")
	append commonarray[1] ("rendNThFrame")
	append commonarray[1] ("rendShowVFB")
	append commonarray[1] ("rendSaveFile")
	append commonarray[1] ("rendUseDevice")
	append commonarray[1] ("rendUseNet")
	append commonarray[1] ("rendFieldRender")
	append commonarray[1] ("rendColorCheck")
	append commonarray[1] ("rendSuperBlack")
	append commonarray[1] ("rendHidden")
	append commonarray[1] ("rendForce2Side")
	append commonarray[1] ("rendAtmosphere")
	append commonarray[1] ("rendDitherTrue")
	append commonarray[1] ("rendDither256")
	append commonarray[1] ("rendMultiThread")
	append commonarray[1] ("rendNThSerial")
	append commonarray[1] ("rendVidCorrectMethod")
	append commonarray[1] ("rendFieldOrder")
	append commonarray[1] ("rendNTSC_PAL")
	append commonarray[1] ("rendSuperBlackThresh")
	append commonarray[1] ("rendFileNumberBase")
	append commonarray[1] ("rendOutputFilename")
	append commonarray[1] ("rendPickupFrames")


	for i = 1 to commonarray[1].count do(
		append commonarray[2] (execute(commonarray[1][i]) as string)
	)
	commonarray[1][2] = ("setRendImageAspect")
	append commonarray [1] "viewport.activeViewport"
	append commonarray [2] (viewport.activeViewport as string)
	acam = viewport.GetCamera()
	if acam != undefined then(
		append commonarray[1] "viewport.setcamera"
		append commonarray[2] ("$'" + acam.name + "'")
	)else(
		append commonarray[1] "viewport.settype"
		append commonarray[2] ("#" + (viewport.gettype() as string))
		format"stored: % % \n"commonarray[1][(commonarray[1].count)]  commonarray[2][(commonarray[2].count)]
	)
	return commonarray
),

fn gatherrende = (
	rendearray = #(#(), #())
	if classof renderers.current == Default_Scanline_Renderer then(
		for i in (getPropNames renderers.current.props) do (
			append rendearray[1] ("renderers.current." + (i as string))
		)
		for i = 1 to (getPropNames renderers.current.props).count do (
			if (getPropNames renderers.current.props)[i] != #antiAliasFilter then(
				if (getPropNames renderers.current.props)[i] != #globalSamplerClassByName then(
						append rendearray[2] (execute(rendearray[1][i]) as string)
				)else(
					append rendearray[2] ( "\"" + (execute(rendearray[1][i]) as string) + "\"")
				)
			)else(
				rfa = (replacestr ":(null" "(" #( (execute(rendearray[1][i]) as string) ) )[1]
				rfb = (replacestr "-" "_" #(rfa))[1]
				append rendearray[2] rfb
			)
		)
	)else(
		tmparray = (getpropnames renderers.current)
		for i = 1 to tmparray.count where tmparray[i] != #notused do(
			if tmparray[i] != #Brazil_Hook do(
				if (execute("renderers.current." + (tmparray[i] as string))) != undefined do(
					append rendearray[1] ("renderers.current." + (tmparray[i] as string))
					if classof (execute("renderers.current." + (tmparray[i] as string))) == string then(
						append rendearray[2] (replacestr ":(null" "(" #( ("\"" + ((execute("renderers.current." + (replacestr "-" "_" #(tmparray[i] as string))[1])) as string) + "\"")))[1]
					)else(
						if superclassof (execute("renderers.current." + (tmparray[i] as string))) == node then(
							atempnode = (execute("renderers.current." + (tmparray[i] as string)))
							append rendearray[2] ("$'" + atempnode.name + "'")
						)else(
							if superclassof (execute("renderers.current." + (tmparray[i] as string))) == texturemap or superclassof (execute("renderers.current." + (tmparray[i] as string))) == material then(
								atempnode = (execute("renderers.current." + (tmparray[i] as string)))
								acmdstring = (("renderers.current." + (tmparray[i] as string)) as string)
								append rendearray[2] ("for i in currentmateriallibrary do(if (i as string) == \"" + (atempnode as string) + "\" do(" + acmdstring + " = i))")
							)else(
								acmdval = (replacestr "-" "_" #(tmparray[i] as string))[1]
								acmdstring = ((execute("renderers.current." + acmdval)) as string)
								acmdstringnonull = (replacestr ":(null" "(" #(acmdstring))[1]
								append rendearray[2] acmdstringnonull
							)
						)
					)
				)
			)
		)
		tmparray = #()
	)
	append rendearray[1] ("renderers.current")
	append rendearray[2] (((execute("classof " + rendearray[1][rendearray[1].count])) as string) + "()")
	return rendearray
),
function captureallrenderer = (
	renderscenedialog.commit()
	--sw = timestamp()
	anarray = gatherrende()
	--esw = timestamp()
	--format"FN:captureallrenderer: gatherrende took % milliseconds\n\n"(esw - sw)
	sw = timestamp()
	alistarray = #()
	for i = 1 to (anarray[1].count) where anarray[2][i] != undefined do(
		if superclassof (execute(anarray[1][i])) == texturemap then(
			alistarray[i] = anarray[2][i]
		)else(
			try(
				if superclassof (execute(anarray[2][i])) == camera then(
					alistarray[i] = (anarray[1][i] + " " + anarray[2][i])
					format"storing: %\n"alistarray[i]
				)else(
					if classof (execute(anarray[2][i])) == name then(
						alistarray[i] = (anarray[1][i] + " " + anarray[2][i])
						format"storing: %\n"alistarray[i]
					)else(
						alistarray[i] = (anarray[1][i] + " = " + anarray[2][i])
					)
				)
			)catch(alistarray[i] = (anarray[1][i] + " = " + anarray[2][i]))
		)
	)
	--esw = timestamp()
	-- format"FN:captureallrenderer: array processing took % milliseconds\n\n"(esw - sw)
	return alistarray
),
function captureallcommonrenderparams = (
	--sw = timestamp()
	renderscenedialog.commit()
	anarray = gathercommon()
	--esw = timestamp()
	-- format"FN:captureallcommonrenderparams: gathercommon took % milliseconds\n\n"(esw - sw)
	--sw = timestamp()
	alistarray = #()
	for i = 1 to (anarray[1].count) where anarray[2][i] != undefined do(
		if superclassof (execute(anarray[1][i])) == texturemap then(
			alistarray[i] = anarray[2][i]
		)else(

			try(
				if superclassof (execute(anarray[2][i])) == camera then(
					alistarray[i] = (anarray[1][i] + " " + anarray[2][i])
					format"storing: %\n"alistarray[i]
				)else(
					if classof (execute(anarray[2][i])) == name then(
						alistarray[i] = (anarray[1][i] + " " + anarray[2][i])
					)else(
						alistarray[i] = (anarray[1][i] + " = " + anarray[2][i])
					)
				)
			)catch(alistarray[i] = (anarray[1][i] + " = " + anarray[2][i]))
			if anarray[1][i] == "rendOutputFilename" do(
				alistarray[i] = (anarray[1][i] +  (" = \"" + anarray[2][i] + "\""))
			)
			if anarray[1][i] == "rendPickupFrames" do(
				alistarray[i] = (anarray[1][i] +  (" = \"" + anarray[2][i] + "\""))
			)
		)
	)

	-- esw = timestamp()
	-- format"FN:captureallcommonrenderparams: array processing took % milliseconds\n\n"(esw - sw)
	return alistarray
),
function getrenderelementstate = (
	acmd = ( "" as stringstream )
	format"renderscenedialog.commit(); renderscenedialog.close(); rr = maxOps.GetCurRenderElementMgr();" to:acmd
	--format"pile.getrenderelementstate.acmd=%\n"acmd
	rr = maxOps.GetCurRenderElementMgr()
	format"rr.SetElementsActive %;"(rr.GetElementsActive()) to:acmd
	format"for i = 0 to (rr.NumRenderElements() - 1) do(" to:acmd
	for i = 0 to (rr.NumRenderElements() - 1) do(
		en = (rr.GetRenderElement i).elementname
		format"if (rr.GetRenderElement i).elementname == \"%\" do((rr.GetRenderElement i).enabled = %);"en (rr.GetRenderElement i).enabled to:acmd
		format"if (rr.GetRenderElement i).elementname == \"%\" do(rr.SetRenderElementFileName i \"%\");"en (slashfix (rr.GetRenderElementFileName i)) to:acmd
	)
	format"); renderscenedialog.open()" to:acmd
	return (acmd as string)
),
function getunifiedssetviz = (
	anarray = #(#(), #())
	for s = 1 to selectionsets.count where selectionsets[s].count != 0 do(
		skipme = 0
		if selectionsets[s].count > 1 then(
			for o = 1 to selectionsets[s].count do(
				if selectionsets[s][o].ishidden == true do(
					skipme = 1; exit
				)
			)
			if skipme == 0 do(append anarray[1] (getNamedSelSetName s); append anarray[2] selectionsets[s][1].ishidden)
		)else(
			if selectionsets[s][1].ishidden == false do(
				append anarray[1] (getNamedSelSetName s); append anarray[2] selectionsets[s][1].ishidden
			)
		)
	)
	astr = ""
	if anarray[1].count != 0 do(
		for i = 1 to anarray[1].count do (
			astr = (astr + "for k in selectionsets[\"" + (anarray[1][i]) + "\"] do(k.ishidden = " + (anarray[2][i] as string)  + "); ")
		)
	)
	return astr
),
function getunifiedssetprp prp = (
	anarray = #(#(), #())
	for s = 1 to selectionsets.count where selectionsets[s].count != 0 do(
		skipme = 0
		if selectionsets[s].count > 1 then(
			for o = 1 to selectionsets[s].count do(
				if isproperty selectionsets[s][o] prp == true then(
					if (getproperty selectionsets[s][o] prp) != (getproperty selectionsets[s][1] prp) do(
						skipme = 1; exit
					)
				)else(skipme = 1; exit)
			)
			if skipme == 0 do(append anarray[1] (getNamedSelSetName s); append anarray[2] (getproperty selectionsets[s][1] prp))
		)else(
			if isproperty selectionsets[s][1] prp == true do(
				append anarray[1] (getNamedSelSetName s); append anarray[2] (getproperty selectionsets[s][1] prp)
			)
		)
	)
	astr = ""
	if anarray[1].count != 0 do(
		for i = 1 to anarray[1].count do (
			astr = (astr + "for k in selectionsets[\"" + (anarray[1][i]) + "\"] do(k." + (prp as string) + " = " + (anarray[2][i] as string)  + "); ")
			--format"    pile.getunifiedssetviz: cmd=%\n"astr
		)
	)
	return astr
),
function getunifiedssetvrm = (
	anarray = #(#(), #(), #(), #(), #())

	for s = 1 to selectionsets.count do(
		skipme = 0
		if selectionsets[s].count != 0 do(
			for i = 1 to selectionsets[s].count where skipme == 0 do(
				aval = (getuserprop selectionsets[s][i] "VRay_Matte_Enable")
				bval = (getuserprop selectionsets[s][i] "VRay_Matte_Alpha")
				if aval == undefined or aval == OK then(skipme = 1)	else(
					if finditem anarray[3] (aval as string) == 0 then (skipme = 1) else(
						if bval == undefined or bval == OK then(skipme = 1)	else(
							if finditem anarray[5] (bval as string) == 0 do(skipme = 1)
						)
					)
				)
			)
			if skipme == 0 do(
				append anarray[1] (getNamedSelSetName s)
				append anarray[2] "VRay_Matte_Enable"
				append anarray[3] (aval as string)
				append anarray[4] "VRay_Matte_Alpha"
				append anarray[5] (bval as string)
			)
		)
	)
	astr = ""
	if anarray[1].count != 0 do(
		for i = 1 to anarray[1].count do (
			astr = (astr + "for k in selectionsets[\"" + (anarray[1][i]) + "\"] do(setuserprop k " + (anarray[2][i])  + " " + (anarray[3][i]) + "); ")
			astr = (astr + "for k in selectionsets[\"" + (anarray[1][i]) + "\"] do(setuserprop k " + (anarray[4][i])  + " " + (anarray[5][i]) + "); ")
		)
	)
	return astr
),

function getunifiedssetena = (
	anarray = #(#(), #())
	for s = 1 to selectionsets.count do(
		if selectionsets[s].count != 0 do(
			skipme = 0
			if selectionsets[s].count > 1 then(
				for o = 1 to selectionsets[s].count where skipme == 0 do(
					if isproperty selectionsets[s][o] #on == true then(
						--format"pile.getunifiedssetena: %.on = %\n"selectionsets[s][o].name selectionsets[s][o].on
						--format"    pile.getunifiedssetena: %.on = %, %.on = %\n"selectionsets[s][o].name selectionsets[s][o].on selectionsets[s][1].name selectionsets[s][1].on
						if selectionsets[s][o].on != selectionsets[s][1].on do(skipme = 1; exit)
					)else(skipme = 1; exit)
				)
				if skipme == 0 do(
					format"pile.getunifiedssetena: all items in % are %\n"(getNamedSelSetName s) selectionsets[s][1].on
					append anarray[1] (getNamedSelSetName s); append anarray[2] selectionsets[s][1].on
				)
			)else(
				if isproperty selectionsets[s][1] #on == true do(
					append anarray[1] (getNamedSelSetName s); append anarray[2] selectionsets[s][1].on
				)
			)
		)
	)
	astr = ""
	if anarray[1].count != 0 do(
		for i = 1 to anarray[1].count do (
			astr = (astr + "for k in selectionsets[\"" + (anarray[1][i]) + "\"] do(k.on = " + (anarray[2][i] as string)  + "); ")
		)
	)
	return astr
),

function getunifiedssetmat = (
	amarray = #(#(), #())
	for s = 1 to selectionsets.count do(
		if selectionsets[s].count != 0 do(
			skipme = 0
			skipmeviz = 0
			if selectionsets[s].count > 1 then(
				for o = 1 to selectionsets[s].count do(
					if selectionsets[s][o].ishidden == true do(
						skipmeviz = 1; exit
					)
				)
				if skipmeviz == 0 do(
					for o = 2 to selectionsets[s].count do(
						if selectionsets[s][o].material != selectionsets[s][1].material do(
							skipme = 1; exit
						)
					)
					if selectionsets[s][1].material == undefined do(skipme = 1)
					if skipme == 0 do(
							append amarray[1] (getNamedSelSetName s)
							append amarray[2] selectionsets[s][1].material.name
					)
				)
			)else(
				if selectionsets[s][1].material != undefined do(
					if selectionsets[s][1].ishidden == false do(
						append amarray[1] (getNamedSelSetName s); append amarray[2] selectionsets[s][1].material.name
					)
				)
			)
		)
	)
	astr = ""

	if amarray[1].count != 0 do(
		for i = 1 to amarray[1].count do (
			astr = (astr + "amat = 0; for h in currentmateriallibrary do(if h.name == (\"" + (amarray[2][i] as string)  + "\") do(amat = h; exit)); for k in selectionsets[\"" + (amarray[1][i]) + "\"] do(k.material = amat); amat = 0; ")
		)
	)

	amarray = #(#(), #(), #(), #())
	for s = 1 to selectionsets.count do(
		if selectionsets[s].count != 0 do(
			skipme = 0
			skipmeviz = 0
			ia = (getuserprop selectionsets[s][1] "VRay_Matte_Alpha")
			ie = (getuserprop selectionsets[s][1] "VRay_Matte_Enable")
			if ie != undefined and ia != undefined do(
				for o = 1 to selectionsets[s].count do(
					aval = (getuserprop selectionsets[s][o] "VRay_Matte_Enable")
					bval= (getuserprop selectionsets[s][o] "VRay_Matte_Alpha")
					if aval != undefined or aval != "undefined" then(
						if aval != ie do(
							skipme = 1; exit
						)
						if bval != undefined or bval != "undefined" then(
							if bval != ia do(
								skipme = 1; exit
							)
						)else(skipme = 1; exit)
					)else(skipme = 1; exit)
				)
				if skipme == 0 do(
					append amarray[1] (getNamedSelSetName s)
					append amarray[2] ie
					append amarray[3] ia
				)
			)
		)
	)
	if amarray[1].count != 0 do(
		for i = 1 to amarray[1].count do (
			if astr.count != 0 do( astr = (astr + "; "))
			astr = (astr + "for k in selectionsets[\"" + (amarray[1][i]) + "\"] do(setuserprop k \"VRay_Matte_Enable\" " +  (amarray[2][i] as string) + ")")
			astr = (astr + "; for k in selectionsets[\"" + (amarray[1][i]) + "\"] do(setuserprop k \"VRay_Matte_Alpha\" " +  (amarray[3][i] as string) + ")")
		)
	)
	amarray = 0
	return astr
),

function captureall idx arollout ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.captureall(index=%, arollout=%)\n"tabs idx arollout to:pilelog)

-- material safetey; puts *most* materials into the matlib, looks for maxfilename.mat and appends to the materiallibrary any materials from the matlib that are missing from the scene, then backs up the matlib before saving it.
	backwashthematlib ind
	backupmymatlib 1 ind

	if harvestcat[1] == true do(
		anarray = #()
		acaparray = #()
		keyname = ((getnamedselsetname idx) + "_" +  "vis")
		g = 1
		for i in selectionsets[idx] do(
			acmd = (i.ishidden as string)
			setuserprop i keyname acmd
			arollout.informations.text = ("capturing vizibility... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
	if harvestcat[23] == true do(
		anarray = #()
		acaparray = #()
		keyname = ((getnamedselsetname idx) + "_" +  "rndb")
		g = 1
		for i in selectionsets[idx] do(
			acmd = (i.renderable as string)
			setuserprop i keyname acmd
			arollout.informations.text = ("capturing renderable... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
	if harvestcat[25] == true do(
		anarray = #()
		acaparray = #()
		keyname = ((getnamedselsetname idx) + "_" +  "aat")
		g = 1
		for i in selectionsets[idx] do(
			acmd = (i.applyatmospherics as string)
			setuserprop i keyname acmd
			arollout.informations.text = ("capturing apply-atmospherics... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
	if harvestcat[2] == true do(
		anarray = #()
		acaparray = #()
		keyname = ((getnamedselsetname idx) + "_" +  "csh")
		g = 1
		for i in selectionsets[idx] do(
			acmd = (i.castshadows as string)
			setuserprop i keyname acmd
			arollout.informations.text = ("capturing castshadows... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
	if harvestcat[3] == true do(
		anarray = #()
		acaparray = #()
		keyname = ((getnamedselsetname idx) + "_" +  "rsh")
		g = 1
		for i in selectionsets[idx] do(
			acmd = (i.receiveshadows as string)
			setuserprop i keyname acmd
			arollout.informations.text = ("capturing receiveshadows... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
	if harvestcat[4] == true do(
		anarray = #()
		acaparray = #()
		keyname = ((getnamedselsetname idx) + "_" +  "vtc")
		g = 1
		for i in selectionsets[idx] do(
			acmd = (i.primaryvisibility as string)
			setuserprop i keyname acmd
			arollout.informations.text = ("capturing primaryvisibility... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
	if harvestcat[5] == true do(
		anarray = #()
		acaparray = #()
		keyname = ((getnamedselsetname idx) + "_" +  "vtr")
		g = 1
		for i in selectionsets[idx] do(
			acmd = (i.secondaryvisibility as string)
			setuserprop i keyname acmd
			arollout.informations.text = ("capturing secondaryvisibility... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
	if harvestcat[6] == true do(
		anarray = #()
		acaparray = #()
		keyname = ((getnamedselsetname idx) + "_" +  "mb")
		g = 1
		for i in selectionsets[idx] do(
			acmd = (i.motionbluron as string)
			setuserprop i keyname acmd
			arollout.informations.text = ("capturing motionbluron... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)

		anarray = #()
		acaparray = #()
		keyname = ((getnamedselsetname idx) + "_" +  "mbt")
		g = 1
		for i in selectionsets[idx] do(
			acmd = ("#" + (i.motionblur as string))
			setuserprop i keyname acmd
			arollout.informations.text = ("capturing motionblur type... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
	if harvestcat[7] == true do(
		anarray = #()
		g = 1
		for i in selectionsets[idx] do(
			try(
				setuserprop i ((getnamedselsetname idx) + "_" +  "mat") ("'" + i.material.name + "'")
			)catch()
			arollout.informations.text = ("capturing materials... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)

	if harvestcat[24] == true do(
		keyname = ((getnamedselsetname idx) + "_" +  "crp")
		akeycmdstring = (captureallcommonrenderparams())
		acmd = ""; for i in akeycmdstring do(acmd = (acmd + i + "; "))
		g = 1
		for i in selectionsets[idx] do(
			setuserprop i keyname acmd
			arollout.informations.text = ("capturing common render params... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
	if harvestcat[8] == true do(
		keyname = ((getnamedselsetname idx) + "_" +  "rnd")
		akeycmdstring = (captureallrenderer())
		acmd = ""; for i in akeycmdstring do(acmd = (acmd + i + "; "))
		g = 1
		for i in selectionsets[idx] do(
			setuserprop i keyname acmd
			arollout.informations.text = ("capturing render params... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)

	if harvestcat[9] == true do(
		keyname = ((getnamedselsetname idx) + "_" +  "env")
		akeycmdarray= (pilecapenv())
		if akeycmdarray != #() do(
			acmd = ""; for i in akeycmdarray do(acmd = (acmd + i + "; "))
			g = 1
			for i in selectionsets[idx] do(
				setuserprop i keyname acmd
				--append caparray acmd
				arollout.informations.text = ("capturing environment... " + ((100.*g/selectionsets[idx].count) as string) + "%")
				g += 1
			)
		)
	)
	if harvestcat[10] == true do(
		keyname = ((getnamedselsetname idx) + "_" +  "atm")
		akeycmdarray= (pilecapatm())
		if akeycmdarray != #() do(
			acmd = ""; for i in akeycmdarray do(acmd = (acmd + i + "; "))
			g = 1
			for i in selectionsets[idx] do(
				setuserprop i keyname acmd
				arollout.informations.text = ("capturing atmospherics... " + ((100.*g/selectionsets[idx].count) as string) + "%")
				g += 1
			)
		)
	)
	if harvestcat[11] == true do(
		keyname = ((getnamedselsetname idx) + "_" +  "efx")
		akeycmdarray= (pilecapeff())
		if akeycmdarray != #() do(
			acmd = ""; for i in akeycmdarray do(acmd = (acmd + i + "; "))
			g = 1
			for i in selectionsets[idx] do(
				setuserprop i keyname acmd
				arollout.informations.text = ("capturing effects... " + ((100.*g/selectionsets[idx].count) as string) + "%")
				g += 1
			)
		)
	)
	if harvestcat[13] == true do(
		anarray = #()
		acaparray = #()
		keyname = ((getnamedselsetname idx) + "_" +  "shd")
		g = 1
		for i in selectionsets[idx] do(
			if superclassof i == light do(
				acmd = ((classof i.shadowgenerator) as string)
				setuserprop i keyname acmd
				arollout.informations.text = ("capturing shadowgenerator... " + ((100.*g/selectionsets[idx].count) as string) + "%")
				g += 1
			)
		)
	)
	if harvestcat[14] == true do(
		anarray = #()
		acaparray = #()
		keyname = ((getnamedselsetname idx) + "_" +  "rpa")
		g = 1
		acmd = getrenderelementstate()
		for i in selectionsets[idx] do(
			setuserprop i keyname acmd
			arollout.informations.text = ("capturing render elelments... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
	if harvestcat[15] == true do(
		anarray = #()
		acaparray = #()
		keyname = ((getnamedselsetname idx) + "_" +  "frs")
		g = 1
		for i in selectionsets[idx] do(
			if classof i == fumefx do(
				acmd = ("$'" + i.name + "'[4][10].shadefire = " + ((getproperty i[4][10] #shadefire) as string))
				acmd = (acmd + "; " + ("$'" + i.name + "'[4][10].shadesmoke = " + ((getproperty i[4][10] #shadesmoke) as string)))
				acmd = (acmd + "; " + ("$'" + i.name + "'[4][10].shadefuel = " + ((getproperty i[4][10] #shadefuel) as string)))
				setuserprop i keyname acmd
				arollout.informations.text = ("capturing fume render state... " + ((100.*g/selectionsets[idx].count) as string) + "%")
				g += 1
			)
		)
	)
	if harvestcat[16] == true do(
		anarray = #()
		keyname = ((getnamedselsetname idx) + "_" +  "ena")
		acmd = ""
		g = 1
		for i in selectionsets[idx] do(
			acmd = (getanabledstate i ind)
			setuserprop i keyname acmd
			arollout.informations.text = ("capturing enabled... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
	if harvestcat[17] == true do(
		anarray = #()
		keyname = ((getnamedselsetname idx) + "_" +  "vrm")
		g = 1
		for i in selectionsets[idx] do(
			aval = (getuserprop i "VRay_Matte_Enable")
			bval= (getuserprop i "VRay_Matte_Alpha")
			if aval != undefined do(
				acmd = ("setuserprop $'" + i.name + "' \"VRay_Matte_Enable\" " + "\"" + (aval as string) + "\"")
				if bval != undefined do(
					acmd = (acmd + "; setuserprop $'" + i.name + "' \"VRay_Matte_Alpha\" " + "\"" + (bval as string) + "\"")
					setuserprop i keyname acmd
				)
			)
			arollout.informations.text = ("capturing Vray Matte... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
	if harvestcat[18] == true do(
		anarray = #()
		acaparray = #()
		keyname = ((getnamedselsetname idx) + "_" +  "osv")
		g = 1
		acmd = getunifiedssetviz()
		for i in selectionsets[idx] do(
			setuserprop i keyname acmd
			arollout.informations.text = ("capturing other set unified viz... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
	if harvestcat[19] == true do(
		anarray = #()
		acaparray = #()
		keyname = ((getnamedselsetname idx) + "_" +  "osm")
		g = 1
		acmd = getunifiedssetmat()
		for i in selectionsets[idx] do(
			setuserprop i keyname acmd
			arollout.informations.text = ("capturing other set unified mat... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
	if harvestcat[26] == true do(
		anarray = #()
		acaparray = #()
		keyname = ((getnamedselsetname idx) + "_" +  "oaat")
		g = 1
		acmd = getunifiedssetprp #applyatmospherics
		for i in selectionsets[idx] do(
			setuserprop i keyname acmd
			arollout.informations.text = ("capturing other set unified apply-atmospherics... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
	if harvestcat[27] == true do(
		anarray = #()
		acaparray = #()
		keyname = ((getnamedselsetname idx) + "_" +  "opv")
		g = 1
		acmd = getunifiedssetprp #primaryvisibility
		for i in selectionsets[idx] do(
			setuserprop i keyname acmd
			arollout.informations.text = ("capturing other set unified primaryvizibility... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
	if harvestcat[20] == true do(
		anarray = #()
		acaparray = #()
		keyname = ((getnamedselsetname idx) + "_" +  "oena")
		g = 1
		acmd = getunifiedssetena()
		for i in selectionsets[idx] do(
			setuserprop i keyname acmd
			arollout.informations.text = ("capturing other set on/off... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
	arollout.informations.text = "done."
),

fn restoresingle akey idx arollout ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.restoresingle(key=%, index=%, arollout=%)\n"tabs akey idx arollout to:pilelog)

	keyname = ((getnamedselsetname idx) + "_" +  akey); g = 1
	format"attempting to restore %...\n"keyname
	if keyname != undefined do(
		isfound = 0
		for i in selectionsets[idx] while isfound == 0 do (
			acmd = (getuserprop i keyname)
			if acmd != undefined  do(
				try(execute(acmd); format"restoring: %\n\n"acmd; isfound = 1)catch(format"**** failed to restore: %\n\n"acmd; isfound = 1)
			)
		)
		arollout.informations.text = ("restoring " + akey + "... " + ((100.*g/selectionsets[idx].count) as string) + "%")
		g += 1
	)
),


function restoreall idx ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.restoreall(index=%)\n"tabs idx to:pilelog)
	-- find, parse and apply stored data
	-- #("vis", "csh", "rsh", "vtc", "vtr", "mb", "mat", "rnd", "env", "atm", "efx", "ray", "adv", "pas", "mod", "ena")

	-- restore vis moved to last place as retsore-other-set-same-vis may override it.
	listmats 0 ind

	if harvestcat[2] == true do(
		keyname = ((getnamedselsetname idx) + "_" +  "csh"); g = 1
		for i in selectionsets[idx] do(
			acmd = (getuserprop i keyname)
			if acmd != undefined  do(
				if classof acmd == booleanclass do(
					i.castshadows = acmd
				)
			)
			pilerollout.informations.text = ("restoring castshadows... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
	if harvestcat[23] == true do(
		keyname = ((getnamedselsetname idx) + "_" +  "rndb"); g = 1
		for i in selectionsets[idx] do(
			acmd = (getuserprop i keyname)
			if acmd != undefined  do(
				if classof acmd == booleanclass do(
					i.renderable = acmd
				)
			)
			pilerollout.informations.text = ("restoring renderable... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
	if harvestcat[3] == true do(
		keyname = ((getnamedselsetname idx) + "_" +  "rsh"); g = 1
		for i in selectionsets[idx] do(
			acmd = (getuserprop i keyname)
			if acmd != undefined  do(
				if classof acmd == booleanclass do(
					i.receiveshadows = acmd
				)
			)
			pilerollout.informations.text = ("restoring receiveshadows... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
	if harvestcat[4] == true do(
		keyname = ((getnamedselsetname idx) + "_" +  "vtc"); g = 1
		for i in selectionsets[idx] do(
			acmd = (getuserprop i keyname)
			if acmd != undefined  do(
				if classof acmd == booleanclass do(
					i.primaryvisibility = acmd
				)
			)
			pilerollout.informations.text = ("restoring primaryvisibility... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
	if harvestcat[5] == true do(
		keyname = ((getnamedselsetname idx) + "_" +  "vtr"); g = 1
		for i in selectionsets[idx] do(
			acmd = (getuserprop i keyname)
			if acmd != undefined  do(
				if classof acmd == booleanclass do(
					i.secondaryvisibility = acmd
				)
			)
			pilerollout.informations.text = ("restoring secondaryvisibility... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
	if harvestcat[6] == true do(
		keyname = ((getnamedselsetname idx) + "_" +  "mb"); g = 1
		g = 1
		for i in selectionsets[idx] do(
			acmd = (getuserprop i keyname)
			if acmd != undefined  do(
				if classof acmd == booleanclass do(
					i.motionbluron = acmd
				)
			)
			pilerollout.informations.text = ("restoring motionbluron... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)

		keyname = ((getnamedselsetname idx) + "_" +  "mbt"); g = 1
		g = 1
		for i in selectionsets[idx] do(
			acmd = (getuserprop i keyname)
			if acmd != undefined  do(
				setproperty i "motionblur" (execute(acmd))
			)
			pilerollout.informations.text = ("restoring motionblur type... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)

	)
	if harvestcat[25] == true do(
		keyname = ((getnamedselsetname idx) + "_" +  "aat"); g = 1
		for i in selectionsets[idx] do(
			acmd = (getuserprop i keyname)
			if acmd != undefined  do(
				if classof acmd == booleanclass do(
					i.applyatmospherics = acmd
				)
			)
			pilerollout.informations.text = ("restoring apply-atmospherics... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
-- restore material moved to last place as retsore-other-set-same-material may override it.

	if harvestcat[8] == true do(
		keyname = ((getnamedselsetname idx) + "_" +  "rnd"); g = 1
		for i in selectionsets[idx] do(
			if (getuserprop i keyname) != undefined  do(
				cmdarray = (stringstoarray (getuserprop i keyname))
				--execute(getuserprop i keyname)
				rpcount =  (cmdarray.count - 1)
				if ol.count != 0 do(
					renderscenedialog.close()
					try(
						execute(cmdarray[rpcount])
						for r = 1 to (rpcount - 1) do(
							aparam = cmdarray[r]
							if aparam != undefined do(
								asfp = (slashfix (aparam))
								try(
									execute(asfp)
								)catch(format"failed to restore: %\n"asfp)
							)
						)
						renderscenedialog.update()
					)catch(format"\n***** could not set the renderer,\n%\nskipping the renderer params...\n\n"cmdarray[rpcount])
				)
				exit
			)
			pilerollout.informations.text = ("restoring renderer... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)

	if harvestcat[24] == true do(
		keyname = ((getnamedselsetname idx) + "_" +  "crp"); g = 1
		for i in selectionsets[idx] do(
			if (getuserprop i keyname) != undefined  do(
				cmdarray = (stringstoarray (getuserprop i keyname))
				rpcount =  (cmdarray.count - 1)
				if ol.count != 0 do(
					renderscenedialog.close()
					-- format"setting the renderer: %\n"cmdarray[(rpcount)]
					for r = 1 to (rpcount) do(
						aparam = cmdarray[r]
						-- format"a param, a number: %\n"((aparam as string) + ", " + (i as string))
						if aparam != "rendOutputFilename = " do(
							if aparam != undefined do(
								if aparam != "renderer = production" then(
									asfp = (slashfix (aparam))
									try(
										execute(asfp)
									)catch(format"failed to restore: %\n"asfp)
								)else(renderer = #production)
							)
						)
					)
					renderscenedialog.update()
					renderscenedialog.open()
				)
				exit
			)
			pilerollout.informations.text = ("restoring common render params... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)

	if harvestcat[9] == true do(
		restoresingle "env" idx pilerollout ind
	)
	if harvestcat[10] == true do(
		restoresingle "atm" idx pilerollout ind
	)
	if harvestcat[11] == true do(
		restoresingle "efx" idx pilerollout ind
	)
	if harvestcat[13] == true do(
		keyname = ((getnamedselsetname idx) + "_" +  "shd"); g = 1
		g = 1
		for i in selectionsets[idx] do(
			acmd = (getuserprop i keyname)
			if acmd != undefined  do(
				if superclassof i == light do(
					execute("$'" + i.name + "'.shadowgenerator = " + acmd + "()")
					-- )catch(format"failed to apply shadowgenerator: %\n"acmd)
				)
			)
			pilerollout.informations.text = ("restoring shadowgenerator... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
	if harvestcat[14] == true do(
		restoresingle "rpa" idx pilerollout ind
	)
	if harvestcat[15] == true do(
		keyname = ((getnamedselsetname idx) + "_" +  "frs"); g = 1
		g = 1
		for i in selectionsets[idx] do(
			acmd = (getuserprop i keyname)
			if acmd != undefined  do(
				if classof i == fumefx do(
					try(
						execute(acmd)
					)catch(format"failed to apply fumefx render state: %\n"acmd)
				)
			)
			pilerollout.informations.text = ("restoring fume render state... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)
-- restore enabled moved to last place as retsore-other-set-same-enabled may override it.
-- restore vray matte moved to last place as retsore-other-set-same-ray-matte may override it.

	if harvestcat[18] == true do(
		restoresingle "osv" idx pilerollout ind
	)
	if harvestcat[19] == true do(
		restoresingle "osm" idx pilerollout ind
	)
	if harvestcat[20] == true do(
		restoresingle "oena" idx pilerollout ind
	)
	if harvestcat[26] == true do(
		restoresingle "oaat" idx pilerollout ind
	)
	if harvestcat[27] == true do(
		restoresingle "opv" idx pilerollout ind
	)
	if harvestcat[21] == true do(
		restoresingle "ccd" idx pilerollout ind
	)

	if harvestcat[1] == true do(
		keyname = ((getnamedselsetname idx) + "_" +  "vis"); g = 1
		for i in selectionsets[idx] do(
			acmd = (getuserprop i keyname)
			if acmd != undefined  do(
				if classof acmd == booleanclass do(
					i.ishidden = acmd
				)
			)
			pilerollout.informations.text = ("restoring ishidden... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)

	if harvestcat[16] == true do(
		keyname = ((getnamedselsetname idx) + "_" +  "ena"); g = 1
		if keyname != undefined do(
			for i in selectionsets[idx] do(
				acmd = (getuserprop i keyname)
				if acmd != undefined  do(
					try(execute(acmd))catch(format"failed to execute: %\n"acmd)
				)
				pilerollout.informations.text = ("restoring enabled... " + ((100.*g/selectionsets[idx].count) as string) + "%")
				g += 1
			)
		)
	)

	if harvestcat[7] == true do(
		keyname = ((getnamedselsetname idx) + "_" +  "mat"); g = 1
		for i in selectionsets[idx] do(
			amatname = (getuserprop i keyname)
			amat = undefined
			for m in currentmateriallibrary do(if ("'" + m.name + "'") == amatname do(amat = m; exit))
			if amat == undefined do(for m in meditmaterials do(if ("'" + m.name + "'") == amatname do(amat = m; exit)))
			if amat == undefined do(for m in scenematerials do(if ("'" + m.name + "'") == amatname do(amat = m; exit)))
			if amat != undefined  then(
				i.material = amat
			)else(format"missing material: %\n"amatname)
			pilerollout.informations.text = ("restoring material... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)

	if harvestcat[17] == true do(
		keyname = ((getnamedselsetname idx) + "_" +  "vrm"); g = 1
		if keyname != undefined do(
			for i in selectionsets[idx] do(
				acmd = (getuserprop i keyname)
				if acmd != undefined  do(
					format"restoring vraymatte: %\n"acmd
					try(execute(acmd))catch(format"failed to execute: %\n"acmd)
				)
			)
			pilerollout.informations.text = ("restoring Vray matte... " + ((100.*g/selectionsets[idx].count) as string) + "%")
			g += 1
		)
	)

	pilerollout.informations.text = "done."
),

/*END data functions */

/*BEGIN import functions */

function getmergedselectionsets = (
	existingselsets = #()
	for q  = 1 to selectionsets.count do(
		append existingselsets (getnamedselsetname q)
	)
	akey = "sset*"
	tmpsetarray = #(#(), #(), #())
	g = 1.0
	for i in objects do(
		astream = ((getuserpropbuffer i) as stringstream)
		akeyarray = #(#(), #())
		while not eof astream do(
			astr = readdelimitedstring astream " ="
			append akeyarray[1] (trimright (trimleft (astr)))
			try(skipToNextLine astream)catch(close astream)

		)
		for t in akeyarray[1] do(
			append akeyarray[2] (getuserprop i t)
		)
		for q = 1 to akeyarray[1].count do(
			if matchpattern akeyarray[1][q] pattern:akey == true do(
				if akeyarray[1][q] != "" do(
					if finditem existingselsets akeyarray[2][q] == 0 do(
						if finditem tmpsetarray[2] akeyarray[2][q] == 0 do(
							append tmpsetarray[1] akeyarray[1][q]
							append tmpsetarray[2] akeyarray[2][q]
							append tmpsetarray[3] #()
						)
					)
				)
			)
		)
		pilerollout.informations.text = ("scanning objects... " + ((100.*g/(objects.count)) as string) + "%")
		g += 1.0
	)
	if tmpsetarray[1].count != 0 then(
		for i in objects do(
			for t = 1 to tmpsetarray[1].count do(
				if (getuserprop i tmpsetarray[1][t]) != undefined do(
				 	if finditem tmpsetarray[3][t] i == 0 do(
				 		append tmpsetarray[3][t] i
					)
				)
			)
		)
		for t = 1 to tmpsetarray[1].count do(
			if tmpsetarray[3][t].count != 0 do(
				selectionsets[(tmpsetarray[2][t] as string)] = tmpsetarray[3][t]
			)
		)
	)else (messagebox"no merged sets found")
),

fn layerstosets = (
	for i = 0 to (layermanager.count - 1) do(
		alayer = layermanager.getlayer i
		alayer.nodes &alayerobjs
		aname = alayer.name
		selectionsets[aname] = alayerobjs
	)
),

/*END import functions */

/*BEGIN optimize functions */

function pebble ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.pebble()\n"tabs to:pilelog)

	-- depends on pillow.
	if querybox"this will clear the medit, continue?" title:"warning, this may cause data loss" beep:true then(
		for i = 1 to meditmaterials.count do(
			meditmaterials[i] = standard()
			meditmaterials[i].name = ("untitled_" + ((pillow i 2 ind) as string))
		)
	)
),

fn clearthematlib = (
	while currentmateriallibrary.count != 0 do(deleteitem currentmateriallibrary  currentmateriallibrary.count)
),


fn clearenv = (
	envEffectsDialog.Close()
	while numAtmospherics != 0 do(deleteAtmospheric numAtmospherics)
	if querybox"remove environment map?" beep:true then(environmentMap = undefined; useEnvironmentMap = false)else()
	envEffectsDialog.Open()
),

fn disableenv = (
	envEffectsDialog.Close()
	if numAtmospherics != 0 do(
		for i = 1 to numAtmospherics do(setactive (getAtmospheric i) false)
	)
	envEffectsDialog.Open()
),


fn cleareff = (

	if numeffects != 0 do(
		q = 1
		envEffectsDialog.Close()
		while q <= numeffects do(
			if (classof (getEffect q)) == Motion_Blur then(
				astream = ("" as stringstream)
				format"keep motion blur effect: %?"(getEffect q).name to:astream
				if querybox(astream) beep:true then(
					q += 1; astream = 0
				)else(deleteEffect q)
			)else(deleteEffect q)
		)
	)
),

fn clearglobaltracks = (
	if querybox"this will break other 3rd party tools (incl. brazil2 and onion), continue?" title:"***warning: this will cause data loss***" beep:true then(
		try(deleteTrackViewNode TrackViewNodes.Global_Tracks)catch()
	)
),

fn clearoldlayers  = (
	lnames = #()
	for i = 0 to (layermanager.count - 1) do(
		alayer = layermanager.getlayer i
		alayer.nodes &alayerobjs
		append lnames alayer.name
	)
	for i = 1 to lnames.count do(
		layermanager.deleteLayerByName lnames[i]
	)
	pilerollout.informations.text = ("cleared " + ((lnames.count - (layermanager.count) ) as string) + " layers.")
),

fn clearlayers  = (
	nlayer = layermanager.getlayer 0
	for i in objects do(nlayer.addnode i)
	lnames = #()
	for i = 0 to (layermanager.count - 1) do(
		alayer = layermanager.getlayer i
		alayer.nodes &alayerobjs
		append lnames alayer.name
	)
	for i = 1 to lnames.count do(
		layermanager.deleteLayerByName lnames[i]
	)
	pilerollout.informations.text = ("cleared " + ((lnames.count - (layermanager.count) ) as string) + " layers.")
),

fn clearcustomfileproperties = (
	if (fileProperties.getNumProperties #custom) != 0 do(
		prpnames = #()
		for i = 1 to (fileProperties.getNumProperties #custom) do(
			append prpnames (fileProperties.getPropertyName #custom i)
		)
		for i in prpnames do(
			fileProperties.deleteProperty #custom i
		)
	)
),


function gutthescene ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.gutthescene()\n"tabs to:pilelog)
	-- remember the 'break your scene' warning?
	if querybox"gut the scene of all but selected?" beep:true then(
		anarray = #()
		for i in selection do(append anarray i)
		delme = #()
		for i in objects where (finditem anarray i) == 0 do( append delme i)
		delete delme
		pebble ind
		clearthematlib()
		clearenv()
		cleareff()
		persistents.removeAll()
		callbacks.removeScripts() ; callbacks.show()
		clearthematlib()
		clearoldlayers()
		clearcustomfileproperties()
		for i in objects do (clearAllAppData i)
		try(deleteTrackViewNode TrackViewNodes.Global_Tracks)catch()
		SceneExposureControl.exposurecontrol = undefined
		environmentMap = undefined; useEnvironmentMap = false
		rendOutputFilename = "";renderscenedialog.close(); renderscenedialog.commit()
	)else()
),

/*END optimize functions */

/*BEGIN scene functions */

fn saveIncrBackup amode ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.saveIncrBackup(amode=%)\n"tabs amode to:pilelog)

	amaxnum = 0
	anewname = ""

	if (doesfileexist (maxfilepath + "wip\\")) == false do(makedir (maxfilepath + "wip\\"))
	basearray = (striplastnums (getfilenamefile maxfilename) ind)
	baseone = basearray[1]
	if basearray[2] != undefined do(amaxnum = (basearray[2] as integer))
	thebackups = getFiles (maxfilepath + "wip\\" + baseone + "*.max")
	-- format"found backups: %\n"thebackups
	format"parsing this maxfile: %\n"basearray
	if thebackups.count != 0 do(
		for f in thebackups do(
			asep = (striplastnums (getfilenamefile f) ind)
			format"parsing backup: %\n"asep
			if asep[2] != "" do(
				if asep[1] == baseone do(
					if (asep[2] as integer) > amaxnum do amaxnum = (asep[2] as integer)
				)
			)
		)
	)
	anewname = (baseone + (pillow (amaxnum + 1) 2 ind) + ".max")
	format"new backup name: %\n"anewname
	if amode == 0 then(
		copyfile (maxfilepath + maxfilename) (maxfilepath + "wip\\" + anewname)
		savemaxfile (maxfilepath + maxfilename) clearneedsaveflag:true usenewfile:true quiet:true
	)else(
		savemaxfile (maxfilepath + maxfilename) clearneedsaveflag:true usenewfile:true quiet:true
		copyfile (maxfilepath + maxfilename) (maxfilepath + "wip\\" + anewname)
	)
	if (doesfileexist (maxfilepath + "wip\\" + anewname)) == true then(
		format"backup complete. \n\n"
		pilerollout.informations.text = ("ok. backup= \\wip\\" + anewname)
	)else(messagebox"backup failed, check permissions and disk space." title:"error")
),

/*end scene functions */

/*BEGIN stateCheck functions */

fn gettristateofmodifiers objs mclass param ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.gettristateofmodifiers(objs.count=%, modifierclass=%, param=%)\n"tabs objs.count mclass param to:pilelog)
	g = 0
	rt = 2
	for i in objs do(
		mc = i.modifiers.count
		if mc != 0 do(
			isunfound = true
			for m = 1 to mc while isunfound do(
				if (classof i.modifiers[m]) == mclass do(
					if (isproperty i.modifiers[m] param) == true do(
						if (getproperty i.modifiers[m] param) == true do(g += 1)
						isunfound = false
					)
				)
			)
		)
	)
	--format"g=%\n"g
	case g of(
		(objs.count): rt = 1
		(0): rt = 0
	)
	-- special cases:
	-- if param == #ishidden do(nrt = (rt - 1); if nrt <= 0 do(rt = abs(nrt)))
	return rt
),

fn gettristateofcommon objs param ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.gettristateofcommon(objs.count=%, param=%)\n"tabs objs.count param to:pilelog)
	--sw = timestamp()
    local first         = true
    local allMatch      = true
    local allFound      = true
    local state         = undefined
    for o in objs do (
        if ( isproperty o param ) then (
            if ( state == undefined )               then state = getProperty o param
            else if state != getProperty o param    then allMatch = false
        )
        else allFound = false

        -- If not allMatch or state is not undefined (oneFound) and not allFound, break out
        if ( not allMatch or (state != undefined and not allFound) ) then exit
    )
    local out = 2
    if ( state == undefind )            then out = 0       -- -1 means no objects had that property, disable control
    else if ( allMatch and allFound )   then out = (if state then(1) else(0))

	if param == #ishidden do(ht=#(1, 0, 2); out = ht[(out+1)])
	--esw = timestamp()
	--format"FN:gettristateofcommon: tristate check for % took % milliseconds\n\n"param (esw - sw)
    return out
),

fn gettristateofsub objs sb param ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.gettristateofsub(objs.count=%, sub=%, param=%)\n"tabs objs.count sb param to:pilelog)
	g = 0
	rt = 2
	for i in objs do(
		try(
			g = (execute("$'" + i.name + "'." + (sb as string) ))
			if (isproperty g param) == true do(
				if (getproperty i param) == true do(g += 1)
			)
		)catch()
	)
	--format"g=%\n"g
	case g of(
		(objs.count): rt = 1
		(0): rt = 0
	)
	-- special cases:
	-- if param == #ishidden do(nrt = (rt - 1); if nrt <= 0 do(rt = abs(nrt)))
	return rt
),

function getgraystate objs aparam invtoggle ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.getgraystate(objs.count=%, param=%, invert=%)\n"tabs objs.count aparam invtoggle to:pilelog)
	-- format"FN: getgraystate ... %\n"aparamlist
	aparamlist = #()
	if invtoggle == 0 then(
		for i in objs do(append aparamlist (execute("$'" + i.name + "'." + aparam)))
	)else(
		for i in objs do(append aparamlist (not (execute("$'" + i.name + "'." + aparam))))
	)

	rtval = 0
	if aparamlist [1] == true then( rtval = 1) else (rtval = 0)
	if aparamlist.count != 1 do(
		for t = 2 to aparamlist .count do(
			if (aparamlist[1] != aparamlist[t]) do(rtval = 2; exit)
		)
	)
	return rtval
),


fn getgraystatefrompfe objs ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.getgraystatefrompfe(objs.count=%)\n"tabs objs.count to:pilelog)
	rt = 0
	for i in objs do(
		if classof objs[i] == ParticleGroup do(
			astr = (getpfgEventname i)
			acmd = ("$'" + astr + "'.isactivated()")
			try(
				aval = execute(acmd)
				if finditem valarray aval != 0 then(append valarray aval)else(rt = 2)
			)catch(format"could not evaluate activation state of: %\n"objs[i].name)
		)
	)
	if valarray != 0 then(
		if rt != 2 do(
			case valarray[1] of(
				true: rt = 1
				false: rt = 0
			)
		)
	)else(rt = 0)
	return rt
),

fn checkchecks extr ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.checkchecks(extrachecks=%) -- updates UI checkboxes.\n"tabs extr to:pilelog)
	--sw = timestamp()
	pilerollout.isviz.tristate = ((gettristateofcommon csl #ishidden ind))
	pilerollout.issel.tristate = ((gettristateofcommon csl #isselected ind))
	pilerollout.isfrz.tristate = ((gettristateofcommon csl #isfrozen ind))
	isena = ((gettristateofcommon csl #on ind))
	pilerollout.ison.tristate = isena
	pilerollout.fumefn.enabled = false
	for i = 1 to csl.count where (classof csl[i]) == fumefx do(pilerollout.fumefn.enabled = true)

	if extr == true do(
		try(pilerollout.iscacheon.tristate = (gettristateofmodifiers csl point_cache2 #enabled ind) )catch()
		if pilerollout.iscacheon.tristate == 0 do(
			try(pilerollout.iscacheon.tristate = (gettristateofmodifiers csl point_cache #enabled ind) )catch()
		)
		if pilerollout.iscacheon.tristate == 0 do(
			try(pilerollout.iscacheon.tristate =  (getgraystate csl "transform.controller.enabled" 0 ind))catch()
		)
		try(pilerollout.isparticleon.tristate = getgraystatefrompfe objs ind)catch()
		try(pilerollout.isparticleon.tristate = getgraystate csl "enabled" 0 ind)catch()
		try(pilerollout.isparticleon.tristate = getgraystate csl "baseobject.Enable_Particles" 0 ind)catch()
		try(pilerollout.isparticleon.tristate = getgraystate csl "viewpercent > 0.0" 0 ind)catch()
		try(pilerollout.isparticleon.tristate = getgraystate csl "viewportcount > 0.0" 0 ind)catch()
		try(pilerollout.isparticleon.tristate = getgraystate csl "Viewport_Particles > 0.0" 0 ind)catch()
		if pilerollout.isparticleon.tristate == 0 do(pilerollout.isparticleon.tristate = (gettristateofmodifiers csl TP_PGroupObjectModifier #enabled ind) )
	)
	if csl.count > 1 then(
		acolor = (color 128 128 128)
		for i in csl do(acolor = (acolor + i.wirecolor))
		acolor = (acolor / csl.count)
		pilerollout.wirecol.color = acolor
	)else(
		if csl.count != 0 do(pilerollout.wirecol.color = csl[1].wirecolor)
	)
	--esw = timestamp()
	--format"FN:checkchecks: checks took % milliseconds\n\n"(esw - sw)
),

/*end stateCheck functions */

/*BEGIN bag functions */

	function fixslash astring ind = (
		ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	    if dopilelog == true do(format"%pile.fixslash(path=%)\n"tabs astring to:pilelog)

		rtstring = ""
		anarray = (filterstring astring "\\")
		if getfilenametype astring != "" then(
			if anarray.count != 0 do(
				for t = 1 to (anarray.count - 1) do(if t != "" do(rtstring = (rtstring + (anarray[t] + "/"))))
				rtstring = (rtstring + anarray[(anarray.count)])
			)
		)else(
			if anarray.count != 0 do(
				for t = 1 to (anarray.count) do(if t != "" do(rtstring = (rtstring + (anarray[t] + "/"))))
			)
		)
		if rtstring != "" then(return rtstring)else(return astring)
	),

	function getlastdir apath ind = (
		ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	    if dopilelog == true do(format"%pile.getlastdir(path=%)\n"tabs apath to:pilelog)
		anarray = filterstring apath "/"
		if anarray.count > 1 then(
			lastdir = anarray[anarray.count]
			if lastdir[lastdir.count] == "/" do(
				lastdir = (trimright lastdir "/")
			)
			return lastdir
		)else(
			anarray = filterstring apath "\\"
				if anarray.count > 1 do(
					lastdir = anarray[anarray.count]
					if lastdir[lastdir.count] == "\\" do(
						lastdir = (trimright lastdir "\\")
					)
				return lastdir
			)
		)
	),

	function gatherdirs adir exclarray ind = (
		ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	    if dopilelog == true do(format"%pile.gatherdirs(path=%, exclude=%)\n"tabs adir exclarray to:pilelog)
		rt = #(#(), #())
		anarray = (getDirectories (adir + "*"))
		larray = for i = 1 to anarray.count collect (getlastdir anarray[i] ind)
		for i = 1 to larray.count do(
			if (maxVersion())[1] >= 9000 then(
				if (bsearch larray[i] exclarray sortbystring) == undefined do(
					append rt[1] anarray[i]
					append rt[2] larray[i]
				)
			)else(
				if (finditem exclarray larray[i]) == 0 do(
					append rt[1] anarray[i]
					append rt[2] larray[i]
				)
			)
		)
		return rt
	),

	function gatherfiles adir anextarray exclfilearray excludedirarray includedirarray ind = (
		ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	    if dopilelog == true do(format"%pile.gatherdirs(path=%, extensions=%, excludeFiles=%, excludeDirs=%, includeDirs=%)\n"tabs adir anextarray exclfilearray excludedirarray includedirarray to:pilelog)

		adirarray = #(adir)
		i = 0
		-- recursive directory harvesting:
		/*
		while i < adirarray.count do(
			darray = #()
			fdir = adirarray[(i + 1)]
			darray = (gatherdirs fdir excludedirarray ind)[1]
			join adirarray darray
			if i > 1000 do(exit)
			i += 1
		)
		*/
		anarray = #()
		for i in adirarray do(
			astr = i
			afixeddir = fixslash astr ind
			sethalt = 0
			apatharray = filterstring afixeddir "/"
			if excludedirarray.count != 0 do(
				if (maxVersion())[1] >= 9000 then(
					if (bsearch apatharray[apatharray.count] excludedirarray sortbystring) != undefined do(sethalt = 1)
				)else(
					if (finditem excludedirarray apatharray[apatharray.count]) != 0 do(sethalt = 1)
				)
			)
			if includedirarray.count != 0 do(
				if includedirarray[1] != "*" do(
					if (maxVersion())[1] >= 9000 then(
						if (bsearch apatharray[apatharray.count] includedirarray sortbystring) == undefined do(sethalt = 1)
					)else(
						if (finditem includedirarray apatharray[apatharray.count]) == 0 do(sethalt = 1)
					)
				)
			)
			if sethalt == 0 do(
				for e in anextarray do(
					farray = getfiles (afixeddir + "/*." + e)
					join anarray farray
				)
			)
		)
		rtarray = #(#(), #())
		if (maxVersion())[1] >= 9000 then(
			for f in anarray where (bsearch (getFilenameType f) exclfilearray sortbystring) == undefined do(
					append rtarray[1] f; append rtarray[2] (getfilenamefile f)
			)
		)else(
			for f in anarray where (finditem exclfilearray (getFilenameType f)) == 0 do(
				append rtarray[1] f; append rtarray[2] (getfilenamefile f)
			)
		)
		return rtarray
	),

/*END bag functions */

/*BEGIN whip functions */

	fn pilegetsequence afilepath ind =(
		ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	    if dopilelog == true do(format"%pile.pilegetsequence(path=%)\n"tabs afilepath to:pilelog)

		nnum = (striplastnums (getfilenamefile afilepath) ind)[1]
		fnw = ((getfilenamepath afilepath) + nnum + "*" + (getfilenametype afilepath))
		-- format"pilegetsequence: input path: %\n"fnw
		sequ = (getfiles fnw)
		qsort sequ sortbystring
		-- for i in sequ do(format"pilegetsequence: found file: %\n"i)
		return sequ
	),

	fn saveIncrBackuprender thepath thefiles aprfx ind = (
		ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
		if dopilelog == true do(format"%pile.saveIncrBackuprender(path=%, files.count=%, prefix=%)\n"tabs thepath thefiles aprfx to:pilelog)

		-- format"FN:saveIncrBackuprender: % % % \n"thepath thefiles aprfx
		copiedfiles = #()
		amaxnum = 0
		anewname = ""
		anext = getfilenametype thefiles[1]
		if (doesfileexist (thepath + "wip\\")) == false do(makedir (thepath + "wip\\"))
		basearray = (striplastnums (getfilenamefile thefiles[1]) ind)
		baseone = basearray[1]

		--nbase = replace baseone baseone.count 1 ""
		basearray = (striplastnums basearray[1] ind)
		if aprfx != "" then(
			baseone = (basearray[1] + (aprfx + "_"))
		)else(
			baseone = basearray[1]
		)
		if basearray[2] != undefined do(amaxnum = (basearray[2] as integer))
		thebackups = getFiles (thepath + "wip\\" + baseone + "*" + anext)
		-- format"found backups: %\n"thebackups
		format"parsing this file: %\n"basearray
		if thebackups.count != 0 do(
			for f in thebackups do(
				asep = (striplastnums (getfilenamefile f) ind)
				nsep = replace asep[1] asep[1].count 1 ""
				asep = (striplastnums nsep ind)
				format"parsing backup: %\n"asep
				if asep[2] != "" do(
					if asep[1] == baseone do(
						if (asep[2] as integer) > amaxnum do amaxnum = (asep[2] as integer)
					)
				)
			)
		)
		for i = 1 to thefiles.count do(
			basearray = (striplastnums (getfilenamefile thefiles[i]) ind)
			if aprfx != "" then(
				baseone = (basearray[1] + (aprfx + "_"))
			)else(
				baseone = basearray[1]
			)
			afnum = basearray[2]
			anewname = (baseone + (pillow (amaxnum + 1) 2 ind) + "_" + afnum +  anext)
			format"new backup name: %\n"anewname
			copyfile (thefiles[i]) (thepath + "wip\\" + anewname)
			if (doesfileexist (thepath + "wip\\" + anewname)) == true then(
				format"copy verified. \n\n"
				append copiedfiles (thepath + "wip\\" + anewname)
			)else(format"copy failed, check permissions and disk space. \n")
			pilerollout.informations.text = ("saving backup of render... " + ((100.*i/thefiles.count) as string) + "%")
		)
		pilerollout.informations.text = ""
	),

	function extractpilerender aset ind = (
		ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
		if dopilelog == true do(format"%pile.extractpilerender(set=%)\n"tabs aset to:pilelog)
		afile = ""
		keyname = ((getnamedselsetname aset) + "_" +  "crp")
		ghu = true
		for q = 1 to selectionsets[aset].count while ghu do(
			akey = (getuserprop selectionsets[aset][q] keyname)
			if akey != "" do(
				if akey != undefined do(
					cmdarray = filterstring akey ";"
					for i in cmdarray do(
						if (matchpattern i pattern:"*rendOutputFilename*") == true do(
							afile = (trimleft i " rendOutputFilename = \"")
							afile = (trimright afile "\"")
							ghu = false
						)
					)
				)
			)
		)
		return afile
	),
	function ramplayseq afile ind = (
		seq = (pilegetsequence afile ind)
		if seq.count != 0 do(
			nifl = ((getfilenamepath afile) + (getfilenamefile afile) + ".ifl")
			tifl = createfile nifl
			for i in seq do(format"%\n"i to:tifl)
			close tifl
			ramplayer nifl ""
		)
	),
	function cyclestoredrender aset ind = (
		afile = (extractpilerender aset ind)
		if afile != "" do(
			if doesfileexist "C:\\Program Files\\FrameCycler_Pro_2.70\\bin\\FrameCycler.exe" == true then(
				try(
					fnw = ((getfilenamepath afile) + (getfilenamefile afile) + "#" + (getfilenametype afile))
					format"attempting to framecycle sequence...\n"
					shelllaunch "C:\\Program Files\\FrameCycler_Pro_2.70\\bin\\FrameCycler.exe" fnw
				)catch(ramplayseq afile ind)
			)else(ramplayseq afile ind)
		)
	),

	function backstoredrender aset ind = (
		ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
		if dopilelog == true do(format"%pile.backstoredrender(set=%)\n"tabs aset to:pilelog)

		afile = (extractpilerender aset ind)
		seq = (pilegetsequence afile ind)
		saveIncrBackuprender (getfilenamepath afile) seq "" ind
	),

	function printrenderpacketsizes = (
		renderSceneDialog.commit()
		anum = ((((rendend - rendstart) as integer) / ticksperframe) + 1)
		astr = ("" as stringstream)
		epad = "    "

		srtarray = #(#(), #())
		append srtarray[1] "render start"; append srtarray[2] ((rendstart as string) + epad)
		append srtarray[1] "render end"; append srtarray[2] ((rendend as string) + epad)
		append srtarray[1] "render range"; append srtarray[2] ((anum as string) + "f" + epad)
		pd = paddedDelimit srtarray " " 0 ": "
		for i in pd do(format"%\n"i to:astr)
		format"\n" to:astr

		srtarray = #(#(), #(), #())
		padlen = (anum as string).count
		for i = 1 to anum do(
			amod=(mod anum i)
			if amod == 0.0 do(
				append srtarray[1] (pillow i padlen 0)
				append srtarray[2] "packets"
				append srtarray[3] ("@ " + (pillow (anum/i) padlen 0) + " hosts" + epad)
			)
		)
		pd = paddedDelimit srtarray " " 0 " "
		for i in pd do(format"%\n"i to:astr)
		srtarray = 0
		messagebox astr title:"packet sizes"
	),

	function showmemytestrenders apath afile anext ind = (
		ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
		if dopilelog == true do(format"%pile.showmemytestrenders(path=%, file=%, extension=%)\n"tabs apath afile anext to:pilelog)

		arr = getfiles ( (striplastnums (apath + afile) ind)[1] + "*" + anext )
		if arr.count != 0 then(
			prv1 = arr[1]
			nifl = ((getfilenamepath prv1) + (getfilenamefile prv1) + ".ifl")
			tifl = createfile nifl
			for i in arr do(format"%\n"i to:tifl)
			close tifl
			ramplayer nifl ""
		)else(
			arr = 0; messagebox"could not find a preview for this file"
		)
		arr = 0
	),

	function showmeapreview  apath afile anext ind = (
		ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
		if dopilelog == true do(format"%pile.showmeapreview(path=%, file=%, extension=%)\n"tabs apath afile anext to:pilelog)

		arr = getfiles ( apath + afile + anext )
		if arr.count != 0 then(
			prv1 = arr[1]
			fcyc = "C:\\Program Files (x86)\\IRIDAS FrameCycler Professional\\bin\\FrameCycler.exe_not"
			if (doesfileexist fcyc) == true then(
				shelllaunch fcyc prv1
			)
			else(
				nifl = ((getfilenamepath prv1) + (getfilenamefile prv1) + ".ifl")
				tifl = createfile nifl
				for i in arr do(format"%\n"i to:tifl)
				close tifl
				ramplayer nifl ""
			)
		)else(
			arr = 0; messagebox"could not find a preview for this file"
		)
		arr = 0
	),

	function makemeapreview adir afname anext prvs prve ind = (
		ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
		if dopilelog == true do(format"%pile.makemeapreview(path=%, name=%, extension=%, start=%, end=%)\n"tabs adir afname anext prvs prve to:pilelog)
		vps = getViewSize()
		rar = interval animationrange.start animationrange.end
		reint = 0
		if animationrange.start > prvs do(reint = 1)
		if animationrange.end < prve do(reint = 1)
		if reint != 0 do(animationRange = interval prvs prve)
		rs = slidertime
		ct1 = (pillow ((prvs as integer) / ticksperframe) 4 ind)
		prv1 = (adir + afname + "_" +  (ct1) + anext)
		oldf = getfiles (adir + afname + "*.*")
		for o in oldf do(format"deleting old preview file: %\n"o; deletefile o)
		oldf = 0
		for t = prvs to prve do(
			sliderTime = t
			dib = gw.getViewportDib()
			ct = (pillow ((currenttime as integer) / ticksperframe) 4 ind)
			prv = (adir + afname + "_" +  (ct) + ".tga")
			buf = bitmap vps.x vps.y filename:prv
			copy dib buf
			save buf
			close buf
			if keyboard.escPressed == true do(slidertime = rs; exit)
		)
		gc()
		if reint != 0 do(animationRange = rar)
		slidertime = rs
	),

	function renderplanarUV ds cclip flp nine = (
		if selection.count != 0 do(
			targ = selection[1]
			mapmod = targ.modifiers[#uvw_mapping]
			if mapmod != undefined then(
				oviz = for i in objects where i.ishidden == false collect i
				try(delete $delme_UVcam)catch()
				acam = freecamera name:"delme_UVcam"
				ovp = viewport.getCamera()
				ovt = 0
				ovxf = 0
				if ovp == undefined do(ovt = viewport.gettype(); ovxf = viewport.getTM())
				viewport.setCamera acam

				acam.transform = (mapmod.gizmo.transform * (inverse (getmodcontexttm targ mapmod)) * targ.objecttransform)
				oxf = acam.transform
				case mapmod.axis of(
					0: (in coordsys acam rotate acam (EulerAngles 0 -90 0); acam.pos = oxf.pos; in coordsys acam rotate acam (EulerAngles 0 0 180); acam.pos = oxf.pos)
					1: (in coordsys acam rotate acam (EulerAngles -90 0 0); acam.pos = oxf.pos; in coordsys acam rotate acam (EulerAngles 0 0 180); acam.pos = oxf.pos)
					2: ()
				)

				tw = (mapmod.width / 2)
				th = (mapmod.length / 2)
				apct = th/tw
				orw = renderwidth
				orh = renderheight
				renderwidth = 1000
				renderheight = ((1000*apct) as integer)
				renderSceneDialog.close()
				renderSceneDialog.commit()
				renderSceneDialog.update()

				if cclip == true then(
					acam.clipmanually = true
					acam.nearclip = ds
					acam.farclip = (ds + 10000)
				)else(
					acam.clipmanually = false
				)
				in coordsys acam(acam.pos.z += ds)
				acam.showcone = true
				aw = sqrt((tw^2)+(ds^2) - 2 * tw * ds * cos(90))
				fa = asin((tw / aw) * sin(90))
				ca = 180 - (90 + fa)
				acam.fov = fa*2
				ogi = 0
				if hasproperty renderers.current #gi_on == true do(ogi = renderers.current.gi_on; renderers.current.gi_on = false)
				ouenv = getUseEnvironmentMap()
				setuseenvironmentmap false
				ovenv = 0
				if hasproperty renderers.current #environment_gi_on == true do(ovenv = renderers.current.environment_gi_on; renderers.current.environment_gi_on = false)
				obcol = getBackGround()
				setBackGround (color 0.0 0.0 0.0)

				hide objects; unhide targ

				render outputfile:(((getdir #preview) + "\\")  + "UV_" + selection[1].name + ".tga") outputwidth:(renderwidth) outputheight:(renderheight) shadows:false renderatmosphericeffects:false renderMultiPassEffects:false renderElements:false VFB:true useRadiosity:false

				unhide oviz

				setBackGround obcol
				setuseenvironmentmap ouenv
				if ogi != 0 do(renderers.current.gi_on = ogi)
				if ovenv != 0 do( renderers.current.environment_gi_on = ovenv)
				delete $delme_UVcam
				renderwidth = orw
				renderheight = orh
				renderSceneDialog.close()
				renderSceneDialog.commit()
				renderSceneDialog.update()
				if ovp != undefined then(viewport.setCamera ovp)else(viewport.settype ovt; viewport.setTM ovxf)

			)else(messagebox"uvw modifier not found.\n")
		)
	),

/*END whip functions */

/*BEGIN UI functions */

fn putvizheader itm setidx fst ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.putvizheader(item=%, setID=%, fst=%)\n"tabs itm setidx fst to:pilelog)
	rrt = ""
	pk = "_"
	iv = (gettristateofcommon selectionsets[setidx] #ishidden ind)
	case iv of(
		0: (pk = "~")
		1: (pk = "V")
		2: (pk = "X")
	)
	if fst == 0 then(
		iflt = (filterstring itm " ")
		rrt = pk
		for i = 2 to iflt.count do(
			rrt = (rrt + " " + iflt[i])
		)
	)else(
		rrt = (pk + " " + itm)
	)
	return rrt
),

fn updateinformations = (
	if csl.count == 1 do(
		ic = ""
		iv = ""
		im = ""
		ip = ""
		ret = #()
		if ifc == true do(ic = "class=" + (classof csl[1] as string); append ret ic)
		if ifv == true do(if classof csl[1] == editable_mesh or classof csl[1] == editable_poly do(iv = "verts=" + (csl[1].numverts as string)); append ret iv)
		if ifm == true do(if csl[1].material != undefined then(im = "mat=" + csl[1].material.name)else(im = "mat=undefined"); append ret im)
		if ifp == true do(if csl[1].parent != undefined then(ip = "parent=" + csl[1].parent.name)else(ip = "parent=undefined"); append ret ip)
		if ret.count != 0 then(
			if ret.count == 1 then(pilerollout.informations.text = ret[1])else(astr = ret[1]; for i = 2 to ret.count do(astr = (astr + " | " + ret[i])); pilerollout.informations.text = astr)
		)
	)
),

fn populateslist lbx selstr nar ind =(
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.populateslist(list=%, selected=%, nar=%)\n"tabs lbx selstr nar to:pilelog)

	lbx.Items = #() -- clear the set-list UI
	rtn = #() -- array for selection-set names, will become the set-list items.
	rti = #()
	sc = #() -- array of set member counts, gathered to determine the padding depth.
	delme = #() -- array for empty sets to delete.
	hasdat = #() -- array of data checks

-- get non-empty sets, delete empty ones:
	stripundefinedfromsets ind
	for i = 1 to selectionsets.count where selectionsets[i].count == 0 do(
		append delme (getnamedselsetname i)
	)
	if delme.count != 0 do(
		for i in delme do(
			idx = (getsetidxfromname i ind)
			if idx != 0 do(
				deleteitem selectionsets idx
			)
		)
		delme = 0
	)

-- gahter set names and set indices:
	for i = 1 to selectionsets.count do(
		append rtn (getnamedselsetname i)
		append rti i
	)

-- sort arrays by set name:
	qsort rti sortbystringinarray a:rtn
	qsort rtn sortbyval

-- gather set object-counts and data presence:
	for i = 1 to rtn.count do(
		append sc selectionsets[(rti[i])].count
		dt = false
		dt = (getuserprop selectionsets[(rti[i])][(random 1 selectionsets[(rti[i])].count)] (rtn[i] + "_vis")) != undefined
		append hasdat dt
	)


-- rebuild setlist array:
	sl = 0
	sl = #(#(), #())
	sl[1] = for i in rtn collect i
	sl[2] = for i in rti collect i

-- set 'allcheck variable' - this is used later to update pile if the scene object count has changed.
	for i = 1 to rtn.count where rtn[i] == "ALL" do(allcheck = selectionsets[(rti[i])].count)

-- putting headers:
	if listtags == true then(
		maxval = ((amax sc) as string).count
		for i = 1 to rtn.count do(
			ssidx = rti[i]
			ssname = rtn[i]
			t = "~"; if hasdat[i] == true do(t = "D")
			vh = putvizheader ("- " + t + " [" + (pillow sc[i] maxval ind) + "]  " + ssname) ssidx 0 ind
			rtn[i] = vh
		)
	)

-- populating the list (max native):
	lbx.items = rtn

-- restoring the selection by searching an array of set names and getting the list indices for the matching names:
	idxa = #()
	if (maxVersion())[1] >= 9000 then(
		for i = 1 to sl[1].count where (bsearch sl[1][i] selstr sortbystring) != undefined do(append idxa i)
	)else(
		for i = 1 to sl[1].count where (finditem selstr sl[1][i]) != 0 do(append idxa i)
	)
	if idxa.count != 0 then(
		if idxa.count == 1 then(
			lbx.selection = idxa[1]
		)else(
			lbx.selection = idxa
		)
	)else(
		lbx.selection = 1
		append idxa 1
	)

-- tidy up:
	rtn = 0; rti = 0; sc = 0

-- disable data restore button id there is no data, or if there is more than 1 set selected:
	if idxa.count != 1 then(
		pilerollout.capdat.enabled = false
		pilerollout.resdat.enabled = false
	)else(
		pilerollout.capdat.enabled = true
		pilerollout.resdat.enabled = hasdat[(idxa[1])]
	)
),

function checkmats ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.checkmats()\n"tabs to:pilelog)
	if checkstoredmatsonly == 1 then(
		pilematlist = (listmats 1 ind)
	)else(pilematlist = (listmats 0 ind))
),

function setslscroll listsel ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.setslscroll(%)\n"tabs listsel to:pilelog)
	if classof listsel == integer do(listsel = #(listsel))
	if listtags == true do(
		if listsel.count > 1 do(
			sm = listsel[listsel.count]
			-- format"sm = %\n"listsel
			lm = ssl.items.count
			cm =((ssl.height / 13) as integer)
			hl = ((listsel.count / 2) as integer)
			hc = ((cm / 2) as integer)
			ladj = (sm + (hc - hl))
			if ladj > lm do(ladj = lm)
			ssl.selection = ladj
			ssl.selection = listsel
		)
	)
),

function selolist sidx oidx dosel doframe ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.selolist(%, %, %, %)\n"tabs sidx oidx dosel doframe to:pilelog)
	-- sw = timestamp()
	if classof sidx == integer then(sidx = #(sidx))else(sidx = (sidx as array))
	cset = #(); for i in sidx do(append cset sl[1][i])
	if pilerollout.autoisoset.checked or pilerollout.autohu.checked do(hide objects)

	csl = #()
	tmp = #()
	for i in sidx do(
		ssidx = sl[2][i]
		if pilerollout.autoisoset.checked or pilerollout.autohu.checked do(unhide selectionsets[ssidx])
		for b in oidx where (finditem selectionsets[ssidx] ol[b]) != 0 do(
			append csl ol[b]
			-- format"selecting: %\n"ol[b]
		)
	)
	if (pilerollout.olist.selection as array)[1] != oidx[1] do(
		-- format"% does not match %\n"(pilerollout.olist.selection as array)[1] oidx[1]
		pilerollout.olist.selection = oidx
	)
	-- esw = timestamp()
	-- format"FN:selolist: getting id's took % milliseconds\n"(esw - sw)
	-- sw = timestamp()
	cslc = csl.count
	if dosel == true then(
		if cslc != 0 do(
			if cslc > 1 do(max create mode)
			disablesceneredraw()
			clearselection()
			select csl
			if doframe == true do(viewport.zoomtobounds false $.min $.max)
			pilerollout.issel.state = true
			enablesceneredraw()
		)
		-- esw = timestamp()
		-- format"FN:selolist: selecting stuff with dosel took % milliseconds\n\n"(esw - sw)
	)else(
		if cslc != 0 do(
			if doframe == true do(
				disablesceneredraw()
				-- cpm = getCommandPanelTaskMode()
				max create mode
				tmpa = getCurrentSelection()
				clearselection()
				select csl
				viewport.zoomtobounds false $.min $.max
				clearselection()
				if tmpa.count != 0 do(
					select tmpa
				)
				tmpa = 0
				-- setCommandPanelTaskMode mode:cpm
				enablesceneredraw()
			)
			-- esw = timestamp()
			-- format"FN:selolist: selecting stuff without dosel took % milliseconds\n\n"(esw - sw)
		)
	)
	checkchecks pilerollout.doextrachecks.state ind
	if pilerollout.autoisoobj.checked do(isolateobjs csl ind)

	tmp = #()

	if csl.count == 1 then (
		pilerollout.onametxt.text = csl[1].name

		if pile.sprp != "" then(
			pilerollout.informations.text = (csl[1].name + pile.sprp + "=" + (execute("$'" + csl[1].name + "'" + pile.sprp) as string))
		)else(
			updateinformations()
		)
	)else(pilerollout.onametxt.text = ""; pilerollout.informations.text = ((csl.count as string) + " objects highlighted."))

	pile.refreshsprp ind

),

function refreshvizheader ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.refreshvizheader()\n"tabs to:pilelog)

	sidx = ssl.selection
	ml = 1
	if classof sidx == integer then(sidx = #(sidx); ml = 0)else(sidx = (sidx as array))

	if listtags == true do(
		c = ssl.items.count; tmp = #()
		for i = 1 to c do(tmp[i] = ssl.items[i])
		for t = 1 to c do(
			ssidx = sl[2][t]
			vh = (putvizheader tmp[t] ssidx 0 ind)
			tmp[t] = vh
		)
		ssl.items = #()
		ssl.items = tmp; tmp = 0
		if ml == 0 then(ssl.selection = sidx[1])else(ssl.selection = sidx)
	)
	idx = sl[2][sidx[1]]
	iv = (gettristateofcommon selectionsets[idx] #ishidden ind)
	if sidx.count > 1 do(
		for i = 2 to sidx.count do(
			idx = sl[2][sidx[i]]
			ov = (gettristateofcommon selectionsets[idx] #ishidden ind)
			if ov != iv then(iv = 2; exit)else(iv = ov)
		)
	)
	case iv of(
		0: (pilerollout.setvizt.tristate = 0)
		1: (pilerollout.setvizt.tristate = 1)
		2: (pilerollout.setvizt.tristate = 2)
	)
),


fn populateOList lbx flt fltc sidx arollout flags ind =(
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.populateOList(%, %, %, %, %, %)\n"tabs lbx flt fltc sidx arollout flags to:pilelog)
	-- format"FN:populateOList: % % % % %\n\n"lbx flt fltc sidx arollout
	lbx.Items = #()
	ol = #()
	-- sw = timestamp()
	if classof sidx == integer then(sidx = #(sidx))else(sidx = (sidx as array))
	for i in sidx do(
		--if dopilelog == true do(format"%pile.populateOList->pile.getsetidxfromname\n"tabs to:pilelog)
		ssidx = sl[2][i]
		-- format"active selection set: %\n"(getnamedselsetname i)
		for o in selectionsets[ssidx] where (finditem ol o) == 0  do(
			-- format"checking % against filter\n"(o.name)
			if flt != "*" then(
				nf = (not arollout.nflt.state)
				case fltc of(
					1: (if (matchpattern o.name pattern:(flt  + "*")) == nf do(append ol o) )
					2: (if (matchpattern (classof o as string) pattern:(flt  + "*")) == nf do(append ol o) )
					3: (if (matchpattern  (superclassof o as string) pattern:(flt  + "*")) == nf do(append ol o) )
					4: (try(if (matchpattern  ((classof o.material) as string) pattern:(flt  + "*")) == nf do(append ol o) )catch())
					5: (
						if o.modifiers.count != 0 do(
							mc = #(); isfound = true
							for m = 1 to o.modifiers.count while isfound do(
								mc = ((classof o.modifiers[m]) as string)
								if (matchpattern mc pattern:(flt  + "*")) == nf do(
									if (finditem ol o) == 0 do(append ol o; isfound = false)
								)
							)
						)
					)
				)
			)else(append ol o)
		)
	)
	-- esw = timestamp()
	-- format"FN:populateOList: gathering the objects took % milliseconds\n\n"(esw - sw)
	-- format"FN populateOList: ol = %\n"ol
	if ol.count != 0 do(
		-- sw = timestamp()
		rt = #()
		-- qsort ol sortbyproperty "name"
		--if dopilelog == true do(format"%pile.populateOList->pile.refreshsprp\n"tabs to:pilelog)
		refreshsprp ind

		if sprp != "" then(
			qsort ol sortbyproperty
		)else(qsort ol sortbyname)

		-- esw = timestamp()
		-- format"FN:populateOList: sorting the list took % milliseconds\n\n"(esw - sw)

		if hrch == true then(
			-- sw = timestamp()
			if flt != "*" then(alst = (list2h ol 1 flt))else(alst = (list2h ol 0 flt))
			-- format"FN:populateOList alst= %\n"alst
			ol = alst[1]
			if alst[1].count != 0 do(
				for i = 1 to alst[1].count do(
					pad = ""
					-- format"FN:populateOList: alst[2][i] = %\n"alst[2][i]
					for t = 1 to alst[2][i] do(pad = (pad + "    "))
					append rt (pad + alst[1][i].name)
				)
			)
			-- esw = timestamp()
			-- format"FN:populateOList: building the hierarchy took % milliseconds\n\n"(esw - sw)
		)else(
			for i in ol do(append rt i.name)
		)
		if flags == true do(
			-- sw = timestamp()
			nrt = #()
			pad = "~"
			for i = 1 to rt.count do(
				a = #(); clo = (instanceMgr.getInstances ol[i] &a)
				vz = pad; if ol[i].ishidden == false do(vz = "V")
				if clo > 1 then(clo = "C")else(clo = pad)
				frz = pad; if ol[i].isfrozen == true do(frz = "F")
				sk = pad; if ol[i].modifiers.count > 0 do(sk = "S")
				mt = "---"; if classof ol[i].material == matteshadow or classof ol[i].material == blur_matte_mtl or (getuserprop ol[i] "VRay_Matte_Enable")  == true do(mt = "M")
				append nrt (( "[" + vz + frz + clo + sk + mt + "]  ") + rt[i])
			)
			-- format"found objects: %\n"rt
			rt = 0; rt = nrt
			-- esw = timestamp()
			-- format"FN:populateOList: displaying flags took % milliseconds\n\n"(esw - sw)
		)
		lbx.Items = rt; rt = 0
--sw = timestamp()
		st = #()
		if csl.count != 0 do(
			for i = 1 to ol.count where finditem csl ol[i] != 0 do(
				append st i
			)
		)
		if st.count != 0 then(
			lbx.selection = st
			if csl.count == 1 then (arollout.onametxt.text = csl[1].name)else(arollout.onametxt.text = "")
		)else(
			lbx.selection = 1
			-- selolist sidx (lbx.selection as array)
			csl = #(ol[1])
			arollout.onametxt.text = csl[1].name
		)
--esw = timestamp()
--format"FN:populateOList: reselecting the list took % milliseconds\n\n"(esw - sw)
-- sw = timestamp()
		if csl.count == 1 then (
			-- pilerollout.onametxt.text = csl[1].name
			if sprp != "" then(
				pilerollout.informations.text = (csl[1].name + sprp + "=" + (execute("$'" + csl[1].name + "'" + sprp) as string))
			)else(
				pilerollout.informations.text = ((classof csl[1]) as string)
			)
		)else(pilerollout.onametxt.text = ""; pilerollout.informations.text = ((csl.count as string) + " objects highlighted."))
		st = 0
-- esw = timestamp()
-- format"FN:populateOList: displaying informations took % milliseconds\n\n"(esw - sw)
-- sw = timestamp()
-- esw = timestamp()
-- format"FN:populateOList: refreshing the viz header took % milliseconds\n\n"(esw - sw)
	)
),
fn selsetlist sidx ind = (
	ind += 1
	tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.selsetlist(%)\n"tabs sidx to:pilelog)
	-- format"pile.selsetlist: \n"
	if classof sidx == integer then(sidx = #(sidx))else(sidx = (sidx as array))
	if sidx.count != 0 do(
		currentpilesetname = sl[1][(sidx[1])]

		sw = timestamp()
		pile.populateOList pilerollout.olist oflt pilerollout.cflt.selection sidx pilerollout doflags ind
		esw = timestamp()
		-- format"    pile.selsetlist: populate objectlist took % milliseconds\n"(esw - sw)

		if pilerollout.sels.state == true do(
			pilerollout.autosel.state = false
			olc = ol.count
			if olc != 0 do(
				select ol
				pilerollout.issel.state = true
			)
		)

		if sidx.count == 1 then (
			pilerollout.snametxt.text = currentpilesetname
		)else(pilerollout.snametxt.text = "")

		sw = timestamp()
		selolist sidx (pilerollout.olist.selection as array) pilerollout.autosel.checked pilerollout.autoframe.state ind
		esw = timestamp()
		-- format"    pile.selsetlist: select in objectlist took % milliseconds\n"(esw - sw)

		if sidx.count != 1 then(
			pilerollout.capdat.enabled = false
			pilerollout.resdat.enabled = false
		)else(
			pilerollout.capdat.enabled = true
			pilerollout.resdat.enabled = hasdat[(sidx[1])]
		)
		refreshvizheader ind
	)
),

fn pileYresize = (


		pad = 8
        plh = 124
		if (maxVersion())[1] >= 9000 do(plh = ssl.height)
		if (classof pile.ssl) == ComboBoxControl then(
        	plh = 20
            if (maxVersion())[1] < 9000 do(pilerollout.height -= 104)
        )else(
        	if (maxVersion())[1] < 9000 do(pilerollout.height += 104)
        )
			pilerollout.snametxt.pos.y = (ssl.pos.y + plh + pad)
			pilerollout.capdat.pos.y = (pilerollout.snametxt.pos.y + 16 + pad)
			capd = pilerollout.capdat.pos.y
			pilerollout.slistf.pos.y = capd
			pilerollout.setf.pos.y = capd
			pilerollout.datf.pos.y = capd
			pilerollout.setvizt.pos.y = capd
			pilerollout.sels.pos.y = capd
			pilerollout.autoisoset.pos.y = capd
			pilerollout.autohu.pos.y = capd
			pilerollout.resdat.pos.y = capd
				pilerollout.nflt.pos.y = (capd + 16 + pad)
				nfl = pilerollout.nflt.pos.y
				pilerollout.flttxt.pos.y = nfl
				pilerollout.flbl.pos.y = nfl
				pilerollout.cflt.pos.y = nfl
					pilerollout.listby.pos.y = (pilerollout.nflt.pos.y + 21 + pad)
					lst = pilerollout.listby.pos.y
					pilerollout.sellbl.pos.y = lst
					pilerollout.srtlbl.pos.y = lst
					pilerollout.sortby.pos.y = lst
						pilerollout.olist.pos.y = (lst + 16 + pad)
						olst = pilerollout.olist.pos.y
						pilerollout.addtoset.pos.y = olst
						pilerollout.remfromset.pos.y = olst+ 16
						pilerollout.syncset.pos.y = olst + 32

		if (maxVersion())[1] >= 9000 then(pilerollout.olist.height = ((pilerollout.height) - (olst + 74)))else()

		if (maxVersion())[1] >= 9000 then(
        	pilerollout.onametxt.pos.y = (olst + pilerollout.olist.height + pad)
        )else(
        	if (classof pile.ssl) == ComboBoxControl then(
				pilerollout.onametxt.pos.y = (560 + pad)
            )else(
               pilerollout.onametxt.pos.y = (664 + pad)
            )
        )

		pilerollout.onamefn.pos.y = pilerollout.onametxt.pos.y


		pilerollout.renfrom.pos.y = (pilerollout.onametxt.pos.y + pilerollout.onametxt.height + pad)
		pilerollout.rento.pos.y = pilerollout.renfrom.pos.y
		pilerollout.doinky.pos.y = pilerollout.renfrom.pos.y

		pilerollout.informations.pos.y = (pilerollout.doinky.pos.y + 26)
		pilerollout.xpt.pos.y = pilerollout.informations.pos.y

		owh = (17 * 16)
        olh = 150
		if (maxVersion())[1] >= 9000 do(olh = (pilerollout.olist.height / 2))
		lhd = olh - (owh / 2)
		pilerollout.copymenu.pos.y = (pilerollout.renfrom.pos.y) - lhd
		pilerollout.matddl.pos.y = pilerollout.copymenu.pos.y - 16
		pilerollout.fumefn.pos.y = pilerollout.matddl.pos.y - 16
		pilerollout.isparticleon.pos.y = pilerollout.fumefn.pos.y - 16
		pilerollout.iscacheon.pos.y = pilerollout.isparticleon.pos.y - 16
		pilerollout.doextrachecks.pos.y = pilerollout.iscacheon.pos.y - 16
		pilerollout.wirecolfn.pos.y = pilerollout.doextrachecks.pos.y - 16
		pilerollout.WireCol.pos.y = pilerollout.wirecolfn.pos.y
		pilerollout.ison.pos.y = pilerollout.WireCol.pos.y - 16
		pilerollout.isfrz.pos.y = pilerollout.ison.pos.y - 16
		pilerollout.isviz.pos.y = pilerollout.isfrz.pos.y - 16
		pilerollout.issel.pos.y = pilerollout.isviz.pos.y - 16
		pilerollout.autoisoobj.pos.y = pilerollout.issel.pos.y - 16
		pilerollout.autoframe.pos.y = pilerollout.autoisoobj.pos.y - 16
		pilerollout.autosel.pos.y = pilerollout.autoframe.pos.y - 16
		pilerollout.objf.pos.y = pilerollout.autosel.pos.y - 16
		pilerollout.propf.pos.y = pilerollout.objf.pos.y - 16
		if pilerollout.olist.pos.y > (pilerollout.propf.pos.y - 16) then(pilerollout.olistf.pos.y = pilerollout.propf.pos.y - 16)else(
			if pilerollout.olist.pos.y < (pilerollout.syncset.pos.y + 16) then(
				pilerollout.olistf.pos.y = (pilerollout.syncset.pos.y + 16)
			)else(
				pilerollout.olistf.pos.y = pilerollout.olist.pos.y
			)
		)
),
/*END UI functions */

/*BEGIN selectionset functions */

function getssetnames ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.getssetnames()\n"tabs to:pilelog)
	rt = #(); for i = 1 to selectionsets.count do(append rt (getnamedselsetname i))
	return rt
),

function getssetobjnames sidx ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.getssetobjnames(%)\n"tabs sidx to:pilelog)
	if classof sidx == integer then(sidx = #(sidx))else(sidx = (sidx as array))
	rt = #()
	for i in sidx do(
		ssidx = sl[2][i]
		for o in selectionsets[ssidx] do(append rt o.name)
	)
	return rt
),

fn getobjsofsets listindex ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.getobjsofsets(%)\n"tabs listindex to:pilelog)
	if classof listindex == integer do(listindex = #(listindex))
	setobjs = #()
	ssetnames = #()
	for s in listindex do(
		ssidx = sl[2][s]
		append ssetnames (getnamedselsetname ssidx)
		objarray = #()
		for i in selectionsets[ssidx] do(append objarray i)
		append setobjs objarray; objarray = #()
	)
	return #(ssetnames, setobjs)
),

function removefromselset objs retiring nopop ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.removefromselset(objs.count=%, set_to_rebuild=%, don't_populate_list=%)\n"tabs objs retiring nopop to:pilelog)
	if classof retiring == integer then(retiring = #(retiring))else(retiring = (retiring as array))
	restoreme = #()
	restoreobjs = #()
	for i = 1 to retiring.count do(
		append restoreme sl[1][(retiring[i])]
		append restoreobjs #()
		idx = sl[2][(retiring[i])]
		propbackwash sl[1][(retiring[i])] objs ind
		for o in selectionsets[idx] where (finditem objs o) == 0 do(
			append restoreobjs[i] o
		)
		deleteitem selectionsets idx
	)
	if nopop == 0 do(
		ds = 0
		for i = 1 to restoreme.count do(
			if restoreobjs[i].count != 0 then(
				selectionsets[(restoreme[i])] = restoreobjs[i]
			)else(ds = 1)
		)
		if ds == 0 then(populateslist ssl restoreme 0 ind)else(populateslist ssl #((getnamedselsetname selectionsets.count)) 0 ind)
		populateOList pilerollout.olist oflt pilerollout.cflt.selection (ssl.selection) pilerollout doflags ind
	)
),

function makenewselset objs names ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.makenewselset(%, %)\n"tabs objs names to:pilelog)
	sidx = (ssl.selection)
	if classof sidx == integer then(sidx = #(sidx))else(sidx = (sidx as array))
	nsn = ""
	if names.count == 0 then(
		nsn = (renameset "new_set" 1 #() ind)
		selectionsets[nsn] = objs
		for o in objs do(setuserprop o ("sset_" + nsn) nsn)
	)else(
		for i in names do(
			nsn = i
			selectionsets[i] = objs
			for o in objs do(setuserprop o ("sset_" + i) i)
		)
	)
	populateslist ssl #(nsn) 0 ind
	sidx = (ssl.selection)
	if classof sidx == integer then(sidx = #(sidx))else(sidx = (sidx as array))
	if sidx.count == 1 then(pilerollout.snametxt.text = nsn)else()
	populateOList pilerollout.olist oflt pilerollout.cflt.selection sidx pilerollout doflags ind
	rt = #(); for i = 1 to ol.count where finditem objs ol[i] != 0 do(append rt i)
	pile.selolist (ssl.selection) rt pile.pilerollout.autosel.checked  pile.pilerollout.autoframe.state 0
),

function addtoselset objs sets ind = (
	ind += 1; tabs = ""; for i = 1 to ind do(tabs = tabs + "    ")
	if dopilelog == true do(format"%pile.addtoselset(%, %)\n"tabs objs sets to:pilelog)
	if classof sets == integer do(sets = #(sets))
	ssel = (getobjsofsets sets ind)
	for i = 1 to objs.count do(
		for t = 1 to ssel[2].count where (finditem ssel[2][t] objs[i]) == 0 do(
			append ssel[2][t] objs[i]
			setuserprop objs[i] ("sset_" + ssel[1][t]) ssel[1][t]
		)
		pilerollout.informations.text = ((((100.*i/objs.count) as integer) as string) + "%")
	)
	for s in ssel[1] do(deleteitem selectionsets (getsetidxfromname s ind))
	mxl = (sets.count as string).count
	nsna = #()
	nsn = ""
	for g = 1 to ssel[1].count do(
		selectionsets[(ssel[1][g])] = ssel[2][g]
	)
	pilerollout.informations.text = ""
	populateslist ssl ssel[1] 0 ind
	if sets.count == 1 then(pilerollout.snametxt.text = ssel[1][1])else()
	ssel = 0
	populateOList pilerollout.olist oflt pilerollout.cflt.selection (ssl.selection) pilerollout doflags ind
	rt = #(); for i = 1 to ol.count where finditem objs ol[i] != 0 do(append rt i)
	pile.selolist (ssl.selection) rt pile.pilerollout.autosel.checked  pile.pilerollout.autoframe.state 0
),

function selectionsetsynccheck = (
	tbl = #(#("LISTITEM"), #("PILE_SETNAME"), #("SELECTIONSET"), #("SELECTIONSETNAME_FROM_PILE_ID"), #("PILE_ID"), #("SET_ID"))
	for i = 1 to ssl.items.count do(append tbl[1] (ssl.items[i]))
	for i = 1 to pile.sl[1].count do(append tbl[2] (pile.sl[1][i]))
	for i = 1 to pile.sl[2].count do(append tbl[3] ((selectionsets[(pile.sl[2][i])] as string)))
	for i = 1 to pile.sl[2].count do(append tbl[4] ((selectionsets[(pile.getsetidxfromname pile.sl[1][i] 0)] as string)))
	for i = 1 to pile.sl[2].count do(append tbl[5] ((pile.sl[2][i] as string)))
	for i = 1 to pile.sl[2].count do(append tbl[6] (((pile.getsetidxfromname pile.sl[1][i] 0) as string)))
	strtable = pile.paddedDelimit tbl "-" 0 " | "
	format"pile.selectionsetsynccheck: selection-set sync check:\n"
	for i in strtable do(format"%\n"i)
	tbl = 0; strtable = 0
),
fn checksetstatechange = (
	try(selectionsets[("ALL")].count)catch(selectionsets[("ALL")] = (objects as array); format"Pile: making 'ALL'\n")
	if selectionsets[("ALL")].count != allcheck or selectionsets[("ALL")].count != objects.count then(
		if dopilelog == true do(format"\npile.checksetstatechange: ALL check failed\n" to:pilelog); ind = 0
		selectionsets[("ALL")] = (objects as array)
		sidx = (ssl.selection); if classof sidx == integer then(sidx = #(sidx))else(sidx = (sidx as array))
		tsn = #(); for i in sidx do(append tsn sl[1][i])
		tsl = csl
		csl = #()
		populateslist ssl tsn 0 ind
		tsn = 0
		populateOList pilerollout.olist oflt pilerollout.cflt.selection (ssl.selection) pilerollout doflags ind
		rt = #()
		for i = 1 to ol.count where (finditem tsl ol[i]) != 0 do(
			append rt i
		)
		if rt.count != 0 do(
			pilerollout.olist.selection = rt
			selolist (ssl.selection) rt pilerollout.autosel.checked pilerollout.autoframe.state ind
		)
		rt = 0; tsl = 0

		if sidx.count == 1 then (pilerollout.snametxt.text = pile.sl[1][1])else(pilerollout.snametxt.text = "")
		refreshvizheader ind
	)else()
)

)
/*END selectionset functions */

rollout rccd "custom data" width:500 height:152 (

	edittext ccedit "" pos:[0,4] width:496 height:92
	button ccc "close" pos:[448,128] width:48 height:16
	button ccsave "save" pos:[8,128] width:48 height:16
	progressBar ccprogbar "" pos:[60,132] width:328 height:8 color:(color 125 100 75)
	button ccexe "execute" pos:[396,128] width:48 height:16
	dropDownList qcap "" pos:[60,100] width:436 height:21
	label grabl "add..." pos:[12,104] width:40 height:16
	-- radioButtons ccmode "" pos:[60,100] width:117 height:16 enabled:true labels:#("all", "selected") default:1 columns:2

	on rccd open do(
		if dopilelog == true do(format"pile.rccd.open\n" to:pilelog); ind = 0
		idx = (pile.ssl.selection)
		if classof idx == array do(idx = idx[1])
		aidx = pile.sl[2][idx]
		keyname = ((getnamedselsetname aidx) + "_" +  "ccd")
		-- format"keyname = %\n"keyname
		-- rrccd = rccd
		for i in selectionsets[aidx] do(
			acmd = (getuserprop i keyname)
			-- format"acmd = %\n"acmd
			if acmd != undefined  do(
				ccedit.text = acmd; exit
			)
		)
		qcap.items = #("$.position",
		"$.rotation",
		"$.scale",
		"$.transform",
		"$.seed",
		"$.rate",
		"$.emitter",
		"slidertime")
		-- rrccd = rccd
	)
	on rccd resized rxf do(
		pad = 8
		ccedit.width = (rccd.width - (2 * pad))
		qcap.width = (rccd.width - (qcap.pos.x + pad))
		ccc.pos.x = (rccd.width - (48 + pad))
		ccexe.pos.x = (rccd.width - (2 * (48 + pad)))
		-- ccprogbar.width = (rccd.width - (ccprogbar.pos.x + (ccexe.pos.x + pad)))
		ccedit.height = (rccd.height - 61)
		qcap.pos.y = (ccedit.height + 16)
		grabl.pos.y = qcap.pos.y
		ccsave.pos.y = (grabl.pos.y + 24)
		ccprogbar.pos.y = (ccsave.pos.y + 4)
		ccexe.pos.y = ccsave.pos.y
		ccc.pos.y = ccsave.pos.y
	)

	on ccsave pressed do(
		sidx = (pile.ssl.selection)
		if classof sidx == array do(sidx = sidx[1])
		aidx = pile.sl[2][sidx]
		anarray = #()
		acaparray = #()
		keyname = ((getnamedselsetname aidx) + "_" +  "ccd")
			g = 1
			for i in selectionsets[aidx] do(
				acmd = ccedit.text
				setuserprop i keyname acmd
				ccprogbar.value = (100.*g/selectionsets[aidx].count)
				g += 1
			)
			ccprogbar.value = 0
	)
	on ccexe pressed do(execute(ccedit.text))
	on ccc pressed do(
		destroydialog rccd
	)
	on qcap selected idx do(
		if selection.count == 1 then(
			prp = ""
			val = 0
			case idx of(
				1: (prp = "pos"; val = ($.pos as string))
				2: (prp = "rotation"; val = ($.rotation as string))
				3: (prp = "scale"; val = ($.scale as string))
				4: (prp = "transform"; val = ($.transform as string))
				5: (if (isproperty $ #seed) == true do(prp = "seed"; val = ($.seed as string) ))
				6: (if (isproperty $ #rate) == true do(prp = "rate"; val = ($.rate as string) ))
				7: (if (isproperty $ #emitter) == true do(prp = "emitter"; val = ("$'" + $.emitter.name + "'") ))
				8: (prp = "slidertime"; val = (slidertime as string))
			)
			fl = (prp == "")
			fl = (val == 0)

			if fl != true then(
				if idx < 8 then(
					astr = ("$'" + $.name + "'." + prp + " = " + val + "; ")
				)else(astr = (prp + " = " + val + "; "))
				cstr = ccedit.text
				if cstr.count != 0 then(
					if cstr[cstr.count] != ";" then(
						if cstr[(cstr.count - 1)] != ";" then(
							cstr = (cstr + "; " + astr)
						)else(cstr = (cstr + astr))
					)else(
						cstr = (" " + cstr + astr)
					)
				)else(cstr = astr)
				ccedit.text = cstr
				cstr = 0
				astr = 0
			)else(messagebox"property not found.")
		)else(messagebox"this only works with 1 object selected.")
	)
)




/*BEGIN RCmenus */

-- dynamic rcmenus:
function pile_bag = (
	if dopilelog == true do(format"pile.bag\n" to:pilelog); ind = 0
	thescriptdirs = #(#(), #())
	thebagoscripts = #(#(), #())
	apath = scriptspath
	thescriptdirs = (pile.gatherdirs apath #("bak", "wip", "versions", "backup", "functions", "Startup") ind)
	tempStr = "rcMenu uiTestMENU (\n"
	for i = 1 to thescriptdirs[1].count do (
		tempStr += "submenu \"" + thescriptdirs[2][i] + "\"(\n"
		thebagoscripts = pile.gatherfiles thescriptdirs[1][i] #("ms") #("_proc_bag") #("bak", "wip", "versions", "backup", "functions", "history") #("*") ind
			for s = 1 to thebagoscripts[1].count do(
				tempStr += "\tmenuItem bmi_" + (i as string) + "_" + (s as string) + " \"" + thebagoscripts[2][s] + "\"\n"
			)
		tempStr += ")\n"
	)
	switches = #("t", "n", "r")
	for i = 1 to thescriptdirs[1].count do (
		thebagoscripts = pile.gatherfiles thescriptdirs[1][i] #("ms") #("_proc_bag") #("bak", "wip", "versions", "backup", "functions", "history") #("*") ind
		for s = 1 to thebagoscripts[1].count do(
			tempStr += "on  bmi_" + (i as string) + "_" + (s as string) + " picked do(filein \"" + thebagoscripts[1][s] + "\")\n"
		)
	)
	tempStr += ")"
	bagmenu = (execute(tempStr))
	return bagmenu
)

rcmenu ssf (
	menuitem ssf_sel "select"
	menuitem ssf_add "add"
	menuitem ssf_clone "clone"
	menuitem ssf_rem "remove"
)

rcmenu scnf (
	submenu "mxs" (
		menuitem scnf_ms "local scripts"
	)
	submenu "max" (
		menuitem scnf_bsav "back-up and save maxfile"
		menuitem scnf_savb "save and back-up maxfile"
		separator fm1
		menuitem scnf_bmat "back-up and save materials"
		menuitem scnf_mbw "restore missing materials from the matlib"
		separator fm22
		menuitem scnf_clp "copy full path to clipboard"
		menuitem scnf_exp "explorer..."
	)
	submenu "scn" (
		menuitem scnf_fmss "rebuild merged selection sets"
		menuitem scnf_glyr "layers -> selectionsets"
		separator gt3
		menuitem scnf_mxo "merge xref objects"
		menuitem scnf_mxs "merge xref scenes"
		separator gt2
		menuitem scnf_cxo "remove xref objects"
		menuitem scnf_cxs "remove xref scenes"
		separator scs2
		menuitem scnf_lpc "localize pointcaches"
		menuitem scnf_rpc "restore pointcache paths"
		separator sepfa
		menuitem scnf_pks "possible packet sizes"
		separator scs4
		submenu "informations" (
			menuitem scnf_ifc "class" checked:false
			menuitem scnf_ifv "numverts" checked:false
			menuitem scnf_ifm "materialname" checked:false
			menuitem scnf_ifp "parent" checked:false
		)
		separator scs32
		menuitem scnf_ptb "print selectionset sync table"
		submenu "diagnostics" (
			menuitem scnf_log "view pile diagnostics"
			menuitem scnf_recl "record pile diagnostics to file" checked:false
		)
	)
	submenu "opt" (
		menuitem scnf_gut "gut the scene"
		separator gt1
		menuitem scnf_reml "remove empty layers"
		menuitem scnf_remal "remove all layers"
		separator gt4
		menuitem scnf_rmlc "delete objects with missing caches"
		separator gt5
		menuitem scnf_cenv "clear environment"
		menuitem scnf_ceff "clear effects"
		menuitem scnf_cmed "clear the material editor"
		menuitem scnf_ccb "clear callbacks"
		menuitem scnf_cpg "clear persistent globals"
		menuitem scnf_cgt "clear globaltracks"
		menuitem scnf_cfp "clear fileproperties"
		menuitem scnf_cad "clear all appddata"
		menuitem scnf_fsb "clear bitmaps from memory"
		separator scs1
		menuitem scnf_dtp "particles disabled"
		menuitem scnf_dpc "pointcaches disabled"
		)
	submenu "ren" (
		menuitem qr_f "quickrender full"
		menuitem qr_h "quickrender half"
		menuitem qr_q "quickrender quarter"
		separator qrs3
		menuitem qr_p "review quickrenders"
		--menuitem qr_clr "clear quickrenders"
		separator qrs1
		submenu "quickrender overrides"(
			menuitem qr_sh "shadows" checked:true
			menuitem qr_atm "atmospherics" checked:true
			menuitem qr_mult "multipass effects" checked:false
			menuitem qr_mbl "motion blur" checked:false
			menuitem qr_gi "indirect illumination (vray)"
		)
		separator qrs2
		menuitem qr_fb "preview animation range"
		menuitem qr_rfb "preview render range"
		menuitem qr_cfb "preview from here"
		separator qrs345
		menuitem qr_last "reload last preview"
		menuitem qr_exp "open preview directory"
		separator qrs34
		menuitem qr_uel "update render element paths"
		menuitem qr_oid "assign unique object IDs"
		separator qrs36
		menuitem qr_ruv "render planar UV"
	)

	on scnf open do(
		if pile != 0 do(
			qr_sh.checked = pile.qrsh
			qr_atm.checked = pile.qratm
			qr_mult.checked = pile.qrmult
			scnf_recl.checked = dopilelog
			cnf_ifc.checked = pile.ifc
			scnf_ifv.checked = pile.ifv
			scnf_ifm.checked = pile.ifm
			scnf_ifp.checked = pile.ifp
			scnf_dtp.checked = pile.dtp
			scnf_dpc.checked = pile.dpc
		)
	)
	-- render menu
	on qr_gi picked do(qr_gi.checked = (not qr_gi.checked))
	on qr_mbl picked do(qr_mbl.checked = (not qr_mbl.checked))
	on qr_p picked do(
		if dopilelog == true do(format"pile.scnf.qr_p.picked\n" to:pilelog); ind = 0
		pile.showmemytestrenders ((getdir #preview) + "\\") "prv_" ".tga" ind
	)
	on qr_f picked do(
		if dopilelog == true do(format"pile.scnf.qr_f.picked\n" to:pilelog); ind = 0
		pile.rendermeapicture (renderwidth) (renderheight) qr_mbl.checked qr_gi.checked qr_sh.checked qr_atm.checked qr_mult.checked ind
	)
	on qr_h picked do(
		if dopilelog == true do(format"pile.scnf.qr_h.picked\n" to:pilelog); ind = 0
		pile.rendermeapicture (renderwidth / 2) (renderheight / 2) qr_mbl.checked qr_gi.checked qr_sh.checked qr_atm.checked qr_mult.checked ind
	)
	on qr_q picked do(
		if dopilelog == true do(format"pile.scnf.qr_q.picked\n" to:pilelog); ind = 0
		pile.rendermeapicture (renderwidth / 4) (renderheight / 4) qr_mbl.checked qr_gi.checked qr_sh.checked qr_atm.checked qr_mult.checked ind
	)
	on qr_sh picked do(qr_sh.checked = (not pile.qrsh); pile.qrsh = qr_sh.checked)
	on qr_atm picked do(qr_atm.checked = (not pile.qratm); pile.qratm = qr_atm.checked)
	on qr_mult picked do(qr_mult.checked = (not pile.qrmult); pile.qrmult = qr_mult.checked)
	on qr_fb picked do(
		if dopilelog == true do(format"pile.scnf.qr_fb.picked\n" to:pilelog); ind = 0
		pile.makemeapreview ((getDir #preview) + "\\") (getfilenamefile maxfilename) ".tga" animationrange.start animationrange.end ind
		pile.showmeapreview  ((getdir #preview) + "\\") (getfilenamefile maxfilename) "*.tga" ind
	)
	on qr_rfb picked do(
		if dopilelog == true do(format"pile.scnf.qr_rfb.picked\n" to:pilelog); ind = 0
		pile.makemeapreview ((getDir #preview) + "\\") (getfilenamefile maxfilename) ".tga" rendstart rendend ind
		pile.showmeapreview  ((getdir #preview) + "\\") (getfilenamefile maxfilename) "*.tga" ind
	)
	on qr_cfb picked do(
		if dopilelog == true do(format"pile.scnf.qr_cfb.picked\n" to:pilelog); ind = 0
		pile.makemeapreview ((getDir #preview) + "\\") (getfilenamefile maxfilename) ".tga" currenttime animationrange.end ind
		pile.showmeapreview  ((getdir #preview) + "\\") (getfilenamefile maxfilename) "*.tga" ind
	)
	on qr_last picked do(
		if dopilelog == true do(format"pile.scnf.qr_last.picked\n" to:pilelog); ind = 0
		pile.showmeapreview  ((getdir #preview) + "\\") (getfilenamefile maxfilename) "*.tga" ind
	)
	on qr_exp picked do(
		shelllaunch "explorer" ((getdir #preview) + "\\")
	)
	on qr_uel picked do(
		if dopilelog == true do(format"pile.scnf.qr_uel.picked\n" to:pilelog); ind = 0
		pile.updaterenderelementpaths ind
	)
	on qr_oid picked do(
		pile.assignobjIDs()
		pile.pilerollout.informations.text = "IDs assigned."
	)
	on qr_ruv picked do(
		pile.renderplanarUV 2000 false false false
	)
	-- maxfile menu

	on scnf_savb picked do(if querybox"save and backup?" title:"save..." beep:true then(if dopilelog == true do(format"pile.scnf.scnf_savb.picked\n" to:pilelog); ind = 0; pile.saveIncrBackup 1 ind)else())
	on scnf_bsav picked do(if querybox"backup and save?" title:"save..." beep:true then(if dopilelog == true do(format"pile.scnf.scnf_bsav.picked\n" to:pilelog); ind = 0; pile.saveIncrBackup 0 ind)else())
	on scnf_exp picked do(shelllaunch "explorer" (maxfilepath))
	on scnf_clp picked do(
		mf = (maxfilepath + maxfilename)
		if mf != "" do(
			afile = createfile (scriptspath + "delme.txt")
			format"%"mf to:afile
			afilep = (scriptspath + "delme.txt")
			doscommand ("CLIP < " + afilep)
			deletefile afilep
		)
	)
	on scnf_ms picked do(
		p = GetDialogPos pile.pilerollout
		popupmenu (pile_bag()) pos:[p.x,p.y]
	)
	on scnf_bmat picked do(
		if dopilelog == true do(format"pile.scnf.scnf_bmat.picked\n" to:pilelog); ind = 0
		pile.listmats 0 ind
		pile.backupmymatlib 0 ind
	)
	on scnf_mbw picked do(
		if dopilelog == true do(format"pile.scnf.scnf_mbw.picked\n" to:pilelog); ind = 0
		pile.pilerollout.informations.text = "attempting to restore missing maps/materials..."
		pile.backwashthematlib ind
		pile.pilerollout.informations.text = "ok"
	)

	-- scene menu

	on scnf_fmss picked do(
		if dopilelog == true do(format"pile.scnf.scnf_fmss.picked\n" to:pilelog); ind = 0
		(pile.getmergedselectionsets())
		pile.populateslist pile.ssl #((getnamedselsetname selectionsets.count)) 0 ind
		pile.populateOList pile.pilerollout.olist pile.oflt pile.pilerollout.cflt.selection (pile.ssl.selection) pile.pilerollout pile.doflags ind
	)
	on scnf_glyr picked do(
		if dopilelog == true do(format"pile.scnf.scnf_glyr.picked\n" to:pilelog); ind = 0
		pile.layerstosets()
		pile.populateslist pile.ssl #((getnamedselsetname selectionsets.count)) 0	ind
		pile.populateOList pile.pilerollout.olist pile.oflt pile.pilerollout.cflt.selection (pile.ssl.selection) pile.pilerollout pile.doflags ind
	)
	on scnf_mxs picked do(
		if querybox"merge all xref scenes?" title:"merge..." beep:true then(
			xc = xrefs.getXRefFileCount()
			if xc >= 1 do(
				while xc > 0 do(
					anxref = xrefs.getXRefFile xc
					merge anxref
					xc = xrefs.getXRefFileCount()
				)
			)
			pile.pilerollout.informations.text = ("merged " + (xc as string) + " scenes.")
		)else()
	)
	on scnf_cxs picked do(
		if querybox"clear all xref scenes?" title:"delete..." beep:true then(
			xc = xrefs.getXRefFileCount()
			if xc >= 1 do(
				while xc > 0 do(
					anxref = xrefs.getXRefFile xc
					delete anxref
					xc = xrefs.getXRefFileCount()
				)
			)
			pile.pilerollout.informations.text = ("removed " + (xc as string) + " xref scenes")
		)else()
	)
	on scnf_cxo picked do(
		if querybox"clear all xref objects?" title:"delete..." beep:true then(
			r = #()
			for i in objects do(
				xfo = (objXRefMgr.isnodexrefed i)
				if xfo != undefined do(
					append r i
				)
			)
			if r.count != 0 do(
				while r.count > 0 do(
					delete r[(r.count)]
				)
			)
			pile.pilerollout.informations.text = ("removed " + (r.count as string) + " xref objects")
			r = 0
		)else()
	)
	on scnf_lpc picked do(
		objs = for i in geometry where i.modifiers[#point_cache] != undefined collect i
		if objs.count != 0 do(
			pile.pilerollout.informations.text = ""
			pile.pilerollout.progbar.pos.y = pile.pilerollout.informations.pos.y
			pile.pilerollout.progbar.pos.x = pile.pilerollout.informations.pos.x
			pile.pilerollout.informations.pos.x += 68
			pile.pilerollout.informations.text = "localizing pointcaches..."
			pile.localizemypcpaths objs
			pile.pilerollout.progbar.pos.x = -500
			pile.pilerollout.informations.pos.x -= 68
			pile.pilerollout.informations.text = "ok"
		)
	)
	on scnf_rpc picked do(
		objs = for i in geometry where i.modifiers[#point_cache] != undefined collect i
		if objs.count != 0 do(
			pile.pilerollout.informations.text = ""
			pile.pilerollout.progbar.pos.y = pile.pilerollout.informations.pos.y
			pile.pilerollout.progbar.pos.x = pile.pilerollout.informations.pos.x
			pile.pilerollout.informations.pos.x += 68
			pile.pilerollout.informations.text = "localizing pointcaches..."
			pile.restoremypcpaths objs
			pile.pilerollout.progbar.pos.x = -500
			pile.pilerollout.informations.pos.x -= 68
			pile.pilerollout.informations.text = "ok"
		)
	)
	on scnf_pks picked do(pile.printrenderpacketsizes())
	on scnf_recl picked do(
		scnf_recl.checked = (not dopilelog)
		dopilelog= (not dopilelog)
		if dopilelog == true then(
			apath = (scriptspath + "pilelog.txt")
			if pilelog != 0 do(
				flush pilelog
				close pilelog
				if (doesfileexist apath) == true do(deletefile apath)
				format"pile diagnostic reset.\n"
			)
			pilelog = createfile apath
			format"session started at %\n\n"localTime to: pilelog
		)else(
			if pilelog != 0 do(
				format"\n\npile diagnostics stopped at %\n\n"localTime to: pilelog
				flush pilelog
				close pilelog
				format"pile diagnostic recording stopped.\n"
			)
		)
	)
	on scnf_log picked do(
		apath = (scriptspath + "pilelog.txt")
		if (doesfileexist apath) == true do(shelllaunch apath "")
	)
	on scnf_ifc picked do(
		scnf_ifc.checked = (not scnf_ifc.checked); pile.ifc = (scnf_ifc.checked); format"pile.scnf_ifc.checked = %, pile.ifc = %\n" scnf_ifc.checked pile.ifc; pile.updateinformations()
	)
	on scnf_ifv picked do(
		scnf_ifv.checked = (not pile.ifv); pile.ifv = (not pile.ifv); pile.updateinformations()
	)
	on scnf_ifm picked do(
		scnf_ifm.checked = (not pile.ifm); pile.ifm = (not pile.ifm); pile.updateinformations()
	)
	on scnf_ifp picked do(
		scnf_ifp.checked = (not pile.ifp); pile.ifp = (not pile.ifp); pile.updateinformations()
	)
	-- optimize menu

	on scnf_gut picked do(
		if dopilelog == true do(format"pile.scnf.scnf_gut.picked\n" to:pilelog); ind = 0
		pile.gutthescene ind
		pile.populateslist pile.ssl #((getnamedselsetname selectionsets.count)) 0 ind
		pile.populateOList pile.pilerollout.olist pile.oflt pile.pilerollout.cflt.selection (pile.ssl.selection) pile.pilerollout pile.doflags ind
	)
	on scnf_reml picked do(
		pile.clearoldlayers()
	)
	on scnf_remal picked do(
		pile.clearlayers()
	)
	on scnf_fsb picked do(
		format"removing bitmaps from memory..."; freescenebitmaps(); format" OK\n"
	)
	on scnf_ptb picked do(
		pile.selectionsetsynccheck()
	)
	on scnf_rmlc picked do(
		if dopilelog == true do(format"pile.scnf.scnf_rmlc.picked\n" to:pilelog); ind = 0
		retiring = #()
		for i in objects do(
			if classof i.transform.controller == Transform_Cache do(
				opc = (i.transform.controller.cachefile)
				if (doesfileexist opc) != true then(append retiring  i)
			)
			if i.modifiers.count > 0 do(
				for m = 1 to i.modifiers.count do(
					if classof i.modifiers[m] == point_cache_2 do(
						if (maxVersion())[1] < 9000 then(
							opc = (i.modifiers[m].cacheFile)
							if (doesfileexist opc) != true then(append retiring  i)
						)else(
							opc = (i.modifiers[m].filename)
							if (doesfileexist opc) != true then(append retiring  i)
						)
					)
				)
			)
		)
		if retiring.count != 0 do(
			i = retiring.count; while i > 0 do(delete retiring[i]; i = (i - 1) )
		)
		pile.pilerollout.informations.text = ("removed " + (retiring.count as string) + " objects")
		retiring = 0
		pile.populateslist pile.ssl #((getnamedselsetname selectionsets.count)) 0 ind
		pile.populateOList pile.pilerollout.olist pile.oflt pile.pilerollout.cflt.selection (pile.ssl.selection) pile.pilerollout pile.doflags ind
	)
	on scnf_cenv picked do(format"removing atmospheric effects...";pile.clearenv(); format" OK\n")
	on scnf_ceff picked do(format"removing post render-effects...";pile.cleareff(); format" OK\n")
	on scnf_cmed picked do(pile.pebble 0)
	on scnf_ccb picked do(format"removing callbacks...";callbacks.removeScripts(); callbacks.show(); format" OK\n")
	on scnf_cpg picked do(format"removing persistents...";persistents.removeAll(); persistents.show(); format" OK\n")
	on scnf_cgt picked do(format"removing globaltracks...";pile.clearglobaltracks(); format" OK\n")
	on scnf_cfp picked do (format"removing customfileproperties...";pile.clearcustomfileproperties(); format" OK\n")
	on scnf_cad picked do(format"removing appdata..."; for i in objects do (clearAllAppData i); format" OK\n")
	-- xrefs:
	on scnf_mxo picked do(
		if querybox"merge all xref objects?" title:"merge..." beep:true then(
			r = #()
			for i in objects do(
				xfo = (objXRefMgr.isnodexrefed i)
				if xfo != undefined do(
					append r i
				)
			)
			if r.count != 0 do(
				objXRefMgr.MergeXRefItemsIntoScene r
			)
			pile.pilerollout.informations.text = ("merged " + (r.count as string) + " objects.")
			r = 0
		)else()
	)
	on scnf_dtp picked do(
		pile.togglemyparticles objects (pile.dtp) 0
		scnf_dtp.checked = (not pile.dtp)
		pile.dtp = (not pile.dtp)
	)
	on scnf_dpc picked do(
		pile.togglemypointcaches objects (pile.dpc) 0
		scnf_dpc.checked = (not pile.dpc)
		pile.dpc = (not pile.dpc)
	)
)

rcmenu pilecapdatalist (
	menuitem cap_sync "sync to stored data" checked:false
	separator syncsep
	menuitem cap_all "all"
	menuitem cap_non "none"
	menuitem cap_inv "invert"
	separator sep1
	menuitem cap_isol "isolate on restore" checked:true
	separator sepe3
	submenu "render"(
		menuitem whpf_prv "preview stored render" enabled:false
		menuitem whpf_bak "back up stored render" enabled:false
		menuitem whpf_exp  "explorer..." enabled:false
	)
	separator sepe8
	menuitem cap_vis "visibility" checked:true						--1
	menuitem cap_ren "renderable" checked:true                  	--23
	menuitem cap_csh "cast shadows" checked:true					--2
	menuitem cap_rsh "recieve shadows" checked:true					--3
	menuitem cap_pvz "visible to camera" checked:true				--4
	menuitem cap_svz "visible to reflections" checked:true			--5
	menuitem cap_mbl "motion blur" checked:true						--6
	menuitem cap_aat "apply atmospherics" checked:true				--25
 	menuitem cap_mat "material" checked:true						--7
	separator sep7
	menuitem cap_crp "common rendner params" checked:true			--24
	menuitem cap_arp "renderer params" checked:true					--8
	menuitem cap_rpa "render elements" checked:true	          		--14
	menuitem cap_env "environment params" checked:true				--9
	menuitem cap_atm "atmospherics state" checked:true				--10
	menuitem cap_efx "effects state" checked:true					--11
	--menuitem cap_ray "raytrace params" checked:false				--12
	menuitem cap_shd "shadowgenerator " checked:false				--13
	menuitem cap_frs "fume render state" checked:false				--15
	menuitem cap_krk "krakatoa preset" checked:false enabled:false 	--22
	menuitem cap_ena "enable" checked:true			--16
	menuitem cap_vrm "Vray matte" checked:true			--17
	separator sep4
	menuitem cap_osv "other sset same viz" checked:false			--18
	menuitem cap_osm "other sset same mat" checked:false			--19
	menuitem cap_oena "other sset on/off"  checked:false			--20
	menuitem cap_oaat "other sset applyatmospherics" checked:false 	--26
	menuitem cap_opv "other sset primaryvizibility" checked:false 	--27
	separator sep5
	menuitem cap_ccd "custom data" checked:false  					--21
	separator sep6
	menuitem cap_ccdlg "edit custom data..."
	on cap_isol picked do(
		pile.dorestoreisol = (not cap_isol.checked)
	)
	on cap_sync picked do(
		pile.capsync = (not cap_sync.checked)
	)
	on cap_ccdlg picked do(
		createdialog rccd style:#(#style_sysmenu, #style_titlebar, #style_border, #style_minimizebox, #style_resizing)
	)

	on pilecapdatalist open do(
		cap_sync.checked = pile.capsync
			if pile.sl.count != 0 then(
				ssel = (pile.ssl.selection); if classof ssel == integer do(ssel = #(ssel))
				whpf_prv.enabled = (pile.pilerollout.resdat.enabled)
				whpf_bak.enabled = (pile.pilerollout.resdat.enabled)
				whpf_exp.enabled = (pile.pilerollout.resdat.enabled)
			)else(
				whpf_prv.enabled = false
				whpf_bak.enabled = false
				whpf_exp.enabled = false
			)

		if pile.capsync == true then(
			sna = (pile.ssl.selection); if classof sna == integer do(sna = #(sna))
			if sna.count  == 1 do(
				sn = pile.sl[1][(sna[1])]
				format"fetching data checks for %\n"sn
				pile.harvestcat[1] = ((getuserprop csl[1] (sn + "_vis")) != undefined)
				pile.harvestcat[2] = ((getuserprop csl[1] (sn + "_csh")) != undefined)
				pile.harvestcat[3] = ((getuserprop csl[1] (sn + "_rsh")) != undefined)
				pile.harvestcat[4] = ((getuserprop csl[1] (sn + "_vtc")) != undefined)
				pile.harvestcat[5] = ((getuserprop csl[1] (sn + "_vtr")) != undefined)
				pile.harvestcat[6] = ((getuserprop csl[1] (sn + "_mb")) != undefined)
				pile.harvestcat[7] = ((getuserprop csl[1] (sn + "_mat")) != undefined)
				pile.harvestcat[8] = ((getuserprop csl[1] (sn + "_rnd"))!= undefined)
				pile.harvestcat[9] = ((getuserprop csl[1] (sn + "_env")) != undefined)
				pile.harvestcat[10] = ((getuserprop csl[1] (sn + "_atm")) != undefined)
				pile.harvestcat[11] = ((getuserprop csl[1] (sn + "_efx")) != undefined)
				--pile.harvestcat[12] = ((getuserprop csl[1] "vis") != undefined)
				pile.harvestcat[13] = ((getuserprop csl[1] (sn + "_shd")) != undefined)
				pile.harvestcat[14] = ((getuserprop csl[1] (sn + "rpa")) != undefined)
				pile.harvestcat[15] = ((getuserprop csl[1] (sn + "_frs")) != undefined)
				pile.harvestcat[16] = ((getuserprop csl[1] (sn + "_ena")) != undefined)
				pile.harvestcat[17] = ((getuserprop csl[1] (sn + "_vrm")) != undefined)
				pile.harvestcat[18] = ((getuserprop csl[1] (sn + "_osv")) != undefined)
				pile.harvestcat[19] = ((getuserprop csl[1] (sn + "_osm")) != undefined)
				pile.harvestcat[20] = ((getuserprop csl[1] (sn + "_oena")) != undefined)
				pile.harvestcat[21] = ((getuserprop csl[1] (sn + "_ccd")) != undefined)
				pile.harvestcat[22] = ((getuserprop csl[1] (sn + "_krk")) != undefined)
				pile.harvestcat[23] = ((getuserprop csl[1] (sn + "_rndb")) != undefined)
				pile.harvestcat[24] = ((getuserprop csl[1] (sn + "_crp")) != undefined)
				pile.harvestcat[25] = ((getuserprop csl[1] (sn + "_aat")) != undefined)
				pile.harvestcat[26] = ((getuserprop csl[1] (sn + "_oaat")) != undefined)
				pile.harvestcat[27] = ((getuserprop csl[1] (sn + "_opv")) != undefined)
			)
		)else(
			cap_isol.checked = pile.dorestoreisol
			/*
			pile.harvestcat[1] = true
			pile.harvestcat[2] = true
			pile.harvestcat[3] = true
			pile.harvestcat[4] = true
			pile.harvestcat[5] = true
			pile.harvestcat[6] = true
			pile.harvestcat[7] = true
			pile.harvestcat[8] = true
			pile.harvestcat[9] = true
			pile.harvestcat[10] = true
			pile.harvestcat[11] = true
			--pile.harvestcat[12] = true
			pile.harvestcat[13] = true
			pile.harvestcat[14] = true
			pile.harvestcat[15] = true
			pile.harvestcat[16] = true
			pile.harvestcat[17] = true
			pile.harvestcat[18] = true
			pile.harvestcat[19] = true
			pile.harvestcat[20] = true
			pile.harvestcat[21] = true
			pile.harvestcat[22] = true
			pile.harvestcat[23] = true
			pile.harvestcat[24] = true
			*/
		)

		cap_isol.checked = pile.dorestoreisol
		cap_vis.checked = pile.harvestcat[1]
		cap_csh.checked = pile.harvestcat[2]
		cap_rsh.checked = pile.harvestcat[3]
		cap_pvz.checked = pile.harvestcat[4]
		cap_svz.checked = pile.harvestcat[5]
		cap_mbl.checked = pile.harvestcat[6]
		cap_mat.checked = pile.harvestcat[7]
		cap_arp.checked = pile.harvestcat[8]
		cap_env.checked = pile.harvestcat[9]
		cap_atm.checked = pile.harvestcat[10]
		cap_efx.checked = pile.harvestcat[11]
		cap_shd.checked = pile.harvestcat[13]
		cap_rpa.checked = pile.harvestcat[14]
		cap_frs.checked = pile.harvestcat[15]
		cap_ena.checked = pile.harvestcat[16]
		cap_vrm.checked = pile.harvestcat[17]
		cap_osv.checked = pile.harvestcat[18]
		cap_osm.checked = pile.harvestcat[19]
		cap_oena.checked = pile.harvestcat[20]
		cap_ccd.checked = pile.harvestcat[21]
		cap_krk.checked = pile.harvestcat[22]
		cap_ren.checked = pile.harvestcat[23]
		cap_crp.checked = pile.harvestcat[24]
		cap_aat.checked = pile.harvestcat[25]
		cap_oaat.checked = pile.harvestcat[26]
		cap_opv.checked = pile.harvestcat[27]
	)
	on cap_all picked do(
		pile.harvestcat[1] = true
		pile.harvestcat[2] = true
		pile.harvestcat[3] = true
		pile.harvestcat[4] = true
		pile.harvestcat[5] = true
		pile.harvestcat[6] = true
		pile.harvestcat[7] = true
		pile.harvestcat[8] = true
		pile.harvestcat[9] = true
		pile.harvestcat[10] = true
		pile.harvestcat[11] = true
		--pile.harvestcat[12] = true
		pile.harvestcat[13] = true
		pile.harvestcat[14] = true
		pile.harvestcat[15] = true
		pile.harvestcat[16] = true
		pile.harvestcat[17] = true
		pile.harvestcat[18] = true
		pile.harvestcat[19] = true
		pile.harvestcat[20] = true
		pile.harvestcat[21] = true
		pile.harvestcat[22] = true
		pile.harvestcat[23] = true
		pile.harvestcat[24] = true
		pile.harvestcat[25] = true
		pile.harvestcat[26] = true
		pile.harvestcat[27] = true
	)
	on cap_non picked do(
		pile.harvestcat[1] = false
		pile.harvestcat[2] = false
		pile.harvestcat[3] = false
		pile.harvestcat[4] = false
		pile.harvestcat[5] = false
		pile.harvestcat[6] = false
		pile.harvestcat[7] = false
		pile.harvestcat[8] = false
		pile.harvestcat[9] = false
		pile.harvestcat[10] = false
		pile.harvestcat[11] = false
		--pile.harvestcat[12] = false
		pile.harvestcat[13] = false
		pile.harvestcat[14] = false
		pile.harvestcat[15] = false
		pile.harvestcat[16] = false
		pile.harvestcat[17] = false
		pile.harvestcat[18] = false
		pile.harvestcat[19] = false
		pile.harvestcat[20] = false
		pile.harvestcat[21] = false
		pile.harvestcat[22] = false
		pile.harvestcat[23] = false
		pile.harvestcat[24] = false
		pile.harvestcat[25] = false
		pile.harvestcat[26] = false
		pile.harvestcat[27] = false
	)
	on cap_inv picked do(
		pile.harvestcat[1] = (not cap_vis.checked)
		pile.harvestcat[2] = (not cap_csh.checked)
		pile.harvestcat[3] = (not cap_rsh.checked)
		pile.harvestcat[4] = (not cap_pvz.checked)
		pile.harvestcat[5] = (not cap_svz.checked)
		pile.harvestcat[6] = (not cap_mbl.checked)
		pile.harvestcat[7] = (not cap_mat.checked)
		pile.harvestcat[8] = (not cap_arp.checked)
		pile.harvestcat[9] = (not cap_env.checked)
		pile.harvestcat[10] = (not cap_atm.checked)
		pile.harvestcat[11] = (not cap_efx.checked)
		--pile.harvestcat[12] = (not cap_ray.checked)
		pile.harvestcat[13] = (not cap_shd.checked)
		pile.harvestcat[14] = (not cap_rpa.checked)
		pile.harvestcat[15] = (not cap_frs.checked)
		pile.harvestcat[16] = (not cap_ena.checked)
		pile.harvestcat[17] = (not cap_vrm.checked)
		pile.harvestcat[18] = (not cap_osv.checked)
		pile.harvestcat[19] = (not cap_osm.checked)
		pile.harvestcat[20] = (not cap_oena.checked)
		pile.harvestcat[21] = (not cap_ccd.checked)
		pile.harvestcat[22] = (not cap_krk.checked)
		pile.harvestcat[23] = (not cap_ren.checked)
		pile.harvestcat[24] = (not cap_crp.checked)
		pile.harvestcat[25] = (not cap_aat.checked)
		pile.harvestcat[26] = (not cap_oaat.checked)
		pile.harvestcat[27] = (not cap_opv.checked)
	)

	on cap_vis picked do(pile.harvestcat[1] = (not cap_vis.checked))
	on cap_csh picked do(pile.harvestcat[2] = (not cap_csh.checked))
	on cap_rsh picked do(pile.harvestcat[3] = (not cap_rsh.checked))
	on cap_pvz picked do(pile.harvestcat[4] = (not cap_pvz.checked))
	on cap_svz picked do(pile.harvestcat[5] = (not cap_svz.checked))
	on cap_mbl picked do(pile.harvestcat[6] = (not cap_mbl.checked))
	on cap_mat picked do(pile.harvestcat[7] = (not cap_mat.checked))
	on cap_arp picked do(pile.harvestcat[8] = (not cap_arp.checked))
	on cap_env picked do(pile.harvestcat[9] = (not cap_env.checked))
	on cap_atm picked do(pile.harvestcat[10] = (not cap_atm.checked))
	on cap_efx picked do(pile.harvestcat[11] = (not cap_efx.checked))
	on cap_shd picked do(pile.harvestcat[13] = (not cap_shd.checked))
	on cap_rpa picked do(pile.harvestcat[14] = (not cap_rpa.checked))
	on cap_frs picked do(pile.harvestcat[15] = (not cap_frs.checked))
	on cap_ena picked do(pile.harvestcat[16] = (not cap_ena.checked))
	on cap_vrm picked do(pile.harvestcat[17] = (not cap_vrm.checked))
	on cap_osv picked do(pile.harvestcat[18] = (not cap_osv.checked))
	on cap_osm picked do(pile.harvestcat[19] = (not cap_osm.checked))
	on cap_oena picked do(pile.harvestcat[20] = (not cap_oena.checked))
	on cap_ccd picked do(pile.harvestcat[21] = (not cap_ccd.checked))
	on cap_krk picked do(pile.harvestcat[22] = (not cap_krk.checked))
	on cap_ren picked do(pile.harvestcat[23] = (not cap_ren.checked))
	on cap_crp picked do(pile.harvestcat[24] = (not cap_crp.checked))
	on cap_aat picked do(pile.harvestcat[25] = (not cap_aat.checked))
	on cap_oaat picked do(pile.harvestcat[26] = (not cap_oaat.checked))
	on cap_opv picked do(pile.harvestcat[27] = (not cap_opv.checked))
	-- render menu
	on whpf_prv picked do(
		if dopilelog == true do(format"pile.pilecapdatalist.whpf_prv.picked\n" to:pilelog); ind = 0
		idx = pile.ssl.selection; if classof idx == integer do(idx = #(idx))
		pile.cyclestoredrender pile.sl[2][(idx[1])] ind
	)
	on whpf_bak picked do(
		if dopilelog == true do(format"pile.pilecapdatalist.whpf_bak.picked\n" to:pilelog); ind = 0
		idx = pile.ssl.selection; if classof idx == integer do(idx = #(idx))
		pile.backstoredrender pile.sl[2][(idx[1])] ind
	)
	on whpf_exp picked do(
		if dopilelog == true do(format"pile.pilecapdatalist.whpf_exp.picked\n" to:pilelog); ind = 0
		idx = pile.ssl.selection; if classof idx == integer do(idx = #(idx))
		shelllaunch "explorer" (getfilenamepath (pile.extractpilerender pile.sl[2][(idx[1])] ind))
	)
)

rcmenu pileobjfunc (
	menuitem ofc_prp "properties"
	separator sepo2
	menuitem ofc_iso "isolate"
	separator sepo3
	menuitem ofc_cpy "copy"
	menuitem ofc_vrm "make a vray proxy"
	separator sepo4
	menuitem ofc_mun "make unique"
	menuitem ofc_ins "make instances of sceneselection"
	menuitem ofc_col "collapse stack"
	menuitem ofc_cme "convert to mesh"
	menuitem ofc_msh "combine as 1 mesh"
	menuitem ofc_exp "explode elements"
	menuitem ofc_cpv "center pivots"
	menuitem ofc_svc "set default vertex colours"
	menuitem ofc_rxf "reset xform and collpase"
	separator sepo7
	menuitem ofc_cms "remove modifiers"
	menuitem ofc_mat "remove materials"
	menuitem ofc_rky "remove keys"
	separator sepo5
	menuitem ofc_add "add to selection"
	menuitem ofc_rem "remove from selection"
	menuitem ofc_usp "unhide and select parents"
	separator sep07
	menuitem ofc_nze "delete empty meshes"
	menuitem ofc_del "delete"

	on pileobjfunc open do(

	)
	on ofc_iso picked do(if dopilelog == true do(format"pile.pileobjfunc.ofc_iso.picked\n" to:pilelog); ind = 0; pile.isolateobjs csl ind)
	on ofc_del picked do(
		if querybox"delete objects?" beep:true then(
			if dopilelog == true do(format"pile.pileobjfunc.ofc_del.picked\n" to:pilelog); ind = 0
			sidx = (pile.ssl.selection); if classof sidx == integer then(sidx = #(sidx))else(sidx = (sidx as array))
			retiring = csl
			pile.removefromselset csl (pile.ssl.selection) 0 ind
			delete retiring
			retiring = 0
		)else()
	)
	on ofc_vrm picked do(select csl; doVRayMeshExport())
	on ofc_prp picked do(select csl; max properties; pile.pilerollout.issel.checked = true)
	on ofc_add picked do(selectmore csl; pile.pilerollout.issel.checked = true)
	on ofc_rem picked do(
		if selection.count != 0 do(
			anarray = #(); for i in selection do(append anarray i); clearselection()
			for i in anarray where (finditem csl i) == 0 do(selectmore i)
			pile.pilerollout.issel.checked = false
			pile.pilerollout.autosel.checked = false
			pile.pilerollout.sels.checked = false
		)
	)
	on ofc_ins picked do(
		if selection.count != 0 do(
			for i in csl where i != selection[1] do(
				try(instancereplace i selection[1])catch(format"% cannot be made and instance of %\n"i.name selection[1].name)
			)
		)
	)
	on ofc_mun picked do(
		if dopilelog == true do(format"pile.pileobjfunc.ofc_mun.picked\n" to:pilelog); ind = 0
		for i in csl do(
			a = #()
			InstanceMgr.GetInstances i &a
			if a.count != 0 do(
				InstanceMgr.MakeObjectsUnique &a #individual
			)
		)
		pile.populateOList pile.pilerollout.olist pile.oflt pile.pilerollout.cflt.selection (pile.ssl.selection) pile.pilerollout pile.doflags ind
	)
	on ofc_col picked do(
		for i in csl do(
			if i.modifiers.count != 0 do(
				try(collapsestack i)catch()
			)
		)
	)
	on ofc_cme picked do(
		if dopilelog == true do(format"pile.pileobjfunc.ofc_cme.picked\n" to:pilelog); ind = 0
		for i in csl do(
			try(collapsestack i)catch()
			try(converttomesh i)catch()
		)
		pile.populateOList pile.pilerollout.olist pile.oflt pile.pilerollout.cflt.selection (pile.ssl.selection) pile.pilerollout pile.doflags ind
	)
	on ofc_svc picked do(
		for i = 1 to csl.count do(
			if classof csl[i] == editable_mesh or classof csl[i] == editable_poly or classof csl[i] == PolyMeshObject then(
				if csl[i].modifiers.count == 0 then(
					defaultvcfaces csl[i]
					for o =  1 to (getnumverts csl[i]) do(setvertcolor csl[i] o (color 128.0 128.0 128.0))
					update csl[i]
				)else(format"set defeult vertex colours failed, modifiers are present.\n")
			)else(format"set defeult vertex colours failed, object not a mesh.\n")
		)
	)
	on ofc_cpv picked do(
		for i = 1 to csl.count do(
			csl[i].pivot = csl[i].center
		)
	)
	on ofc_rxf picked do(
		for i = 1 to csl.count do(
			if classof csl[i] == editable_mesh or classof csl[i] == editable_poly or classof csl[i] == PolyMeshObject do(
				ResetXForm csl[i]
				collapsestack csl[i]
			)
		)
	)
	on ofc_mat picked do(
		pile.pilerollout.informations.text = ""
		pile.pilerollout.progbar.pos.y = pile.pilerollout.informations.pos.y
		pile.pilerollout.progbar.pos.x = pile.pilerollout.informations.pos.x
		pile.pilerollout.informations.pos.x += 68
		pile.pilerollout.informations.text = "removing materials..."
		for i = 1 to csl.count do(
			csl[i].material = undefined
			pile.pilerollout.progbar.value = 100.*i/(csl.count)
		)
		pile.pilerollout.progbar.pos.x = -500
		pile.pilerollout.informations.pos.x -= 68
		pile.pilerollout.informations.text = "ok"
	)
	on ofc_msh picked do(
		if dopilelog == true do(format"pile.pileobjfunc.ofc_msh.picked\n" to:pilelog); ind = 0
		tch = #()
		for i = 1 to csl.count do(
			if classof csl[i] == editable_mesh or classof csl[i] == editable_poly or classof csl[i] == PolyMeshObject do(
				append tch csl[i]
			)
		)
		if tch.count >= 2 then(
			pile.pilerollout.informations.text = ""
			pile.pilerollout.progbar.pos.y = pile.pilerollout.informations.pos.y
			pile.pilerollout.progbar.pos.x = pile.pilerollout.informations.pos.x
			pile.pilerollout.informations.pos.x += 68
			pile.pilerollout.informations.text = "combining..."
			collapsestack tch[1]; converttomesh tch[1]
			for i = 2 to tch.count do(
				collapsestack tch[i]; converttomesh tch[i]
				-- meshop.attach tch[1] tch[i] attachmat:#mattoID deletesourcenode:true
				attach tch[1] tch[i]
				tch[i] = 0
				pile.pilerollout.progbar.value = 100.*i/(tch.count)
			)
			pile.pilerollout.progbar.pos.x = -500
			pile.pilerollout.informations.pos.x -= 68
			pile.pilerollout.informations.text = "ok"
			tch = 0
			pile.populateOList pile.pilerollout.olist pile.oflt pile.pilerollout.cflt.selection (pile.ssl.selection) pile.pilerollout pile.doflags ind
		)else()
	)
	on ofc_exp picked do(
		if dopilelog == true do(format"pile.pileobjfunc.ofc_exp.picked\n" to:pilelog); ind = 0
		ne = #()
		for i in csl do(
			if classof i == editable_mesh do(
				e = pile.detachelements i ind
				join ne e
			)
		)
		if ne.count != 0 do(
			pile.addtoselset ne (pile.ssl.selection) ind
			rt = #()
			for i = 1 to pile.ol.count where (finditem ne pile.ol[i]) != 0 do(
				append rt i
			)
			if rt.count != 0 do(
				pile.pilerollout.olist.selection = rt
				pile.selolist (pile.ssl.selection) rt pile.pilerollout.autosel.checked pile.pilerollout.autoframe.state ind
			)
		)
		rt = 0; ne = 0
	)
	on ofc_nze picked do(
		if dopilelog == true do(format"pile.pileobjfunc.ofc_nze.picked\n" to:pilelog); ind = 0
		pile.pilerollout.informations.text = ""
		pile.pilerollout.progbar.pos.y = pile.pilerollout.informations.pos.y
		pile.pilerollout.progbar.pos.x = pile.pilerollout.informations.pos.x
		pile.pilerollout.informations.pos.x += 68
		pile.pilerollout.informations.text = "finding empty meshes..."
		delme = #()
		for i = 1 to csl.count where (classof csl[i]) == editable_mesh or (classof csl[i]) == editable_poly do(
			if csl[i].numverts == 0 do(
				append delme csl[i]
			)
			pile.pilerollout.progbar.value = 100.*i/(csl.count)
		)
		pile.pilerollout.progbar.value = 0.0
		if delme.count != 0 then(
			for i in delme do(format"empty mesh: %\n"i.name)
			pile.pilerollout.informations.text = "deleting empty meshes..."
			delete delme
			pile.populateOList pile.pilerollout.olist pile.oflt pile.pilerollout.cflt.selection (pile.ssl.selection) pile.pilerollout pile.doflags ind
			pile.pilerollout.informations.text = "empty meshes deleted."
		)else(pile.pilerollout.informations.text = "no empty meshes found.")
		pile.pilerollout.progbar.pos.x = -500
		pile.pilerollout.informations.pos.x -= 68
		delme = 0
	)
	on ofc_cms picked do(
		for i in csl do(
			while i.modifiers.count != 0 do(
				deletemodifier i i.modifiers.count
			)
		)
	)
	on ofc_cpy picked do(
		if dopilelog == true do(format"pile.pileobjfunc.ofc_cpy.picked\n" to:pilelog); ind = 0
		cparray = #()
		if csl.count > 1 then(
			for i in csl do(
				acopy = copy i name:(i.name)
				pile.repnumberedname #(acopy) (pile.striplastnums i.name ind)[1] ind
				append cparray acopy
			)
		)else(acopy = copy csl[1] name:(csl[1].name); pile.repnumberedname #(acopy) csl[1].name ind; append cparray acopy)

		pile.addtoselset cparray (pile.ssl.selection) ind
		join csl cparray
		pile.populateOList pile.pilerollout.olist pile.oflt pile.pilerollout.cflt.selection (pile.ssl.selection) pile.pilerollout pile.doflags ind
		pile.selolist (pile.ssl.selection) (pile.pilerollout.olist.selection as array) pile.pilerollout.autosel.checked  pile.pilerollout.autoframe.state ind
		cparray = 0
	)
	on ofc_usp picked do(
		parents = #()
		for i in csl do(
			aparent = i.parent
			while aparent != undefined do(
				if finditem parents aparent == 0 do(append parents aparent)
				aparent = aparent.parent
			)
		)
		clearselection()
		if parents.count != 0 do(
			for i in parents do(
				selectmore i
				i.ishidden = false
			)
		)
		pile.pilerollout.issel.state = false; pile.pilerollout.autosel.state = false; pile.pilerollout.sels.state = false
	)
	on ofc_deletekeys picked do(
		ofc_deletekeys.checked = (not ofc_deletekeys.checked)
	)
	on ofc_cleanup picked do(
		ofc_cleanup.checked = (not ofc_cleanup.checked)
	)
	on ofc_rky picked do(
		for i in csl do(deletekeys i)
	)
)

rcmenu pilesetfunc (
	menuitem sfc_sel "select"
	menuitem sfc_iso "isolate"
	menuitem sfc_sap "add parents"
	menuitem sfc_sac "add children"
	separator sep2
	menuitem sfc_nfsc "new from scene selection"
	menuitem sfc_afsc "add from scene selection"
	menuitem sfc_rfsc "remove scene selection"
	separator bluh33
	menuitem syc_sel "sync to scene selection"
	menuitem syc_all "sync to all visible"
	separator sep3
	menuitem sfc_nav "new from all visible"
	menuitem sfc_nall "new from all"
	menuitem sfc_uall "add all"
	menuitem sfc_ualv "add all visible"
	seperator sep4
	menuitem sfc_nfls "new from list selection"
	menuitem sfc_rfls "remove list selection"
	separator sep5
	menuitem sfc_rmss "remove these sets"
	menuitem sfc_rsso "remove these sets and delete objects"
	separator sep7
	menuitem sfc_fob "flush this selectionset's data"
	menuitem sfc_fre "attempt forced restore"

	on sfc_sel picked do(
		if dopilelog == true do(format"pile.pilesetfunc.sfc_sel.picked\n" to:pilelog); ind = 0
		if pile.pilerollout.autosel.checked then(
			osl = #(); for i = 1 to pile.ol.count do(append osl i); pile.pilerollout.olist.selection = osl; osl = 0
			pile.selolist (pile.ssl.selection) (pile.pilerollout.olist.selection as array) true pile.pilerollout.autoframe.state ind
			if csl.count == 1 then (pile.pilerollout.onametxt.text = csl[1].name)else(pile.pilerollout.onametxt.text = "")
		)else(
			select pile.ol
		)
	)
	on sfc_iso picked do(
		if dopilelog == true do(format"pile.pilesetfunc.sfc_iso.picked\n" to:pilelog); ind = 0
		if pile.isocache.count == 0 then(
			for i in objects do(
				if i.ishidden == false do(append pile.isocache i)
			)
			hide objects
			unhide pile.ol
		)else(
			disablesceneredraw()
			hide objects
			for i in pile.isocache do(try(unhide i)catch())
			pile.isocache = #()
			enablesceneredraw()
		)
		pile.checkchecks pile.pilerollout.doextrachecks.state ind
	)
	on sfc_sap picked do(
		if dopilelog == true do(format"pile.pilesetfunc.sfc_sap.picked\n" to:pilelog); ind = 0
		parents = pile.getparents csl 1 ind; if parents.count != 0 do(pile.addtoselset parents (pile.ssl.selection) ind)
	)
	on sfc_sac picked do(
		if dopilelog == true do(format"pile.pilesetfunc.sfc_sac.picked\n" to:pilelog); ind = 0
		ac = pile.getchildren csl 1 ind; if ac.count != 0 do(pile.addtoselset ac (pile.ssl.selection) ind)
	)
	on sfc_nfls picked do(
		if dopilelog == true do(format"pile.pilesetfunc.sfc_nfls.picked\n" to:pilelog); ind = 0
		pile.makenewselset csl #() ind
	)
	on sfc_nfsc picked do(
		if selection.count != 0 do(
			if dopilelog == true do(format"pile.pilesetfunc.sfc_nfsc.picked\n" to:pilelog); ind = 0
			pile.makenewselset (selection as array) #() ind
		)
	)
	on sfc_afsc picked do(
		if dopilelog == true do(format"pile.pilesetfunc.sfc_afsc.picked\n" to:pilelog); ind = 0
		pile.addtoselset (selection as array) (pile.ssl.selection) ind
	)
	on sfc_rfsc picked do(
		if dopilelog == true do(format"pile.pilesetfunc.sfc_rfsc.picked\n" to:pilelog); ind = 0
		pile.removefromselset (selection as array) (pile.ssl.selection) 0 ind
	)
	on sfc_rmss picked do(
		if dopilelog == true do(format"pile.pilesetfunc.sfc_rmss.picked\n" to:pilelog); ind = 0
		retiring = (pile.ssl.selection); if classof retiring == integer then(retiring = #(retiring))else(retiring = (retiring as array))
		for i in retiring do(
			format"pile.pilesetfinc.sfc_rmss: set to remove = %, ID = %, actual set name = %\n"pile.sl[1][i] pile.sl[2][i] (getnamedselsetname (pile.getsetidxfromname pile.sl[1][i] ind))
			idx = (pile.getsetidxfromname pile.sl[1][i] ind)
			objs = #(); for o in selectionsets[idx] do(append objs o)
			pile.propbackwash pile.sl[1][i] objs ind
			format"pile.pilesetfinc.sfc_rmss:  deleting selectionset: %\n"(selectionsets[idx])
			deleteitem selectionsets idx
			objs = 0
		)
		pile.populateslist pile.ssl #((getnamedselsetname selectionsets.count)) 0 ind
		pile.populateOList pile.pilerollout.olist pile.oflt pile.pilerollout.cflt.selection (pile.ssl.selection) pile.pilerollout pile.doflags ind
	)
	on sfc_rfls picked do(
		if dopilelog == true do(format"pile.pilesetfunc.sfc_rfls.picked\n" to:pilelog); ind = 0
		pile.removefromselset csl (pile.ssl.selection) 0 ind
	)
	on sfc_rsso picked do(
		if dopilelog == true do(format"pile.pilesetfunc.sfc_rsso.picked\n" to:pilelog); ind = 0
		retiring = (pile.ssl.selection); if classof retiring == integer then(retiring = #(retiring))else(retiring = (retiring as array))
		delme = #()
		for i in retiring do(
			idx = pile.sl[2][i]
			for o in selectionsets[idx] where (finditem delme o) == 0 do(append delme o)
			deleteitem selectionsets idx
		)
		i = delme.count; while i > 0 do(delete delme[i]; i = (i - 1) )
		pile.populateslist pile.ssl #((getnamedselsetname selectionsets.count)) 0 ind
		pile.populateOList pile.pilerollout.olist pile.oflt pile.pilerollout.cflt.selection (pile.ssl.selection) pile.pilerollout pile.doflags ind
	)
	on sfc_nav picked do(
		uh = for i in objects where i.ishidden == false collect i
		if uh.count != 0 do(
			if dopilelog == true do(format"pile.pilesetfunc.sfc_nav.picked\n" to:pilelog); ind = 0
			pile.makenewselset uh #() ind
		)
		uh = 0
	)
	on syc_sel picked do(
		if dopilelog == true do(format"pile.pilesetfunc.syc_sel.picked\n" to:pilelog); ind = 0
		tn = #()
		retiring = (pile.ssl.selection); if classof retiring == integer then(retiring = #(retiring))else(retiring = (retiring as array))
		for i in retiring do(
			append tn pile.sl[1][i]
			idx = pile.sl[2][i]
			deleteitem selectionsets idx
		)
		pile.makenewselset (selection as array) tn ind
		tn = 0
	)
	on syc_all picked do(
		if dopilelog == true do(format"pile.pilesetfunc.syc_all.picked\n" to:pilelog); ind = 0
		tn = #()
		retiring = (pile.ssl.selection); if classof retiring == integer then(retiring = #(retiring))else(retiring = (retiring as array))
		for i in retiring do(
			append tn pile.sl[1][i]
			idx = pile.sl[2][i]
			deleteitem selectionsets idx
		)
		pile.makenewselset (pile.getallvisible()) tn ind
		tn = 0
	)
	on sfc_nall picked do(
		if dopilelog == true do(format"pile.pilesetfunc.sfc_nall.picked\n" to:pilelog); ind = 0
		pile.makenewselset objects #() ind
	)
	on sfc_uall picked do(
		if dopilelog == true do(format"pile.pilesetfunc.sfc_uall.picked\n" to:pilelog); ind = 0
		pile.addtoselset objects (pile.ssl.selection) ind
	)
	on sfc_ualv picked do(
		uh = for i in objects where i.ishidden == false collect i
		if uh.count != 0 do(
			if dopilelog == true do(format"pile.pilesetfunc.sfc_ualv.picked\n" to:pilelog); ind = 0
			pile.addtoselset uh (pile.ssl.selection) ind
		)
		uh = 0
	)
	on sfc_fob picked do(
		if querybox"remove pile data from objects on this set?" beep:true then(
			idx = (pile.ssl.selection)
			if classof idx != integer then(idx = (idx as array); idx = idx[1])
			pile.propbackwash pile.sl[1][idx] pile.ol 0
			pile.populateslist pile.ssl #(pile.sl[1][idx]) 0 0
		)
	)
	on sfc_fre picked do(
		if querybox"restore data for this set?" beep:true then(
			if dopilelog == true do(format"pile.pilesetfunc.sfc_fre.picked\n" to:pilelog); ind = 0
			sidx = (pile.ssl.selection); if classof sidx != integer do(sidx = (sidx as array)[1])
			format"sidx = %\n"sidx
			if pile.dorestoreisol == true do(
				pile.isolateobjs pile.ol ind
			)
			pile.restoreall pile.sl[2][sidx] 0
		)else()
	)
)

rcmenu pileobjprps (

	menuitem opr_rnd "renderable" checked:false
	menuitem opr_box "boxmode" checked:false
	menuitem opr_csh "castshadows" checked:false
	menuitem opr_rsh "receiveshadows" checked:false
	menuitem opr_edg "alledges" checked:false
	menuitem opr_bfc "backfacecull" checked:false
	menuitem opr_pvz "primaryVisibility" checked:false
	menuitem opr_svz "secondaryVisibility" checked:false
	menuitem opr_aat "applyatmospherics" checked:false
	menuitem opr_xry "see-through" checked:false
	menuitem opr_vtk "vertexticks" checked:false
	menuitem opr_vtc "vertexcolours" checked:false
	menuitem opr_trj "trajectory" checked:false
	menuitem opr_mbo "motionbluron" checked:false
	menuitem opr_mbi "image motion blur" checked:false
	menuitem opr_mbob "object motion blur" checked:false
	on pileobjprps open do(
		if dopilelog == true do(format"pile.pileobjprps.open\n" to:pilelog); ind = 0;
		opr_rnd.checked = (pile.getboolstate csl #renderable 0 ind)
		opr_box.checked = (pile.getboolstate csl #boxmode 0 ind)
		opr_csh.checked = (pile.getboolstate csl #castshadows 0 ind)
		opr_rsh.checked = (pile.getboolstate csl #receiveshadows 0 ind)
		opr_edg.checked = (pile.getboolstate csl #alledges 0 ind)
		opr_bfc.checked = (pile.getboolstate csl #backfacecull 0 ind)
		opr_pvz.checked = (pile.getboolstate csl #primaryVisibility 0 ind)
		opr_svz.checked = (pile.getboolstate csl #secondaryVisibility 0 ind)
		opr_aat.checked = (pile.getboolstate csl #applyatmospherics 0 ind)
		opr_xry.checked = (pile.getboolstate csl #xray 0 ind)
		opr_vtk.checked = (pile.getboolstate csl #vertexticks 0 ind)
		opr_vtc.checked = (pile.getboolstate csl #showvertexcolors 0 ind)
		opr_trj.checked = (pile.getboolstate csl #showTrajectory 0 ind)
		opr_mbo.checked = (pile.getboolstate csl #motionbluron 0 ind)
		opr_mbi.checked = (pile.getboolstate csl #motionblur #image ind)
		opr_mbob.checked = (pile.getboolstate csl #motionblur #object ind)
	)
	on opr_rnd picked do(if dopilelog == true do(format"pile.pileobjprps.opr_rnd.picked\n" to:pilelog); ind = 0; pile.paramtoggle csl #renderable opr_rnd.checked 0 ind;  opr_rnd.checked = (pile.getboolstate csl #renderable 0 ind))
	on opr_box picked do(if dopilelog == true do(format"pile.pileobjprps.opr_box.picked\n" to:pilelog); ind = 0; pile.paramtoggle csl #boxmode opr_box.checked 0 ind;  opr_box.checked = (pile.getboolstate csl #boxmode 0 ind))
	on opr_csh picked do(if dopilelog == true do(format"pile.pileobjprps.opr_csh.picked\n" to:pilelog); ind = 0; pile.paramtoggle csl #castshadows opr_csh.checked 0 ind;  opr_csh.checked = (pile.getboolstate csl #castshadows 0 ind))
	on opr_rsh picked do(if dopilelog == true do(format"pile.pileobjprps.opr_rsh.picked\n" to:pilelog); ind = 0; pile.paramtoggle csl #receiveshadows opr_rsh.checked 0 ind;  opr_rsh.checked = (pile.getboolstate csl #receiveshadows 0 ind))
	on opr_edg picked do(if dopilelog == true do(format"pile.pileobjprps.opr_edg.picked\n" to:pilelog); ind = 0; pile.paramtoggle csl #alledges opr_edg.checked 0 ind;  opr_edg.checked = (pile.getboolstate csl #alledges 0 ind))
	on opr_bfc picked do(if dopilelog == true do(format"pile.pileobjprps.opr_bfc.picked\n" to:pilelog); ind = 0; pile.paramtoggle csl #backfacecull opr_bfc.checked 0 ind;  opr_bfc.checked = (pile.getboolstate csl #backfacecull 0 ind))
	on opr_pvz picked do(if dopilelog == true do(format"pile.pileobjprps.opr_pvz.picked\n" to:pilelog); ind = 0; pile.paramtoggle csl #primaryVisibility opr_pvz.checked 0 ind;  opr_pvz.checked = (pile.getboolstate csl #primaryVisibility 0 ind))
	on opr_svz picked do(if dopilelog == true do(format"pile.pileobjprps.opr_svz.picked\n" to:pilelog); ind = 0; pile.paramtoggle csl #secondaryVisibility opr_svz.checked 0 ind;  opr_svz.checked = (pile.getboolstate csl #secondaryVisibility 0 ind))
	on opr_aat picked do(if dopilelog == true do(format"pile.pileobjprps.opr_aat.picked\n" to:pilelog); ind = 0; pile.paramtoggle csl #applyatmospherics opr_aat.checked 0 ind;  opr_aat.checked = (pile.getboolstate csl #applyatmospherics 0 ind))
	on opr_xry picked do(if dopilelog == true do(format"pile.pileobjprps.opr_xry.picked\n" to:pilelog); ind = 0; pile.paramtoggle csl #xray opr_xry.checked 0 ind;  opr_xry.checked = (pile.getboolstate csl #xray 0 ind))
	on opr_vtk picked do(if dopilelog == true do(format"pile.pileobjprps.opr_vtk.picked\n" to:pilelog); ind = 0; pile.paramtoggle csl #vertexticks opr_vtk.checked 0 ind;  opr_vtk.checked = (pile.getboolstate csl #vertexticks 0 ind))
	on opr_vtc picked do(if dopilelog == true do(format"pile.pileobjprps.opr_vtc.picked\n" to:pilelog); ind = 0; pile.paramtoggle csl #showvertexcolors opr_vtc.checked 0 ind;  opr_vtc.checked = (pile.getboolstate csl #showvertexcolors 0 ind))
	on opr_trj picked do(if dopilelog == true do(format"pile.pileobjprps.opr_trj.picked\n" to:pilelog); ind = 0; pile.paramtoggle csl #showTrajectory opr_trj.checked 0 ind;  opr_trj.checked = (pile.getboolstate csl #showTrajectory 0 ind))
	on opr_mbo picked do(if dopilelog == true do(format"pile.pileobjprps.opr_mbo.picked\n" to:pilelog); ind = 0; pile.paramtoggle csl #motionbluron opr_mbo.checked 0 ind;  opr_mbo.checked = (pile.getboolstate csl #motionbluron 0 ind))
	on opr_mbi picked do(if dopilelog == true do(format"pile.pileobjprps.opr_mbi.picked\n" to:pilelog); ind = 0; pile.paramtoggle csl #motionblur opr_mbi.checked #image ind;  opr_mbi.checked = (pile.getboolstate csl #motionblur #image ind))
	on opr_mbob picked do(if dopilelog == true do(format"pile.pileobjprps.opr_mbob.picked\n" to:pilelog); ind = 0; pile.paramtoggle csl #motionblur opr_mbob.checked #object ind;  opr_mbob.checked = (pile.getboolstate csl #motionblur #object ind))
)

rcmenu pilefumefunc (
	menuitem ff_smo "render smoke" checked:false
	menuitem ff_fir "render fire" checked:false
	menuitem ff_fue "render fuel" checked:false
	on pilefumefunc open do(
		if dopilelog == true do(format"pile.pilefumefunc.open\n" to:pilelog); ind = 0
		ff_smo.checked = (pile.getboolstateofreferenceblock csl 10 #shadesmoke 0 ind)
		ff_fir.checked = (pile.getboolstateofreferenceblock csl 10 #shadefire 0 ind)
		ff_fue.checked = (pile.getboolstateofreferenceblock csl 10 #shadefuel 0 ind)
	)
	on ff_smo picked do(
		if dopilelog == true do(format"pile.pilefumefunc.ff_smo.picked\n" to:pilelog); ind = 0
		pile.refblockparamtoggle csl 10 #shadesmoke ff_smo.checked 0; ff_smo.checked = (pile.getboolstateofreferenceblock csl 10 #shadesmoke 0 ind)
	)
	on ff_fir picked do(
		if dopilelog == true do(format"pile.pilefumefunc.ff_fir.picked\n" to:pilelog); ind = 0
		pile.refblockparamtoggle csl 10 #shadefire ff_fir.checked 0; ff_fir.checked = (pile.getboolstateofreferenceblock csl 10 #shadefire 0 ind)
	)
	on ff_fue picked do(
		if dopilelog == true do(format"pile.pilefumefunc.ff_fue.picked\n" to:pilelog); ind = 0
		pile.refblockparamtoggle csl 10 #shadefuel ff_fue.checked 0; ff_fue.checked = (pile.getboolstateofreferenceblock csl 10 #shadefuel 0 ind)
	)

)

rcmenu pilecolfunc (
	menuitem cfc_lin "linear"
	menuitem cfc_easn "ease"
	menuitem cfc_sin "sine"
	menuitem cfc_ran "random"
	menuitem cfc_stv "send to vertex colours"
	menuitem cfc_stl "send to light colours"

	on cfc_lin picked do(
		for i = 1 to csl.count do(
			sr = csl[1].wirecolor.r
			sg = csl[1].wirecolor.g
			sb = csl[1].wirecolor.b
			dr = csl[csl.count].wirecolor.r
			dg = csl[csl.count].wirecolor.g
			db = csl[csl.count].wirecolor.b
			csl[i].wirecolor.r = ((((dr - sr) / csl.count) * i) + sr)
			csl[i].wirecolor.g = ((((dg - sg) / csl.count) * i) + sg)
			csl[i].wirecolor.b = ((((db - sb) / csl.count) * i) + sb)
		)
	)
	on cfc_sin picked do(
		for i = 1.0 to csl.count do(
			ct = (csl.count as float)
			qt = (i - (ct * 0.25))
			sr = csl[1].wirecolor.r
			sg = csl[1].wirecolor.g
			sb = csl[1].wirecolor.b
			dr = csl[csl.count].wirecolor.r
			dg = csl[csl.count].wirecolor.g
			db = csl[csl.count].wirecolor.b
			csl[i].wirecolor.r = ((sin(qt/((ct / 2.0)/180.0)) / 2.0 + 0.5) * (dr - sr)) + sr
			csl[i].wirecolor.g = ((sin(qt/((ct / 2.0)/180.0)) / 2.0 + 0.5) * (dg - sg)) + sg
			csl[i].wirecolor.b = ((sin(qt/((ct / 2.0)/180.0)) / 2.0 + 0.5) * (db - sb)) + sb
		)
	)
	on cfc_easn picked do(
		for i = 1.0 to csl.count do(
			ct = (csl.count as float)
			oi = (i - (ct / 2.0))
			sr = csl[1].wirecolor.r
			sg = csl[1].wirecolor.g
			sb = csl[1].wirecolor.b
			dr = csl[csl.count].wirecolor.r
			dg = csl[csl.count].wirecolor.g
			db = csl[csl.count].wirecolor.b
			csl[i].wirecolor.r = ((sin(oi/(ct / 180.0)) / 2.0 + 0.5) * (dr - sr)) + sr
			csl[i].wirecolor.g = ((sin(oi/(ct / 180.0)) / 2.0 + 0.5) * (dg - sg)) + sg
			csl[i].wirecolor.b = ((sin(oi/(ct / 180.0)) / 2.0 + 0.5) * (db - sb)) + sb
		)
	)
	on cfc_ran picked do(
		for i = 1.0 to csl.count do(
			sr = csl[1].wirecolor.r
			sg = csl[1].wirecolor.g
			sb = csl[1].wirecolor.b
			dr = csl[csl.count].wirecolor.r
			dg = csl[csl.count].wirecolor.g
			db = csl[csl.count].wirecolor.b
			csl[i].wirecolor.r = (random 0.0 pile.pilerollout.wirecol.color.r)
			csl[i].wirecolor.g = (random 0.0 pile.pilerollout.wirecol.color.g)
			csl[i].wirecolor.b = (random 0.0 pile.pilerollout.wirecol.color.b)
		)
	)

	on cfc_stv picked do(
		for i = 1 to csl.count do(
			if classof csl[i] == editable_mesh or classof csl[i] == editable_poly or classof csl[i] == PolyMeshObject then(
				if csl[i].modifiers.count == 0 then(
					defaultvcfaces csl[i]
					for o =  1 to (getnumverts csl[i]) do(setvertcolor csl[i] o csl[i].wirecolor)
					csl[i].showvertexcolors = true
					update csl[i]
				)else(format"set vertex colours failed, modifiers are present.\n")
			)else(format"set vertex colours failed, object not a mesh.\n")
		)
	)
	on cfc_stl picked do(
		for i = 1 to csl.count do(
			if superclassof csl[i] == light then(
				if (hasproperty csl[i] #rgb) == true do(csl[i].rgb = csl[i].wirecolor)
			)else(format"set light colours failed, object not a light.\n")
		)
	)
)

rcmenu pilelistfunc (
	menuitem lstf_flg "show flags" checked:false
	menuitem listf_hrch "show hierarchy" checked:false
	separator lstf_sep1
	menuitem lstf_inv "invert"
	menuitem lstf_syn "sync to scene selection"
	menuitem lstf_svz "sync to vizible"

	on pilelistfunc open do(
		lstf_flg.checked = pile.doflags
		listf_hrch.checked = pile.hrch
	)
	on lstf_flg picked do(
		if dopilelog == true do(format"pile.pilelistfunc.lstf_flg.picked\n" to:pilelog); ind = 0
		lstf_flg.checked = (not pile.doflags)
		pile.doflags = lstf_flg.checked
		pile.populateOList pile.pilerollout.olist pile.oflt pile.pilerollout.cflt.selection (pile.ssl.selection) pile.pilerollout pile.doflags ind
	)
	on listf_hrch picked do(
		if dopilelog == true do(format"pile.pilelistfunc.listf_hrch.picked\n" to:pilelog); ind = 0
		pile.hrch = (not listf_hrch.checked)
		pile.populateOList pile.pilerollout.olist pile.oflt pile.pilerollout.cflt.selection (pile.ssl.selection) pile.pilerollout pile.doflags ind
	)
	on lstf_inv picked do(
		if dopilelog == true do(format"pile.pilelistfunc.lstf_inv.picked\n" to:pilelog); ind = 0
		inv = (pile.invertarray (pile.pilerollout.olist.selection as array) (pile.pilerollout.olist.items.count) ind)
		pile.pilerollout.olist.selection = inv
		pile.selolist (pile.ssl.selection) inv pile.pilerollout.autosel.checked pile.pilerollout.autoframe.state ind
	)
	on lstf_syn picked do(
		if selection.count != 0 do(
			if dopilelog == true do(format"pile.pilelistfunc.lstf_syn.picked\n" to:pilelog); ind = 0
			tsl = (selection as array)
			rt = #()
			for i = 1 to pile.ol.count where (finditem tsl pile.ol[i]) != 0 do(
				append rt i
			)
			if rt.count != 0 do(
				pile.pilerollout.olist.selection = rt
				pile.selolist (pile.ssl.selection) rt pile.pilerollout.autosel.checked pile.pilerollout.autoframe.state ind
			)
		)
	)
	on lstf_svz picked do(
		if pile.ol.count != 0 do(
			if dopilelog == true do(format"pile.pilelistfunc.lstf_svz.picked\n" to:pilelog); ind = 0
			sidx = (pile.ssl.selection); if classof sidx == integer then(sidx = #(sidx))else(sidx = (sidx as array))
			rt = #()
			for i = 1 to pile.ol.count where pile.ol[i].ishidden== false do(
				append rt i
			)
			if rt.count != 0 do(
				pile.pilerollout.olist.selection = rt
				pile.selolist sidx rt pile.pilerollout.autosel.checked pile.pilerollout.autoframe.state ind
			)
		)
	)
)
rcmenu onamefunc (
	menuitem nfc_sn "prepend set name"
	-- menuitem nfc_id "prepend class ID" -- M = mesh, PO = Poly, S = spline, L = light, C = camera, H = helper, B = bone, F = force, P = particle, N = nurbs, PG = patchgrid.
	-- menuitem nfc_pn "prepend highest parent name"
	separator seppo
	menuitem nfc_on "%o : original name"
	menuitem nfc_nn "%n : original name without numbers"
	menuitem nfc_cl "%c : class"
	menuitem nfc_ca "%a : abbreviated class (1 letter)"
	menuitem nfc_sa "%s : abbreviated superclass (1 letter)"
	on onamefunc open do(
		sidx = (pile.ssl.selection); if classof sidx == integer then(sidx = #(sidx))else(sidx = (sidx as array))
		nfc_sn.enabled = (sidx.count == 1)
	)
	on nfc_sn picked do(
		if dopilelog == true do(format"pile.onamefunc.nfc_sn.picked\n" to:pilelog); ind = 0
		idx = (pile.ssl.selection); if classof idx == array do(idx = idx[1])
		--idx = (pile.ssl.selection)
		for i in csl do(i.name = (pile.sl[1][idx] + "_" + i.name))
		pile.populateOList pile.pilerollout.olist pile.oflt pile.pilerollout.cflt.selection (pile.ssl.selection) pile.pilerollout pile.doflags ind
		pile.selolist (pile.ssl.selection) pile.pilerollout.olist.selection pile.pilerollout.autosel.checked pile.pilerollout.autoframe.state ind
	)
	on nfc_on picked do(pile.pilerollout.informations.text = csl[1].name)
	on nfc_nn picked do(
		if dopilelog == true do(format"pile.onamefunc.nfc_nn.picked\n" to:pilelog); ind = 0
		pile.pilerollout.informations.text = (pile.striplastnums csl[1].name ind)[1]
	)
	on nfc_cl picked do(pile.pilerollout.informations.text = ((classof csl[1]) as string))
	on nfc_ca picked do(pile.pilerollout.informations.text = toUpper ((classof csl[1]) as string)[1])
	on nfc_sa picked do(pile.pilerollout.informations.text = toUpper ((superclassof csl[1]) as string)[1])

)
rcmenu slistdisplayfunc (
	menuitem sld_lst "multilistbox"
	menuitem sld_tag "show flags"
	menuitem sld_svz "select visible"
	on slistdisplayfunc open do (
		sld_lst.checked = (classof pile.ssl == MultiListBoxControl)
		sld_tag.checked = pile.listtags
	)
	on sld_tag picked do(
		if dopilelog == true do(format"pile.slistdisplayfunc.sld_tag.picked\n" to:pilelog); ind = 0
		pile.listtags = (not sld_tag.checked)
		sidx = (pile.ssl.selection); if classof sidx == integer then(sidx = #(sidx))else(sidx = (sidx as array))
		selstr = for i in sidx collect pile.sl[1][i]
		pile.populateslist pile.ssl selstr 1 ind
		pile.refreshvizheader ind
	)
	on sld_lst picked do(
		ossel = (pile.ssl.selection)
		sidx = (pile.ssl.selection)
		if classof sidx == integer then(sidx = #(sidx))else(sidx = (sidx as array))
		selstr = for i in sidx collect pile.sl[1][i]

		if (classof pile.ssl == MultiListBoxControl) == true then(
			pile.pilerollout.slist.pos.x = pile.ssl.pos.x
			if (maxVersion())[1] >= 9000 do(pile.pilerollout.slist.width = pile.ssl.width)
			ossel = (pile.ssl.selection as array)[1]
			selstr = #(pile.sl[1][1])
			if (maxVersion())[1] >= 9000 then(pile.ssl.pos.x -= (pile.ssl.width + 50))else(pile.ssl.pos.x = -500)
			pile.ssl = pile.pilerollout.slist
			try(pile.pilerollout.height -= (pile.pilerollout.mslist.height	- 64))catch(pile.pileYresize())
		)else(
			pile.pilerollout.mslist.pos.x = pile.ssl.pos.x
			if (maxVersion())[1] >= 9000 do(pile.pilerollout.mslist.width = pile.ssl.width)
			if (maxVersion())[1] >= 9000 then(pile.ssl.pos.x -= (pile.ssl.width + 50))else(pile.ssl.pos.x = -500)
			pile.ssl = pile.pilerollout.mslist
			try(pile.pilerollout.height += (pile.ssl.height	- 32))catch(pile.pileYresize())
		)
		pile.populateslist pile.ssl selstr 1 0
		pile.populateOList pile.pilerollout.olist pile.oflt pile.pilerollout.cflt.selection ossel pile.pilerollout pile.doflags 0
		pile.selolist ossel (pile.pilerollout.olist.selection as array) pile.pilerollout.autosel.checked pile.pilerollout.autoframe.state 0
	)
)

rcmenu newsetmenu (
	menuitem snw_lst "new from list selection"
	menuitem snw_sel "new from scene selection"
	menuitem snw_viz "new from all visible"
	on snw_lst picked do(
		if dopilelog == true do(format"pile.newsetmenu.snw_lst.picked\n" to:pilelog); ind = 0
		pile.makenewselset csl #() ind
	)
	on snw_sel picked do(
		if selection.count != 0 do(
			if dopilelog == true do(format"pile.newsetmenu.snw_sel.picked\n" to:pilelog); ind = 0
			pile.makenewselset (selection as array) #() ind
		)
	)
	on snw_viz picked do(
		isvis = for i in objects where i.ishidden == false collect i
		if isvis.count != 0 do(
			if dopilelog == true do(format"pile.newsetmenu.snw_viz.picked\n" to:pilelog); ind = 0
			pile.makenewselset isvis #() ind
		)isvis = 0
	)
)

rcmenu addtosetmenu (
	menuitem sad_nfl "new from list selection"
	separator sd2
	menuitem sad_lst "add scene selection"
	menuitem sad_viz "add all visible"
	separator sep1
	menuitem sad_par "add parents"
	menuitem sad_anc "add parents (recursive)"
	menuitem sad_chi "add children"
	menuitem sad_dec "add children (recursive)"
	on sad_nfl picked do(
		if dopilelog == true do(format"pile.addtosetmenu.sad_nfl.picked\n" to:pilelog); ind = 0
		pile.makenewselset csl #() ind
	)
	on sad_lst picked do(
		if dopilelog == true do(format"pile.addtosetmenu.sad_lst.picked\n" to:pilelog); ind = 0
		if selection.count != 0 do(pile.addtoselset (selection as array) (pile.ssl.selection) ind)
	)
	on sad_viz picked do(
		uh = for i in objects where i.ishidden == false collect i
		if uh.count != 0 do(
			if dopilelog == true do(format"pile.addtosetmenu.sad_viz.picked\n" to:pilelog); ind = 0
			pile.addtoselset uh (pile.ssl.selection) ind
		)
		uh = 0
	)
	on sad_par picked do(
		if dopilelog == true do(format"pile.addtosetmenu.sad_par.picked\n" to:pilelog); ind = 0
		parents = pile.getparents csl 0 ind; if parents.count != 0 do(pile.addtoselset parents (pile.ssl.selection) ind)
	)
	on sad_anc picked do(
		if dopilelog == true do(format"pile.addtosetmenu.sad_anc.picked\n" to:pilelog); ind = 0
		parents = pile.getparents csl 1 ind; if parents.count != 0 do(pile.addtoselset parents (pile.ssl.selection) ind)
	)
	on sad_chi picked do(
		if dopilelog == true do(format"pile.addtosetmenu.sad_chi.picked\n" to:pilelog); ind = 0
		ac = pile.getchildren csl 0 ind; if ac.count != 0 do(pile.addtoselset ac (pile.ssl.selection) ind)
	)
	on sad_dec picked do(
		if dopilelog == true do(format"pile.addtosetmenu.sad_dec.picked\n" to:pilelog); ind = 0
		ac = pile.getchildren csl 1 ind; if ac.count != 0 do(pile.addtoselset ac (pile.ssl.selection) ind)
	)
)

rcmenu remfromsetmenu (
	menuitem srm_lst "remove list selection"
	menuitem srm_sel "remove scene selection"
	menuitem srm_viz "remove all visible"
	on srm_lst picked do(
		if dopilelog == true do(format"pile.remfromsetmenu.srm_lst.picked\n" to:pilelog); ind = 0
		pile.removefromselset csl (pile.ssl.selection) 0 ind
	)
	on srm_sel picked do(
		if dopilelog == true do(format"pile.remfromsetmenu.srm_sel.picked\n" to:pilelog); ind = 0
		if selection.count != 0 do(pile.removefromselset (selection as array) (pile.ssl.selection) 0 ind)
	)
	on srm_viz picked do(
		uh = for i in objects where i.ishidden == false collect i
		if uh.count != 0 do(
			if dopilelog == true do(format"pile.remfromsetmenu.srm_viz.picked\n" to:pilelog); ind = 0
			pile.removefromselset uh (pile.ssl.selection) 0 ind
		)
		uh = 0
	)
)

rcmenu syncsetmenu (
	menuitem ssy_lst "sync to list selection"
	menuitem ssy_sel "sync to scene selection"
	menuitem ssy_viz "sync to all visible"
	on ssy_lst picked do(
		if dopilelog == true do(format"pile.syncsetmenu.ssy_lst.picked\n" to:pilelog); ind = 0
		tn = #()
		retiring = (pile.ssl.selection); if classof retiring == integer then(retiring = #(retiring))else(retiring = (retiring as array))
		for i in retiring do(
			append tn pile.sl[1][i]
			idx = pile.sl[2][i]
			deleteitem selectionsets idx
		)
		pile.makenewselset csl tn ind
		tn = 0
	)
	on ssy_sel picked do(
		if dopilelog == true do(format"pile.syncsetmenu.ssy_sel.picked\n" to:pilelog); ind = 0
		tn = #()
		retiring = (pile.ssl.selection); if classof retiring == integer then(retiring = #(retiring))else(retiring = (retiring as array))
		for i in retiring do(
			append tn pile.sl[1][i]
			idx = pile.sl[2][i]
			deleteitem selectionsets idx
		)
		pile.makenewselset (selection as array) tn ind
		tn = 0
	)
	on ssy_viz picked do(
		uh = (for i in objects where i.ishidden == false collect i)
		if uh.count != 0 do(
			if dopilelog == true do(format"pile.syncsetmenu.ssy_viz.picked\n" to:pilelog); ind = 0
			tn = #()
			retiring = (pile.ssl.selection); if classof retiring == integer then(retiring = #(retiring))else(retiring = (retiring as array))
			for i in retiring do(
				append tn pile.sl[1][i]
				idx = pile.sl[2][i]
				deleteitem selectionsets idx
			)
			pile.makenewselset uh tn ind
			tn = 0
		)
		uh = 0
	)
)

function matlistfn = (
	if csl.count != 0 do(
		if dopilelog == true do(format"pile.matlistfn()\n" to:pilelog); ind = 0
		astr = "rcmenu matlist (\n\tmenuitem mfn_st \"stored only\" checked:false\n\tseparator sep1\n"
		for i = 1 to pile.pilematlist[1].count do(
			astr = (astr + "\tmenuitem mfn_" + (i as string) + " \"" + pile.pilematlist[2][i] + "\"\n")
		)
		astr = (astr + "\ton matlist open do(\n")
		for i = 1 to csl.count do(
			idx = pile.findinarray csl[i].material pile.pilematlist[1]
			if idx != 0 do(
				astr = astr + "\t\tmfn_" + (idx as string) + ".checked = true\n"
			)
		)
		astr = astr + "\t)\n"
		for i = 1 to pile.pilematlist[1].count do(
			if pile.pilematlist[2][i] != "undefined" or pile.pilematlist[2][i] != "multi" do(
				astr = (astr + "\ton mfn_" + (i as string) + " picked do(\n\t\tfor m in csl do (m.material = pile.pilematlist[1][" + (i as string) + "])\n\t)\n")
			)
		)
		astr = astr + ")\n"
		mmenu = (execute(astr))
		return mmenu
	)
)
function setlistfn = (
	if csl.count != 0 do(
		if dopilelog == true do(format"pile.setlistfn()\n" to:pilelog); ind = 0
		astr = "rcmenu setlistmenu (\n\tmenuitem slm_cp \"copy\" checked:true\n\tmenuitem slm_mv \"move\" checked:false\n\tseparator sep1\n"
		for i = 1 to pile.sl[1].count do(
			astr = (astr + "\tmenuitem slm_" + (i as string) + " \"" + pile.sl[1][i] + "\"\n")
		)
		astr = (astr + "on setlistmenu open do(if pile.copyormove == 0 then(slm_cp.checked = true; slm_mv.checked = false)else(slm_cp.checked = false; slm_mv.checked = true))\n")
		astr = (astr + "on slm_cp picked do(pile.copyormove = 0)\n")
		astr = (astr + "on slm_mv picked do(pile.copyormove = 1)\n")
		for ts = 1 to pile.sl[1].count do(
			astr = (astr + "\t on slm_" + (ts as string) + " picked do(\n\t\t tcs = #(); tr = #() \n\t\t for i in csl do(append tr i) \n\t\t sidx = (pile.ssl.selection); if classof sidx == integer then(sidx = #(sidx))else(sidx = (sidx as array)) \n\t\t for i in sidx do( append tcs pile.sl[2][i]) \n\t\t case pile.copyormove of( \n\t\t\t 0: (pile.addtoselset csl #(" + (ts as string) + ") 0) \n\t\t\t 1: (pile.removefromselset tr tcs 0 0; pile.addtoselset tr #(" + (ts as string) + ") 0; tr = 0) \n\t\t) \n\t\t ts = 0; tcs = 0 \n\t)\n")
		)
		astr = astr + ")\n"
		--format"pile.setlistfn: returns:\n%\n"astr
		smenu = (execute(astr))
		return smenu
	)
)



/*END RCmenus */



/*BEGIN rollout */


rollout rpile "pile V7200" width:250 height:636
(
	label rpad "" pos:[232,8] width:4 height:4
	multiListBox mslist "" pos:[8,8] width:232 height:9
	dropdownList slist "" pos:[8,8] width:232 height:21
	edittext snametxt "" pos:[4,36] width:236 height:16

	edittext flttxt "" pos:[144,84] width:64 height:16
	label flbl "FLT" pos:[8,80] width:24 height:16
	dropdownList cflt "" pos:[36,80] width:104 height:21 items:#("name", "class", "superclass", "materialclass", "modifierclass")
	checkbox nflt "^" pos:[216,84] width:24 height:16 toolTip:"not"

	label sellbl "SEL" pos:[8,108] width:24 height:16
	edittext listby "" pos:[32,108] width:76 height:16
	label srtlbl "SRT" pos:[112,108] width:24 height:16
	edittext sortby "" pos:[136,108] width:102 height:16 toolTip:"sort by property, EG: .pos.z"

	button addtoset "+>" pos:[4,132] width:28 height:16 toolTip:"add to selection set..."
	button remfromset "->" pos:[4,148] width:28 height:16 toolTip:"remove from selection from set..."
	button syncset "=>" pos:[4,164] width:28 height:16 toolTip:"sync selection set to..."

	multiListBox olist "" pos:[36,132] width:204 height:32

	edittext onametxt "" pos:[32,564] width:180 height:16
	button onamefn ">" pos:[220,564] width:20 height:16 toolTip:"object-name tags & functions"

	button slistf "L>" pos:[8,56] width:24 height:16 toolTip:"selectionset list functions"
	button setf "S>" pos:[32,56] width:24 height:16 toolTip:"selectionset functions"
	button datf "D>" pos:[56,56] width:24 height:16 toolTip:"data checks"
	checkbox setvizt "V" pos:[84,56] width:26 height:16 toolTip:"selectionset vizibility"
	checkbutton sels "S" pos:[114,56] width:24 height:16 toolTip:"selectionset autoselect"
	checkbutton autoisoset "ISO" pos:[138,56] width:24 height:16 toolTip:"selectionset auto isolate (toggle)"
	checkbutton autohu "HU" pos:[162,56] width:24 height:16 toolTip:"selectionset auto isolate"

	button capdat "C" pos:[192,56] width:24 height:16 toolTip:"capture data"
	button resdat "R" pos:[216,56] width:24 height:16 toolTip:"restore data"

	button olistf "L>" pos:[4,204] width:28 height:16 toolTip:"list options\nflags:\nV=visible\nF=frozen\nC=instanced\nS=has modifiers\nM=matte"

	button propf "P>" pos:[4,228] width:28 height:16 toolTip:"object properties"
	button objf "O>" pos:[4,244] width:28 height:16 toolTip:"object functions"
	checkbutton autosel "SEL" pos:[4,260] width:28 height:16 toolTip:"auto-select"
	checkbutton autoframe "FRM" pos:[4,276] width:28 height:16 toolTip:"auto-frame"
	checkbutton autoisoobj "ISO" pos:[4,292] width:28 height:16 toolTip:"auto isolate"

	checkbox issel "S" pos:[4,312] width:28 height:16 toolTip:"selected"
	checkbox isviz "V" pos:[4,328] width:28 height:16 toolTip:"vizibility"
	checkbox isfrz "F" pos:[4,344] width:28 height:16 toolTip:"frozen"
	checkbox ison "O" pos:[4,360] width:28 height:16 toolTip:"on/off"
	colorPicker wirecol "" pos:[0,380] width:16 height:16 title:""
	button wirecolfn ">" pos:[16,380] width:16 height:16 toolTip:"wirecolour interpolation across highlighted objects"
	checkbutton doextrachecks "..." pos:[4,400] width:28 height:16 toolTip:"extra checks"
	checkbox iscacheon "c" pos:[4,420] width:28 height:12 enabled:false toolTip:"point-cache"
	checkbox isparticleon "p" pos:[4,436] width:28 height:16 enabled:false toolTip:"particle enabled/viewpercent"
	button fumefn "Fu>" pos:[4,456] width:28 height:16 toolTip:"fume functions"
	button matddl "M>" pos:[4,472] width:28 height:16 toolTip:"materials"
	button copymenu "Cp>" pos:[4,488] width:28 height:16 toolTip:"copy/move objects to another set"

	edittext renfrom "" pos:[32,584] width:92 height:16
	edittext rento "" pos:[124,584] width:92 height:16
	button doinky "ok" pos:[220,584] width:20 height:16 toolTip:"perform wildcard rename"

	label informations "" pos:[4,608] width:200 height:20

	checkbutton xpt ">>" pos:[220,608] width:16 height:16 tooltop:"watch this space..."

	progressBar progbar "" pos:[-500,0] width:60 height:8


/*END Rollout */

/*BEGIN Events */

	on rpile open do(
		if objects.count != 0 then(

			pile = thepilestruct()
			pile.pilerollout = rpile
			if dopilelog == true do(
				afile = (scriptspath + "pilelog.txt")
				if doesfileexist afile do(deletefile afile)
				pilelog = createfile afile
				format"session started at %\n\n"localTime to: pilelog
				format"pile.pilerollout.open\n" to:pilelog
			)
			pile.ssl = slist
			if (maxVersion())[1] >= 9000 then(mslist.pos.x -= mslist.width + 50)else(mslist.pos.x -= 500)
			pad = 8
			try(
				pile.ssl.width = (rpile.width - (2 * pad))
				olist.width = (rpile.width - (2 * pad))
			)catch()
			rpile.width += 1
			try(getnamedselsetname 1)catch(selectionsets["ALL"] = objects)
			gsw = timestamp()
			pile.populateslist pile.ssl #((getnamedselsetname 1)) 0 0
			pile.populateOList olist pile.oflt cflt.selection (pile.ssl.selection) rpile pile.doflags 0


			pile.selolist (pile.ssl.selection) (olist.selection as array) autosel.checked autoframe.state 0
			/*
			informations.text = "attempting to restore missing maps/materials..."
			pile.backwashthematlib 0
			informations.text = "ok"
			*/

		)else(messagebox"nothing to do here"; destroydialog rpile)

	)
	on xpt changed val do(
		try(
			cui.UnRegisterDialogBar rpile
			if val == true do(pile.xpsx = 150; rpile.width += pile.xpsx)
			if val == false do(txp = pile.xpsx; pile.xpsx = 0; rpile.width -= txp)
			cui.RegisterDialogBar rpile maxSize:[-1,-1] minsize:[250,500] tyle:#(#cui_dock_vert, #cui_floatable, #cui_handles)
		)catch()
	)
	on rpile resized ns do(
		if (maxVersion())[1] >= 9000 do(
			pad = 8
			pile.ssl.width = ((rpile.width - pile.xpsx) - (pile.ssl.pos.x + 2))
			rpad.pos.x = (pile.ssl.width + pile.ssl.pos.x)
			plh = pile.ssl.height
			if (classof pile.ssl) == ComboBoxControl do(plh = (pile.ssl.height / 32))
			snametxt.pos.y = (pile.ssl.pos.y + plh + pad)
				capdat.pos.y = (snametxt.pos.y + 16 + pad)
				slistf.pos.y = capdat.pos.y
				setf.pos.y = capdat.pos.y
				datf.pos.y = capdat.pos.y
				setvizt.pos.y = capdat.pos.y
				sels.pos.y = capdat.pos.y
				autoisoset.pos.y = capdat.pos.y
				autohu.pos.y = capdat.pos.y
				resdat.pos.y = capdat.pos.y
					nflt.pos.y = (capdat.pos.y + 16 + pad)
					flttxt.pos.y = nflt.pos.y
					flbl.pos.y = nflt.pos.y
					cflt.pos.y = nflt.pos.y
						listby.pos.y = (nflt.pos.y + 21 + pad)
						sellbl.pos.y = listby.pos.y
						srtlbl.pos.y = listby.pos.y
						sortby.pos.y = listby.pos.y
							olist.pos.y = (listby.pos.y + 16 + pad)
							addtoset.pos.y = olist.pos.y
							remfromset.pos.y = olist.pos.y + 16
							syncset.pos.y = olist.pos.y + 32

			olist.width = ((rpile.width - pile.xpsx) - (olist.pos.x + 4))
			olist.height = ((rpile.height) - (olist.pos.y + 74))


			flttxt.width = ((rpile.width - pile.xpsx) - 180)
			flttxt.pos.x = (cflt.width + cflt.pos.x + 4)
			nflt.pos.x = (olist.pos.x + olist.width - (28))

			listby.width = (((rpile.width - pile.xpsx) - listby.pos.x) * 0.5)
			srtlbl.pos.x = (listby.width + listby.pos.x + (pad))
			sortby.pos.x = srtlbl.pos.x + 30
			sortby.width = ((rpile.width - pile.xpsx) - (sortby.pos.x + (6)))


			capdat.pos.x = (olist.pos.x + olist.width - (48))
			resdat.pos.x = (olist.pos.x + olist.width - (24))

			snametxt.width = pile.ssl.width
			onametxt.pos.y = (olist.pos.y + olist.height + pad)
			onametxt.width = ((rpile.width - pile.xpsx) - 68 )
			onamefn.pos.x = (onametxt.width + onametxt.pos.x + 8)
			onamefn.pos.y = onametxt.pos.y
			xpt.pos.x = onamefn.pos.x

			renfrom.pos.y = (onametxt.pos.y + onametxt.height + pad)
			rento.pos.y = renfrom.pos.y
			doinky.pos.y = renfrom.pos.y

			renfrom.width = (((rpile.width - pile.xpsx) / 2) - 36)
			rento.pos.x = (renfrom.pos.x + renfrom.width + pad)
			rento.width = ((rpile.width - pile.xpsx) - rento.pos.x - 24 - (pad))
			doinky.pos.x = (rento.pos.x + rento.width + pad)

			informations.pos.y = (doinky.pos.y + 26)
			xpt.pos.y = informations.pos.y

			owh = (17 * 16)
			olh = (olist.height / 2)
			lhd = olh - (owh / 2)
			copymenu.pos.y = (renfrom.pos.y) - lhd
			matddl.pos.y = copymenu.pos.y - 16
			fumefn.pos.y = matddl.pos.y - 16
			isparticleon.pos.y = fumefn.pos.y - 16
			iscacheon.pos.y = isparticleon.pos.y - 16
			doextrachecks.pos.y = iscacheon.pos.y - 16
			wirecolfn.pos.y = doextrachecks.pos.y - 16
			WireCol.pos.y = wirecolfn.pos.y
			ison.pos.y = WireCol.pos.y - 16
			isfrz.pos.y = ison.pos.y - 16
			isviz.pos.y = isfrz.pos.y - 16
			issel.pos.y = isviz.pos.y - 16
			autoisoobj.pos.y = issel.pos.y - 16
			autoframe.pos.y = autoisoobj.pos.y - 16
			autosel.pos.y = autoframe.pos.y - 16
			objf.pos.y = autosel.pos.y - 16
			propf.pos.y = objf.pos.y - 16
			if olist.pos.y > (propf.pos.y - 16) then(olistf.pos.y = propf.pos.y - 16)else(
				if olist.pos.y < (syncset.pos.y + 16) then(
					olistf.pos.y = (syncset.pos.y + 16)
				)else(
					olistf.pos.y = olist.pos.y
				)
			)
		)
	)

	on sortby entered txt do(
		if dopilelog == true do(format"pile.pilerollout.sortby.entered(%)\n" txt to:pilelog); ind = 0
		pile.populateOList olist pile.oflt cflt.selection (pile.ssl.selection) rpile pile.doflags ind
		pile.selolist (pile.ssl.selection) (olist.selection as array) autosel.checked autoframe.state ind
	)

	on listby changed txt do(
		if dopilelog == true do(format"pile.pilerollout.listby.changed(%)\n" txt to:pilelog); ind = 0
		olist.selection = (pile.listfilterer txt olist.items)
		pile.selolist (pile.ssl.selection) (olist.selection as array) autosel.checked autoframe.state ind
	)
	on rpile lbuttondown pos do(
    	if (maxVersion())[1] >= 9000 do(
          if classof pile.ssl == MultiListBoxControl do(
              pile.mposy = pos.y
              if pile.mposy > (pile.ssl.pos.y + pile.ssl.height) then(
                  if pile.mposy < ((pile.ssl.pos.y + pile.ssl.height) + 8) then(
                      pile.amresizing = 1
                      setSysCur #move
                  )else(pile.amresizing = 0)
              )else(pile.amresizing = 0)
          )
        )
	)
	on rpile lbuttonup pos do(
    	if (maxVersion())[1] >= 9000 do(
          if classof pile.ssl == MultiListBoxControl do(
              pile.amresizing = 0
              pile.rposy = (pile.ssl.pos.y + pile.ssl.height)
              pile.rslh = pile.ssl.height
              setSysCur #arrow
          )
        )
	)
	on rpile mousemove mxf do(
    	if (maxVersion())[1] >= 9000 do(
          if classof pile.ssl == MultiListBoxControl do(
              if mxf.y > (pile.ssl.pos.y + pile.ssl.height) do(
                  if mxf.y < ((pile.ssl.pos.y + pile.ssl.height) + 8) do(
                      setSysCur #move
                  )
              )

              if pile.amresizing == 1 then(
                  if mxf.y > 60.0 and mxf.y < (rpile.height - 4) then(
                      npos = (mxf.y - pile.mposy)
                      pile.ssl.height = (pile.rslh + npos)
                      pile.pileYresize()
                  )
              )
          )
        )
		pile.checksetstatechange()

	)

	on mslist doubleclicked itm do(
		ap = (pile.gettristateofcommon pile.ol #ishidden 0)
		if ap >= 1 then(ap = false)else(ap = true)
		for i in pile.ol do (i.ishidden = (not ap))
		isviz.state = (ap)
		pile.refreshvizheader 0
	)
	on mslist rbuttondown do(popupmenu ssf)
	on mslist selectionend do(
		if dopilelog == true do(format"pile.ssl.selectionend\n" to:pilelog); ind = 0
		pile.selsetlist pile.ssl.selection ind
	)
	on slist selected val do(
		gsw = timestamp()
		if dopilelog == true do(format"\npile.ssl.selected(%)\n"val to:pilelog); ind = 0
		pile.checksetstatechange()
		pile.selsetlist #(val) ind
	)
	on slistf pressed do(popupmenu slistdisplayfunc)

	on flttxt changed txt do(
		if dopilelog == true do(format"pile.pilerollout.flttxt.changed(%)\n" txt to:pilelog); ind = 0
		if txt != "" then(pile.oflt = txt)else(pile.oflt = "*")
		pile.populateOList olist pile.oflt cflt.selection (pile.ssl.selection) rpile pile.doflags ind
		pile.selolist (pile.ssl.selection) (olist.selection as array) autosel.checked autoframe.state ind
	)

	on cflt selected val do(
		if dopilelog == true do(format"pile.pilerollout.cflt.changed(%)\n" val to:pilelog); ind = 0
		if flttxt.text != "" then(pile.oflt = flttxt.text)else(pile.oflt = "*")
		pile.populateOList olist pile.oflt cflt.selection (pile.ssl.selection) rpile pile.doflags ind
		pile.selolist (pile.ssl.selection) (olist.selection as array) autosel.checked autoframe.state ind
	)
	on nflt changed val do(
		if dopilelog == true do(format"pile.pilerollout.nflt.changed(%)\n" val to:pilelog); ind = 0
		if flttxt.text != "" then(pile.oflt = flttxt.text)else(pile.oflt = "*")
		pile.populateOList olist pile.oflt cflt.selection (pile.ssl.selection) rpile pile.doflags ind
		pile.selolist (pile.ssl.selection) (olist.selection as array) autosel.checked autoframe.state ind
	)
	on olist selectionend do(
		--sw = timestamp()
		if dopilelog == true do(format"pile.pilerollout.olist.selectionend\n" to:pilelog); ind = 0
		pile.checksetstatechange()
		pile.selolist (pile.ssl.selection) (olist.selection as array) autosel.checked autoframe.state ind

		--esw = timestamp()
		--format"UI:olist: all selection code took % milliseconds\n\n"(esw - sw)
	)
	on olist doubleclicked val do(
		if dopilelog == true do(format"pile.pilerollout.olist.doubleclicked\n" to:pilelog); ind = 0
		olist.selection = #all
		pile.selolist (pile.ssl.selection) (olist.selection as array) autosel.checked autoframe.state ind
		onametxt.text = ""; informations.text = ((csl.count as string) + " objects highlighted.")
	)
	on onametxt entered txt do(
		if txt != "" do(
			if dopilelog == true do(format"pile.pilerollout.onametxt.entered(%)\n" txt to:pilelog); ind = 0
			p = findstring txt "%"
			if p != undefined then(pile.reptaggedname csl txt ind)else(pile.repnumberedname csl txt ind)
			pile.populateOList olist pile.oflt cflt.selection (pile.ssl.selection) rpile pile.doflags ind
		)
	)
	on onamefn pressed do(popupmenu onamefunc)
	on snametxt entered txt do(
		if txt != "" do(
			if dopilelog == true do(format"pile.pilerollout.snametxt.entered(%)\n" txt to:pilelog); ind = 0
			ssel = (pile.getobjsofsets (pile.ssl.selection) ind)
			for s in ssel[1] do(deleteitem selectionsets (pile.getsetidxfromname s ind))
			sidx = (pile.ssl.selection); if classof sidx == integer then(sidx = #(sidx))else(sidx = (sidx as array))
			mxl = (sidx.count as string).count
			nsna = #()
			nsn = ""
			for g = 1 to ssel[2].count do(
				nsn = (pile.renameset txt mxl nsna ind)
				append nsna nsn
			)
			for s = 1 to ssel[1].count do(
				pile.pilerenameobjbufferkey ssel[1][s] nsna[s] ssel[2][s] ind
				pile.pilerenameobjbuffervalsubstring ssel[1][s] nsna[s] ind
				for o in ssel[2][s] do (
					setuserprop o ("sset_" + nsna[s]) nsna[s]
				)
			)
			for g = 1 to ssel[1].count do(
				selectionsets[(nsna[g])] = ssel[2][g]
			)
			ssel = 0
			pile.populateslist pile.ssl nsna 0 ind; sc = #()
			sidx = (pile.ssl.selection); if classof sidx == integer then(sidx = #(sidx))else(sidx = (sidx as array))
			if sidx.count == 1 then(snametxt.text = nsn)else()
			pile.populateOList olist pile.oflt cflt.selection sidx rpile pile.doflags ind
		)
	)

	on setf pressed do(
		popupmenu pilesetfunc
	)
	on setvizt changed val do (
		if dopilelog == true do(format"pile.pilerollout.setvizt.changed(%)\n" val to:pilelog); ind = 0
		sidx = pile.ssl.selection
		if classof sidx == integer then(sidx = #(sidx))else(sidx = (sidx as array))
		for i = 1 to sidx.count do(
			idx = pile.sl[2][(sidx[i])]
			-- format"changing visibility of selectionset %, idx = %\n"selectionsets[idx] idx
			if val == true do(unhide selectionsets[idx]; isviz.state = true)
			if val == false do(hide selectionsets[idx]; isviz.state = false)
		)
		pile.refreshvizheader ind
	)
	on olistf pressed do(
		popupmenu pilelistfunc
	)
	on autosel changed val do(

		if val == true then(
			if dopilelog == true do(format"pile.pilerollout.autosel.changed(%)\n" val to:pilelog); ind = 0
			sels.state = false
			cslc = csl.count
			if cslc != 0 do(
				if cslc > 1 do(max create mode)
				select csl
				issel.state = true
			)
			pile.refreshvizheader ind
		)else()
	)

	on sels changed val do(
		if val == true do(
			if dopilelog == true do(format"pile.pilerollout.sels.changed(%)\n" val to:pilelog)
			autosel.state = false
			olc = pile.ol.count
			if olc != 0 do(
				if olc > 1 do(max create mode)
				select pile.ol
				issel.state = true
			)
		)
	)

	on autoframe changed val do(
		if val == true do(
			if dopilelog == true do(format"pile.pilerollout.autoframe.changed(%)\n" val to:pilelog)
			if csl.count != 0 do(
				max create mode
				tmpa = getCurrentSelection()
				select csl
				viewport.zoomtobounds false $.min $.max
				clearselection()
				if tmpa.count != 0 do(
					select tmpa
				)
				tmpa = 0
			)
		)
	)
	on isviz changed val do(
		if dopilelog == true do(format"pile.pilerollout.isviz.changed(%)\n" val to:pilelog); ind = 0
		for i in csl do i.ishidden = (not val)
		pile.refreshvizheader ind
	)

	on issel changed val do(
		cslc = csl.count
		if cslc > 1 do(max create mode)
		disablesceneredraw()
		for i = 1 to cslc do(
			if val == true then(selectmore csl[i])else(deselect csl[i])
		)
		enablesceneredraw()
		if val == false do(
			if autosel.checked do(autosel.state = false)
			if sels.checked do(sels.state = false)
		)
		cslc = 0
	)
	on isfrz changed val do(
		for i = 1 to csl.count do(
			csl[i].isfrozen = val
		)
	)
	on ison changed val do(
		for i = 1 to csl.count do(
			if (isproperty csl[i] #on) == true do(
				csl[i].on = ison.state
			)
		)
	)
	on remfromset pressed do(
		popupmenu remfromsetmenu
	)
	on addtoset pressed do(
		popupmenu addtosetmenu
	)
	on syncset pressed do(
		popupmenu syncsetmenu
	)
	on datf pressed do(
		popupmenu pilecapdatalist
	)

	on capdat pressed do(
		if querybox"capture settings for this set?" beep:true then(
			if dopilelog == true do(format"pile.pilerollout.capdat.pressed\n" to:pilelog); ind = 0
			idx = (pile.ssl.selection)
			if classof idx != integer then(idx = (idx as array); idx = idx[1])
			ccdc = ""
			if pile.harvestcat[21] == true do(
				ccdc = (getuserprop pile.ol[1] (pile.sl[1][idx] + "_ccd"))
			)
			pile.propbackwash pile.sl[1][idx] pile.ol ind
			if ccdc != "" do(
				if ccdc != undefined do(
					for i in selectionsets[(pile.sl[2][idx])] do(
						setuserprop i (pile.sl[1][idx] + "_ccd") ccdc
					)
				)
			)
			pile.captureall pile.sl[2][idx] pile.pilerollout ind
			ssln = #()
			idx = (pile.ssl.selection); if classof idx == integer do(idx = #(idx))
			for i in idx do(append ssln pile.sl[1][i])
			pile.populateslist pile.ssl ssln 1 ind
			ssln = 0
			pile.refreshvizheader ind
		)else()
	)

	on resdat pressed do(
		if querybox"restore captured settings for this set?" beep:true then(
			if dopilelog == true do(format"pile.pilerollout.resdat.pressed\n" to:pilelog); ind = 0
			idx = (pile.ssl.selection)
			if classof idx != integer then(idx = (idx as array); idx = idx[1])
			if pile.dorestoreisol == true do(
				pile.isolateobjs pile.ol ind
				pile.refreshvizheader ind
			)
			pile.restoreall pile.sl[2][idx] 0
			pile.refreshvizheader ind
		)else()
	)

	on objf pressed do(
		popupmenu pileobjfunc
	)
	on doextrachecks changed val do(
		if dopilelog == true do(format"pile.pilerollout.doextrachecks.changed(%)\n" val to:pilelog)
		if val == true do(
			pile.checkchecks true 0
		)
		iscacheon.enabled = val
		isparticleon.enabled = val
	)
	on fumefn pressed do(
		popupmenu pilefumefunc
	)
	on iscacheon changed val do(
		for i in csl where i.modifiers[#point_cache] != undefined do(
			setuserprop i "pointcacheon" val
			i.modifiers[#point_cache].enabled = val
		)
	)

	on isparticleon changed val do(
		if dopilelog == true do(format"pile.pilerollout.isparticleon.changed(%)\n" val to:pilelog); ind = 0
		pile.togglemyparticles csl (val) 0
	)
	on wirecolfn pressed do(
		popupmenu pilecolfunc
	)
	on wirecol changed col do(
		for i in csl do(
			i.wirecolor = col
		)
	)
	on copymenu pressed do(
		popupmenu(setlistfn())
	)
	on propf pressed do(
		popupmenu pileobjprps
	)
	on bagm pressed do(
		popupmenu (pile_bag())
	)
	on autoisoset changed val do(
		if dopilelog == true do(format"pile.pilerollout.autoisoset.changed(%)\n" val to:pilelog); ind = 0
		if val == true then(
			pile.isocache = for i in objects where i.ishidden == false collect i
			hide objects
			unhide pile.ol
		)else(
			if pile.isocache.count != 0 do(
				disablesceneredraw()
				hide objects
				for i in pile.isocache do(try(unhide i)catch())
				pile.isocache = #()
				enablesceneredraw()
			)
		)
		pile.checkchecks pile.pilerollout.doextrachecks.state ind
		pile.refreshvizheader ind
	)
	on autohu changed val do(
		if dopilelog == true do(format"pile.pilerollout.autohu.changed(%)\n" val to:pilelog); ind = 0
		if val == true then(
			pile.isocache = #()
			hide objects
			unhide pile.ol
		)else(

		)
		pile.checkchecks pile.pilerollout.doextrachecks.state ind
		pile.refreshvizheader ind
	)
	on doinky pressed do(
		if dopilelog == true do(format"pile.pilerollout.autoframe.changed(%)\n" val to:pilelog); ind = 0
		pile.inky renfrom.text rento.text csl ind
		pile.populateOList olist pile.oflt cflt.selection (pile.ssl.selection) rpile pile.doflags ind
	)

	on matddl pressed do(
		if dopilelog == true do(format"pile.pilerollout.matddl.pressed\n" to:pilelog); ind = 0
		pile.checkmats ind
		popupmenu (matlistfn())
	)
	on autoisoobj changed val do(
		if dopilelog == true do(format"pile.pilerollout.autoisoobj.changed(%)\n" val to:pilelog); ind = 0
		if val == true then(
			pile.isocache = for i in objects where i.ishidden == false collect i
			hide objects
			unhide csl
		)else(
			if pile.isocache.count != 0 do(
				disablesceneredraw()
				hide objects
				for i in pile.isocache do(try(unhide i)catch())
				pile.isocache = #()
				enablesceneredraw()
			)
		)
		pile.checkchecks pile.pilerollout.doextrachecks.state ind
		pile.refreshvizheader ind
	)
	on quickrenderer pressed do(
		popupmenu pileqr
	)
	on rpile close do(
		if dopilelog == true do(
			format"\nsession ended nicely at %\n"localTime to:pilelog
			flush pilelog
			close pilelog
		)
	)

)

/*END events */

/*BEGIN ccRollout */


/*END ccRollout */


if (maxVersion())[1] < 9000 then(
	createdialog rpile 250 640 100 100 style:#(#style_sysmenu, #style_titlebar, #style_border, #style_minimizebox, #style_noresize) menu:scnf
)else(
	createdialog rpile 250 640 100 100 style:#(#style_sysmenu, #style_titlebar, #style_border, #style_minimizebox, #style_resizing) menu:scnf
	try(cui.RegisterDialogBar rpile maxSize:[-1,-1] minsize:[250,500] tyle:#(#cui_dock_vert, #cui_floatable, #cui_handles))catch()
	-- registerViewWindow rpile
)
