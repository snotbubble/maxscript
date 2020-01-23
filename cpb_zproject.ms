/*
project one object down onto another,
source must be a mesh.
fixed direction is [0,0,-1].
by c.p.brown. 2008~2009.
*/


src = 0
targ = 0
ovp = #()

fn zproject s t gs gl pb = (
	pb.pos.x = 16
	undo "Zproject" on(

		rm = RayMeshGridIntersect()
		rm.Initialize gs
		rm.addNode t
		rm.buildGrid()
		
		for i = 1 to s.numverts do (
			v = s.verts[i]
			npos = (rm.intersectRay v.pos [0,0,-1] true)
			co = (npos > 0)
			
			if co then(
				d = rm.getHitDist (rm.getClosestHit())
				v.pos.z -= d
			)else(v.pos.z = gl)
			pb.value = (100.*i/s.numverts)
		)
		update s
		if keyboard.escPressed == true do(exit)
	)
	pb.pos.x = 500
	pb.value = 0.0
)

fn meshflt obj = (
	classof obj == editable_mesh
)

rollout rzp "Z-Projector" width:160 height:208
(
	pickbutton bsrc "source" pos:[16,16] width:128 height:32 tooltip:"plane to project, must be a mesh" filter:meshflt
	pickbutton btarg "target" pos:[16,56] width:128 height:32 tooltip:"object to project onto, must be below the source"
	label lbl1 "ground" pos:[16,96] width:48 height:16
	spinner glevel "" pos:[72,96] width:64 height:16 range:[-10000,10000,0] scale:1
	button redbutton "go" pos:[16,144] width:128 height:24
	button oops "reset" pos:[16,176] width:128 height:16
	spinner gs "" pos:[72,120] width:64 height:16 enabled:true range:[2,100,20] type:#integer scale:1
	label lbl3 "grid" pos:[16,120] width:40 height:16
	progressBar progbar "" pos:[500,144] width:128 height:24
	
	on bsrc picked obj do(
		bsrc.text = obj.name
		src = obj
	)

	on btarg picked obj do(
		btarg.text = obj.name
		targ = obj
	)
	
	on redbutton pressed do(
		for i = 1 to src.numverts do(append ovp src.verts[i].pos)
		zproject src targ gs.value glevel.value progbar
	)
	on oops pressed do(
		for i = 1 to src.numverts do(src.verts[i].pos = ovp[i])
		update src
	)
	
)
createdialog rzp
