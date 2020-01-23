-- by c.p.brown. 2009.
(
src = 0
targ = 0

fn sameflt obj = (
	if classof obj == editable_mesh do(obj.numfaces == src.numfaces)
)
rollout ruvc "copy uvs" width:160 height:84
(
	pickButton srcb "source" pos:[8,8] width:144 height:24
	pickButton trgb "target" pos:[8,40] width:144 height:24 enabled:false filter:sameflt
	-- button cpyb "copy uvs" pos:[8,72] width:144 height:16
	
	on srcb picked obj do(
		srcb.text = obj.name
		trgb.enabled = true
		src = obj
	)
	on trgb picked obj do(
		trgb.text = obj.name
		targ = obj
		if src != 0 or targ != 0 do(
			stv = getNumTVerts src
			tva = #()
			buildTVFaces targ
			setNumTVerts targ stv
			for i = 1 to targ.numfaces do(
				tva = #()
				srcmid = (getFaceMatID src i)
				setFaceMatID targ i srcmid
				srctv = (gettvface src i)
				setTVFace targ i srctv
				for v = 1 to 3 do(
					atv = (gettvert src srctv[v])
					append tva atv
				)
				for p = 1 to 3 do(settvert targ srctv[p] tva[p])
			)
			update targ
		)
	)
)
createdialog ruvc
)
