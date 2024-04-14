-- title:   game title
-- author:  game developer, email, etc.
-- desc:    short description
-- site:    website link
-- license: MIT License (change this to your license of choice)
-- version: 0.1
-- script:  moon

export PI = 3.1416
export WINDOW_W = 240
export WINDOW_H = 136
export MAP_SCR_W = 30
export MAP_SCR_H = 17
export PLAYER_W = 8
export PLAYER_H = 14
SWIPE_W = 16
SWIPE_H = 16
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

export CRYSTAL_BOUNCE = 1
export CRYSTAL_SUMMON_VEL = 1

export SFX_JUMP = 0
export SFX_SWIPE = 1
export SFX_SWIPE_HIT = 2
export SFX_THROW = 3
export SFX_AIMING = 4
export SFX_CRYSTAL_BOUNCE = 5
export SFX_SUMMON = 6
export SFX_UNSUMMON = 7

export MAP_ENEMY_SLIME = 6
export MAP_ENEMY_FLYING_CRITTER = 7
export SLIME_W = 12
export SLIME_H = 12

export LAYER_NONE = 0
export LAYER_SWIPES = 1
export LAYER_ENEMIES = 2

export IMP_RANGE = 32

export DEBUG_DRAW_HITBOXES = true

export BOOT = ->
	game_init!

export game_init = ->
	init_view_room_list!
	player = player_new(vecnew(10, 60))
	camera.pos = vecnew(0, player.pos.y - WINDOW_H/2)
	-- Spawn enemies
	for x = 0, WINDOW_W
		for y = 0, WINDOW_H
			m = mget(x, y)
			spawn_pos = vecnew(x*8, (y-1)*8)
			if m == MAP_ENEMY_SLIME
				mset(x, y, 0)
				enemy_new(spawn_pos)
			elseif m == MAP_ENEMY_FLYING_CRITTER
				mset(x, y, 0)
				enemy_flying_critter_new(spawn_pos)

export TIC = ->
	cls(0)
	game_update!
	t += 1

export game_update = ->
	entity_list_update!
	entity_list_overlaps!
	entity_list_ckrm!
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
	p.attack = 0
	p.attack_t = t
	p.attack_row = 0
	p.aim_rad = 0
	p.prev_btn_6_holding = false
	return p

export player_movement = (player) ->
	-- Can't move/jump if attacking on ground
	if not player.down_col or player.attack == 0
		if btn(2)
			player.right_dir = false
			player.fvec.x -= 1
		if btn(3)
			player.right_dir = true
			player.fvec.x += 1
		if btnp(4) and player.down_col
			player.gravity = -2
			sfx(SFX_JUMP)
	if btn(5) and player.attack == 0
		player.attack = 15
		player.attack_t = t
		player.attack_row = 1 - player.attack_row
		dy = player.attack_row * 2
		swipe_new(player, vecnew(0, dy))
		sfx(SFX_SWIPE)
	if player.attack > 0
		player.attack -= 1

export player_aim_mode = (player) ->
	if btnp(6)
		if player.right_dir
			player.aim_rad = PI -- 180 degree
		else
			player.aim_rad = 0

	if btn(2)
		player.aim_rad -= 0.1
		if player.aim_rad < 0
			player.aim_rad = 0
	if btn(3)
		player.aim_rad += 0.1
		if player.aim_rad > PI
			player.aim_rad = PI
	
	if btnp(4) and player.down_col
			player.gravity = -2
			sfx(SFX_JUMP)

export player_update = (player) ->
	if not btn(6)
		player_movement(player)

		if player.prev_btn_6_holding
			dir = vec_from_rad(player.aim_rad)
			crystal_bounce_new(player.pos, vecmul(dir, 4.5))
			sfx(SFX_THROW)


	else
		if not player.prev_btn_6_holding
			sfx(SFX_AIMING)
		player_aim_mode(player)

	player.prev_btn_6_holding = btn(6)
	
export player_draw = (player) ->
	draw_pos = get_draw_pos(player.pos)

	spr_id = 256

	if player.attack > 0
		d = (t - player.attack_t) // 5
		if d > 2
			d = 2
		spr_id = 320 + d * 2 + player.attack_row * 32
	elseif not player.down_col
		-- Jumping/falling
		if player.gravity < 0
			spr_id = 266
		else
			spr_id = 268
	else
		if (btn(2) or btn(3)) and not btn(6)
			-- walking (frames: 0, 1, 0, 2)
			d = t // 8 % 4
			if d == 2
				d = 0
			elseif d == 3
				d = 2
			spr_id = 260 + d * 2
		else
			-- idle
			spr_id = 256 + (t // 30 % 2) * 2

	flip = 1
	if player.right_dir
		flip = 0

	spr(spr_id, draw_pos.x - 4, draw_pos.y - 2, 0, 1, flip, 0, 2, 2)


	if btn(6)
		dir = vec_from_rad(player.aim_rad)
		player_center = vecadd(draw_pos, vecnew(PLAYER_W/2, PLAYER_H/2))
		added = vecadd(player_center, vecmul(dir, 15))
		line(player_center.x, player_center.y, added.x, added.y, 12)

export swipe_new = (player, pos) ->
	if player.right_dir
		pos.x += 4
	else
		pos.x -= 12
	pos.y -= 2
	s = entity_new(pos, vecnew(SWIPE_W, SWIPE_H), swipe_update, swipe_draw, nil)
	s.pos_d = pos
	s.t = 10
	s.gravity_enabled = false
	s.parent = player
	s.layer = LAYER_SWIPES
	s.overlap_checked = false
	return s

export swipe_update = (swipe) ->
	swipe.t -= 1
	if swipe.t == 0
		swipe.rm_next_frame = true
	swipe.pos = vecadd(swipe.parent.pos, swipe.pos_d)
	
export swipe_draw = (swipe) ->
	spr_id = 478
	flip = 1
	if swipe.parent.right_dir
		flip = 0
	if swipe.t > 5 != swipe.parent.right_dir
		flip += 2

	draw_pos = get_draw_pos(swipe.pos)
	if DEBUG_DRAW_HITBOXES
		rectb(draw_pos.x, draw_pos.y, swipe.sz.x, swipe.sz.y, 11)
	spr(spr_id, draw_pos.x, draw_pos.y, 0, 1, flip, 0, 2, 2)

export crystal_bounce_new = (pos, efvec) ->
	crystal = entity_new(pos, vecnew(8, 8), crystal_bounce_update, crystal_bounce_draw)
	crystal.type = CRYSTAL_BOUNCE
	crystal.external_fvec = veccopy(efvec)

export crystal_bounce_update = (crystal) ->
	bounce = 0
	if crystal.up_col or crystal.down_col
		crystal.external_fvec.y *= -1
		bounce += math.abs(crystal.external_fvec.y)
	if crystal.left_col or crystal.right_col
		crystal.external_fvec.x *= -1
		bounce += math.abs(crystal.external_fvec.x)
	if bounce > 1
		sfx(SFX_CRYSTAL_BOUNCE,70,30,0,15,math.min(15,bounce - 1))
	if veclength(crystal.external_fvec) < CRYSTAL_SUMMON_VEL
		crystal.rm_next_frame = true
		imp_new(crystal.pos)
		timed_ent_new(crystal.pos, 10, {412, 414}, 5, vecnew(-16, -16), 2, 2, 2)
		sfx(SFX_SUMMON)

export crystal_bounce_draw = (crystal) ->
	draw_pos = get_draw_pos(crystal.pos)
	spr_id = 509
	spr(spr_id, draw_pos.x, draw_pos.y, 0, 1, 0, 0, 1, 1)

export projectile_new = (pos, dir, atk_player, atk_enemies, color) ->
	pjt = entity_new(pos, vecnew(1, 1), projectile_update, projectile_draw, nil)
	pjt.dir = veccopy(vecnormalized(dir))
	pjt.atk_player = atk_player
	pjt.atk_enemies = atk_enemies
	pjt.color = color

	pjt.gravity_enabled = false
	return pjt

export projectile_update = (pjt) ->
	pjt.fvec = vecmul(pjt.dir, 2)
	if entity_col(pjt)
		pjt.rm_next_frame = true

export projectile_draw = (pjt) ->
	draw_pos = get_draw_pos(pjt.pos)
	tail_pos = vecadd(draw_pos, vecmul(pjt.dir, 5))
	line(draw_pos.x, draw_pos.y, tail_pos.x, tail_pos.y, pjt.color)

export enemy_flying_critter_new = (pos) ->
	e = entity_new(pos, vecnew(8, 8), enemy_flying_critter_update, enemy_flying_critter_draw, nil)
	e.hp = 20
	e.layer = LAYER_ENEMIES
	e.gravity_enabled = false

	e.following = player
	e.following_range = 50
	e.following_rad_margin = 0.05
	e.following_rad = rndf(PI*e.following_rad_margin, PI - PI*e.following_rad_margin)
	e.following_rad_right = false
	e.sight_range = 90

	e.attack_timer_max = 4 * 60
	e.attack_timer = e.attack_timer_max

	return e

export enemy_flying_critter_in_sight = (e) ->
	if (e.following_rad_right)
		e.following_rad += 0.01
		if e.following_rad > PI - PI*e.following_rad_margin
			e.following_rad = PI - PI*e.following_rad_margin
			e.following_rad_right = false
	else
		e.following_rad -= 0.01
		if e.following_rad < PI * e.following_rad_margin
			e.following_rad = PI * e.following_rad_margin
			e.following_rad_right = true


	e_center = entity_get_center(e)

	dir = vec_from_rad(e.following_rad)
	dest = vecadd(vecmul(dir, e.following_range), player.pos)

	dir_dest = vecsub(dest, e_center)
	e.fvec = vecmul(dir_dest, 0.05)

export enemy_flying_critter_attack = (e) ->
	e_center = entity_get_center(e)
	following_center = entity_get_center(e.following)
	dir = vecsub(following_center, e_center)

	e.attack_timer -= 1
	if e.attack_timer <= 0
		e.attack_timer = e.attack_timer_max
		projectile_new(e_center, dir, true, false, 12)

export enemy_flying_critter_update = (e) ->
	e_center = entity_get_center(e)
	following_center = entity_get_center(e.following)
	dist = veclength(vecsub(e_center, following_center))

	if dist <= e.sight_range
		enemy_flying_critter_in_sight(e)
		enemy_flying_critter_attack(e)

export enemy_flying_critter_draw = (e) ->
	draw_pos = get_draw_pos(e.pos)
	spr_id = 448

	spr(spr_id, draw_pos.x - 4, draw_pos.y - 4, 0, 1, 0, 0, 2, 2)

export enemy_new = (pos) ->
	e = entity_new(pos, vecnew(SLIME_W, SLIME_H), enemy_update, enemy_draw, nil)
	e.t = 30
	e.hp = 20
	e.layer = LAYER_ENEMIES
	e.dx = 1
	return e

export enemy_update = (enemy) ->
	enemy.t -= 1
	if enemy.t == 0
		enemy.t = 20
	if enemy.hp <= 0
		enemy.rm_next_frame = true
	enemy.fvec.x = enemy.dx * 0.1
	right_col_point = vecnew((enemy.pos.x+enemy.sz.x)//8, (enemy.pos.y + enemy.sz.y-1)//8)
	left_col_point = vecnew((enemy.pos.x-1)//8, (enemy.pos.y + enemy.sz.y-1)//8)
	-- Check if can't go right: right is solid or a left col or below-right is not solid or not up col
	if map_solid(right_col_point.x, right_col_point.y) or map_left_col(right_col_point.x, right_col_point.y) or not (
		map_solid(right_col_point.x, right_col_point.y+1) or map_up_col(right_col_point.x, right_col_point.y+1)
	)
		enemy.dx = -1
	-- Check if can't go left: left is solid or a right col or below-left is not solid or not up col
	elseif map_solid(left_col_point.x, left_col_point.y) or map_right_col(left_col_point.x, left_col_point.y) or not (
		map_solid(left_col_point.x, left_col_point.y+1) or map_up_col(left_col_point.x, left_col_point.y+1)
	)
		enemy.dx = 1
	
export enemy_draw = (enemy) ->
	spr_id = 480
	if enemy.t < 10
		spr_id += 2
	flip = 0

	draw_pos = get_draw_pos(enemy.pos)
	if DEBUG_DRAW_HITBOXES
		rectb(draw_pos.x, draw_pos.y, enemy.sz.x, enemy.sz.y, 11)
		right_col_point = vecnew(draw_pos.x+enemy.sz.x, draw_pos.y + enemy.sz.y-1)
		left_col_point = vecnew(draw_pos.x-1, draw_pos.y + enemy.sz.y-1)
		pix(right_col_point.x, right_col_point.y, 4)
		pix(left_col_point.x, left_col_point.y, 4)
	spr(spr_id, draw_pos.x - 2, draw_pos.y - 4, 0, 1, flip, 0, 2, 2)

export imp_new = (pos) ->
	i = entity_new(pos, vecnew(0, 0), imp_update, imp_draw, nil)
	i.t = 120
	i.attack_t = 0
	i.gravity_enabled = false
	return i

export imp_update = (imp) ->
	imp.t -= 1
	if imp.t == 0
		imp.rm_next_frame = true
		timed_ent_new(imp.pos, 16, {414, 412}, 8, vecnew(-16, -16), 2, 2, 2)
		sfx(SFX_UNSUMMON)
	imp.attack_t -= 1
	if imp.attack_t <= 0
		imp.attack_t = 10
		-- Acquire random new target in range
		targets = {}
		for i, v in ipairs(entity_list)
			if v.layer == LAYER_ENEMIES and v.hp > 0 and veclength(vecsub(v.pos, imp.pos)) <= IMP_RANGE
				table.insert(targets, v)
		if #targets > 0
			target = targets[math.random(#targets)]
			target.hp -= 5
			-- TODO SFX, gfx
	
export imp_draw = (imp) ->
	spr_id = 444
	if imp.t % 20 < 10
		spr_id += 2
	flip = 0

	draw_pos = get_draw_pos(imp.pos)
	if DEBUG_DRAW_HITBOXES
		circb(draw_pos.x, draw_pos.y, IMP_RANGE, 11)
	spr(spr_id, draw_pos.x - 8, draw_pos.y - 8, 0, 1, flip, 0, 2, 2)

export timed_ent_new = (pos, ttl, sprites, frames_per_sprite, draw_off, scale, sx, sy) ->
	e = entity_new(pos, vecnew(0, 0), timed_ent_update, timed_ent_draw, nil)
	e.t = ttl
	e.sprites = sprites
	e.frames_per_sprite = frames_per_sprite
	e.draw_off = draw_off
	e.scale = scale
	e.sx = sx
	e.sy = sy
	e.gravity_enabled = false
	return e

export timed_ent_update = (e) ->
	e.t -= 1
	if e.t == 0
		e.rm_next_frame = true
	
export timed_ent_draw = (e) ->
	frame = (e.t // e.frames_per_sprite) % #e.sprites
	spr_id = e.sprites[#e.sprites - frame]
	draw_pos = get_draw_pos(e.pos)
	spr(spr_id, draw_pos.x + e.draw_off.x, draw_pos.y + e.draw_off.y, 0, e.scale, 0, 0, e.sx, e.sy)

export entity_collision = (e) ->
	fvec = vecadd(e.fvec, e.external_fvec)

	if fvec.y >= 0
		for x = 0, e.sz.x//8
			add = vecnew(x*8, e.sz.y)
			if x == e.sz.x//8
				add.x -= 1
			pos = vecadd(e.pos, add)
			if map_solid(pos.x//8, pos.y//8) or map_up_col(pos.x//8, pos.y//8)
				e.down_col = true
				break

	if fvec.y <= 0
		for x = 0, e.sz.x//8
			add = vecnew(x*8, -1)
			if x == e.sz.x//8
				add.x -= 1
			pos = vecadd(e.pos, add)
			if map_solid(pos.x//8, pos.y//8) or map_down_col(pos.x//8, pos.y//8)
				e.up_col = true
				break

	if fvec.x <= 0
		for y = 0, e.sz.y//8
			add = vecnew(-1, y*8)
			if y == e.sz.y//8
				add.y -= 1
			pos = vecadd(e.pos, add)
			if map_solid(pos.x//8, pos.y//8) or map_right_col(pos.x//8, pos.y//8)
				e.left_col = true
				break

	if fvec.x >= 0
		for y = 0, e.sz.y//8
			add = vecnew(e.sz.x, y*8)
			if y == e.sz.y//8
				add.y -= 1
			pos = vecadd(e.pos, add)
			if map_solid(pos.x//8, pos.y//8) or map_left_col(pos.x//8, pos.y//8)
				e.right_col = true
				break

export entity_physic = (e) ->
	if e.gravity_enabled
		e.gravity += 0.1
		if e.down_col and e.gravity > 0
			e.gravity = 0
		if e.up_col and e.gravity < 0
			e.gravity = 0
		e.fvec.y += e.gravity
	entity_move_x(e)
	entity_move_y(e)

	e.external_fvec = vecshrink(e.external_fvec, 0.03)

export entity_move_x = (e) ->
	fvec = vecadd(e.external_fvec, e.fvec)
	if fvec.x == 0
		return
	next_pos = veccopy(e.pos)
	next_pos.x += fvec.x
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
	fvec = vecadd(e.external_fvec, e.fvec)
	if fvec.y == 0
		return
	next_pos = veccopy(e.pos)
	next_pos.y += fvec.y
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

export entity_get_center = (e) ->
	return vecadd(e.pos, vecdiv(e.sz, 2))

export entity_col = (e) ->
	return e.up_col or e.down_col or e.left_col or e.right_col

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
		fvec: vecnew(0, 0),
		external_fvec: vecnew(0, 0),

		up_col: false,
		down_col: false,
		left_col: false,
		right_col: false,

		layer: LAYER_NONE,
	}
	table.insert(entity_list, entity)
	return entity

export entity_list_update = () ->
	for i, v in ipairs(entity_list)
		v.up_col = false
		v.down_col = false
		v.left_col = false
		v.right_col = false

		entity_collision(v)
		v.fvec = vecnew(0, 0)
		v.update(v)

		if v.default_physic
			entity_physic(v)

export entity_list_overlaps = () ->
	for i, v in ipairs(entity_list)
		for j, v2 in ipairs(entity_list)
			if v.layer == LAYER_SWIPES and not v.overlap_checked
				if v2.layer == LAYER_ENEMIES and v2.hp > 0 and entity_overlap(v, v2)
					v2.hp -= 10
					v.overlap_checked = true
					
					v2.external_fvec = vecnew(-2, -2)
					v_parent_center = vecnew(v.parent.pos.x + v.parent.sz.x/2, v.parent.pos.y + v.parent.sz.y/2)
					v2_center = vecnew(v2.pos.x + v2.sz.x/2, v2.pos.y + v2.pos.y/2)
					if v_parent_center.x < v2_center.x
						v2.external_fvec.x = 2

					sfx(SFX_SWIPE_HIT)

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

export rect_collide = (pos1, sz1, pos2, sz2) ->
	if pos1.x + sz1.x <= pos2.x
		return false
	if pos1.x >= pos2.x + sz2.x
		return false
	if pos1.y + sz1.y <= pos2.y
		return false
	if pos1.y >= pos2.y + sz2.y
		return false
	return true

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

export vecshrink = (vec, n) ->
	len = veclength(vec)

	if len - n <= 0.1
		return vecnew(0, 0)

	dir = vecnormalized(vec)
	return vecmul(dir, len - n)

export vec_from_rad = (rad) ->
	base_vec = vecnew(-1, 0)
	new_vec = vecnew(0, 0)
	new_vec.x = base_vec.x * math.cos(rad) - base_vec.y * math.sin(rad)
	new_vec.y = base_vec.x * math.sin(rad) + base_vec.y * math.cos(rad)
	return new_vec

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

export entity_overlap = (e1, e2) ->
	return e1.pos.x+e1.sz.x>e2.pos.x and e2.pos.x+e2.sz.x>e1.pos.x and e1.pos.y+e1.sz.y>e2.pos.y and e2.pos.y+e2.sz.y>e1.pos.y

-- <TILES>
-- 001:fdedffefdfefffedeedfeeddfddffedfeeffedffdffeedfedfeeddfefedfdfef
-- 002:655656566766767677777777fdeedeeff0ee0e0f000000000000000000000000
-- 003:000000000000000000000000000000000f0e0e00fdeedeeffdeedeefffffffff
-- 004:09ba00009ba000009ba000009ba000009ba000009ba000009ba0000009ba0000
-- 005:0000ab9000000ab900000ab900000ab900000ab900000ab900000ab90000ab90
-- 006:0000000000077000007557000755557075f55f57755555577555555707777770
-- 007:000000000000000000dddd00dddccddddddccddd00dddd000000000000000000
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
-- 064:00000000000000000000001100000111000001110000011c0000111c0001120c
-- 065:00000000000000001100000011100000c1100000fcf00000ccc00000cc200c00
-- 066:00000000000000000000001100000111000001110000011c0000001200000012
-- 067:00000000000000001100000011100000c1110000fcf00000ccc00000cc200000
-- 068:000000000000000000000111000011110000111c000011cf0000112c0000122c
-- 069:0000000000000000100000001100000011000000cf000000cc000000c2000000
-- 080:00000021000000110000002200000022000000ff00000fff00000dd000000f00
-- 081:12111200111120001112000022200000fff000000c0000000c0000000f000000
-- 082:00000021000002110000c2210000002200000022000000ff00000dd000000f00
-- 083:121c2000111120001112000021f00000fff000000c0000000c0000000f000000
-- 084:0001021100000111000022110000c2220000022f00000fff00000d0000000f00
-- 085:2100000011c000001220000010000000f0000000cd0000000c0000000f000000
-- 096:000000000000000000000011000001110000011c000001cf0000021c00000021
-- 097:0000000000000000110000001110000011100000c1f00000cc100000c0200000
-- 098:000000000000000000000011000001110000011c000001cf000001cc0000120c
-- 099:0000000000000000110000001110000011100000c1f00000cc100000c2000000
-- 100:000000000000000000000011000001110000011c000001cf000001cc0000120c
-- 101:0000000000000000110000001110000011100000c1f00000cc100000c0200000
-- 112:000000220000021100002111000c10110000002f00000ff000000d0000000f00
-- 113:122200001112000011c0000011000000ff000000cd0000000c0000000f000000
-- 114:00001122000022110000c011000000110000ffff00000df000000d0000000f00
-- 115:112000001112000011200000c2000000f0000000c0000000dc0000000f000000
-- 116:000100220000021100000c1100000011000000ff000000d000000d0000000f00
-- 117:11200000111200001c20000011000000ff0000000c0000000c0000000f000000
-- 156:0000000000000000000000000000000000000033000033430000344400033444
-- 157:0000000000000000000000000000000000000000303000003333000044333000
-- 158:0000000000000088000088880000880000080003008830000088304008830400
-- 159:0000000080000000880088000008388030004388004000380004408000008000
-- 172:0003344400003344000033330000033300000000000000000000000000000000
-- 173:4443300044433000444300003433000033300000000000000000000000000000
-- 174:0880000000803000000000000008000000834000008830000008838000008800
-- 175:0000080000000800000040000004000083400380000033808883880000880000
-- 188:00000000000000000004000000044488000048880000888800008811000888ff
-- 189:000000000000000000004000884440008884000088880000111800001ff88000
-- 190:000000000004000000044488000048880000888800008811000888ff00008111
-- 191:0000000000004000884440008884000088880000111800001ff8800011180000
-- 192:00000000000000000000000000000000000000dd00000ddc000dddcf00ddddcf
-- 193:00000000000000000000000000000000dd000000cd000000cdddd000cdddd000
-- 204:00808111008800110828880800022088000800880000088000000f0000000000
-- 205:111808001100880080888280880228008800800088000000f000000000000000
-- 206:000000110000880800088088008880880008088000000f000000000000000000
-- 207:1100000080880000880880008808880088080000f00000000000000000000000
-- 208:00000dcc00000ddd000000000000000000000000000000000000000000000000
-- 209:cd000000dd000000000000000000000000000000000000000000000000000000
-- 222:000000000000000000000000000cccc00000cccc0000000d0000000000000000
-- 223:00000000000000000000000000000000cc000000dccc00000dddcc0000edddc0
-- 224:0000000000000000000000000000000000000000000000000000000000000077
-- 225:0000000000000000000000000000000000000000000000000000000077000000
-- 238:00000000000000000000000f0000ffff000ffff0000000000000000000000000
-- 239:00eeddc00feddd00feee0000ee00000000000000000000000000000000000000
-- 240:00000765000076c500007cf5000765f500075655000756650007655500007777
-- 241:56700000556700005f5700005f56700055557000555c7000ccc6700077770000
-- 242:0000007700000765000076c500076cf5007655f5007566550076555500077777
-- 243:7700000056700000556700005f5670005f55670055555700cccc670077777000
-- 252:433300003cc430003cc343003443343003443343003443c300034cc300003334
-- 253:008888000812288081122888822cc228822cc228888228c808822c8000888800
-- 254:00099000009ba90009bb9a909bbb99a99a99aac909a9ac90009ac90000099000
-- 255:0077770007cc55707cc666576557777c765567c707656c700076c70000077000
-- </SPRITES>

-- <MAP>
-- 003:000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:000000000000000000000000000000000000000000100000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000
-- 005:000000000000000000000000000000000000000000100000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000
-- 006:000000000000000000000000000000000000000010000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000
-- 007:000000000000000000000000000000000000000010000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000
-- 008:000000000000000000000000000000000000001000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000
-- 009:000000000000000000000000000000000000001000000000000000000000000000000000100000000000000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000
-- 010:000000000000000000007000000000000000100000000000000000000000000000000000100000000040000000000000005000000000000000000010101000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010
-- 011:000000000000000000000000000000000000100000000000006000000000000000000000000000000040000060000000005000006000006000001010001010101010101000006000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010
-- 012:000000000000000000000000000000000000000000000000202020200000000000000000000000101010101010101010101010101010101010101010000000000000000010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:000000000000000000006000000000000000000000000000000000000000101010101010101010000000000000000000000000000000000010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:222234568aabdeffffedcba877777777
-- 002:0123456789abcdef0123456789abcdef
-- 003:555555568aabdeffffedcba865432100
-- 005:0000000000012345cdefffffffffffff
-- 006:00000000000000000cb7777789abcdef
-- 007:000145689abbcdeeefdccba995555555
-- </WAVES>

-- <SFX>
-- 000:a10071035106611071208130a140b150c160c180d190d1a0e1b0e1d0e1f0f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100400000004000
-- 001:d1f071d041a06160b130d100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100400000000000
-- 002:04057404a403c403d403e402f402f401f401f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400c00000000000
-- 003:d4f0b4d0a4b094909480a470b450c440d420d410e400e400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400500000000000
-- 004:e200f201e201e203020302040203020302020200020e020d020d020e020f02070207020702060205020502040203020202020200020002000200020050000004000f
-- 005:8000f000e000e000e000e000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000600000000000
-- 006:04d004c0847065804580359025a035b045c075d0a5f0b500c500d500e500e500f500f400f400f400f400f400f400f400f400f400f400f400f400f400207000000000
-- 007:d4f094e094d0a4b0c480d460e430f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400100000000000
-- 032:010021003100510051005100510051005100510051005100510051005100510051005100510051005100510051005100510051005100510051005100200000000000
-- 033:0305130323024301430073009300b300c300d300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300a00000000000
-- 034:6400b400d400e400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400700000000000
-- 035:04054404540374038403a402b402c401d401e400e400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400b00000000000
-- 036:0500150025003500450045004501450255015500650f75007500850095009500a500a500a500a500b500b500b500b500b500b500b500b500c500c500400000000056
-- 037:360056007600860096009600a600a600a600c600c600c600c600c600c600c600c600c600c600c600c600c600c600c600c600c600c600c600c600c600400000210000
-- 038:47c077009700b700b700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700e80000320000
-- 039:030523033100510051005100510051005100510051005100510051005100510051005100510051005100510051005100510051005100510051005100a05000000000
-- 040:04f024a03100510051005100510051005100510051005100510051005100510051005100510051005100510051005100510051005100510051005100200000000000
-- </SFX>

-- <PATTERNS>
-- 000:40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e400814000000000000000000400814000000000000000000
-- 001:400806400806100800400806100800400806100800400806400804100800400804100800400804000800100800000000800858800858100850800858100850800858100000800858600858100000600858100000400858000000100000000000400806400806100800400806100800400806100800400806400804100800400804100800400804000800100800000000800858800858100850800858100850600858100000600858400858100000000000000000000000000000000000000000
-- 002:4008084008081008004008081008004008081008004008084008061008004008061008004008060008001008000000004f8958400858100000400858100000400858100000400858e00856100000e00856100000d008560000001000000000004ff9084008081008004008081008004008081008004008084008061008004008061008004008060008001008000000004f8958400858100000400858100000e00856100000e00856d008561000008ff948000000900848100840900848b00848
-- 003:4ff904000000400806b00804100800000000400806100800400806600806400806100800400804000000e00802000000100800000800e00804d00804000000100800900804100800900804b00804900804100800e00802000000d00802000000100800000000d00804800804000000000000d00804100800d00802000000d00804100800d00802100800900806000000000000100800900806100800b00806000000100800000000900806100800b00806100800b00802000000400804000000
-- 004:b00848000000000000000000000000000000800848000000b0084800000000000000000040084a000000e00848000000000000000000d00848000000000000000000900848000000000000000000800848000000900848100840900848b008480000000000000000000000000000000000000000000000000000000000000000000000000000000000008f8958000000000000100000800858100000600858000000100850000000400858100000600858000000100000000000bff948000000
-- 005:0ff10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000048f958000000000000100000400858100000f00856000000100000000000d00856100000f00856000000100000000000000000000000
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
-- 033:90087400000040082e00000090088400000040082e00000090087400000040082e000820900884000000b00884000820b0087400000040082e000820b0088400000040082e000820b0087400000040082e00082090088400000040082e00082080087400000040082e00082080088400000040082e00082080087400000040082e000820b00884000000d00884000820d0087400000040082e000820d0088400000040082e000820d0087400000040082e000820b0087400000040082e000000
-- 034:4f8958000000000000000000000000000000000000000000000000000000000000000000000000000000b00856000000000000000000000000000000000000000000000000000000000000000000000000000000900856000000000000000000800856000000000000000000000000000000000000000000000000000000000000000000000000000000d00856000000000000000000000000000000000000000000000000000000000000000000000000000000b00856000000000000000000
-- 035:d00846000000000000000000000000000000900846000000d00846000000800848000000000000000000600848000000000000000000b00848000000000000000000f00846000000000000000000000000000000000000000000000000000000f00846000000000000000000000000000000b00846000000f00846000000400848000000600848000000400848000000000000000000f00846000000000000000000d00846000000000000000000000000000000000000000000000000000000
-- 037:88f958000000000000000000000000000000000000000000000000000000000000000000000000000000f00858000000000000000000000000000000000000000000600858000000000000000000000000000000000000000000000000000000600858000000000000000000000000000000000000000000000000000000000000000000000000000000b0085800000000000000000000000000000000000000000040085a000000000000000000000000000000f00858000000000000000000
-- 038:4008084008081008004008081008004008081008004008084008061008004008061008004008060008001008000000004f8958400858100000400858100000400858100000400858e00856100000e00856100000d008560000001000000000004ff9084008081008004008081008004008081008004008084008061008004008061008004008060008001008000000004f8958400858100000400858100000e00856100000e00856d00856100000400848000000f00846000000d00846000000
-- 039:800848000000000000000000000000000000400848000000800848000000900848000000b00848000000f00846000000000000000000b00846000000000000000000800846000000f00846000000400848000000600848000000500848000000000000000000600848000000800848000000000000000000000000000000000000000000000000000000600848000000000000100000600848100000500848000000000000100000600848100000800848000000100000000000d00846000000
-- 040:d8f958000000000000000000000000000000000000000000000000000000000000000000000000000000f00858000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800858000000000000000000000000000000500858000000000000000000000000000000000000000000000000000000f00858000000000000100000f00858100000d00858000000000000100000f0085810000050085a000000100850000000800858000000
-- 041:9f8956000000000000000000000000000000000000000000000000000000000000000000000000000000b00856000000000000000000000000000000000000000000000000000000000000000000000000000000800856000000d00856000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d00858000000000000100000d00858100000800856000000000000100000d00858000000d00856000000800856000000900856000000
-- 042:9f8958000000000000000000000000000000000000000000000000000000000000000000000000000000d00858000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00858000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d00858000000000000100000d00858100000f00858000000100000000000000000000000000000000000000000000000000000000000
-- 043:600848000000000000000000000000000000000000000000000000000000800848000000000000000000900848000000000000000000000000000000000000000000000000000000900848000000800848000000400848100000400848000000000000000000000000000000000000000000000000000000000000000000d00846000000400848000000600848000000000000100000b00846100000b00848000000100000000000000000000000800848000000900848100000900848b00848
-- 044:d8f95800000000000000000000000000000000000000000000000000000000000000000000000000000040085a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d0085800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040085a00000000000010000040085a10000060085a000000100000000000000000000000000000000000000000000000000000020300
-- 045:e0087400000040082e000000e0088400000040082e000000e0087400000040082e000820900884000000e0087200082040082e000820e00872000820e0088200000040082e000820e0088400000040082e00082090088400000040082e00082090087400000040082e00082090088400000040082e00082090087400000040082e000820900884000000b0087400082040082e000820b00874000820b0088400000040082e00082040082e000820b00884000820d00874000000b00884000000
-- </PATTERNS>

-- <TRACKS>
-- 000:996c57180302701581c42ac27015430d31932d44551857167015430a7f58996c571807222e84a92aa86a2e84a9eeac6b700000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2cff9696f06c6eef7d57ffcd75a7f07038b764257179a11c003b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

