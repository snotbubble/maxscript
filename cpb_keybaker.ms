/*
keyframe the transforms of an object.
by c.p.brown. 2009.
*/

(
keybakersrc = undefined
keybakertarg = undefined
	
rollout rbakeme "keybaker" width:224 height:72(
	button bbb "bake selected" pos:[16,16] width:192 height:24 enabled:true
	progressBar pgb "ProgressBar" pos:[16,48] width:192 height:8
	
	on bbb pressed do(
		if selection.count != 0 then(
			for i in selection do(
				keybakersrc =  (snapshot i);  keybakersrc.parent = undefined
				keybakertarg = i	
				if keybakersrc != undefined and keybakertarg != undefined then(
					with animate on(
						for t = animationrange.start to animationrange.end do(
							if classof keybakertarg == Editable_mesh then(
								at time t (
									slidertime = t
									atarg = (snapshot keybakertarg)
									keybakersrc.transform = atarg.transform
									delete atarg
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
					select keybakersrc
				)else(messagebox"source or target is missing")
			)
		)else(messagebox"slect some objects first...")
	)
)	
createdialog rbakeme style:#(#style_sysmenu, #style_titlebar, #style_border, #style_minimizebox, #style_maximizebox)	
)
