/*
script launcher.
by c.p.brown 2009.
otimizations by Lukas Lepikovsk.
*the search path is set at the beginning.
*directory searches are recursive.
*creates a directory called 'bag' in the scriptspath
to which network scripts are copied before execution.
this directory is volatile! 
don't save anything important in there.
*/

(
therepdirs = #()
thebagoscripts = #()
filteredscripts = #(#(), #())
thescriptdirs = #(#(), #())
thekeys = #()
grbag = 0


	fn sortbystring s1 s2 = (
		if s1>s2 then 1
		else if s1<s2 then -1
		else 0
	)
	fn slashfix apath = (
		clientlist = #()
		for i = 1 to apath.count do(if apath[i] == "\\" do(append clientlist i))
		q = 0
		for i in clientlist do(apath = replace apath (i + q) 1 "\\\\"; q += 1)
		return apath
	)
		
	fn readbagkeywords akey afile = (
		ret = ""
		if doesfileexist afile == true do(
			sc = openfile afile mode:"r"
			c = 1
			while not eof sc do(
				if c > 2 do(exit)
				aline = readline sc
				if aline != "" do(
					if matchpattern aline pattern:("--" + akey + "=*") == true do(
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
	)	
	function bag_getlastdir apath = (
		anarray = filterstring apath "\\"
		if anarray.count > 1 then(
			lastdir = anarray[anarray.count]
			if lastdir[lastdir.count] == "\\" do(
				astr = (astr = (trimright astr "\\")); lastdir = astr
			)
			return lastdir
		)else() -- format"no / delimeter found in %\n"apath)
	)
	
	function bag_gatherdirs adir exclarray = (
		-- format"FN: bag_gatherdirs: adir = %\n"adir
		anarray = (getDirectories (adir + "*"))
		append anarray (adir + ".")
		barray = #();  
		for i in anarray do( 
			alastdir = (bag_getlastdir i)
			for d in exclarray do(
				if (finditem exclarray alastdir) == 0 then(if finditem barray i == 0 do(append barray i))else()
			)
		)
		rtarray = #(#(), #())
		qsort barray sortbystring
		for f in barray do(append rtarray[1] f; append rtarray[2] (bag_getlastdir f))
		return rtarray
	)
	
	function bag_gatherfiles adir anextarray rec = (
		if adir[adir.count] == "." do(adir = trimright adir ".")
		adirarray = #(adir)
		anarray = #()
		rtarray = #(#(), #())
		-- format"FN: bag_gatherfiles: input path = %\n"adir
		if rec == 1 then(
			i = 0
			while i < adirarray.count do(
				darray = #()
				fdir = adirarray[(i + 1)]
				darray = (bag_gatherdirs fdir #("wip", "versions", "backup", "functions", "Startup", "old"))[1]
				join adirarray darray
				if i > 1000 do(exit)
				i += 1
			)
			-- anarray = #()
			for i in adirarray do(
				astr = i
				-- if i[i.count] == "\\" do(astr = (trimright astr "\\"))
				-- format"FN: bag_gatherfiles: searching in directory for scripts: %\n"astr
				for e in anextarray do(
					farray = getfiles (astr + "*." + e)
					join anarray farray
				)
			)
		)else(
			for e in anextarray do(
				farray = getfiles (adir + "*." + e)
				join anarray farray
			)			
		)
		qsort anarray sortbystring	
		thekeys = #()
		for i in anarray do(
			tg = ((getfilenamefile i) + ", ")
			astr = readbagkeywords "keywords" i
			if astr != "" do(
				tg = tg + astr
			)
			append thekeys tg
			tg = 0
		)
		for f in anarray do(
			append rtarray[1] f; append rtarray[2] (getfilenamefile f)
		)
		return rtarray
	)
	
	fn sread ascript = (
		anarray = #()
		ascr = openfile(ascript)
		while not eof ascr do(
			alin = readline ascr
			for c = 1 to alin.count do(if alin[c] == "\t" do( alin[c] = "        "))
			append anarray alin
		)
		flush ascr
		close ascr
		return anarray
	)
	
	fn bag_readscriptheader ascript = (
		anarray = #()
		ascr = openfile(ascript)
		astr = ""
		ablockc = 0
		asc = 0
		skl = 1
		while not eof ascr do(
			alin = readline ascr
			if alin.count  == 0 and ablockc == 0 do(asc = 0; exit)
			if alin.count > 1 do(
				ftc = (alin[1] + alin[2]) 
				if ftc != "--" and alin[1] != "/" and ablockc == 0 do(asc = 0; exit)
				if ftc == "--" and ablockc == 0 do(asc = 1)
				if ftc == "/*" then(ablockc = 1; asc = 0; skl = 1)else(skl = 0)
				if ftc == "*/" do(ablockc = 0; asc = 0; exit)
			)
			--format"line chars=%, "alin.count
			--format"is in a block: %, "ablockc
			--format"is a single-line comment: %\n"asc		
			-- if (ablockc + asc >= 1) and skl == 0 do(astr = (astr +  (alin + "\n")))
			for c = 1 to alin.count do(if alin[c] == "\t" do( alin[c] = "        "))
			if (ablockc + asc >= 1) and skl == 0 do(append anarray alin)
		)
		flush ascr
		close ascr
		--return astr
		return anarray
	)
	function writebagreps ar = (
	
		apath = (scriptspath + "bag.ini")
		try(deletefile apath)catch()
		afile = (createfile apath)
		for i in ar do(
			format (i + "\n") to: afile
		)
		flush afile
		close afile	
		
	)
	
	function readbagreps = (
		apath = (scriptspath + "bag.ini")
		format"FN:readbagreps:default path=%\n"apath
		afile = 0
		ret = #()
		emptyreps = 0
		if doesfileexist apath != true then(emptyreps = 1)

		if emptyreps == 0 do( 
			afile = (openfile apath)
			while not eof afile do(
				aline = readline afile
				if aline != "" do(append ret aline)
			)
			if ret.count == 0 then(emptyreps = 1)
			flush afile
			close afile			
		)
		
		if emptyreps == 1 do(
			format"FN:readbagreps: ini not found or empty, making a new one and adding the scriptspath.\n"
			try(deletefile apath)catch()
			afile = (createfile apath)
			format (scriptspath + "\n") to: afile
			append ret scriptspath
			flush afile
			close afile		
		)
		format"FN:readbagreps:returning=%\n"ret
		return ret
	)
	
	function getbagreps = (
		therepdirs = #()
		therepdirs = readbagreps()
		format"FN:getbagreps: therepdirs=%\n"therepdirs
		qsort therepdirs sortbystring
		grbag.reps.items = therepdirs
		grbag.reps.selection = 1
	)	
	function bag idx ridx = (
		thescriptdirs = #(#(), #())
		apath = therepdirs[ridx]
		thescriptdirs = (bag_gatherdirs apath #("wip", "versions", "backup", "functions", "Startup", "old"))
		if thescriptdirs[1].count != 0 then(
			thebagoscripts = bag_gatherfiles thescriptdirs[1][idx] #("ms") 0
		)else(thebagoscripts = #(#(),#()) )
	)	
	function refreshbagreps adir = (
		if therepdirs.count != 0 then(
			qsort therepdirs sortbystring
			grbag.reps.items = #()
			grbag.reps.items = therepdirs
			idx = (finditem therepdirs adir)
			try(grbag.reps.selection = idx)catch(grbag.reps.selection = 1; idx = 1)
			bag 1 idx
			if thescriptdirs[2].count != 0 then(
				grbag.dirs.items = thescriptdirs[2]
				filterscripts grbag.gsearch.text
			)else(grbag.dirs.items = #(); grbag.scriptlist.items = #())
		)else(
			getbagreps()
		)
	)
	function filterscripts txt = (
		if thebagoscripts[1].count != 0 do(
			maskr = #()
			for i = 1 to thekeys.count do(
				if (matchpattern thekeys[i] pattern:("*" + txt + "*")) == true do(
					append maskr i
				)
			)
			filteredscripts = #(#(),#())
			for i in maskr do(
				append filteredscripts[1] thebagoscripts[1][i]
				append filteredscripts[2] thebagoscripts[2][i]
			)
			grbag.scriptlist.items = filteredscripts[2]
			if grbag.scriptlist.items.count != 0 do(grbag.snotes.items = (bag_readscriptheader filteredscripts[1][1]) )
		)
	)

	function flipslash astring = (
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
	)
	function bag_getlastdir apath = (
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
	)	
	function makemeamacro afile acat rootp idx = (
		afile = (slashfix afile)
		srcpath = (slashfix filteredscripts[1][idx])
		if acat == "." do(
			astr = "" as stringstream
			format"use \".\" as the category instead of \"%\"?"rootp to:astr
			if querybox astr title:"root path selected" beep:true then(format"user selected yes\n")else(acat = rootp; format"user selected no\n")
		)
		mstr = "macroscript " + (getfilenamefile afile) + " category:\"" + acat + "\" (deletefile \"" + afile + "\"; copyFile \"" + srcpath + "\" \"" +  afile + "\"; filein \"" + afile + "\")"
		format"macroscript = %\n"mstr
		mpath = ((getdir #ui) + "macroscripts\\")
		format"macroscripts dir = %\n"mpath
		amacro = createfile (mpath + (getfilenamefile afile) + ".mcr")
		format mstr to:amacro
		flush amacro
		close amacro
		ms = ("" as stringstream)
		format"Macro created. category: %.\nrestart max to use it."acat to:ms
		messagebox ms
	)
	
	rcmenu repfn (
			
			menuitem rep_add "add..."
			menuitem rep_rem "remove"
			separator rep_sep1
			menuitem rep_exp "explorer..."
		
		on rep_exp picked do(
			shelllaunch "explorer" therepdirs[grbag.reps.selection]
		)
		on rep_add picked do(
			nrep = getSavePath initialDir:scriptspath title:"choose repository path"
			if nrep != undefined do(
				if nrep[(nrep.count)] != "\\" do(nrep = nrep + "\\")
				append therepdirs nrep
				refreshbagreps nrep
				writebagreps therepdirs
			)
		)
	)
	
	rcmenu scriptfn (
			menuitem findsdir "explorer..."
			menuitem edits "edit"
			menuitem locl "localize"
		
		on scriptfn open do(
			locl.enabled = (grbag.scriptlist.items.count > 0)
			edits.enabled = (grbag.scriptlist.items.count > 0)
		)
		on edits picked do(
			edit filteredscripts[1][grbag.scriptlist.selection]
		)		
		on findsdir picked do(
			shelllaunch "explorer" thescriptdirs[1][grbag.dirs.selection]
		)
		on locl picked do(
			val = grbag.scriptlist.selection
			adir = thescriptdirs[2][grbag.dirs.selection]
			nf = ((getfilenamefile filteredscripts[1][val] ) + (getfilenametype filteredscripts[1][val]))
			loc = ""
			if adir[adir.count] == "." then(
				loc = (scriptspath + "bag\\")
			)else(
				loc = (scriptspath + "bag\\" + adir + "\\")
			)
			if doesfileexist loc then(
				deletefile (loc + nf)
			)else(
				makeDir loc
			)
			if doesfileexist loc then(
				makemeamacro (loc + nf) thescriptdirs[2][grbag.dirs.selection] (bag_getlastdir therepdirs[grbag.reps.selection]) val
			)else(astr = ("" as stringstream); format"couldn't create local dir %" loc to: astr; messagebox astr)
		)
	)
	
	rollout rbag "bag" width:496 height:288
	(
		dropdownList reps "Repository path:" pos:[8,8] width:448 height:40
		dropdownList dirs "Script categories" pos:[8,56] width:200 height:40
		
		listbox scriptlist "" pos:[8,104] width:200 height:8
		
		editText gsearch "" pos:[6,224] width:202 height:16
		
		multiListBox snotes "" pos:[216,56] width:272 height:16
		
		button runs "run" pos:[8,248] width:168 height:24
		button filefn ">" pos:[184,248] width:24 height:24
		button apth ">" pos:[464,24] width:24 height:24
		
		
		on rbag open do(
			
			grbag = rbag
			getbagreps()
			bag 1 1
			dirs.items = thescriptdirs[2]
			scriptlist.items = thebagoscripts[2]
			if scriptlist.items.count != 0 do( snotes.items = (bag_readscriptheader thebagoscripts[1][1]) )
			filterscripts gsearch.text
		)
		
		on rbag resized nsz do(
			buff = 8
			reps.width = (rbag.width - (16 + (4 * buff)))
			apth.pos.x = (rbag.width - (16 + (2 * buff)))
			snotes.width = (rbag.width - (snotes.pos.x + buff))
			snotes.height = (rbag.height - (snotes.pos.y + buff))
			scriptlist.height = (rbag.height - (scriptlist.pos.y + (24 + 16 + (buff * 3))))
			gsearch.pos.y = (rbag.height - (24 + buff + 16 + buff))
			runs.pos.y = (rbag.height - (24 + buff))
			filefn.pos.y = runs.pos.y
		)
		on reps selected val do(
			bag 1 val
			dirs.items = thescriptdirs[2]
			filterscripts gsearch.text
		)
		on apth pressed do(popupmenu repfn)
		on dirs selected val do(
			bag val reps.selection
			filterscripts gsearch.text
		)
		on scriptlist selected val do(
			snotes.items = (bag_readscriptheader filteredscripts[1][val])	
		)
		on gsearch changed txt do(
			filterscripts txt
		)
		on runs pressed do(
			val = scriptlist.selection
			loc = (scriptspath + "bag\\" + thescriptdirs[2][dirs.selection] + "\\")
			makeDir loc
			nf = ((getfilenamefile filteredscripts[1][val] ) + (getfilenametype filteredscripts[1][val]))
			try(deletefile (loc + nf))catch()
			copyFile filteredscripts[1][val] (loc + nf)
			filein (loc + nf)
		)
		on scriptlist doubleclicked val do(
			snotes.items = (sread filteredscripts[1][val])
		)
		on filefn pressed do(popupmenu scriptfn)
	)
	
	createdialog rbag style:#(#style_sysmenu, #style_titlebar, #style_border, #style_minimizebox, #style_resizing)
)
