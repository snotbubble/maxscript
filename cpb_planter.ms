--by c.p.brown. 2009.
rollout rplanter "planter V0001" width:184 height:64
(
	pickButton planttarg "ground" pos:[8,8] width:168 height:24
	button plantit "plant" pos:[8,32] width:168 height:24
	on planttarg picked obj do(
		planttarg.text = obj.name
	)
	on plantit pressed do(
		ground = planttarg.object
		rm = RayMeshGridIntersect()
		rm.Initialize 100
		rm.addNode ground
		rm.buildGrid()
		-- plant tree control points
		for i in selection do(
			aray = rm.intersectRay i.position [0,0,-1] false
			if aray > 0 do(
				cp = rm.getClosestHit()
				pd = (rm.getHitDist cp)
				i.pos.z -= (pd + 0.5)
			)
		)
	)	
)

createdialog rplanter
