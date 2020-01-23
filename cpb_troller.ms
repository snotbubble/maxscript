/*
trackview bypass script.
remember to hit refresh if you change your scene selection!
by c.p.brown. 2008~2009.
*/

(
global actrllist = #(#(), #())
global ctrlkeyarray = #(#(), #())
global grtroller = 0


/*BEGIN generic functions */

fn gatherctrl input = (
	-- grab controllers for selected objs
	ctrlarray = #(#(), #())
	genincr = 1
	aname = ""
	for t in input do(
		subarray= #()
		subarray = #(t)
		i = 0
		aname = ""
		while i < subarray.count do(
			i += 1
			junkarray = #()
			for q = 1 to subarray[i].numsubs do(
				if subarray[i][q].controller != undefined do(
					if subarray[i][q].controller.keys.count > 0 do(
						if subarray[i][q].numsubs == 0 do(
							if subarray[i][q].keys.count != 0 do(
								append ctrlarray[1] subarray[i][q].object
								astr = "."
								try(astr = (astr + subarray[i].parent.object.name + "."))catch(try(astr = (astr + subarray[i].parent.name + "."))catch())
								try(astr = (astr + subarray[i].object.name + "."))catch(try(astr = (astr + subarray[i].name + "."))catch())
								try(astr = (astr + subarray[i][q].parent.object.name + "."))catch(try(astr = (astr + subarray[i][q].parent.name + "."))catch())
								try(astr = (astr + subarray[i][q].object.name + "."))catch(try(astr = (astr + subarray[i][q].name + "."))catch())
								append ctrlarray[2] (t.name + astr)
								-- format"ctrl name = %\n"(t.name + "." + astr)
							)
						)
					)
				)
				append junkarray subarray[i][q]
			)
			join subarray junkarray
		)
		genincr += 1
	)
	-- for i = 1 to ctrlarray[1].count do (format"%\n"((ctrlarray[1][i] as string)))
	return ctrlarray
)

function offsetkeyvals thekeys aval = (
	for i in thekeys do (i.value += aval)
)
function offsetkeytimes thekeys aval = (
	thekeys.time += aval
)

/*END generic functions */

/*begin troller functions */

fn scalemykeys ctrler scalefac af = (
	
	if ctrler.keys.count != 0 do(
		for k in ctrler.keys do(
			ek = k.time
			du = (ek - af)
			nk = ((du * (scalefac / 100.0)) + af)
			k.time = nk
		)
	)
)

function getcsl = (
	docsl = 0
	if csl != undefined then(
		if csl.count != 0 then(
			try(
				for i in csl do(i.name)
				docsl = 1
			)catch(docsl = 0)
		)else(docsl = 0)
	)else(docsl = 0)
	return docsl
)

function gettrollerobjs = (
	ret = 0
	if grtroller.capsel.state == true then(
		ret = selection
	)else(
		if grtroller.capcsl.state == true then(
			dcsl = getcsl()
			if dcsl == 1 do(ret = csl)
		)else()
	)
	return ret
)

function refreshctrlhelper arollout partof = (
	objs = (gettrollerobjs())
	switchoffkeys = 0
	switchoffall = 0
	if objs.count != 0 then(
		if partof > 2 do(
			actrllist = #(#(), #())
			append actrllist[2] "all"
			for i in objs do(
				tctrllist = gatherctrl i
				if tctrllist[1].count != 0 do(
					for t = 1 to tctrllist[1].count do(if finditem actrllist[1] tctrllist[1][t] == 0 do(append actrllist[1] tctrllist[1][t]; append actrllist[2] tctrllist[2][t]))
				)
			)
			-- format"ctrllist: %\n"actrllist[2]
			if actrllist[1].count != 0 then(
				arollout.ctrllist.items = actrllist[2]
			)else(arollout.ctrllist.items = #())
		)
		if partof > 1 do(
			switchoff = 0
			if actrllist[1].count != 0 then(
				ctrlkeyarray = #(#(), #())
				if arollout.ctrllist.selection != 0 then(

					arollout.lbloffsetkeystostart.enabled = true
					arollout.spnoffsettostart.enabled = true
					arollout.btnoffsettostart.enabled = true
					arollout.lbloffsetkeystoend.enabled = true
					arollout.spnoffsettoend.enabled = true
					arollout.btnoffsettoend.enabled = true
					arollout.lblkeyoffs.enabled = true
					arollout.spnkeyoffs.enabled = true
					arollout.btndokeyoffs.enabled = true
					arollout.kvxoffs.enabled = true
					arollout.btndokeyvaloffs.enabled = true
					arollout.lblkeyvaloffs.enabled = true
					arollout.popctrlfn.enabled = true

					if arollout.ctrllist.selection != 1 then(
						thekeys = actrllist[1][(arollout.ctrllist.selection - 1)].keys
						if thekeys.count != 0 then(
							for k = 1 to thekeys.count do(
								 append ctrlkeyarray[1] (thekeys[k].time as string); append ctrlkeyarray[2] thekeys[k].value
							)
							if ctrlkeyarray[1].count != 0 then(
								arollout.keytimelist.items = ctrlkeyarray[1]
								arollout.keytimelist.enabled = true
								arollout.lblkeynum.enabled = true
								arollout.kvx.enabled = true
								if (classof ctrlkeyarray[2][1]) == point3 then(
									arollout.kvy.enabled = true
									arollout.kvz.enabled = true
									arollout.bkvy.enabled = true
									arollout.bkvz.enabled = true
								)else(
									arollout.kvy.enabled = false
									arollout.kvz.enabled = false
									arollout.bkvy.enabled = false
									arollout.bkvz.enabled = false
								)
								arollout.popkeyfunc.enabled = true
								arollout.bkvx.enabled = true
								arollout.lblkeyval.enabled = true
								arollout.lblkeyattime.enabled = true
								arollout.lblkff.enabled = true
								arollout.kff.enabled = true
								arollout.bkff.enabled = true
							)else(
								switchoffkeys = 1
							)
						)else(switchoffall = 1)
					)else(
						switchoffkeys = 1
					)
				)else(
					switchoffall = 1
				)
			)else(
				switchoffall = 1
			)
		)

		if partof > 0 do(
			if ctrlkeyarray[2].count != 0 then(
				if classof ctrlkeyarray[2][1] == point3 then(
					try(
						arollout.kvx.value = ctrlkeyarray[2][arollout.keytimelist.selection].x
						arollout.kvy.value = ctrlkeyarray[2][arollout.keytimelist.selection].y
						arollout.kvz.value = ctrlkeyarray[2][arollout.keytimelist.selection].z
					)catch(
						arollout.kvx.value = ctrlkeyarray[2][1].x
						arollout.kvy.value = ctrlkeyarray[2][1].y
						arollout.kvz.value = ctrlkeyarray[2][1].z
					)
				)else(
					try(
						arollout.kvx.value = ctrlkeyarray[2][arollout.keytimelist.selection]
					)catch(
						arollout.kvx.value = ctrlkeyarray[2][1]
					)
				)
				arollout.lblkeynum.text = ("x" + (ctrlkeyarray[2].count as string))
			)else(arollout.kvx.value = 0.0; arollout.lblkeynum.text = "")
		)
		if ctrlkeyarray[1].count != 0 do(arollout.kff.value = (ctrlkeyarray[1][arollout.keytimelist.selection] as integer))
	)else(switchoffall = 1)

	if switchoffkeys == 1 do(
		arollout.keytimelist.items = #()
		arollout.keytimelist.enabled = false
		arollout.lblkeynum.enabled = false
		arollout.kvx.enabled = false
		arollout.popkeyfunc.enabled = false
		arollout.bkvx.enabled = false
		arollout.kvy.enabled = false
		arollout.kvz.enabled = false
		arollout.bkvy.enabled = false
		arollout.bkvz.enabled = false
		arollout.lblkeyval.enabled = false
		arollout.lblkeyattime.enabled = false
		arollout.lblkff.enabled = false
		arollout.kff.enabled = false
		arollout.bkff.enabled = false
	)
	if switchoffall == 1 do(

		arollout.lbloffsetkeystostart.enabled = false
		arollout.spnoffsettostart.enabled = false
		arollout.btnoffsettostart.enabled = false
		arollout.lbloffsetkeystoend.enabled = false
		arollout.spnoffsettoend.enabled = false
		arollout.btnoffsettoend.enabled = false
		arollout.lblkeyoffs.enabled = false
		arollout.spnkeyoffs.enabled = false
		arollout.btndokeyoffs.enabled = false
		arollout.kvxoffs.enabled = false
		arollout.btndokeyvaloffs.enabled = false
		arollout.lblkeyvaloffs.enabled = false
		arollout.popctrlfn.enabled = false

		arollout.keytimelist.items = #()
		arollout.keytimelist.enabled = false
		arollout.lblkeynum.enabled = false
		arollout.kvx.enabled = false
		arollout.popkeyfunc.enabled = false
		arollout.bkvx.enabled = false
		arollout.kvy.enabled = false
		arollout.kvz.enabled = false
		arollout.bkvy.enabled = false
		arollout.bkvz.enabled = false
		arollout.lblkeyval.enabled = false
		arollout.lblkeyattime.enabled = false
		arollout.lblkff.enabled = false
		arollout.kff.enabled = false
		arollout.bkff.enabled = false
	)
)

function orter bora afunc arollout = (
	if arollout.ctrllist.selection != undefined do(
		if arollout.ctrllist.selection != (-1) do(
			if arollout.ctrllist.selection > 1 then(
				if bora == 0 then(
					setbeforeort actrllist[1][(arollout.ctrllist.selection - 1)] afunc
				)else(
					setafterort actrllist[1][(arollout.ctrllist.selection - 1)] afunc
				)
			)else(
				if actrllist[1].count != 0 do(
					for i = 1 to actrllist[1].count do(
						if bora == 0 then(
							setbeforeort actrllist[1][i] afunc
						)else(
							setafterort actrllist[1][i] afunc
						)
					)
				)
			)
		)
	)
)

function tanger afunc arollout = (
	csel = arollout.ctrllist.selection
	if csel  != undefined do(
		if csel  != (-1) do(
			if csel  > 1 then(
				if (classof actrllist[1][csel]) == bezier_float do(
					if actrllist[1][csel].keys.count > 0 do(
						for k = 1 to actrllist[1][csel].keys.count do(
							actrllist[1][csel].keys[k].intangenttype = afunc
							actrllist[1][csel].keys[k].outtangenttype = afunc
						)
					)
				)
			)else(
				if actrllist[1].count != 0 do(
					for i = 1 to actrllist[1].count do(
						if classof actrllist[1][i] == bezier_float do(
							if actrllist[1][i].keys.count > 0 do(
								for k = 1 to actrllist[1][i].keys.count do(
									actrllist[1][i].keys[k].intangenttype = afunc
									actrllist[1][i].keys[k].outtangenttype = afunc
								)
							)
						)
					)
				)
			)
		)
	)
)

/*end troller functions */

rcmenu trollerkeyfn (
	menuitem kfn_rem "remove key"

	on kfn_rem picked do(
		format"removing key: % from controller: %\n"grtroller.keytimelist.selection actrllist[1][(grtroller.ctrllist.selection - 1)]
		deletekey actrllist[1][(grtroller.ctrllist.selection - 1)] grtroller.keytimelist.selection
		refreshctrlhelper grtroller 2
	)

)


rcmenu trollerfn (
	submenu "ORT before >" (
		menuitem ortb_con "constant"
		menuitem ortb_lin "linear"
		menuitem ortb_rep "repeat"
		menuitem ortb_rrep "relative repeat"
		menuitem ortb_mir "mirror"
	)

	submenu "ORT after  >" (
		menuitem orta_con "constant"
		menuitem orta_lin "linear"
		menuitem orta_rep "repeat"
		menuitem orta_rrep "relative repeat"
		menuitem orta_mir "mirror"
	)
	separator spctsep1
	submenu "all bezier tangents >" (
		menuitem bezi_smo "smooth"
		menuitem bezi_lin "linear"
		menuitem bezi_ste "step"
		menuitem bezi_fas "fast"
		menuitem bezi_slo "slow"
		menuitem bezi_cus "custom"
		menuitem bezi_aut "auto"
	)
	separator spctsep2
	menuitem ctr_remk "delete any keys at frame zero"

	on ortb_con picked do(orter 0 #constant grtroller)
	on ortb_lin picked do(orter 0 #linear grtroller)
	on ortb_rep picked do(orter 0 #loop grtroller)
	on ortb_rrep picked do(orter 0 #relativerepeat grtroller)
	on ortb_mir picked do(orter 0 #pingpong grtroller)
	on orta_con picked do(orter 1 #constant grtroller)
	on orta_lin picked do(orter 1 #linear grtroller)
	on orta_rep picked do(orter 1 #loop grtroller)
	on orta_rrep picked do(orter 1 #relativerepeat grtroller)
	on orta_mir picked do(orter 1 #pingpong grtroller)
	on bezi_smo picked do(tanger #smooth grtroller)
	on bezi_lin picked do(tanger #linear grtroller)
	on bezi_ste picked do(tanger #step grtroller)
	on bezi_fas picked do(tanger #fast grtroller)
	on bezi_slo picked do(tanger #slow grtroller)
	on bezi_cus picked do(tanger #custom grtroller)
	on bezi_aut picked do(tanger #auto grtroller)

	on ctr_remk picked do(
		for i in actrllist[1] do(
			akey = i.keys
			for k = 1 to akey.count do(
				if akey[k].time == 0f do(
					format"deleting key % at time %\n"k akey[k].time
					deletekey i k; exit
				)
			)
			refreshctrlhelper grtroller 3
		)
	)
)

/*begin troller UI */

rollout rtroller "troller" width:420 height:264
(
	GroupBox grpkey "keys" pos:[212,64] width:200 height:192
	GroupBox grpctrl "controller" pos:[8,64] width:200 height:192
	checkbutton capsel "scene selection" pos:[8,8] width:80 height:16 checked:true
	checkbutton capcsl "pile selection" pos:[92,8] width:80 height:16
	button refreshtroller "refresh" pos:[176,8] width:40 height:16

	dropdownList ctrllist "" pos:[8,32] width:404 height:21

	label lbloffsetkeystostart "Offset keys to start:" pos:[16,88] width:92 height:12
	spinner spnoffsettostart "" pos:[120,88] width:48 height:16 range:[-5000000,5000000,0] type:#integer
	button btnoffsettostart "ok" pos:[176,88] width:24 height:16

	label lbloffsetkeystoend "Offset keys to end:" pos:[16,112] width:92 height:16
	spinner spnoffsettoend "" pos:[120,112] width:48 height:16 range:[-5000000,5000000,0] type:#integer
	button btnoffsettoend "ok" pos:[176,112] width:24 height:16

	label lblkeyoffs "Offset keys by frame:" pos:[16,136] width:100 height:12
	spinner spnkeyoffs "" pos:[120,136] width:48 height:16 range:[-500000,500000,0] type:#integer
	button btndokeyoffs "ok" pos:[176,136] width:24 height:16

	spinner kvxoffs "" pos:[120,160] width:48 height:16 range:[-500000,500000,0]
	button btndokeyvaloffs "ok" pos:[176,160] width:24 height:16
	label lblkeyvaloffs "Offset key values:" pos:[16,160] width:96 height:12

	button popctrlfn "controller fn>" pos:[120,232] width:80 height:16

	label lblkeyattime "key @ time:" pos:[220,88] width:56 height:12
	dropdownList keytimelist "" pos:[284,88] width:64 height:21
	label lblkeynum "####" pos:[356,88] width:48 height:16

	label lblkff "Key time:" pos:[220,116] width:56 height:16
	spinner kff "" pos:[284,116] width:88 height:16 range:[-500000,500000,0] type:#integer
	button bkff "ok" pos:[380,116] width:24 height:16

	label lblkeyval "Key value:" pos:[220,136] width:56 height:16

	spinner kvx "" pos:[284,136] width:88 height:16 range:[-500000,500000,0]
	button bkvx "ok" pos:[380,136] width:24 height:16

	spinner kvy "" pos:[284,156] width:88 height:16 range:[-500000,500000,0]
	button bkvy "ok" pos:[380,156] width:24 height:16

	spinner kvz "" pos:[284,176] width:88 height:16 range:[-500000,500000,0]
	button bkvz "ok" pos:[380,176] width:24 height:16

	button popkeyfunc "key fn>" pos:[284,196] width:120 height:16
	spinner scaley "" pos:[120,184] width:48 height:16 range:[1,1000,100] type:#integer scale:1
	button doscaley "ok" pos:[176,184] width:24 height:16
	
	label lbl9 "Scale keys by %:" pos:[16,184] width:96 height:12

	spinner scaleaf "" pos:[120,208] width:80 height:16 range:[-500000,500000,0]
	label lbl10 "Anchor frame:" pos:[40,208] width:72 height:12


/*end troller UI */


/*begin troller events */
	on rtroller open do(
		grtroller = rtroller
		registerRightClickMenu trollerfn
		registerRightClickMenu trollerkeyfn
		refreshctrlhelper rtroller 3
		-- nval = true; if ctrllist.items.count == 0 do(nval = false)
	)

	on rtroller resized ns do(
		if (maxVersion())[1] >= 9000 do(
			-- grpkey.width = rtroller.width - 16
			-- grpctrl.width = rtroller.width - 16
			ctrllist.width = rtroller.width - 30
		)
	)

	on refreshtroller pressed do(
		refreshctrlhelper rtroller 3
	)

	on capsel changed val do(
		if val == true then(
			if selection.count != 0 then(
				capcsl.state = false
				refreshctrlhelper rtroller 3
			)else(messagebox"nothing selected"; capsel.state = false)
		)else(
		)
	)
	on capcsl changed val do(
		if val == true do(
			docsl = getcsl()
			if docsl == 1 then(
				capsel.state = false
				refreshctrlhelper rtroller 3
			)else(messagebox"pile selection not found"; capcsl.state = false)
		)
	)
	on chqdoctrl changed val do(
		if val == true do(refreshctrlhelper rtroller 3; if ctrllist.items.count == 0 do(nval = false))
		-- for i = 3 to ctrlhelperarray.count do(execute("arollout." + ctrlhelperarray[i] + ".enabled = " + (nval as string)))
	)
	on ctrllist selected anitem do(
		refreshctrlhelper rtroller 2
	)
	on keytimelist selected anitem do(
		refreshctrlhelper rtroller 1
		format"keytimelist changed to %\n"keytimelist.items[anitem]
	)

	on btndokeyoffs pressed do(
		-- format"thekeys: %\n"actrllist[1][ctrllist.selection].keys
		if ctrllist.selection != 1 then(
			offsetkeytimes actrllist[1][(ctrllist.selection - 1)].keys spnkeyoffs.value
			refreshctrlhelper rtroller 2
		)else(
			for c = 1 to actrllist[1].count do(
				offsetkeytimes actrllist[1][c].keys spnkeyoffs.value
			)
			refreshctrlhelper rtroller 3
		)
	)
	on btndokeyvaloffs pressed do(
		if ctrllist.selection != 1 then(
			offsetkeyvals actrllist[1][(ctrllist.selection - 1)].keys kvxoffs.value
			refreshctrlhelper rtroller 2
		)else(
			for c = 1 to actrllist[1].count do(
				offsetkeyvals actrllist[1][c].keys kvxoffs.value
			)
			refreshctrlhelper rtroller 3
		)
	)

	on bkff pressed do(
		akeynum = keytimelist.selection
		actrllist[1][(ctrllist.selection - 1)].keys[akeynum].time = kff.value
		refreshctrlhelper rtroller 2
	)

	on bkvx pressed do(
		akeynum = keytimelist.selection
		akv = (classof actrllist[1][(ctrllist.selection - 1)].keys[akeynum].value)
		if akv == point3 then(
			actrllist[1][(ctrllist.selection - 1)].keys[akeynum].value.x = kvx.value
		)else(
			actrllist[1][(ctrllist.selection - 1)].keys[akeynum].value = kvx.value
		)
		refreshctrlhelper rtroller 2
	)

	on bkvy pressed do(
		akeynum = keytimelist.selection
		akv = (classof actrllist[1][(ctrllist.selection - 1)].keys[akeynum].value)
		if akv == point3 do(
			actrllist[1][(ctrllist.selection - 1)].keys[akeynum].value.y = kvy.value
			refreshctrlhelper rtroller 2
		)
	)

	on bkvz pressed do(
		akeynum = keytimelist.selection
		akv = (classof actrllist[1][(ctrllist.selection - 1)].keys[akeynum].value)
		if akv == point3 do(
			actrllist[1][(ctrllist.selection - 1)].keys[akeynum].value.z = kvz.value
			refreshctrlhelper rtroller 2
		)
	)

	on btnoffsettostart pressed do(
		if ctrllist.selection != 1 then(
			firstkeyval = (spnoffsettostart.value - actrllist[1][(ctrllist.selection - 1)].keys[1].time)
			offsetkeytimes actrllist[1][(ctrllist.selection - 1)].keys firstkeyval
			refreshctrlhelper rtroller 2
		)else(
			for c = 1 to actrllist[1].count do(
				firstkeyval = (spnoffsettostart.value - actrllist[1][c].keys[1].time)
				offsetkeytimes actrllist[1][c].keys firstkeyval
			)
			refreshctrlhelper rtroller 3
		)
	)

	on btnoffsettoend pressed do(
		if ctrllist.selection != 1 then(
			kct = actrllist[1][(ctrllist.selection - 1)].keys.count
			lastkeyval = (spnoffsettoend.value - actrllist[1][ctrllist.selection].keys[kct].time)
			offsetkeytimes actrllist[1][ctrllist.selection].keys lastkeyval
			refreshctrlhelper rtroller 2
		)else(
			for c = 1 to actrllist[1].count do(
				kct = actrllist[1][c].keys.count
				lastkeyval = (spnoffsettoend.value - actrllist[1][c].keys[kct].time)
				offsetkeytimes actrllist[1][c].keys lastkeyval
			)
			refreshctrlhelper rtroller 3
		)
	)
	on doscaley pressed do(
		undo on(
			if ctrllist.selection != 1 then(
				scalemykeys actrllist[1][ctrllist.selection] scaley.value scaleaf.value
				refreshctrlhelper rtroller 2
			)else(
				for c = 1 to actrllist[1].count do(
					scalemykeys actrllist[1][c] scaley.value scaleaf.value
				)
				refreshctrlhelper rtroller 3
			)
		)	
	)
	on popctrlfn pressed do(popupmenu trollerfn)

	on popkeyfunc pressed do(popupmenu trollerkeyfn)

/*end troller events */
)
if (maxVersion())[1] < 9000 then(
	createdialog rtroller 420 264 100 100 style:#(#style_sysmenu, #style_titlebar, #style_border, #style_minimizebox, #style_noresize)
)else(
	createdialog rtroller 420 264 100 100 style:#(#style_sysmenu, #style_titlebar, #style_border, #style_minimizebox, #style_resizing) lockHeight:true
)

)
