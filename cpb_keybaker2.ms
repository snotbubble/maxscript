/*
keyframe the transforms of one 
object using another object.
by c.p.brown. 2008~2009.
*/


global keybakersrc = undefined
global keybakertarg = undefined
rollout rkeybaker "keybaker" width:320 height:104
(
	pickButton sbt "pick obj to bake" pos:[16,16] width:208 height:24
	pickButton tbt "pick target" pos:[16,48] width:208 height:24
	button bbb "bake" pos:[232,16] width:72 height:56 enabled:false
	progressBar pgb "ProgressBar" pos:[16,80] width:288 height:8

	on sbt picked obj do(
		keybakersrc = obj
		sbt.text = obj.name
		if keybakertarg != undefined do(bbb.enabled  = true)
	)
	
	on tbt picked obj do(
		keybakertarg = obj
		tbt.text = obj.name
		if keybakersrc != undefined do(bbb.enabled  = true)
	)
	
	on bbb pressed do(
		if keybakersrc != undefined and keybakertarg != undefined then(
			with animate on(
				for t = animationrange.start to animationrange.end do(
					if classof keybakertarg == Editable_mesh then(
						at time t (
							slidertime = t
							-- atarg = (snapshot keybakertarg)
							atarg = (keybakertarg)
							keybakersrc.transform = atarg.transform
							-- delete atarg
							pgb.value = (100.*t/animationrange.end) 
						)
					)else(
						at time t (
							keybakersrc.transform = keybakertarg.transform
							if superclassof keybakersrc == camera do(keybakersrc.fov = keybakertarg.fov)
							pgb.value = (100.*t/animationrange.end) 
						)
					)
					if keyboard.escPressed == true do(exit)
				)
			)
			pgb.value = 0.0
		)else(messagebox"source or target is missing")
	)
)	
createdialog rkeybaker 320 110 100 100 style:#(#style_sysmenu, #style_titlebar, #style_border, #style_minimizebox, #style_maximizebox)	
