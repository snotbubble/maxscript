--keywords=versioning, backup, publish
/*
maxscript versioning/publishing.
by c.p.brown. 2008~2010.
*/
global grpeel = 0
global peel = 0

struct peelstruct (
	scripts = #(),
	archives = #(),
	pubs = #(),
	versions = #(#(), #(), #()),
	delimiter = "------------------------------------------------------------------------",
	fn striplastversion str = ( 
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
	fn pillow anum pad = (
		snum = ""
		case (anum < 0) of(
			true: (anum = (0 - anum); snum = (anum as string); while snum.count < pad do(snum = ("0" + snum)); snum = ("-" + snum))
			false: (snum = (anum as string); while snum.count < pad do(snum = ("0" + snum)))
		)
		return snum	
	),
	fn incramentversion s incr = (
		nn = #(0, 0)
		sn = (getfilenamefile s)
		se = (getfilenametype s)
		lv = 0
		if versions[1].count != 0 do(
			vna = versions[1]
			sort vna
			lv = (vna[vna.count] as integer)
		)
		nv = ((floor((lv + incr) / incr) * incr) as integer)
		pnv = (pillow nv  4)
		nn[1] = (sn + "_V" + pnv + se)
		nn[2] = pnv
		--format"peel.incramentversion: new version = %\n"nn
		return nn	
	),
	fn writeini = (
		apath = scriptspath + "peel.txt"
		deletefile apath
		createfile apath
		theini = openfile apath mode:"r+"
		for i in scripts do(
			if i != "" do(format ("S" + i + "\r")to:theini)
		)
		for i in archives do(
			if i != "" do(format ("A" + i + "\r")to:theini)
		)
		for i in pubs do(
			if i != "" do(format ("P" + i + "\r")to:theini)
		)	
		flush theini
		close theini
	),
	fn readini = (
		scripts = #()
		archives = #()
		pubs = #()
		apath = scriptspath + "peel.txt"
		if doesfileexist apath == false do(
			createfile apath
		)
		theini = openfile apath
		while not eof theini do(
			aline = readline theini
			if aline != "" do(
				if aline[1] == "S" then(
					tline = (trimleft aline "S")
					if doesfileexist tline != false do(append scripts tline)
				)
				if aline[1] == "A" then(
					tline = (trimleft aline "A")
					if doesfileexist tline != false do(append archives tline; format"!!!!! % is OK\n"tline)
				)
				if aline[1] == "P" do(
					tline = (trimleft aline "P")
					if doesfileexist tline != false do(append pubs tline)
				)			
			)
		)
		flush theini
		close theini	
	),
	fn readkeywords k pf = (
		ret = ""
		if doesfileexist pf == true do(
			sc = openfile pf mode:"r"
			c = 1
			while not eof sc do(
				if c > 20 do(exit)
				aline = readline sc
				if aline != "" do(
					if matchpattern aline pattern:("--" + k + "=*") == true do(
						ar = filterstring aline "="
						if ar.count > 1 do(
							if ar[2] != "" do(
								ret = ar[2]; exit
							)
						)
					)
				)
				c += 1
			)
			flush sc
			close sc
		)
		return ret
	),
	fn getversionnotes sn a vn = (
		note = ""
		np = (a + sn + "_history.txt")
		if doesfileexist np  == false then(
			createfile np
		)else(
			theini = openfile np
			iar = 0
			while not eof theini do(
				aline = readline theini
				lp = (filterstring aline " ")
				if lp.count != 0 do(
					fp = (getfilenametype lp[1])
					if fp == ".ms" or fp == ".mcr" do(
						fp = (striplastversion (getfilenamefile lp[1]))
						if fp[2] == vn do(
							iar = 1
							-- note = (note + aline + "\n")
						)
					)
				)
				if aline == delimiter do(
					iar = 0
				)
				if iar == 1 do(
					note = (note + aline + "\n")
				)
			)
			flush theini
			close theini
		)
		return note	
	),
	fn getversionentries sn a = (
		vna = #()
		np = (a + sn + "_history.txt")
		if doesfileexist np == false then(
			createfile np
		)else(
			theini = openfile np
			while not eof theini do(
				aline = readline theini
				-- format"peel.getversionentries: raw line = %\n"aline
				lp = (filterstring aline " ")
				if lp.count != 0 do(
					fp = (getfilenametype lp[1])
					if fp == ".ms" or fp == ".mcr" do(
						fp = (striplastversion (getfilenamefile lp[1]))
						--format"peel.getversionentries: found script ref = %\n"fp
						fp[1] = (trimright fp[1] "_V")
						if fp[1] == sn do(
							--format"peel.getversionentries: % = %\n\n"fp[1] sn
							append vna (getfilenamefile lp[1])
						)
					)
				)
			)
			flush theini
			close theini
		)
		return vna	
	),
	fn getversions s a = (
		--format"peel.getversions % %\n" s a
		versions = #(#(), #(), #())
		sn = (getfilenamefile s)
		se = (getfilenametype s)
		vf = (getfiles (a + sn + "_V*" + se))
		vn = for i = 1 to vf.count collect (getfilenamefile vf[i])
		vh = (getversionentries sn a)
		for i = 1 to vh.count where (finditem vn vh[i]) == 0 do(append vn vh[i])
		sort vn
		--for i in vn do(format"peel.getversions found version: %\n"i)
		for i = 1 to vn.count do(
			append versions[2] vn[i]
			append versions[1] (striplastversion vn[i])[2]
			append versions[3] (getversionnotes sn a versions[1][i])
		)
	),
	fn writenotes a sn p r = (
		np = (a + sn + "_history.txt")
		if doesfileexist np == false do(
			createfile np
		)
		theini = openfile np mode:"r+"
		for i = 1 to versions[1].count do(
			try(
				if versions[3][i] == "" then(
					format ("(missing version notes)\n\n" + delimiter + "\n")to:theini
				)else(
					format (versions[3][i] + "\n" + delimiter + "\n")to:theini
					--format"    peel.writenotes: writing:\n %\n"versions[3][i]
				)
			)catch(
				format ("(missing version notes)\n\n" + delimiter + "\n")to:theini	
			)
		)
		flush theini
		close theini
	),
	fn refresh a s p v r = (
		format"peel.refresh: a=% s=% p=% v=% r=% \n"a s p v r
		readini()
		if scripts.count != 0 and archives.count != 0 do(
			getversions scripts[s] archives[a]
		)
/*
			for i = 1 to versions[1].count do(
				format"version == %\n" versions[1][i]
				format"filename = %\n" versions[2][i]
				format"note ===== %\n\n" versions[3][i]
			)
*/
		r.pl.items = pubs
		r.al.items = archives
		r.sl.items = scripts
		r.sl.selection = s
		r.al.selection = a	
		if versions[1].count != 0 then(
			r.evl.items = versions[1]
			r.evl.selection = v
			r.evn.text = versions[3][v]
		)else(
			r.evl.items = #()
			r.evn.text = ""	
		)
		if r.ck.state == true then(
			if r.kn.text != "" do(
				sn = (getfilenamefile scripts[s])	
				se = (getfilenametype scripts[s])	
				pf = (pubs[p] + sn + se)
				if doesfileexist pf == true do(
					r.kw.text = readkeywords r.kn.text pf
				)
			)
		)else(r.kw.text = "")
		if scripts.count != 0 do(
			nv = (incramentversion scripts[s] (10^(r.vinc.state - 1)))
			r.lvt.text = ("= " + nv[2])
		)	
	)
)
rcmenu sfn (
	menuitem nsrc "add..."
	menuitem rsrc "remove"
	separator sep1
	menuitem sexp "explorer..."
	menuitem scpy "copy full path"
	
	on nsrc picked do(
		ns = getOpenFileName filename:scriptspath title:"choose maxscript"
		if (finditem peel.scripts ns) == 0 do(
			append peel.scripts ns
			peel.writeini()
			peel.refresh grpeel.al.selection peel.scripts.count  grpeel.pl.selection 1 grpeel
		)
	)
	on rsrc picked do(
		peel.scripts[grpeel.sl.selection] = ""
		peel.writeini()
		peel.refresh 1 1 1 1 grpeel
	)
	on sexp picked do(
		p = peel.scripts[grpeel.sl.selection]
		shelllaunch "explorer" (getfilenamepath p) 
	)
	on scpy picked do(
		setclipboardText peel.scripts[grpeel.sl.selection]
	)
)
rcmenu afn (
	menuitem narc "add..."
	menuitem rarc "remove"
	separator sep1
	menuitem aexp "explorer..."
	menuitem acpy "copy full path"
	
	on narc picked do(
		try(
			ns = getSavePath initialDir:scriptspath title:"choose archive path"
			if ns[ns.count] != "\\" do(ns = ns + "\\")
			if (finditem peel.archives ns) == 0 do(
				append peel.archives ns
				peel.writeini()
				peel.refresh peel.archives.count grpeel.sl.selection grpeel.pl.selection 1 grpeel
			)
		)catch()
	)
	on rarc picked do(
		peel.archives[grpeel.alist.selection] = ""
		peel.writeini()
		peel.refresh peel.archives.count grpeel.sl.selection grpeel.pl.selection 1 grpeel
	)
	on aexp picked do(
		p = versions[grpeel.al.selection]
		shelllaunch "explorer" (getfilenamepath p) 
	)
	on acpy picked do(
		setclipboardText versions[grpeel.al.selection]
	)
)
rcmenu pfn (
	menuitem npub "add..."
	menuitem rpub "remove"
	separator sep1
	menuitem pexp "explorer..."
	menuitem pcpy "copy full path"
	
	on npub picked do(
		try(
			ns = getSavePath initialDir:scriptspath title:"choose archive path"
			if ns[ns.count] != "\\" do(ns = ns + "\\")
			append peel.pubs ns
			peel.writeini()
			peel.refresh grpeel.al.selection grpeel.sl.selection peel.pubs.count grpeel.evl.selection grpeel
		)catch()
	)
	on rpub picked do(
		peel.pubs[grpeel.pl.selection] = ""
		peel.writeini()
		peel.refresh grpeel.al.selection grpeel.sl.selection peel.pubs.count grpeel.evl.selection grpeel
	)
	on pexp picked do(
		p = peel.pubs[grpeel.pl.selection]
		shelllaunch "explorer" (getfilenamepath p) 
	)
	on pcpy picked do(
		setclipboardText peel.pubs[grpeel.pl.selection]
	)
)

rollout rpeel "peel_v2" width:364 height:528
(
	button apb ">" pos:[324,96] width:20 height:20
	button doit "doit" pos:[20,476] width:324 height:28
	button ppb ">" pos:[324,144] width:20 height:20
	button spb ">" pos:[324,48] width:20 height:20
	checkbox cc "" pos:[20,144] width:12 height:16
	checkbox ck "" pos:[40,172] width:16 height:16 enabled:false
	dropdownList al "archive to:" pos:[20,76] width:296 height:40
	dropdownList pl "also copy to:" pos:[40,124] width:276 height:40
	dropdownList sl "script" pos:[20,28] width:296 height:40
	edittext evn "" pos:[80,260] width:264 height:80
	edittext kn "" pos:[64,192] width:92 height:20 text:"keywords" enabled:false
	edittext kw "" pos:[200,192] width:144 height:20 enabled:false
	edittext vn "" pos:[16,396] width:328 height:48
	GroupBox grp1 "select paths" pos:[8,8] width:348 height:216
	GroupBox grp2 "new version" pos:[8,360] width:348 height:156
	GroupBox grp3 "detected versions" pos:[8,236] width:348 height:116
	label lbl2 "note" pos:[24,378] width:28 height:16
	label lk "and insert keyword header into copy:" pos:[60,172] width:200 height:16 enabled:false
	listbox evl "" pos:[16,260] width:60 height:6
	radiobuttons vinc "" pos:[24,456] width:249 height:16 labels:#("edit", "patch", "release", "version") columns:4
	label lkn "key" pos:[40,192] width:20 height:16 enabled:false
	label lkw "words" pos:[164,192] width:28 height:16 enabled:false
	label lvt "=####" pos:[261,456] width:80 height:16
	
	on rpeel open do(
		grpeel = rpeel
		peel = peelstruct()
		peel.refresh 1 1 1 1 grpeel
	)
	on rpeel resized xy do(
		evn.width = (rpeel.width - (24 + evn.pos.x))
		kw.width = (rpeel.width - (24 + kw.pos.x))
		grp1.width = (rpeel.width - (8 + grp1.pos.x))
		grp2.width = grp1.width
		grp3.width = grp1.width
		ppb.pos.x = (rpeel.width - 44)
		apb.pos.x = ppb.pos.x
		spb.pos.x = ppb.pos.x
		doit.pos.x = ((rpeel.width / 2.0) - (162))
		sl.width = (rpeel.width - (8 + 44 + sl.pos.x))
		al.width = sl.width
		pl.width = (rpeel.width - (8 + 44 + pl.pos.x))
		vn.width = (rpeel.width - (24 + vn.pos.x))
	)
	on spb pressed do(
		popupmenu sfn
	)	
	on apb pressed do(
		popupmenu afn
	)
	on ppb pressed do(
		popupmenu pfn
	)
	on sl selected idx do(
		peel.refresh al.selection idx pl.selection 1 grpeel
	)
	on evl selected idx do(
		evn.text = peel.versions[3][idx]
	)
	on evn entered txt do(
		peel.versions[3][evl.selection] = txt
		psl = ""; if peel.pubs.count != 0 do(psl = peel.pubs[pl.selection])
		peel.writenotes peel.archives[al.selection] (getfilenamefile peel.scripts[sl.selection]) psl grpeel
	)
	on ck changed val do(
		if val == true then(
			if kn.text != "" do(
				sn = (getfilenamefile peel.scripts[sl.selection])	
				se = (getfilenametype peel.scripts[sl.selection])	
				pf = (peel.pubs[pl.selection] + sn + se)
				if doesfileexist pf == true do(
					kw.text = peel.readkeywords kn.text pf
				)
			)
		)else(kw.text = "")
	)
	on cc changed val do(
		ck.enabled = val
		lkn.enabled = val
		kw.enabled = val
		kn.enabled = val
		lkw.enabled = val
		lk.enabled = val
	)
	on vinc changed val do(
		if peel.scripts.count != 0 do(
			nv = (peel.incramentversion peel.scripts[sl.selection] (10^(vinc.state - 1)))
			lvt.text = ("= " + nv[2])
		)
	)
	on doit pressed do(
		if peel.scripts[sl.selection] != undefined or peel.archives[al.selection] != undefined do(
			nv = (peel.incramentversion peel.scripts[sl.selection] (10^(vinc.state - 1)))
			append peel.versions[2] nv[1]
			append peel.versions[1] nv[2]
			append peel.versions[3] (nv[1] + " [" + localTime + "]:\n" + vn.text + "\n")
			cy = peel.versions[2].count
			format"\npeel.doit: appended version number : %\n" peel.versions[1][cy]
			format"peel.doit: appended version name : %\n" peel.versions[2][cy]
			format"peel.doit: appended version note : %\n\n" peel.versions[3][cy]
			psl = ""; if peel.pubs.count != 0 do(psl = peel.pubs[pl.selection])
			peel.writenotes peel.archives[al.selection] (getfilenamefile peel.scripts[sl.selection]) psl grpeel
			format"***** peel.doit: copying backup : %\n\n" (peel.archives[al.selection] + nv[1])
			copyfile peel.scripts[sl.selection] (peel.archives[al.selection] + nv[1])
			-- publishing:
			if cc.checked do(
				-- coppy the source to the pub dir:
				sn = ((getfilenamefile peel.scripts[sl.selection]) + (getfilenametype peel.scripts[sl.selection]))
				copyfile peel.scripts[sl.selection] (peel.pubs[pl.selection] + sn)
				if doesfileexist (peel.pubs[pl.selection] + sn) == true then(
					-- keywords:
					if ck.checked do(
						nsa = #()
						if kw.text != "" and kn.text != " " do(
							kline = ("--" + kn.text + "=" + kw.text)
							nsa = #(kline)
						)
						-- read source script into the array:
						sc = openfile peel.scripts[sl.selection] mode:"r"
						while not eof sc do(
							aline = readline sc
							append nsa aline
						)
						flush sc
						close sc
						-- delete and re-create the published file, stream array contents to it:
						if nsa.count != 0 do(
							deletefile (peel.pubs[pl.selection] + sn)
							kp = createfile (peel.pubs[pl.selection] + sn)
							if kp != undefined then(
								for i in nsa do(
									format"%\n"(i) to:kp
								)
								flush kp
								close kp
							)else(messagebox"Keyword copy failed!\nCheck disk space and permissions.")
							nsa = 0
						)
					)
				)else(messagebox"Copy failed!\nCheck disk space and permissions.")
			)
			peel.refresh al.selection sl.selection pl.selection (peel.versions[3].count) grpeel
		)
	)
)
createdialog rpeel style:#(#style_sysmenu, #style_titlebar, #style_border, #style_minimizebox, #style_resizing) lockHeight:true

