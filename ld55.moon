-- title:   game title
-- author:  game developer, email, etc.
-- desc:    short description
-- site:    website link
-- license: MIT License (change this to your license of choice)
-- version: 0.1
-- script:  moon

export WINDOW_W = 240
export WINDOW_H = 136
export MAP_SCR_W = 30
export MAP_SCR_H = 17
export PLAYER_W = 8
export PLAYER_H = 14
export t = 0
export entity_list = {}
export player = {}
export camera = { pos: {x: 0, y: 0} }
export view_room_list = {}
export prev_view_room = {}

export camera_tweening = false
export camera_tween_destination = {}
export camera_tween_origin = {}
export camera_tweening_start_at = 0
export CAMERA_TWEENING_TIME = 60

export BOOT = ->
	game_init!

export game_init = ->
	init_view_room_list!
	player = player_new(vecnew(10, 10))
	camera.pos = vecnew(player.pos.x - WINDOW_W/2, player.pos.y - WINDOW_H/2)

export TIC = ->
	cls(0)
	game_update!
	t += 1

export game_update = ->
	entity_list_update!
	camera_update!

	draw_pos = get_draw_pos(vecnew(0, 0))
	map(camera.pos.x//8-1, camera.pos.y//8-1, 32, 19, 8-camera.pos.x%8-16, 8-camera.pos.y%8-16)
	entity_list_draw!

export init_view_room_list = ->
	for y = 0, 7
		for x = 0, 7
			room = {
				pos: vecnew(x * 30 * 8, y * 17 * 8),
				sz: vecnew(30 * 8, 17 * 8),
				rm: false,
			}
			table.insert(view_room_list, room)
	
	resize = (pos, sz) ->
		i = pos.y * 8 + pos.x + 1
		v = view_room_list[i]
		v.sz.x = sz.x * 30 * 8
		v.sz.y = sz.y * 17 * 8
		for x = pos.x, pos.x + sz.x - 1
			for y = pos.y, pos.y + sz.y - 1
				if x == pos.x and y == pos.y
					continue
				j = y * 8 + x + 1
				view_room_list[j].rm = true

	resize(vecnew(1, 0), vecnew(2, 1))

	for i = #view_room_list, 1, -1
		v = view_room_list[i]
		if v.rm
			table.remove(view_room_list, i)

export get_view_room = ->
	for i, v in ipairs(view_room_list)
		if (in_rect(vecadd(player.pos, vecnew(PLAYER_W/2, PLAYER_H)), v.pos, v.sz))
			return v
	return nil

export get_draw_pos = (vec) ->
	return vecsub(vecfloor(vec), vecfloor(camera.pos))

export snap_camera_pos_to_view_room = (camera_pos, view_room) ->
	if camera_pos.x < view_room.pos.x
		camera_pos.x = view_room.pos.x
	if camera_pos.y < view_room.pos.y
		camera_pos.y = view_room.pos.y
	if camera_pos.x + WINDOW_W >= view_room.pos.x + view_room.sz.x
		camera_pos.x = view_room.pos.x + view_room.sz.x - WINDOW_W
	if camera_pos.y + WINDOW_H >= view_room.pos.y + view_room.sz.y
		camera_pos.y = view_room.pos.y + view_room.sz.y - WINDOW_H

export camera_update = ->
	camera_spd = 0.06

	v = vecnew(WINDOW_W/2-PLAYER_W/2, WINDOW_H/2-PLAYER_H/2)
	nx_camera_pos = vecsub(player.pos, v)
	view_room = get_view_room!
	snap_camera_pos_to_view_room(nx_camera_pos, view_room)

	if not camera_tweening and view_room != prev_view_room
		camera_tweening = true
		camera_tweening_start_at = t
		camera_tween_destination = veccopy(nx_camera_pos)
		camera_tween_origin = veccopy(camera.pos)
	
	if camera_tweening and t - camera_tweening_start_at > CAMERA_TWEENING_TIME
		camera_tweening = false

	if camera_tweening
		n = (t - camera_tweening_start_at) / CAMERA_TWEENING_TIME
		tween_diff = vecsub(camera_tween_destination, camera_tween_origin)
		tween_dir = vecnormalized(tween_diff)
		tween_length = veclength(tween_diff)
		camera.pos = vecadd(camera_tween_origin, vecmul(tween_dir, ease(n) * tween_length))
		if n >= 1
			camera.pos = veccopy(camera_tween_destination)

	if not camera_tweening
		sub = vecsub(nx_camera_pos, camera.pos)
		if veclength(sub) <= 0.1
			camera.pos = nx_camera_pos
			return
		dir = vecnormalized(sub)
		add_len = veclength(sub) * camera_spd
		add = vecmul(dir, add_len)
		camera.pos = vecadd(camera.pos, add)

	prev_view_room = view_room

export player_new = (pos) ->
	p = entity_new(pos, vecnew(PLAYER_W, PLAYER_H), player_update, player_draw, nil)
	p.right_dir = true
	p.on_floor = false
	return p

export player_update = (player) ->
	if btn(2)
		player.right_dir = false
		player.fvec.x -= 1
	if btn(3)
		player.right_dir = true
		player.fvec.x += 1
	if btnp(4) and player.down_col
		player.gravity = -2
	
export player_draw = (player) ->
	draw_pos = get_draw_pos(player.pos)

	spr_id = 256

	if not player.on_floor
		-- Jumping/falling
		if player.gravity < 0
			spr_id = 266
		else
			spr_id = 268
	else
		if btn(2) or btn(3)
			-- walking
			spr_id = 260 + (t // 10 % 3) * 2
		else
			-- idle
			spr_id = 256 + (t // 30 % 2) * 2

	flip = 1
	if player.right_dir
		flip = 0

	spr(spr_id, draw_pos.x - 4, draw_pos.y - 2, 0, 1, flip, 0, 2, 2)

export entity_collision = (e) ->
	for x = 0, e.sz.x//8
		add = vecnew(x*8, e.sz.y)
		if x == e.sz.x//8
			add.x -= 1
		pos = vecadd(e.pos, add)
		if map_col(pos.x//8, pos.y//8)
			if pos.y == floor2(pos.y, 8)
				e.down_col = true
				break

	for x = 0, e.sz.x//8
		add = vecnew(x*8, -1)
		if x == e.sz.x//8
			add.x -= 1
		pos = vecadd(e.pos, add)
		if map_col(pos.x//8, pos.y//8)
			if pos.y == floor2(pos.y, 8) + 7
				e.up_col = true
				break

	for y = 0, e.sz.y//8
		add = vecnew(-1, y*8)
		if y == e.sz.y//8
			add.y -= 1
		pos = vecadd(e.pos, add)
		if map_col(pos.x//8, pos.y//8)
			e.left_col = true
			break

	for y = 0, e.sz.y//8
		add = vecnew(e.sz.x, y*8)
		if y == e.sz.y//8
			add.y -= 1
		pos = vecadd(e.pos, add)
		if map_col(pos.x//8, pos.y//8)
			e.right_col = true
			break

export entity_physic = (e) ->
	e.gravity += 0.1
	e.on_floor = false
	if e.down_col and e.gravity > 0
		e.gravity = 0
		e.on_floor = true
	if e.up_col and e.gravity < 0
		e.gravity = 0
	e.fvec.y += e.gravity
	entity_move_x(e)
	entity_move_y(e)

export entity_move_x = (e) ->
	if e.fvec.x == 0
		return
	next_pos = veccopy(e.pos)
	next_pos.x += e.fvec.x
	physic_pt_list = get_physic_pt_list(next_pos, e.sz)
	for i, v in ipairs(physic_pt_list)
		if map_solid(v.x//8, v.y//8)
			if e.pos.x + e.sz.x <= floor2(v.x, 8)
				e.pos.x = floor2(v.x, 8) - e.sz.x
			elseif e.pos.x >= floor2(v.x, 8) + 8
				e.pos.x = floor2(v.x, 8) + 8
			return
		if map_left_col(v.x//8, v.y//8)
			if e.pos.x + e.sz.x <= floor2(v.x, 8)
				e.pos.x = floor2(v.x, 8) - e.sz.x
				return
		if map_right_col(v.x//8, v.y//8)
			if e.pos.x >= floor2(v.x, 8) + 8
				e.pos.x = floor2(v.x, 8) + 8
				return
	e.pos.x = next_pos.x
	
export entity_move_y = (e) ->
	if e.fvec.y == 0
		return
	next_pos = veccopy(e.pos)
	next_pos.y += e.fvec.y
	physic_pt_list = get_physic_pt_list(next_pos, e.sz)
	for i, v in ipairs(physic_pt_list)
		if map_solid(v.x//8, v.y//8)
			if e.pos.y + e.sz.y - 1 <= floor2(v.y, 8)
				e.pos.y = floor2(v.y, 8) - e.sz.y
			elseif e.pos.y + 1 >= floor2(v.y, 8) + 8
				e.pos.y = floor2(v.y, 8) + 8
			return
		if map_up_col(v.x//8, v.y//8)
			if e.pos.y + e.sz.y - 1 <= floor2(v.y, 8)
				e.pos.y = floor2(v.y, 8) - e.sz.y
				return
		if map_down_col(v.x//8, v.y//8)
			if e.pos.y + 1 >= floor2(v.y, 8) + 8
				e.pos.y = floor2(v.y, 8) + 8
				return
	e.pos.y = next_pos.y

export get_physic_pt_list = (pos, sz) ->
	list = {}
	for x = 0, math.ceil(sz.x / 8)
		for y = 0, math.ceil(sz.y / 8)
			add = vecnew(x * 8, y * 8)
			if x == math.ceil(sz.x / 8)
				add.x = sz.x - 1
			if y == math.ceil(sz.y / 8)
				add.y = sz.y - 1
			table.insert(list, vecadd(pos, add))
	return list

export entity_new = (pos, sz, update, draw, ckrm) ->
	entity = {
		pos: veccopy(pos),
		sz: veccopy(sz),

		update: update,
		draw: draw,
		ckrm: ckrm,

		rm_next_frame: false,

		default_physic: true,
		gravity_enabled: true,
		gravity: 0,
		on_floor: false,
		fvec: vecnew(0, 0),

		up_col: false,
		down_col: false,
		left_col: false,
		right_col: false,
	}
	table.insert(entity_list, entity)
	return entity

export entity_list_update = () ->
	for i, v in ipairs(entity_list)
		v.up_col = false
		v.down_col = false
		v.left_col = false
		v.right_col = false
		v.fvec = vecnew(0, 0)

		entity_collision(v)
		v.update(v)

		if v.default_physic
			entity_physic(v)

export entity_list_draw = () ->
	for i, v in ipairs(entity_list)
		v.draw(v)

export entity_list_ckrm = () ->
	for i = #entity_list, 1, -1
		v = entity_list[i]

		if v.ckrm == nil
			if v.rm_next_frame
				table.remove(entity_list, i)
			continue

		v.ckrm(i, v)

export map_col = (x, y) ->
	if map_solid(x, y)
		return true
	if map_up_col(x, y)
		return true
	if map_down_col(x, y)
		return true
	if map_left_col(x, y)
		return true
	if map_right_col(x, y)
		return true
	return false

export map_solid = (x, y) ->
	m = mget(x, y)
	return m == 1

export map_up_col = (x, y) ->
	m = mget(x, y)
	return m == 2

export map_down_col = (x, y) ->
	m = mget(x, y)
	return m == 3

export map_left_col = (x, y) ->
	m = mget(x, y)
	return m == 4

export map_right_col = (x, y) ->
	m = mget(x, y)
	return m == 5

export in_rect = (pos, rect_pos, rect_sz) ->
	if pos.x < rect_pos.x
		return false
	if pos.y < rect_pos.y
		return false
	if pos.x >= rect_pos.x + rect_sz.x
		return false
	if pos.y >= rect_pos.y + rect_sz.y
		return false
	return true

export floor2 = (a, b) ->
	return a // b * b

export vecnew = (x, y) ->
	return { x: x, y: y }

export veccopy = (vec) ->
	return { x: vec.x, y: vec.y }

export vecadd = (veca, vecb) ->
	return { x: veca.x + vecb.x, y: veca.y + vecb.y }

export vecsub = (veca, vecb) ->
	return { x: veca.x - vecb.x, y: veca.y - vecb.y }

export vecmul = (vec, n) ->
	return { x: vec.x * n, y: vec.y * n }

export vecdiv = (vec, n) ->
	return { x: vec.x / n, y: vec.y / n }

export vecdivdiv = (vec, n) ->
	return { x: vec.x // n, y: vec.y // n }

export veclength = (vec) ->
	return math.sqrt(vec.x*vec.x + vec.y*vec.y)

export vecnormalized = (vec) ->
	len = veclength(vec)
	return { x: vec.x/len, y: vec.y/len }

export vecequals = (veca, vecb) ->
	return veca.x == vecb.x and veca.y == vecb.y

export vecfloor = (vec) ->
	return { x: math.floor(vec.x), y: math.floor(vec.y) }

export vecround = (vec) ->
	return { x: round(vec.x), y: round(vec.y) }

export round = (n) ->
	return math.floor(n + 0.5)

export rndf = (a, b) ->
	return math.random() * (b - a) + a

export rndi = (a, b) ->
	return math.random(a, b)

export dice = (a, b) ->
	rnd = rndi(1, b)
	return rnd >= 1 and rnd <= a

-- From https://easings.net/#easeInOutSine
export ease = (n) ->
	return -(math.cos(math.pi * n) - 1) / 2

-- <TILES>
-- 001:ccccccccc000000cc000000cc000000cc000000cc000000cc000000ccccccccc
-- 002:ccccccccc000000c000000000000000000000000000000000000000000000000
-- 003:000000000000000000000000000000000000000000000000c000000ccccccccc
-- 004:cc000000c0000000c0000000c0000000c0000000c0000000c0000000cc000000
-- 005:000000cc0000000c0000000c0000000c0000000c0000000c0000000c000000cc
-- </TILES>

-- <SPRITES>
-- 000:000000000000000000000011000001110000011c000001cf000001cc0000120c
-- 001:0000000000000000110000001110000011100000c1f00000cc100000c0210000
-- 002:00000000000000000000000000000011000001110000011c000001cf000001cc
-- 003:000000000000000000000000110000001110000011100000c1f00000cc100000
-- 004:000000000000000000000011000001110000011c000001cf000001cc0001120c
-- 005:00000000000000001100000011100000c1110000ccf00000cc100000c0211000
-- 006:0000000000000011000001110000011c000001cf000001cc0000120c00001021
-- 007:00000000110000001110000011100000c1f00000cc100000c021000012010000
-- 008:0000000000000011000001110000011c000001cf000001cc0000120c00001021
-- 009:00000000110000001110000011100000c1f00000cc100000c021000012010000
-- 010:0000000000000011000001110000011c000001cf000001cc0000120c00001021
-- 011:00000000110000001110000011100000c1f00000cc100000c021000012010000
-- 012:000000000000000000000011000001110000011c000001cf000001cc0001120c
-- 013:00000000000000001100000011100000c1110000ccf00000cc100000c0211000
-- 016:000100110000021100000111000011110000c2ff000000c0000000c0000000f0
-- 017:11001000112000001110000011110000ff2c00000c0000000c0000000f000000
-- 018:0001200c0000001100000211000011110000c211000000ff000000c0000000f0
-- 019:c0021000110000001120000011110000112c0000ff0000000c0000000f000000
-- 020:0000002100000211000002110000002c000000ff0000000c0000000c0000000f
-- 021:12000000110000001100000011000000ff000000d0000000d0000000f0000000
-- 022:00000021000000120000001100000011000000ff0000fcc00000000000000000
-- 023:110000002c000000110000001ff00000ffc0000000c0000000f0000000000000
-- 024:000002110000021100000c1100000011000000ff00000fdd0000000000000000
-- 025:112000001c20000011000000ff000000cd0000000c0000000f00000000000000
-- 026:00000211000021110000211100000c11000000ff000000c000000c000000f000
-- 027:1120000011120000111200001fc00000ff0000000c0000000f00000000000000
-- 028:00000021000022110000c11100000011000000ff0000fdd00000000000000000
-- 029:1200000011220000111c000011000000ff0000000c0000000c0000000f000000
-- 032:00000000000000000000001100000111000001c1000001fc000001cc0000120c
-- 033:000000000000000011000000111000001c1000001f100000cc100000c0210000
-- 048:000100210000021100001111000cc011000000ff000000c0000000c0000000f0
-- 049:120010001120000011110000110cc000ff0000000c0000000c0000000f000000
-- </SPRITES>

-- <MAP>
-- 004:000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:000000000000000000000000000000000000100000000000000000000000000000000000000000000040000000000000005000000000000000000010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:000000000000000000000000000000000000100000000000000000000000000000000000000000000040000000000000005000000000000000001010001010101010101000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:000000000000000000000000000000000000000000000000202020200000000000000000000000101010101010101010101010101010101010101010000000000000000010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:000000000000000000000000000000000000000000000000000000000000101010101010101010000000000000000000000000000000000010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:222234568aabdeffffedcba865432100
-- 002:0123456789abcdef0123456789abcdef
-- 003:555555568aabdeffffedcba865432100
-- 005:0000000000012345cdefffffffffffff
-- 006:00000000000000000cb7777789abcdef
-- 007:000145689abbcdeeefdccba995555555
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000300000000000
-- 032:010021003100510051005100510051005100510051005100510051005100510051005100510051005100510051005100510051005100510051005100202000000000
-- 033:0305130323024301430073009300b300c300d300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300a00000000000
-- 034:6400b400d400e400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400700000000000
-- 035:04054404540374038403a402b402c401d401e400e400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400b00000000000
-- 036:0500150025003500450045004501450255015500650f75007500850095009500a500a500a500a500b500b500b500b500b500b500b500b500c500c500400000000056
-- 037:360056007600860096009600a600a600a600c600c600c600c600c600c600c600c600c600c600c600c600c600c600c600c600c600c600c600c600c600400000210000
-- 038:47c077009700b700b700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700e80000320000
-- </SFX>

-- <PATTERNS>
-- 000:40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e400814000000000000000000400814000000000000000000
-- 001:400806400806100800400806100800400806100800400806400804100800400804100800400804000800100800000000800858800858100850800858100850800858100000800858600858100000600858100000400858000000100000000000400806400806100800400806100800400806100800400806400804100800400804100800400804000800100800000000800858800858100850800858100850600858100000600858400858100000000000000000000000000000000000000000
-- 002:4008084008081008004008081008004008081008004008084008061008004008061008004008060008001008000000004f8958400858100000400858100000400858100000400858e00856100000e00856100000d008560000001000000000004ff9084008081008004008081008004008081008004008084008061008004008061008004008060008001008000000004f8958400858100000400858100000e00856100000e00856d00856100000800848000000900848100840900848b00848
-- 003:400804000000400806b00804100800000000400806100800400806600806400806100800400804000000e00802000000100800000800e00804d00804000000100800900804100800900804b00804900804100800e00802000000d00802000000100800000000d00804800804000000000000d00804100800d00802000000d00804100800d00802100800900806000000000000100800900806100800b00806000000100800000000900806100800b00806100800b00802000000400804000000
-- 004:b00848000000000000000000000000000000800848000000b0084800000000000000000040084a000000e00848000000000000000000d00848000000000000000000900848000000000000000000800848000000900848100840900848b008480000000000000000000000000000000000000000000000000000000000000000000000000000000000008f8958000000000000100000800858100000600858000000100850000000400858100000600858000000100000000000bff948000000
-- 005:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000048f958000000000000100000400858100000f00856000000100000000000d00856100000f00856000000100000000000000000000000
-- 006:40081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000000082040082e40081400000040082e00082040083c000000d00856000000000000100000d0085640082e40083c00000040082e40082e40081400000000082040082e40083c00000040082e40082e
-- 007:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b8f956b00856100000b00856100000b00856100000b00856900856100000900856100000800856000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00856b00856100000b00856100000900856100000900856800856100000000000000000000000000000000000000000
-- 008:400804000000400806b00804100800000000400806100800400806600806400806100800400804000000e00802000000100800000800e00804d00804000000100800900804100800900804b00804900804100800e00802000000d00802000000100800000000d00804800804000000000000d00804100800d00802000000d00804100800d00802100800c00806000000000000100800c00806100800b00806000000100800000000900806100800b00806100800b00802000000400804000000
-- 009:b00848000000000000000000000000000000800848000000b0084800000000000000000040084a10000040084a60084a000000000000e00848000000000000000000900848000000000000000000800848100000b008480000004008480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007f8958000000000000100000700858100000600858000000100000000000700858100000900858000000100000000000bff948000000
-- 010:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000048f958000000000000100000400858100000e00856000000100000000000400858100000600858000000100000000000000000000000
-- 011:40081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c000000b00858000000000000100000b0085840082e90085800000000082040082e40081400000040082e00082040083c00000040082e40082e
-- 012:4f496af0086ab0086a80086a4f896af0086ab0086a80086a4fb96af0086ab0086a80086a4ff96af0086ab0086a80086aebf96ad0086a90086a60086ae8f96ad0086a90086a60086ae4f96ad0086a90086a60086ae8f96ad0086a90086a60086abbf96a80086a40086ad00868bfb96a80086a40086ad00868bf896a80086a40086ad00868bf496a80086a48f95800000090086a80086a400858d00868f0085600000040086ad00868d00856d00868f008560000004f896a80086ab0086ad0086a
-- 013:4f496af0086ab0086a80086a4f896af0086ab0086a80086a4fb96af0086ab0086a80086a4ff96af0086ab0086a80086aebf96ad0086a90086a60086ae8f96ad0086a90086a60086ae4f96ad0086a90086a60086ae8f96ad0086a90086a60086abbf96a80086a40086ad00868bff96a80086a40086ad00868bfb96a80086a40086ad00868bf896a80086a48f958000000000000100000400858100000e008560000001000000000004ff948000000600848000000700848000000900848000000
-- 014:400804000000400806b00804100800000000400806100800400806600806400806100800400804000000e00802000000100800000800e00804d00804000000100800900804100800900804b00804900804100800e00802000000d00802000000100800000000d00804800804000000000000d00804100800d00802000000d00804100800d00802100800900806000000000000100800900806100800b00806000000100800000000e00804000000000000000000e00804000000000000000000
-- 015:40081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c000000b00858000000000000100000b0085840082e90085800000040082e40082e400814000000000000000000400814000000000000000000
-- 016:b00848000000000000000000000000000000800848000000b0084800000000000000000040084a10000040084a60084a000000000000e00848000000000000000000900848000000000000000000800848100000b008480000004008480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007f895800000000000010000070085810000060085800000010000000000040086a00000060086a00000070086a00000090086a000000
-- 017:40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040083c40082e
-- 018:c00804000000000000000000100000000000c00804000000b00804000000c00804000000100000000000c00802000000100000000000c00802100000c00802100000000000000000000000000000e00802000000900804000000e00804000000c00804000000100000000000c00804100000700804000000c00804e00804c00804000000100000000000c00802000000100000000000c00802100000c00802100000000000000000000000000000e00802000000900804000000e00804000000
-- 019:b00848000000000000000000000000000000000000000000000000000000000000900848b00848000000900848000000000000000000000000000000000000000000000000000000400848000000600848000000700848000000900848000000b00848000000000000000000000000000000000000000000000000000000000000000000b00848100000900848000000000000000000e00848000000000000000000900848000000000000000000000000000000000000000000000000000000
-- 020:700848000000000000000000000000000000000000000000000000000000000000600848700848000000600848000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700848000000000000000000000000000000000000000000000000000000000000000000700848100000600848000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 021:a00804000000000000000000100000000000900806000000a00806000000a00804000000100000000000a00804000000100000000000a00804100000a00804100000000000000000000000000000900804000000000000000000700804000000600804000000100000000000600804000000100000000000600804100800600804000000100000000000b00804000000000000000000100800000000b00804100000b00804000000100000000000000000000000000000000000000000000000
-- 022:900848000000000000000000000000000000000000000000000000000000000000700848900848000000700848000000000000000000000000000000000000000000000000000000000000000000500848100000700848000000900848000000000000000000000000000000000000000000000000000000000000000000800848000000900848100000b00848000000000000000000000000000000000000000000000000000000000000000000800848000000900848100000900848b00848
-- 023:500848000000000000000000000000000000000000000000000000000000000000000000500848000000400848000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600848000000000000000000000000000000000000000000000000000000000000000000000000000000400848000000f00846000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000
-- 024:40081400000000000000000040083c00000000000000000040081400000000000000000040083c00000000000000000040081400000000000000000040083c00000000000000000040081400000000000000000040083c00000000000000000040081400000000000000000040083c00000000000000000040081400000000000000000040083c00000000000000000040081400000000000000000040083c00000000000000000040081400000000000000000040083c00000040082e40082e
-- 025:400806400806100800400806100800400806100800400806400804100800400804100800400804000800100800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000400806400806100800400806100800400806100800400806400804100800400804100800400804000800100800000000000000000000000000000000000000000000000000000000000000000000b00804000000e00804000000400806000000
-- 027:4008084008081008004008081008004008081008004008084008061008004008061008004008060008001008000000004f8958400858100000400858100000400858100000400858e00856100000e008561000004008580000001000000000004ff9084008081008004008081008004008081008004008084008061008004008061008004008060008001008000000004f8958400858100000400858100000e00856100000e00856d00856100000b00806000000e00806000000400808000000
-- 028:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b8f956b00856100000b00856100000b00856100000b00856900856100000900856100000b00856000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00856b00856100000b00856100000900856100000900856800856100000000000000000000000000000000000000000
-- 029:400804000000400806b00804100800000000400806100800400806600806400806100800400804000000e00802000000100800000800e00804d00804000000100800900804100800900804b00804900804100800e00802000000d00802000000100800000000d00804800804000000000000d00804100800d00802000000d00804100800d00802100800900806000000000000100800900806100800b00806000000100800000000b00804000000000000000000b00804000000000000000000
-- 030:b00848000000000000000000000000000000800848000000b0084800000000000000000040084a10000040084a60084a000000000000e00848000000000000000000900848000000000000000000800848100000b008480000004008480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007f8958000000000000100000700858100000600858000000100000000000400858000000600858000000e00856000000400858000000
-- 031:40081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c000000b00858000000000000100000b0085840082e90085800000000082040082e700848000000600848000000400814000000e00846400848
-- 032:4f496af0086ab0086a80086a4f896af0086ab0086a80086a4fb96af0086ab0086a80086a4ff96af0086ab0086a80086aebf96ad0086a90086a60086ae8f96ad0086a90086a60086ae4f96ad0086a90086a60086ae8f96ad0086a90086a60086abbf96a80086a40086ad00868bff96a80086a40086ad00868bfb96a80086a40086ad00868bf896a80086a48f958000000000000100000400858100000e00856000000100000000000cff856000000e00856000000b00856000000000000000000
-- </PATTERNS>

-- <TRACKS>
-- 000:996c57180302701581c42ac27015430d31932d44551857167015430a7f58996c57180302000000000000000000000000700000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2cff9696f06c6eef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

