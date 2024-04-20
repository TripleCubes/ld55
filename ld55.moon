-- title:   Crystalline
-- author:  TripleCubes, congusbongus
-- desc:    Summon friends in this cute platformer
-- site:    website link
-- license: MIT License
-- version: 0.1
-- script:  moon

export PI = 3.1416
export WINDOW_W = 240
export WINDOW_H = 136
export MAP_SCR_W = 30
export MAP_SCR_H = 17
export PLAYER_W = 8
export PLAYER_H = 14
FONTH=5
SWIPE_W = 16
SWIPE_H = 16
export t = 0
export entity_list = {}
export player = {}
export camera = { pos: {x: 0, y: 0} }
export view_room_list = {}
export prev_view_room = {}
export inventory = {}
export current_room_copy = nil

export camera_tweening = false
export camera_tween_destination = {}
export camera_tween_origin = {}
export camera_tweening_start_at = 0
export CAMERA_TWEENING_TIME = 60

export CRYSTAL_SUMMON_VEL = 1
export CRYSTAL_TRIGGER_RADIUS = 12
export CRYSTAL_HIT_DMG = 10

export SFX_JUMP = 0
export SFX_NEXT = 1
export SFX_ANGEL_HIT = 2
export SFX_THROW = 3
export SFX_AIMING = 4
export SFX_CRYSTAL_BOUNCE = 5
export SFX_SUMMON = 6
export SFX_UNSUMMON = 7
export SFX_IMP_ATTACK = 8
export SFX_CRYSTAL_GET = 9
export SFX_DEATH = 10

export MAP_ENEMY_SLIME = 6
export MAP_ENEMY_FLYING_CRITTER = 7
export MAP_CRYSTAL_YELLOW = 8
export MAP_CRYSTAL_RED = 9
export MAP_CRYSTAL_BLUE = 10
export MAP_CRYSTAL_GREEN = 11
export MAP_CRYSTAL_SPAWNER_YELLOW = 12
export MAP_CRYSTAL_SPAWNER_RED = 13
export MAP_CRYSTAL_SPAWNER_BLUE = 14
export MAP_CRYSTAL_SPAWNER_GREEN = 15
export MAP_RESPAWN = 16
export MAP_RESPAWN_INVISIBLE = 255
export SLIME_W = 12
export SLIME_H = 12
export WATER_RADIUS = 3
export WATER_SPAWN_INTERVAL = 8

export LAYER_NONE = 0
export LAYER_SWIPES = 1
export LAYER_ENEMIES = 2
export LAYER_WATER = 3

export CRYSTAL_YELLOW = 0
export CRYSTAL_RED = 1
export CRYSTAL_BLUE = 2
export CRYSTAL_GREEN = 3
export CRYSTAL_COLORS = {
	{4,3},{2,8},{10,9},{5,6}
}

export IMP_RANGE = 32
export CROC_RANGE = 16

export BTN_THROW = 5

export MUSIC = true
export DEBUG_DRAW_HITBOXES = false
export ENDING_MODE = false

class Button
  new:(x,y,w,h,label,textcolor,fillcolor,hovercolor)=>
    @x=x
    @y=y
    @label=label
    @textcolor=textcolor
    @fillcolor=fillcolor
    @hovercolor=hovercolor
    @width=w
    @height=h
    @textw=print label,0,-6
    @wasDown=false
    @hover=false
    @clicked=false
 
  update:=>
    mx,my,left=mouse!
    @hover=mx>=@x and mx<=@x+@width and my>=@y and my<=@y+@height
    -- Change cursor: hand
    if @hover
      poke(0x3FFB,129)
    -- Clicking on press
    @clicked=false
    if left and @hover and not @wasDown
      @clicked=true
    @wasDown=left
 
  draw:=>
    -- border
    rectb @x,@y,@width,@height,@textcolor
    -- fill
    fillcolor=@fillcolor
    if @hover
        fillcolor=@hovercolor
        if @wasDown
            fillcolor=@textcolor
    rect @x+1,@y+1,@width-2,@height-2,fillcolor
    -- label centered
    print @label,@x+(@width-@textw)/2,@y+(@height-FONTH)/2,@textcolor

-- Base state class
class State
	new:=>
		@tt=0
        -- Set the next state to switch to
		@nextstate=self
 
	reset:=>
        -- Reset is called whenever the game enters this state
		@tt=0
 
	update:=>
		@tt+=1
 
	finish:=>
        -- Finish is called whenever the game exits this state
        return
 
	next:=>
        -- Returns the next state to switch to, or self to remain in the same state
        return self
 
	draw:=>return
 
-- Skip to the next state on any button press.
-- Contains a grace period to avoid accidentally skipping too early
class SkipState extends State
	new:(grace)=>
		super!
		@grace=grace
 
	finish:=>
		sfx(SFX_NEXT)
 
	next:=>
		if @tt>@grace and (btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5))
			@finish!
			@nextstate\reset!
			return @nextstate
		return self

class TitleState extends SkipState
	new:(cheatstate)=>
		super(10)
		@button=Button(170,120,64,10,"Music: #{MUSIC and "on" or "off"}",12,6,5)
		@cheatbutton=Button(0,135,1,1,"",15,6,5)
		@cheatstate = cheatstate
		@img_values = {0,15,7,15,7,15,7,15,7,15,7,15,7,15,7,15,7,15,7,0,7,0,8,0,15,7,15,7,15,0,8,15,8,0,15,7,6,7,0,8,15,8,2,8,2,8,15,8,0,15,7,6,5,6,7,15,0,8,2,8,2,8,0,7,6,12,5,7,0,8,15,8,15,1,2,8,2,8,2,8,15,8,0,15,7,6,12,5,6,5,6,5,6,5,7,15,0,8,1,8,2,8,2,8,0,12,15,12,0,7,6,12,6,5,7,0,8,15,8,15,1,8,2,8,2,8,2,8,15,8,15,8,15,8,0,12,0,15,7,6,5,12,6,5,6,5,6,5,7,15,0,8,1,2,8,2,8,0,15,12,0,15,12,0,7,12,6,5,7,0,8,15,8,15,1,3,1,8,2,8,2,8,2,8,14,8,15,8,15,0,12,15,0,12,15,0,13,0,15,7,6,12,6,5,6,5,6,5,7,0,8,1,2,8,2,8,12,0,12,0,12,0,12,0,7,6,12,6,5,7,0,8,15,8,15,1,3,1,2,8,2,8,2,8,2,8,12,0,12,0,12,0,12,0,15,7,5,7,6,7,6,7,6,7,6,7,6,7,5,12,7,15,0,8,1,2,8,2,12,0,12,0,12,0,12,0,7,5,7,12,7,0,8,15,8,2,8,2,8,2,8,12,15,0,15,12,0,12,0,12,0,12,0,15,12,0,15,7,5,6,5,6,5,6,5,6,5,6,5,7,12,7,0,8,2,8,2,12,0,12,0,3,1,12,0,8,0,12,0,12,0,12,15,0,7,5,6,7,12,7,0,8,15,8,2,8,2,8,2,8,2,8,12,15,0,8,2,0,12,0,14,12,0,14,12,0,12,0,13,12,0,15,12,0,2,1,12,0,4,12,0,12,0,12,0,14,12,0,12,7,5,6,5,12,15,0,5,6,5,6,5,6,5,12,0,7,15,7,12,7,15,0,8,2,12,0,8,2,8,0,12,0,12,0,12,0,12,0,12,15,0,1,12,0,12,0,12,0,12,0,14,12,0,15,12,0,7,12,0,5,6,5,12,0,7,12,7,0,8,15,8,2,8,2,8,2,8,2,8,12,0,8,2,8,2,0,14,12,0,4,12,15,12,0,12,0,12,15,0,12,15,0,12,15,0,12,0,5,6,5,12,0,7,0,8,2,12,15,0,8,2,8,0,12,0,12,15,0,12,15,12,15,0,12,15,12,0,12,0,12,0,15,12,0,12,0,5,6,12,15,12,0,7,0,8,15,8,2,8,2,8,2,8,2,8,12,0,8,2,8,2,8,0,12,15,12,15,12,0,12,0,12,15,0,15,0,12,15,0,8,1,0,12,15,0,12,0,12,15,0,12,15,0,12,15,0,12,15,0,15,0,12,0,5,6,5,12,0,12,15,0,15,7,0,8,12,0,8,2,8,2,8,0,12,0,15,0,12,0,12,15,12,15,0,12,15,0,8,12,0,8,3,1,0,15,0,3,0,12,0,3,0,12,0,12,0,12,0,12,0,12,0,5,12,0,6,12,0,7,0,8,15,8,2,8,2,8,2,8,2,8,12,15,0,8,2,8,2,8,15,0,12,15,0,12,0,12,0,12,0,2,12,0,3,8,2,12,15,0,8,2,8,1,3,1,3,0,2,1,3,12,15,0,3,1,3,0,12,0,12,0,12,0,12,15,0,12,0,5,12,5,12,15,0,15,0,15,7,15,0,8,2,8,12,0,8,2,8,0,15,12,0,12,0,12,15,0,12,15,0,1,2,8,12,0,8,1,3,1,12,15,12,0,1,3,12,0,12,0,12,0,12,0,12,0,5,12,0,13,6,7,0,8,15,8,15,8,15,8,2,8,12,0,8,2,12,8,0,12,15,0,12,0,12,0,12,0,3,1,12,0,8,2,8,1,3,1,3,1,4,12,0,12,0,3,1,3,1,12,15,0,12,15,0,12,0,12,15,0,12,0,5,6,12,15,0,12,7,0,8,15,8,2,8,2,12,0,8,12,8,0,12,0,12,15,0,14,12,0,12,0,12,0,1,12,0,8,1,12,0,1,12,0,1,12,0,12,0,12,0,12,0,12,15,0,5,12,0,12,7,0,8,15,8,15,8,14,8,15,8,2,8,2,8,12,0,8,12,8,0,14,12,0,12,15,0,12,0,15,12,0,3,12,15,0,1,3,1,3,1,12,0,3,1,12,0,3,1,12,0,12,0,12,0,12,0,12,15,0,7,12,15,14,12,6,7,15,0,8,15,12,0,12,8,0,4,12,0,12,0,12,0,12,15,0,1,12,0,1,12,0,1,12,0,1,12,0,12,0,12,0,12,0,12,0,7,12,0,12,7,0,8,15,8,15,8,14,8,15,2,8,2,8,2,12,15,0,12,15,0,12,0,2,3,12,15,0,3,12,0,3,1,3,1,12,15,0,3,1,12,0,3,1,12,0,2,0,12,0,12,0,12,0,12,0,15,7,12,15,12,7,0,12,0,8,0,12,15,12,0,12,0,12,0,2,1,12,0,3,1,15,12,0,12,0,8,15,8,15,8,2,8,2,8,2,0,12,15,0,12,0,12,15,0,14,12,0,3,1,2,0,12,15,12,15,12,0,12,15,0,12,0,8,0,15,12,0,12,0,15,12,0,12,0,3,1,0,15,12,15,0,12,15,0,15,12,15,12,15,12,15,0,12,15,0,12,0,12,15,0,12,15,0,8,15,8,14,8,2,8,0,15,0,15,0,15,0,15,0,15,0,15,0,12,0,13,15,0,15,0,15,0,15,0,3,1,3,1,0,15,0,15,0,15,0,3,0,15,0,15,0,15,0,8,15,0,15,0,15,0,2,0,15,0,15,0,2,0,15,0,15,0,15,0,15,0,15,0,15,0,15,0,15,0,15,0,15,0,15,0,15,0,8,0,12,15,0,2,1,3,0,3,1,3,0,8,2,8,0,3,1,0,3,1,0,12,15,0,2,3,1,3,1,3,1,3,1,8,1,3,1,3,1,8,1,3,1,3,1,3,0,4,12,0,1,2,8,1,2,8,1,3,0,12,15,0,2,1,3,1,3,1,3,1,3,1,2,8,2,1,3,1,3,1,2,8,2,8,1,3,1,3,1,3,1,3,1,0,12,0,1,2,8,1,2,8,1,3,0,12,15,0,2,3,1,3,1,3,1,3,1,3,1,3,1,3,1,3,1,2,8,2,1,3,1,2,1,3,1,3,1,3,1,3,1,8,2,8,2,8,2,1,3,1,3,1,3,1,3,1,0,14,12,0,3,1,8,1,8,1,0,12,0,3,1,3,1,3,1,3,1,3,1,3,1,2,1,3,1,2,8,2,8,2,1,3,1,3,1,2,1,3,1,2,8,2,8,2,1,2,1,3,1,3,1,3,1,0,12,0,3,1,3,1,8,1,8,1,3,0,13,12,15,0,15,0,15,0,3,1,3,1,3,1,3,1,3,1,3,1,3,1,3,1,3,1,2,8,2,8,2,1,3,1,3,1,3,1,2,1,2,8,2,8,2,1,3,1,3,1,0,3,1,8,1,8,1,3,0,3,1,3,1,3,1,3,1,3,1,3,1,3,1,3,1,3,1,2,1,2,8,2,8,2,8,1,3,1,3,1,3,1,3,1,2,1,2,8,2,8,2,1,3,1,2,1,3,0,3,1,8,2,8,1,8,1,0,2,1,3,1,3,1,3,1,3,1,3,1,3,1,3,1,3,1,3,1,2,1,2,8,2,8,2,8,2,1,3,1,3,1,3,1,2,1,2,8,2,8,2,8,1,3,1,3,1,0,15,9,0,1,3,2,8,2,8,1,8,1,0,9,0,2,3,1,3,1,3,1,3,1,3,1,3,1,3,1,3,1,3,1,3,1,2,8,2,8,2,8,2,8,2,8,2,1,3,1,3,1,2,1,3,1,2,8,2,8,2,1,3,1,2,0,15,9,15,9,0,1,8,1,2,8,2,8,1,8,1,0,9,10,9,0,9,0,2,1,3,1,3,1,3,1,3,1,3,1,3,1,8,2,8,1,3,1,3,1,8,2,8,2,8,1,8,2,8,2,8,2,8,2,8,1,3,1,3,1,3,1,2,1,3,1,2,8,2,8,2,8,1,0,15,9,10,11,9,0,9,0,9,0,1,8,2,8,2,1,8,2,8,12,1,8,1,8,2,8,3,0,9,11,9,0,9,0,3,1,3,1,3,1,3,1,3,1,3,1,8,2,8,2,1,3,1,8,2,8,2,12,1,2,8,2,8,2,8,2,8,1,3,1,3,1,3,1,2,1,2,1,2,8,2,0,15,9,10,11,10,11,9,0,9,0,15,0,9,0,1,8,2,8,2,12,1,8,2,8,1,8,1,0,9,11,9,0,15,0,9,0,2,0,3,1,3,1,3,1,3,1,3,1,3,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,12,1,2,8,2,8,2,8,2,8,2,8,1,3,1,3,1,3,1,3,1,2,1,0,15,9,10,11,10,11,10,11,9,0,15,0,15,0,9,0,3,2,0,1,8,2,8,12,8,12,1,2,8,1,3,0,9,10,11,9,15,0,9,0,2,3,2,0,3,1,3,1,3,1,3,1,8,2,8,2,8,2,12,1,2,8,2,8,2,8,2,8,2,1,3,1,2,1,3,1,3,1,2,1,3,0,15,9,11,10,11,10,11,10,9,0,15,0,15,0,15,0,9,0,3,12,3,2,0,1,8,2,8,12,1,8,2,8,1,3,0,9,10,11,9,15,0,9,0,2,3,12,4,2,3,2,0,2,1,3,1,3,1,3,1,8,2,8,2,12,1,8,2,8,2,8,2,8,2,8,1,3,1,3,1,2,1,3,1,3,1,3,1,3,0,15,9,10,11,10,11,10,11,10,11,9,0,15,0,15,0,9,0,3,12,4,3,2,0,8,1,8,2,12,1,2,8,2,8,1,3,0,9,11,9,15,9,15,0,9,0,2,12,3,4,2,3,2,0,8,2,3,1,3,1,3,1,8,2,8,12,1,2,8,2,8,2,8,2,8,2,8,1,3,1,3,1,3,1,2,1,3,1,3,1,3,1,0,15,9,10,11,10,11,10,11,10,11,10,9,0,15,0,15,0,15,9,15,0,3,12,3,4,3,2,0,2,8,1,8,12,1,8,12,8,2,8,2,8,1,8,0,9,11,9,15,0,9,0,2,3,12,3,2,4,2,3,2,0,8,1,3,1,3,1,0,12,2,8,2,8,2,8,1,3,1,3,1,3,1,3,1,3,1,3,1,3,8,2,8,2,8,0,9,0,3,12,3,4,3,2,0,1,3,0,12,8,2,8,2,8,1,8,2,8,0,9,12,9,0,2,3,12,3,2,3,2,4,2,3,2,0,2,3,1,3,1,3,1,3,1,3,0,12,15,14,15,14,15,14,15,12,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,0,9,0,9,15,9,15,9,12,9,0,3,12,4,3,4,3,2,0,3,1,0,12,0,15,12,15,12,0,12,2,8,2,8,2,8,2,8,2,8,0,9,0,15,9,12,9,0,2,12,4,3,2,3,2,3,2,3,4,2,3,2,3,0,2,3,1,3,1,3,1,3,1,0,12,0,15,14,15,14,15,14,15,14,15,14,12,15,14,15,14,15,14,15,14,15,14,15,0,12,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,0,15,0,15,0,15,0,15,0,9,15,9,12,9,0,3,4,3,4,3,0,3,1,3,0,12,0,15,12,15,0,12,2,8,1,0,9,15,9,12,9,0,2,3,4,2,3,2,4,2,0,2,3,1,3,1,3,1,3,1,3,1,3,1,0,12,0,15,12,0,12,0,2,8,2,8,2,8,2,8,1,2,1,2,1,3,0,15,0,15,0,9,15,9,12,9,0,3,4,3,0,3,1,0,12,0,12,0,12,0,8,1,3,0,15,9,12,9,0,2,3,4,2,3,0,2,3,1,3,1,3,1,3,1,3,1,3,1,3,1,3,1,0,12,0,12,0,12,0,3,1,2,8,2,8,2,8,2,8,1,2,1,3,1,3,0,9,0,15,0,9,12,9,0,3,4,3,0,3,1,3,0,12,0,1,8,1,3,0,9,15,9,12,9,0,2,3,4,2,3,2,3,2,3,2,3,4,2,0,2,3,1,3,1,3,1,3,1,3,1,3,1,2,1,3,0,12,0,3,1,2,8,2,8,2,8,2,1,3,1,3,0,9,12,0,3,4,3,12,3,0,3,1,0,12,0,1,2,1,8,1,3,0,9,12,0,2,4,2,12,3,2,0,2,3,1,3,1,3,1,3,1,3,1,3,1,3,1,3,1,2,1,3,1,3,1,3,1,0,12,0,2,3,1,3,1,8,2,8,2,8,2,8,2,8,1,2,1,3,1,3,1,3,0,9,15,9,0,3,2,4,3,12,3,0,3,1,0,12,0,1,2,8,1,3,0,9,0,2,3,2,4,2,3,2,3,2,3,2,12,3,2,0,2,1,3,1,3,1,3,1,3,1,3,1,3,1,3,1,3,1,3,1,3,1,2,1,0,12,0,2,1,3,1,2,1,8,2,8,2,8,2,8,2,8,2,1,3,1,3,0,3,4,3,12,3,0,3,1,0,12,0,1,0,8,1,3,0,2,4,12,3,2,0,3,1,3,1,3,1,3,1,3,1,3,1,3,1,2,1,3,1,3,1,3,1,3,1,2,1,3,0,8,0,12,0,2,3,1,3,1,3,1,0,8,2,8,2,8,2,8,2,8,2,8,2,1,3,1,3,1,0,3,4,12,3,0,8,1,8,1,0,8,0,12,0,1,0,8,2,8,1,3,0,2,3,2,3,2,0,8,2,8,2,8,1,3,1,3,1,3,1,3,1,3,1,8,2,8,2,1,3,1,3,1,3,1,3,0,8,2,8,0,12,0,2,3,1,3,1,3,1,2,0,2,8,2,8,2,8,2,8,2,8,2,8,2,1,0,3,0,8,2,8,1,8,1,0,8,2,8,0,12,0,1,0,8,2,8,2,8,2,8,0,2,3,2,3,2,3,2,3,2,3,2,0,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,1,3,1,3,1,3,1,0,8,2,8,2,8,0,12,0,2,3,1,3,1,3,1,3,1,3,1,3,0,8,2,8,2,8,2,8,2,8,2,8,2,8,0,2,8,2,8,2,8,2,8,1,3,0,8,2,8,0,12,0,3,1,0,2,8,0,8,2,8,2,0,8,2,8,2,8,2,8,2,8,2,8,2,0,8,2,8,1,3,1,3,1,3,1,0,8,2,8,2,8,2,0,12,0,2,3,1,3,1,3,1,3,1,3,1,3,1,0,8,2,1,8,0,8,2,8,0,12,0,8,0,1,8,1,3,0,8,1,2,1,3,1,3,1,8,2,8,2,0,8,2,8,2,8,2,8,0,8,2,0,8,2,8,2,1,3,1,3,1,3,1,0,8,1,8,0,8,2,8,2,8,0,13,15,0,8,2,8,0,8,1,3,0,8,1,3,1,3,1,3,8,2,8,2,8,0,8,2,8,2,8,2,8,2,8,0,13,4,13,4,13,4,13,4,13,4,13,4,13,4,15,0,8,2,8,2,8,2,8,2,8,2,8,2,8,1,3,1,3,1,2,1,3,1,0,8,1,8,2,0,8,2,8,2,0,4,13,4,13,4,13,4,13,4,13,4,13,15,0,8,2,8,2,0,8,1,3,0,2,1,3,1,3,1,3,1,3,1,8,2,8,2,8,0,8,2,8,2,8,2,8,2,8,0,13,4,13,12,13,12,13,12,13,12,13,12,4,13,14,15,0,8,2,8,2,8,2,8,2,8,0,2,8,2,8,2,8,2,1,3,1,3,1,3,0,3,1,8,2,0,8,2,8,2,8,0,13,4,15,0,8,2,8,2,0,8,1,3,0,2,1,3,1,3,1,3,1,3,1,2,8,2,8,0,8,2,8,2,8,2,0,13,4,12,13,4,13,4,12,13,4,13,12,13,15,14,15,0,8,2,8,2,8,0,8,2,8,2,8,2,8,1,2,1,3,1,3,1,3,0,8,3,1,8,0,8,0,4,13,4,13,4,15,0,8,1,0,8,1,3,1,3,1,3,1,3,1,8,2,8,2,8,2,0,8,2,8,0,13,4,12,13,12,4,13,12,4,13,12,13,14,15,0,8,2,8,2,8,2,8,1,3,1,3,1,3,0,8,1,8,0,8,0,4,13,4,15,0,9,0,8,2,1,3,0,8,1,3,1,3,1,3,1,3,1,8,2,8,2,8,2,8,0,8,2,8,2,8,2,8,13,12,13,4,13,12,4,13,12,4,15,14,0,15,9,0,2,8,2,8,2,8,1,3,1,3,1,3,0,8,1,8,0,8,2,8,2,8,2,8,4,13,15,9,0,8,2,8,1,3,0,2,1,3,1,3,1,3,1,3,1,8,2,8,2,8,2,8,0,8,2,8,2,8,2,8,2,8,2,8,4,2,13,14,15,14,15,14,15,9,15,9,15,9,15,9,15,9,0,8,2,8,2,8,2,1,3,1,3,1,3,0,3,1,8,0,8,2,8,2,8,2,8,2,4,15,6,9,0,8,2,8,1,3,0,2,1,3,1,3,1,3,1,3,1,3,1,8,2,8,2,8,2,8,0,8,2,8,2,8,2,8,4,6,9,15,9,15,9,15,9,0,8,2,8,2,8,2,8,2,1,3,1,3,1,3,0,3,1,8,0,8,2,8,2,8,2,4,6,9,0,8,1,3,0,3,1,3,1,3,1,3,1,3,1,8,2,8,2,8,2,8,2,0,8,2,8,2,8,2,8,2,8,4,6,9,15,9,15,9,15,9,15,9,0,8,2,8,2,8,2,8,2,1,3,1,3,1,3,0,3,1,8,0,8,2,8,2,8,4,6,9,0,8,1,3,0,2,1,3,1,3,1,3,1,3,8,2,8,2,8,2,8,2,8,0,8,2,8,2,8,2,8,2,8,2,4,6,9,15,9,15,9,15,9,0,2,8,2,8,2,8,2,1,3,1,3,1,3,1,3,0,3,1,8,2,8,0,8,2,8,2,8,2,8,2,8,4,6,9,0,8,1,3,0,2,3,1,3,1,3,1,3,1,8,2,8,2,8,2,8,2,8,0,8,2,8,2,8,2,8,2,8,2,8,2,4,6,9,15,9,15,9,15,9,15,9,0,8,2,8,2,8,2,8,1,3,1,3,1,3,1,3,0,3,1,8,2,8,2,8,0,8,2,8,2,8,2,8,2,8,4,6,9,0,8,1,3,0,8,3,1,3,1,3,1,3,1,8,2,8,2,8,2,8,2,8,0,8,2,8,2,8,2,8,2,8,2,8,2,4,6,7,9,15,9,15,9,15,9,15,9,0,2,8,2,8,2,8,2,8,2,1,3,1,3,1,0,8,2,1,8,2,8,2,8,0,8,2,8,2,8,2,8,2,8,4,6,9,0,8,2,8,0,8,1,3,1,3,8,1,3,1,3,8,2,8,2,8,2,8,2,8,0,8,2,8,2,8,2,8,2,8,2,8,2,8,4,6,7,9,15,9,15,9,15,9,15,9,15,9,0,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,0,2,8,2,1,8,2,8,2,0,8,2,8,2,8,2,8,2,8,2,4,6,9,0,8,2,8,0,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,0,8,2,8,2,8,2,8,2,8,2,8,2,4,6,9,15,9,15,9,15,9,15,9,15,9,0,8,2,8,2,8,2,8,2,8,2,8,2,0,8,2,8,2,8,0,8,2,8,2,8,2,8,2,8,4,6,9,0,8,0,8,2,8,2,8,2,8,2,8,2,8,2,8,2,4,6,9,15,9,15,9,15,9,15,9,15,9,0,8,2,8,2,8,2,8,0,8,2,8,2,8,2,8,2,8,2,8,4,6,9,0,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,4,6,9,15,9,15,9,15,9,15,9,15,9,0,8,2,8,2,8,2,4,6,9,0,8,2,8,2,8,2,8,2,8,2,8,2,1,4,6,9,15,9,15,9,15,9,15,9,15,9,15,9,15,9,0,8,2,8,2,8,2,8,2,8,2,8,2,8,4,6,9,0,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,4,6,7,9,15,9,15,9,15,9,15,9,15,9,15,9,0,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,4,6,9,0,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,4,6,9,15,9,15,9,15,9,15,9,15,9,15,9,15,9,15,9,0,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,4,6,9,0,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,4,6,9,15,9,15,9,15,9,15,9,15,9,15,9,15,9,0,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,4,6,9,0,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,8,2,4,6,9,15,9,15,9,15,9,15,9,15,9,15,9,15,9,15,9,15,9,0,8,2,8,2,8,2,8,2,8,2,8,2,8,2,4,6,9,0}
		@img_runs = {2103,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,221,20,74,13,132,1,19,1,1,1,71,5,8,2,129,1,3,18,4,69,2,1,2,1,4,1,4,1,1,127,1,3,13,6,1,3,1,67,7,3,3,2,4,125,4,1,13,8,4,65,2,1,1,1,1,1,4,1,1,1,4,1,2,123,1,3,2,13,1,1,1,1,1,1,3,3,1,63,5,2,1,3,5,1,6,86,8,1,7,19,3,2,15,4,7,3,61,2,1,1,1,3,4,1,1,1,1,1,2,1,1,1,1,1,1,84,17,18,1,2,2,1,5,15,1,1,1,1,3,2,1,59,5,4,3,6,1,8,84,1,6,2,1,5,18,4,7,18,6,3,57,2,1,1,1,3,1,1,3,1,1,1,1,1,4,1,2,1,2,1,84,4,1,4,4,1,6,1,10,1,3,1,6,20,1,1,1,1,1,3,56,5,6,2,6,2,3,7,83,4,5,4,6,3,9,4,1,5,22,4,3,55,2,1,1,1,3,1,2,1,2,1,1,1,1,1,3,12,81,4,5,4,5,4,9,1,2,11,1,1,2,1,2,1,2,1,2,1,5,1,2,2,1,55,4,8,1,6,2,13,81,4,5,4,4,6,8,3,11,19,3,3,55,1,1,1,1,2,1,2,1,2,12,2,1,1,6,51,1,29,4,5,4,5,1,4,8,1,2,1,1,1,1,1,1,1,1,1,1,1,19,2,4,55,4,1,6,1,12,5,5,45,4,1,2,2,2,25,4,5,4,6,3,1,8,4,10,2,16,3,3,56,1,1,1,1,1,1,1,1,1,1,2,10,1,1,4,1,1,3,5,1,1,4,1,1,6,1,9,1,2,7,1,2,3,1,3,15,7,1,2,8,4,5,4,6,1,2,8,2,3,1,1,1,1,1,1,1,1,1,1,1,7,1,2,2,2,1,2,2,3,1,56,10,2,10,2,1,3,1,7,4,3,3,4,3,6,6,5,8,1,1,1,16,4,7,7,4,5,4,4,1,4,5,1,3,2,2,6,2,3,4,1,7,1,2,3,4,57,1,1,1,1,1,1,1,1,1,1,2,10,1,1,1,4,1,4,1,19,4,1,8,1,28,3,10,6,4,1,4,4,1,2,6,1,3,16,2,2,3,1,11,2,4,58,11,1,9,1,1,3,2,4,1,21,7,10,2,2,8,1,5,4,4,4,3,5,6,3,6,3,5,1,4,3,17,2,3,1,4,2,7,2,3,59,1,1,1,1,1,2,1,1,1,1,1,9,2,1,1,3,1,3,4,7,1,5,1,5,6,10,4,3,1,1,2,2,4,1,6,1,1,1,2,1,4,4,6,3,1,5,3,1,5,4,1,4,7,1,1,1,1,4,2,1,1,2,4,2,6,1,2,1,1,60,12,9,2,2,2,2,1,2,4,7,2,2,3,5,6,4,1,3,1,5,2,1,4,2,3,1,3,3,3,1,1,2,3,1,4,2,1,3,3,6,3,6,4,5,7,4,4,2,3,3,2,2,4,4,2,61,1,1,1,2,1,1,1,1,1,1,1,9,1,1,1,1,2,1,3,1,4,5,1,9,4,6,4,1,5,3,1,2,1,1,3,1,3,1,1,1,1,1,4,1,1,1,2,1,3,1,4,1,1,1,1,1,1,3,6,3,6,4,5,5,1,6,3,2,2,6,1,2,1,1,1,2,1,1,1,62,12,1,3,6,2,4,2,2,4,1,4,11,4,4,3,1,3,8,1,1,3,1,2,3,2,3,7,2,4,1,1,3,2,3,1,3,6,3,6,4,5,5,7,3,2,2,8,3,1,1,3,63,1,1,2,1,3,1,4,2,1,6,2,2,1,3,2,5,3,1,11,4,4,3,5,9,2,1,2,4,2,1,1,1,2,1,3,1,3,1,3,1,3,2,1,1,1,1,3,1,5,3,1,5,4,5,4,1,7,3,2,1,1,6,1,2,3,4,64,9,1,1,1,2,1,7,2,2,3,2,5,3,12,4,1,2,1,2,6,2,2,6,2,2,4,2,2,9,4,2,1,4,2,3,3,6,3,6,4,5,4,8,3,1,1,2,5,2,4,4,65,1,1,1,1,1,1,1,1,3,1,1,1,1,8,2,1,3,1,3,1,5,13,8,1,6,2,4,1,4,2,1,4,1,1,5,1,1,1,2,3,2,2,1,4,2,1,2,3,6,3,6,4,5,4,8,3,1,1,1,5,1,1,4,1,2,1,67,14,1,9,2,1,1,2,1,7,13,8,6,2,6,4,1,1,1,5,2,7,4,2,4,4,2,3,3,6,3,6,4,5,4,8,3,2,2,4,2,3,4,69,1,1,2,1,1,1,1,1,1,1,1,1,1,23,1,13,6,1,6,2,3,1,2,4,1,1,1,6,2,1,1,1,1,6,1,1,1,2,5,2,1,2,4,1,1,3,4,5,4,5,4,8,3,2,1,1,6,1,2,3,1,2,68,13,1,16,2,4,14,5,7,4,1,1,3,3,2,1,1,1,63,7,23,69,1,1,2,1,2,2,1,1,1,1,1,14,1,2,6,12,5,1,5,1,12,2,1,1,1,1,10,2,9,2,41,5,8,1,1,12,71,12,1,2,10,5,6,12,1,3,7,11,3,1,3,1,1,8,1,2,7,1,2,1,5,3,6,3,6,2,1,6,2,1,6,5,6,2,3,9,1,73,1,1,1,1,3,1,5,3,1,1,1,1,1,1,1,8,1,1,1,14,3,6,1,1,1,1,1,1,1,4,2,2,3,1,1,3,1,1,1,1,1,2,2,1,1,1,1,1,1,3,2,1,1,1,1,1,2,1,2,1,1,1,3,1,2,1,1,1,6,1,1,1,6,1,1,1,8,1,1,1,7,1,1,1,1,1,1,1,76,13,34,2,1,17,1,8,1,7,2,2,1,6,2,2,1,4,3,1,5,3,1,169,2,1,10,1,7,1,1,2,1,1,1,3,4,1,2,5,6,1,5,1,2,4,5,4,1,167,1,2,11,19,3,1,15,4,1,16,1,166,2,1,10,1,8,1,2,1,2,1,1,1,2,1,2,2,2,1,1,1,9,1,3,1,1,2,1,1,1,5,1,1,1,3,165,3,11,21,1,3,16,1,5,13,2,163,3,1,10,1,1,1,1,1,1,1,1,1,1,2,1,2,1,3,1,2,2,1,2,2,1,2,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,2,2,1,1,1,2,1,2,1,2,162,1,5,8,1,23,5,16,6,13,162,6,8,1,3,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,1,1,1,2,2,1,2,1,2,1,2,1,4,1,1,1,1,2,2,1,2,1,2,1,1,1,1,160,6,8,1,24,1,1,5,16,6,11,1,159,1,1,1,1,1,1,1,8,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,3,1,1,1,1,2,2,1,2,1,2,1,2,1,4,1,1,1,1,2,2,1,2,1,4,173,1,28,7,16,5,9,1,173,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,1,1,1,1,1,3,1,2,1,2,1,2,1,1,1,2,1,1,1,1,2,2,1,2,1,2,1,171,1,31,4,1,2,16,6,8,170,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,3,1,1,1,1,1,2,1,1,2,2,1,2,1,2,1,3,1,2,1,1,1,1,1,1,2,1,2,1,1,51,1,3,115,32,1,1,2,2,4,16,6,6,50,6,113,1,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,1,1,1,1,3,1,1,1,1,2,2,1,2,1,2,1,2,1,4,1,1,1,1,2,2,1,1,1,48,1,4,1,2,112,18,3,10,1,4,2,7,17,6,4,47,2,3,1,3,1,110,1,1,1,2,1,2,1,2,1,2,1,2,1,1,1,1,1,3,1,2,1,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,1,2,1,2,1,2,1,1,1,3,1,1,1,1,1,2,2,46,1,1,1,3,1,1,1,1,3,108,18,1,1,1,1,8,1,1,4,2,1,9,17,4,2,1,1,45,2,5,1,4,3,107,1,1,1,2,1,2,1,2,1,2,1,2,1,1,3,2,2,1,2,1,1,2,1,5,1,1,1,1,1,2,1,1,1,2,1,2,1,2,1,3,1,1,1,3,1,3,2,44,1,1,1,2,1,2,1,1,1,1,1,1,3,106,16,3,2,10,2,6,1,3,1,7,20,1,1,43,2,7,1,2,3,1,3,28,15,62,1,1,1,2,1,2,1,2,1,2,1,1,1,1,1,2,1,1,1,1,2,1,1,1,1,1,8,2,1,2,1,1,1,1,1,1,1,1,2,1,2,1,1,1,4,1,1,1,5,42,1,2,1,1,1,2,1,1,1,1,1,2,1,1,4,27,15,2,60,13,1,1,5,1,10,10,1,2,10,19,3,38,2,1,8,1,6,1,5,25,15,1,2,59,1,2,1,2,1,2,1,1,1,1,2,1,1,1,24,1,2,1,1,1,2,1,1,1,2,2,1,3,1,1,1,2,1,3,1,5,3,34,1,2,2,1,2,1,2,1,1,1,1,2,1,1,1,2,4,24,3,10,5,1,58,11,2,1,3,26,2,2,1,9,22,3,30,2,2,9,1,9,1,4,23,2,1,10,3,2,1,1,57,1,1,1,2,1,2,1,2,1,1,2,1,28,3,2,1,1,1,1,2,1,1,2,2,1,2,1,2,1,2,1,1,1,1,1,7,5,24,1,1,1,3,1,2,1,2,1,1,1,2,1,5,1,2,4,22,3,10,4,3,2,54,2,10,2,1,31,3,1,8,2,1,27,3,20,2,13,1,5,2,4,1,3,22,3,10,1,4,2,1,2,52,2,1,1,2,1,2,1,2,1,1,1,33,2,2,1,1,1,1,1,1,3,1,2,3,1,3,1,2,1,2,1,1,1,1,1,2,1,7,19,1,2,1,2,1,2,1,2,1,2,1,1,1,1,7,1,1,1,2,1,22,3,10,3,2,5,1,51,2,1,9,1,37,2,2,1,3,2,2,2,1,26,3,17,3,13,1,11,1,3,22,2,1,10,1,3,3,2,1,2,50,2,3,1,2,1,2,1,45,1,2,1,3,1,2,2,1,2,1,2,1,3,1,2,1,2,1,1,1,2,1,1,1,1,18,31,22,3,10,6,3,3,2,48,10,1,1,47,2,2,2,2,7,11,2,2,5,19,23,3,3,23,2,1,10,2,2,1,2,3,2,1,2,45,1,1,1,1,1,1,2,1,2,1,3,8,1,1,2,1,2,1,1,32,2,1,3,2,1,1,1,1,2,1,2,1,2,1,2,1,3,1,1,1,1,21,2,12,2,1,2,1,2,3,2,24,3,9,1,9,2,4,1,43,1,12,3,4,5,15,10,10,2,4,1,1,1,2,6,1,8,1,2,2,3,24,1,1,11,7,4,1,25,3,9,1,1,1,1,3,1,2,1,1,2,1,1,1,41,1,1,3,1,3,1,2,1,2,3,4,7,3,1,2,1,1,1,1,1,2,1,7,1,1,1,1,1,1,1,1,1,1,2,6,3,3,1,1,1,1,1,1,1,1,1,1,1,1,1,2,1,2,30,1,2,1,1,1,2,1,2,4,1,1,5,1,25,3,13,8,1,4,38,3,14,1,3,4,12,9,7,8,10,5,1,8,11,29,1,10,4,6,1,26,2,2,13,2,1,4,2,3,36,1,1,5,1,1,1,2,1,2,1,2,1,1,3,6,18,1,7,17,6,3,1,1,1,1,1,1,1,1,1,1,3,1,2,1,34,1,3,1,1,2,1,1,5,1,27,4,22,3,35,1,20,3,8,17,7,15,8,3,9,8,1,31,8,3,5,1,28,4,1,21,2,1,32,1,2,3,1,1,1,1,1,2,1,2,1,1,1,2,1,2,4,13,10,8,11,12,3,1,1,1,1,1,1,1,1,1,1,2,1,3,1,1,1,31,1,2,1,3,2,5,1,30,5,20,3,30,2,23,1,4,54,3,3,8,8,2,31,1,4,2,4,1,32,4,1,10,1,1,1,1,1,1,1,1,1,3,28,1,1,5,1,1,1,3,1,2,1,2,1,3,1,4,1,4,52,4,1,3,1,1,2,1,1,1,2,2,1,5,1,31,6,4,35,4,9,8,1,3,25,3,29,4,51,5,3,1,1,7,10,1,30,6,3,37,4,8,8,1,1,2,22,1,2,5,1,1,1,1,1,2,1,1,1,2,1,2,1,2,1,2,1,1,1,1,1,1,5,50,4,1,1,1,1,2,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1,2,2,30,1,1,4,39,4,1,5,9,1,3,20,2,35,6,48,5,6,1,9,10,2,29,5,40,3,1,1,4,3,1,1,1,1,1,1,1,1,2,19,1,4,1,2,1,1,1,2,1,2,1,3,1,2,1,2,1,2,1,2,1,3,1,1,7,47,4,1,1,1,3,1,1,1,1,1,2,1,1,1,1,1,2,3,1,5,2,73,5,3,8,2,3,18,1,38,8,45,5,8,1,11,11,1,73,5,3,9,2,1,18,1,2,1,1,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,2,5,43,5,1,1,2,1,2,1,1,2,1,1,1,1,1,1,1,1,1,1,2,2,1,1,1,1,4,74,5,1,10,3,18,4,20,3,12,2,2,6,41,6,9,3,9,1,4,6,1,75,2,1,1,12,2,18,1,1,1,1,2,3,1,2,1,2,1,2,1,2,1,1,1,1,1,2,2,1,2,1,2,1,1,1,2,1,1,2,5,38,6,1,1,2,1,2,1,2,1,5,1,1,1,1,2,2,1,1,1,1,1,2,2,2,76,17,18,4,2,4,9,8,12,2,2,1,2,5,36,7,11,6,2,1,2,1,6,1,5,78,3,1,1,1,1,1,1,1,2,1,2,19,1,1,3,1,1,1,1,1,2,1,2,1,2,1,1,2,1,1,1,2,2,1,2,1,2,1,2,2,1,1,2,1,1,6,31,8,1,1,1,1,1,1,2,1,2,1,1,1,7,2,1,2,1,1,1,1,1,2,1,1,1,1,114,2,6,1,2,1,2,1,9,11,1,2,2,2,3,7,27,9,1,14,10,2,1,1,3,2,3,1,118,1,1,1,1,2,1,2,1,2,1,1,1,1,1,1,1,4,1,2,1,2,1,2,2,1,1,3,1,1,1,8,23,9,1,1,2,1,2,1,2,1,2,1,2,1,1,157,1,1,10,3,2,3,2,4,9,19,9,1,1,1,3,13,2,156,1,1,1,2,1,2,1,2,1,1,1,1,2,1,1,3,1,1,1,3,33,3,1,1,1,1,1,2,2,1,2,1,2,1,4,155,1,11,4,2,2,2,4,3,2,5,14,3,7,3,1,2,1,5,13,1,153,1,4,1,2,1,2,1,1,1,1,1,1,2,1,1,2,1,1,1,4,1,5,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,4,3,1,1,1,1,1,2,1,1,1,1,1,1,2,1,2,1,2,1,1,1,2,152,1,12,4,1,2,7,3,2,5,1,1,1,1,1,1,1,1,1,1,1,1,3,3,2,3,1,6,2,1,7,10,2,150,1,2,1,1,1,2,1,2,1,1,1,1,1,1,1,3,1,1,1,1,1,1,4,1,6,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,1,1,2,1,1,1,1,1,3,2,1,1,1,1,1,1,2,2,1,4,1,2,1,148,1,12,5,1,2,7,3,2,5,1,1,13,1,3,2,2,2,5,1,6,7,10,1,146,1,2,1,2,1,2,1,2,1,1,1,1,2,1,3,1,1,1,2,1,1,12,1,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1,2,1,1,3,1,1,9,1,2,1,1,1,1,1,2,1,1,1,2,1,2,1,143,1,1,13,6,3,4,15,1,10,1,1,1,3,20,7,10,142,1,3,1,2,1,2,1,2,1,1,1,1,1,1,1,1,4,1,1,1,16,2,1,1,1,1,1,1,1,1,1,1,2,1,2,21,1,1,1,2,1,1,2,2,1,2,1,1,1,140,1,14,7,4,2,17,2,10,2,3,12,1,9,6,2,8,1,137,2,2,1,2,1,2,1,2,1,2,1,1,1,1,1,1,1,12,3,1,3,1,3,1,1,1,1,1,2,1,1,1,1,1,1,4,1,1,1,12,9,1,1,1,1,1,3,2,1,2,1,2,2,134,1,15,7,12,1,3,1,3,1,3,1,3,2,12,15,9,5,2,1,9,2,131,1,3,1,2,1,2,1,2,1,2,1,1,1,1,1,2,1,11,1,1,2,1,1,1,2,1,2,1,1,3,1,1,1,3,1,3,1,3,4,1,2,1,2,1,2,1,2,9,1,1,1,1,3,2,2,1,2,1,3,1,129,1,15,8,11,3,2,1,1,1,5,1,1,5,9,3,17,10,3,1,4,9,1,127,1,2,1,1,1,2,1,2,1,2,1,1,1,1,1,1,1,2,1,10,2,3,2,1,1,1,4,12,9,5,1,2,1,2,1,5,10,1,1,1,1,1,1,1,2,2,1,2,1,2,2,123,2,15,8,10,1,2,3,4,1,4,12,11,16,10,8,10,2,121,1,2,1,2,1,2,1,2,1,2,1,1,1,1,1,2,1,1,9,2,1,2,3,4,1,1,1,1,13,13,3,1,3,1,2,1,1,1,3,9,1,1,1,1,1,1,1,2,2,1,2,1,4,2,118,1,14,9,9,1,5,3,6,2,13,13,17,9,8,12,2,115,1,3,1,2,1,2,1,2,1,1,1,1,1,1,1,1,1,1,10,1,1,4,1,1,2,2,1,3,1,14,14,4,1,3,1,4,1,3,10,1,1,1,1,1,1,2,2,1,2,1,2,1,3,1,112,2,12,1,1,7,11,3,4,1,1,2,2,1,3,1,14,14,18,10,7,13,1,109,1,1,3,1,1,1,2,1,2,2,1,2,1,1,1,1,1,1,11,1,3,2,1,1,1,1,2,2,1,2,1,15,15,4,1,2,1,2,1,3,1,3,10,1,2,1,1,1,1,1,2,1,2,1,2,1,3,1,105,3,12,1,1,2,1,5,12,1,1,3,2,3,1,2,5,1,15,15,19,11,8,11,2,98,2,3,5,1,2,1,2,1,1,1,1,2,1,2,1,1,1,1,12,1,1,1,2,1,1,1,3,1,2,4,1,16,15,1,3,1,3,1,3,1,3,1,3,12,1,1,1,1,1,1,1,2,2,2,1,1,1,3,98,1,1,14,4,1,2,1,4,12,3,1,2,1,5,1,2,4,1,16,15,21,12,6,1,11,98,2,3,1,1,1,1,2,1,2,1,1,2,1,1,2,1,1,1,1,13,1,3,1,2,1,3,1,1,1,2,2,1,1,17,15,1,3,1,2,1,2,1,3,1,3,1,3,12,1,1,1,1,2,1,1,1,1,1,1,2,1,1,1,98,2,5,2,3,2,1,5,1,17,1,1,6,1,3,3,2,2,1,1,17,16,22,13,2,1,12,98,2,1,1,1,1,1,3,1,1,1,2,1,1,1,1,18,1,1,1,5,1,1,1,2,3,2,2,1,18,16,5,1,4,1,2,1,2,1,2,1,2,14,1,1,1,1,1,1,1,2,1,1,1,1,101,6,1,4,2,2,19,3,1,5,3,2,3,2,2,1,18,16,24,13,10,136,1,3,1,2,1,2,3,2,2,1,1,1,1,1,19,17,3,1,2,1,3,1,3,1,4,1,3,14,1,1,1,1,1,1,1,137,1,1,6,1,2,3,2,2,1,3,1,19,17,25,154,2,1,1,5,1,1,1,1,1,1,1,2,2,1,3,20,18,6,1,2,1,2,1,2,1,3,1,5,151,2,4,5,5,4,6,20,19,25,148,2,2,4,2,1,2,4,1,1,3,4,1,1,20,19,3,1,2,1,3,1,4,1,2,1,2,1,1,1,2,145,2,2,2,4,2,1,2,4,1,1,3,4,1,20,20,28,141,2,2,2,2,2,1,1,2,1,2,2,1,1,1,1,2,1,1,2,1,21,20,1,6,1,2,1,2,1,2,1,3,1,4,1,4,138,1,2,2,2,2,2,4,1,2,2,3,1,2,1,1,2,22,21,30,134,2,1,1,1,1,2,2,2,2,3,1,1,1,1,1,1,1,2,1,2,1,1,1,23,21,3,1,2,1,3,1,2,1,3,1,3,1,3,1,2,1,2,132,1,2,1,1,4,2,2,2,3,5,1,1,2,1,2,1,1,1,23,22,32,127,2,1,1,1,1,1,1,3,1,1,1,2,2,3,4,1,1,1,1,1,1,2,1,1,24,23,4,1,2,1,4,1,2,1,2,1,2,1,3,1,6,124,2,2,1,1,3,1,3,1,4,2,3,4,1,5,3,25,23,34,120,2,2,2,1,1,3,1,2,1,1,1,3,2,2,1,1,2,1,1,1,4,2,26,24,4,1,3,1,2,1,3,1,3,1,2,1,3,1,1,1,1,1,3,117,2,2,2,4,6,3,3,2,2,1,1,2,3,4,28,25,34,60}

	reset:=>
		super!
		if MUSIC
			music(1)
		else
			music!

	next:=>
		if @cheatbutton.clicked
			@finish!
			@cheatstate\reset!
			return @cheatstate
		if @tt>@grace and (btnp(4) or btnp(5))
			@finish!
			@nextstate\reset!
			return @nextstate
		return self

	update:=>
		super!
		poke(0x3FFB,128)  -- cursor pointer
		@cheatbutton\update!
		@button\update!
		if @button.clicked
			MUSIC = not MUSIC
			if MUSIC
				music(1)
			else
				music!
			@button.label = "Music: #{MUSIC and "on" or "off"}"

	draw:=>
		super!
		-- draw image
		val_i=0
		run=0
		for y=0,136-1
			for x=0,240-1
				if run==0
					val_i=val_i+1
					run=@img_runs[val_i]
				run=run-1
				pix(x,y,@img_values[val_i])
		print("Press Z or X to continue", 10, 122, 12)
		@button\draw!
		@cheatbutton\draw!

class GameState extends State
	reset:=>
		super!
		game_init!
		t = 0

	update:=>
		super!
		ENDING_MODE = false
		-- Add a grace period
		if @tt > 30
			game_update!
			t += 1
 
	draw:=>
		super!
		map(camera.pos.x//8-1, camera.pos.y//8-1, 32, 19, 8-camera.pos.x%8-16, 8-camera.pos.y%8-16)
		map_text_draw!
		entity_list_draw!

		-- Draw barrier stopping player from exiting if there are enemies
		room = get_view_room!
		if enemy_in_room(room)
			draw_pos = get_draw_pos(room.pos)
			rectb(draw_pos.x, draw_pos.y, room.sz.x, room.sz.y, 8)

class EndState extends State
	reset:=>
		super!
		game_init!
		player = player_new(vecnew(6 * 8, 131 * 8))
		camera.pos = vecnew(player.pos.x - 4 * 8, player.pos.y - 8 * 8)
		-- Generate endless terrain
		for x = 0, WINDOW_W // 8
			@gen_col(x)
		ENDING_MODE = true
		t = 0

	update:=>
		super!
		-- Generate the column immediately to the right of the player
		if (player.pos.x % 8) == 0
			x = player.pos.x//8 + 23
			if x > WINDOW_W
				x -= WINDOW_W
			@gen_col(x)
		game_update!
		-- Despawn entities out of sight
		for i, v in ipairs(entity_list)
			if player.pos.x < WINDOW_W * 8 - 100 and player.pos.x - v.pos.x > 50
				v.rm_next_frame = true
		t += 1
 
	draw:=>
		super!
		-- Fixed camera
		camera.pos.x = player.pos.x - 56
		camera.pos.y = 118 * 8
		map(camera.pos.x//8-1, camera.pos.y//8-1, 32, 19, 8-camera.pos.x%8-16, 8-camera.pos.y%8-16)
		map_text_draw!
		entity_list_draw!

	gen_col:(x)=>
		-- Clear tiles
		for y = 122, 132
			mset(x, y, 0)
		-- Ground
		mset(x, 133, 33)
		-- Below ground
		ground_ids = {1, 17, 49}
		tile_id = ground_ids[math.random(#ground_ids)]
		mset(x, 134, tile_id)

		ground_placed = false
		-- Flowers
		tile_id = math.random(18, 50)
		if tile_id < 29
			ground_placed = true
			mset(x, 131, tile_id)
			mset(x, 132, tile_id + 16)
		-- Slimes
		if not ground_placed and math.random(0, 20) == 0
			ground_placed = true
			mset(x, 132, 6)
		-- Gem spawner
		tile_id = math.random(12, 100)
		if not ground_placed and tile_id <= 15
			ground_placed = true
			mset(x, 132, tile_id)
		
		-- Flyers
		if math.random(0, 40) == 0
			mset(x, 125, 7)

		for y = 122, 132
			spawn_map_entity(x, y)


endState = EndState!
titleState = TitleState(endState)
gameState = GameState!
state=titleState

export map_text = (x, y, text) ->
	pos = vecnew(x, y)
	draw_pos = get_draw_pos(vecmul(pos, 8))
	print(text, draw_pos.x, draw_pos.y, 12, false, 1, true)

export map_text_draw = ->
	map_text(6, 6, "Arrow keys to move")
	map_text(6, 7, "Z to jump")
	map_text(6, 8, "X to throw crystal")
	
	map_text(36, 5, "Use arrow keys while holding X to aim")

	map_text(98, 91, "You win")
	map_text(98, 92, "A game by congusbongus and TripleCubed")
	map_text(98, 93, "Thanks for playing")

export BOOT = ->
	titleState.nextstate = gameState
	gameState.nextstate = titleState
	endState.nextstate = titleState
	state\reset!

export enemy_in_room = (room) ->
	cond = false
	for i, v in ipairs(entity_list)
		if v.is_spawner != nil and in_rect(v.pos, room.pos, room.sz)
			cond = true

	for i, v in ipairs(entity_list)
		if v.layer == LAYER_ENEMIES and in_rect(v.pos, room.pos, room.sz) and cond
			return true

	return false

export copy_room = (view_room) ->
	current_room_copy = {pos: veccopy(view_room.pos), sz: veccopy(view_room.sz), list: {}}

	for x = 0, view_room.sz.x//8
		table.insert(current_room_copy.list, {})
		for y = 0, view_room.sz.y//8
			m = mget(x + view_room.pos.x//8, y + view_room.pos.y//8)
			table.insert(current_room_copy.list[x + 1], m)

export reset_room = ->
	crc = current_room_copy
	for x = crc.pos.x//8, crc.pos.x//8 + crc.sz.x //8
		for y = crc.pos.y//8, crc.pos.y//8 + crc.sz.y//8
			mset(x, y, crc.list[x-crc.pos.x//8 + 1][y-crc.pos.y//8 + 1])

export clear_all_entities = ->
	for i, v in ipairs(entity_list)
		if v.is_change_scene != nil
			continue

		if v != player
			v.rm_next_frame = true

export replace_respawn_tile = ->
	for x = 0, WINDOW_W - 1
		for y = 0, WINDOW_H - 1
			if mget(x, y) == MAP_RESPAWN
				mset(x, y, MAP_RESPAWN_INVISIBLE)

export load_room = (view_room, reset) ->
	if reset
		clear_all_entities()
		if current_room_copy != nil
			reset_room()
	copy_room(view_room)
	inventory = {}
	-- Spawn enemies
	for x = view_room.pos.x//8, view_room.pos.x//8 + view_room.sz.x//8
		for y = view_room.pos.y//8, view_room.pos.y//8 + view_room.sz.y//8
			spawn_map_entity(x, y)

export spawn_map_entity = (x, y) ->
	m = mget(x, y)
	spawn_pos = vecnew(x*8, (y-1)*8)
	if m == MAP_ENEMY_SLIME
		mset(x, y, 0)
		enemy_new(spawn_pos)
	elseif m == MAP_ENEMY_FLYING_CRITTER
		mset(x, y, 0)
		enemy_flying_critter_new(spawn_pos)
	elseif m == MAP_CRYSTAL_YELLOW
		mset(x, y, 0)
		crystal_collectable_new(spawn_pos, CRYSTAL_YELLOW)
	elseif m == MAP_CRYSTAL_RED
		mset(x, y, 0)
		crystal_collectable_new(spawn_pos, CRYSTAL_RED)
	elseif m == MAP_CRYSTAL_BLUE
		mset(x, y, 0)
		crystal_collectable_new(spawn_pos, CRYSTAL_BLUE)
	elseif m == MAP_CRYSTAL_GREEN
		mset(x, y, 0)
		crystal_collectable_new(spawn_pos, CRYSTAL_GREEN)
	elseif m == MAP_CRYSTAL_SPAWNER_YELLOW
		mset(x, y, 0)
		crystal_spawner_new(spawn_pos, CRYSTAL_YELLOW)
	elseif m == MAP_CRYSTAL_SPAWNER_RED
		mset(x, y, 0)
		crystal_spawner_new(spawn_pos, CRYSTAL_RED)
	elseif m == MAP_CRYSTAL_SPAWNER_BLUE
		mset(x, y, 0)
		crystal_spawner_new(spawn_pos, CRYSTAL_BLUE)
	elseif m == MAP_CRYSTAL_SPAWNER_GREEN
		mset(x, y, 0)
		crystal_spawner_new(spawn_pos, CRYSTAL_GREEN)
	elseif reset and m == MAP_RESPAWN_INVISIBLE
		player.pos = vecnew(x * 8, y * 8 - 8)

export game_init = ->
	init_view_room_list!
	player = player_new(vecnew(6 * 8, 12 * 8))
	camera.pos = vecnew(0, 0)
	if MUSIC
		music(0,-1,-1,true,true)

export TIC = ->
	cls(0)
	state\update!
	state\draw!
	state=state\next!

export game_update = ->
	entity_list_update!
	entity_list_overlaps!
	entity_list_ckrm!
	camera_update!

	replace_respawn_tile!

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
	resize(vecnew(0, 3), vecnew(2, 1))
	resize(vecnew(3, 1), vecnew(2, 2))
	resize(vecnew(1, 5), vecnew(2, 1))

	for i = #view_room_list, 1, -1
		v = view_room_list[i]
		if v.rm
			table.remove(view_room_list, i)

export get_view_room = ->
	if ENDING_MODE
		return nil
	for i, v in ipairs(view_room_list)
		if (in_rect(vecadd(player.pos, vecnew(PLAYER_W/2, PLAYER_H/2)), v.pos, v.sz))
			return v
	return nil

export get_draw_pos = (vec) ->
	v = vecsub(vecfloor(vec), vecfloor(camera.pos))
	if v.x < 0
		v.x += WINDOW_W * 8
	if v.x >= WINDOW_W * 8
		v.x -= WINDOW_W * 8
	return v

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
	if view_room != nil
		snap_camera_pos_to_view_room(nx_camera_pos, view_room)

		if not camera_tweening and view_room != prev_view_room
			load_room(view_room, false)
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

	p.visible = true
	p.death_at = true
	return p

export player_movement = (player) ->
	if ENDING_MODE
		player.right_dir = true
		player.fvec.x = 1
	if btn(2)
		player.right_dir = false
		player.fvec.x -= 1
	if btn(3)
		player.right_dir = true
		player.fvec.x += 1
	if btnp(4) and player.down_col
		player.gravity = -2
		sfx(SFX_JUMP)

export player_aim_mode = (player) ->
	if btnp(BTN_THROW)
		if player.right_dir
			player.aim_rad = PI -- 180 degree
		else
			player.aim_rad = 0

	target_angle = nil
	if btn(0)
		if btn(2)
			-- upleft
			target_angle = PI / 4
		elseif btn(3)
			-- upright
			target_angle = 3*PI / 4
		else
			-- up
			target_angle = PI / 2
	elseif btn(2)
		-- left
		target_angle = 0
	elseif btn(3)
		-- right
		target_angle = PI
	elseif btn(1)
		-- down
		if player.aim_rad < PI / 2
			target_angle = 0
		else
			target_angle = PI
	if target_angle != nil
		dr = clamp(target_angle - player.aim_rad, -0.05, 0.05)
		player.aim_rad += dr

	player.right_dir = player.aim_rad >= PI / 2
	
	if btnp(4) and player.down_col
		player.gravity = -2
		sfx(SFX_JUMP)

export crystal_throw = (pos, dir) ->
	if #inventory != 0
		if inventory[1] == CRYSTAL_YELLOW
			crystal_no_bounce_new(pos, dir)
		else if inventory[1] == CRYSTAL_RED
			crystal_bounce_new(pos, dir)
		else if inventory[1] == CRYSTAL_BLUE
			crystal_fast_new(pos, dir)
		else if inventory[1] == CRYSTAL_GREEN
			crystal_slow_new(pos, dir)

		table.remove(inventory, 1)

export player_update = (player) ->
	if player.visible
		if player.attack > 0
			player.attack -= 1
		if not btn(BTN_THROW)
			player_movement(player)

			-- auto throw crystal if ending mode
			throw = player.prev_btn_6_holding
			if ENDING_MODE and #inventory > 0
				-- Check if there are enemies nearby to hit
				closest_enemy = {nil, nil}
				closest_ground_enemy = {nil, nil}
				closest_air_enemy = {nil, nil}
				for i, v in ipairs(entity_list)
					if v.layer == LAYER_ENEMIES
						d = vecsub(v.pos, player.pos)
						dist = veclength(d)
						if dist < 150
							if closest_enemy[2] == nil or closest_enemy[2] > dist
								closest_enemy = {d, dist}
							if d.y > -10
								if closest_ground_enemy[2] == nil or closest_ground_enemy[2] > dist
									closest_ground_enemy = {d, dist}
							else
								if closest_air_enemy[2] == nil or closest_air_enemy[2] > dist
									closest_air_enemy = {d, dist}
				if inventory[1] == CRYSTAL_YELLOW
					-- Attack closest enemy
					if closest_enemy[1] != nil
						throw = true
						player.aim_rad = PI - math.atan2(-closest_enemy[1].y, closest_enemy[1].x)
						if player.aim_rad > PI
							player.aim_rad = PI
				else if inventory[1] == CRYSTAL_RED
					-- Attack closest enemy at an angle
					if closest_enemy[1] != nil
						throw = true
						player.aim_rad = PI - math.atan2(-closest_enemy[1].y, closest_enemy[1].x)
						if player.aim_rad > PI
							player.aim_rad = PI
				else if inventory[1] == CRYSTAL_BLUE
					-- Attack if there's a ground enemy
					if closest_ground_enemy[1] != nil
						throw = true
						player.aim_rad = PI * 3 / 4
				else if inventory[1] == CRYSTAL_GREEN
					-- Attack closest ground enemy if it's close enough
					if closest_ground_enemy[1] != nil and closest_ground_enemy[1].x < 50 and closest_ground_enemy[1].x > 5
						throw = true
						player.aim_rad = PI * 3 / 4
			if throw
				dir = vec_from_rad(player.aim_rad)
				crystal_throw(player.pos, vecmul(dir, 4.5))
				sfx(SFX_THROW)
				player.attack = 15
				player.attack_t = t
				player.attack_row = 1 - player.attack_row

		else
			if not player.prev_btn_6_holding
				sfx(SFX_AIMING)
			player_aim_mode(player)

		player.prev_btn_6_holding = btn(BTN_THROW)

		if not ENDING_MODE
			-- Death from enemies
			for i, v in ipairs(entity_list)
				if v.layer == LAYER_ENEMIES or (v.atk_player != nil and v.atk_player == true)
					if rect_collide(player.pos, player.sz, entity_get_center(v), vecnew(3,3))
						if v.atk_player != nil and v.atk_player == true
							v.rm_next_frame = true
						player.visible = false
						player.death_at = t
						sfx(SFX_DEATH)
						death_animation_new(entity_get_center(player))

	if not player.visible
		if t - player.death_at == 10
			change_scene!
		if t - player.death_at == 50
			load_room(get_view_room!, true)
			player.visible = true
			inventory = {}

export player_draw = (player) ->
	if not player.visible
		return

	draw_pos = get_draw_pos(player.pos)

	spr_id = 256
	if player.prev_btn_6_holding
		spr_id = 352
	elseif player.attack > 0
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
		if player.fvec.x != 0 and not btn(BTN_THROW)
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

	-- Palette swap based on crystal
	if #inventory == 0
		palset(5,13)
		palset(6,14)
	else
		ii = inventory[1]+1
		palset(5,CRYSTAL_COLORS[ii][1])
		palset(6,CRYSTAL_COLORS[ii][2])
	spr(spr_id, draw_pos.x - 4, draw_pos.y - 2, 0, 1, flip, 0, 2, 2)
	palset!


	if btn(BTN_THROW)
		dir = vec_from_rad(player.aim_rad)
		player_center = vecadd(draw_pos, vecnew(PLAYER_W/2, PLAYER_H/2))
		for i = 0, 30
			added = vecadd(player_center, vecmul(dir, 1))
			if i > 8 and (t // 5 - i) % 4 == 0
				line(player_center.x, player_center.y, added.x, added.y, 12)
			player_center = added


	for i, v in ipairs(inventory)
		crystal_spr_id = 508
		crystal_spr_id += v
		pos = vecnew(4 + i * 10, 4)
		spr(crystal_spr_id, pos.x, pos.y, 0, 1, 0, 0, 1, 1)

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

export blackhole_new = (pos, range) ->
	e = entity_new(pos, vecnew(8, 8), blackhole_update, blackhole_draw, nil)
	e.default_physic = false
	e.t = 200

	return e

export blackhole_update = (e) ->
	e.t -= 1
	if e.t == 0
		e.rm_next_frame = true
		timed_ent_new(e.pos, 16, {414, 412}, 8, vecnew(-16, -16), 2, 2, 2)
		sfx(SFX_UNSUMMON)
	if e.t % WATER_SPAWN_INTERVAL == 0
		water_new(vecadd(e.pos, vecnew(-6, -8)), vecnew((math.random() - 0.5) * 0.7, -2))

export blackhole_draw = (e) ->
	spr_id = 388
	if t % 10 < 5
		spr_id += 2
	draw_pos = vecadd(get_draw_pos(e.pos), vecmul(vecnew(math.random(-1, 1), math.random(-1, 1)), 0.6))
	spr(spr_id, draw_pos.x - 8, draw_pos.y - 8, 0, 1, 0, 0, 2, 2)

export angel_new = (pos, following) ->
	angel = entity_new(pos, vecnew(8, 8), angel_update, angel_draw, nil)
	angel.gravity_enabled = false
	angel.t = 0
	angel.die_t = 60
	
	angel.following = following
	angel.following_range = 20
	angel.following_rad_margin = 0.05
	angel.following_rad = rndf(PI*angel.following_rad_margin, PI - PI*angel.following_rad_margin)
	angel.following_rad_right = false
	angel.sight_range = 60
	
	angel.attack_timer_max = 1 * 60
	angel.attack_timer = angel.attack_timer_max
	return angel

export angel_in_sight = (e) ->
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
	dest = vecadd(vecmul(dir, e.following_range), e.following.pos)

	dir_dest = vecsub(dest, e_center)
	e.fvec = vecmul(dir_dest, 0.05)

export angel_attack = (e) ->
	e_center = entity_get_center(e)
	following_center = entity_get_center(e.following)
	dir = vecsub(following_center, e_center)

	e.attack_timer -= 1
	if e.attack_timer <= 0
		e.attack_timer = e.attack_timer_max
		projectile_laser_new(e_center, e.following, 11)
		sfx(SFX_ANGEL_HIT)
		timed_ent_new(e.following.pos, 5, {411}, 5, vecnew(-4, -4), 2, 1, 1)

export angel_update = (e) ->
	e_center = entity_get_center(e)
	following_center = entity_get_center(e.following)
	dist = veclength(vecsub(e_center, following_center))

	if dist <= e.sight_range
		angel_in_sight(e)
		angel_attack(e)

	e.t -= 1
	if e.t <= 0
		e.t = 16

	if e.following == nil or e.following.hp <= 0
		e.die_t -= 1
		if e.die_t == 0
			e.rm_next_frame = true
			timed_ent_new(e.pos, 16, {414, 412}, 8, vecnew(-16, -16), 2, 2, 2)
			sfx(SFX_UNSUMMON)

export angel_draw = (angle) ->
	draw_pos = get_draw_pos(angle.pos)
	spr_id = 384
	if angle.t % 16 < 8
		spr_id += 2
	spr(spr_id, draw_pos.x - 8, draw_pos.y - 8, 0, 1, 0, 0, 2, 2)

export croc_new = (pos, right_dir) ->
	e = entity_new(pos, vecnew(16, 16), croc_update, croc_draw, nil)
	e.right_dir = right_dir
	e.t = 180
	e.attack_t = 0
	return e

export croc_update = (e) ->
	e.t -= 1
	if e.t == 0
		e.rm_next_frame = true
		timed_ent_new(e.pos, 16, {414, 412}, 8, vecnew(-16, -16), 2, 2, 2)
		sfx(SFX_UNSUMMON)
	if e.right_col or e.left_col
		e.right_dir = not e.right_dir
	if e.right_dir
		e.fvec.x = 0.7
	else
		e.fvec.x = -0.7
	e.attack_t -= 1
	if e.attack_t <= 0
		e.attack_t = 5
		-- Attack all target in range
		targets = {}
		for i, v in ipairs(entity_list)
			if v.layer == LAYER_ENEMIES and v.hp > 0 and veclength(vecsub(v.pos, e.pos)) <= CROC_RANGE
				v.hp -= 3
				sfx(SFX_IMP_ATTACK)
				timed_ent_new(v.pos, 5, {411}, 5, vecnew(-4, -4), 2, 1, 1)

export croc_draw = (e) ->
	spr_id = 440
	if t % 20 < 10
		spr_id += 2
	draw_pos = get_draw_pos(e.pos)
	flip = 1
	if e.right_dir
		flip = 0
	spr(spr_id, draw_pos.x, draw_pos.y, 0, 1, flip, 0, 2, 2)

-- Fish
export crystal_fast_new = (pos, efvec) ->
	crystal = entity_new(pos, vecnew(8, 8), crystal_fast_update, crystal_fast_draw, nil)
	crystal.external_fvec = veccopy(efvec)
	return crystal

export crystal_fast_update = (crystal) ->
	spawn = false
	if entity_col(crystal)
		spawn = true

	for i, v in ipairs(entity_list)
		if v.layer == LAYER_ENEMIES and rect_collide(crystal.pos, crystal.sz, v.pos, v.sz)
			spawn = true
			break

	if spawn
		crystal.rm_next_frame = true
		center = entity_get_center(crystal)
		blackhole_new(center)
		timed_ent_new(center, 10, {412, 414}, 5, vecnew(-16, -16), 2, 2, 2)
		sfx(SFX_SUMMON)

export crystal_fast_draw = (crystal) ->
	draw_pos = get_draw_pos(crystal.pos)
	spr_id = 510
	spr(spr_id, draw_pos.x, draw_pos.y, 0, 1, 0, 0, 1, 1)

-- Angel
export crystal_no_bounce_new = (pos, efvec) ->
	crystal = entity_new(pos, vecnew(8, 8), crystal_no_bounce_update, crystal_no_bounce_draw, nil)
	crystal.gravity_enabled = false
	crystal.efvec = veccopy(efvec)

export crystal_no_bounce_update = (crystal) ->
	crystal.fvec = crystal.efvec
	crystal_center = entity_get_center(crystal)
	if entity_col(crystal)
		crystal.rm_next_frame = true
		timed_ent_new(crystal_center, 10, {412, 414}, 5, vecnew(-8, -8), 1, 2, 2)
		sfx(SFX_CRYSTAL_BOUNCE)

	for i, v in ipairs(entity_list)
		if v.layer == LAYER_ENEMIES
			dist = veclength(vecsub(crystal.pos, v.pos))
			if dist <= 30
				crystal.rm_next_frame = true
				angel_new(crystal.pos, v)
				timed_ent_new(crystal_center, 10, {412, 414}, 5, vecnew(-16, -16), 2, 2, 2)
				sfx(SFX_SUMMON)
				return

export crystal_no_bounce_draw = (crystal) ->
	draw_pos = get_draw_pos(crystal.pos)
	spr_id = 508
	spr(spr_id, draw_pos.x, draw_pos.y, 0, 1, 0, 0, 1, 1)

-- Imp
export crystal_bounce_new = (pos, efvec) ->
	crystal = entity_new(pos, vecnew(8, 8), crystal_bounce_update, crystal_bounce_draw, nil)
	crystal.external_fvec = veccopy(efvec)

export crystal_bounce_update = (crystal) ->
	trigger = false
	center = vecadd(crystal.pos, vecnew(4, 4))
	for i, v in ipairs(entity_list)
		if v.layer == LAYER_ENEMIES and v.hp > 0 and veclength(vecsub(v.pos, center)) <= CRYSTAL_TRIGGER_RADIUS
			v.hp -= CRYSTAL_HIT_DMG
			trigger = true
			break
	if trigger or veclength(crystal.external_fvec) < CRYSTAL_SUMMON_VEL
		crystal.rm_next_frame = true
		imp_new(crystal.pos)
		timed_ent_new(crystal.pos, 10, {412, 414}, 5, vecnew(-16, -16), 2, 2, 2)
		sfx(SFX_SUMMON)
		return
	bounce = 0
	if crystal.up_col or crystal.down_col
		crystal.external_fvec.y *= -1
		bounce += math.abs(crystal.external_fvec.y)
	if crystal.left_col or crystal.right_col
		crystal.external_fvec.x *= -1
		bounce += math.abs(crystal.external_fvec.x)
	if bounce > 1
		sfx(SFX_CRYSTAL_BOUNCE,70,30,0,15,math.min(15,bounce - 1))

export crystal_bounce_draw = (crystal) ->
	draw_pos = get_draw_pos(crystal.pos)
	spr_id = 509
	spr(spr_id, draw_pos.x, draw_pos.y, 0, 1, 0, 0, 1, 1)
	if DEBUG_DRAW_HITBOXES
		center = vecadd(draw_pos, vecnew(4, 4))
		circb(center.x, center.y, CRYSTAL_TRIGGER_RADIUS, 11)

-- Croc
export crystal_slow_new = (pos, efvec) ->
	crystal = entity_new(pos, vecnew(8, 8), crystal_slow_update, crystal_slow_draw, nil)
	crystal.gravity_enabled = true
	crystal.efvec = vecmul(efvec, 0.7)
	return crystal

export crystal_slow_update = (crystal) ->
	crystal.fvec = crystal.efvec
	spawn = false
	if entity_col(crystal)
		spawn = true

	if spawn
		crystal.rm_next_frame = true
		center = vecadd(entity_get_center(crystal), vecnew(0, -12))
		croc_new(center, crystal.efvec.x > 0)
		timed_ent_new(center, 10, {412, 414}, 5, vecnew(-16, -16), 2, 2, 2)
		sfx(SFX_SUMMON)

export crystal_slow_draw = (crystal) ->
	draw_pos = get_draw_pos(crystal.pos)
	spr_id = 511
	spr(spr_id, draw_pos.x, draw_pos.y, 0, 1, 0, 0, 1, 1)

export projectile_explosion_new = (pos, range, atk_player, atk_enemy) ->
	pjt = entity_new(pos, vecnew(0, 0), projectile_explosion_update, projectile_explosion_draw, nil)
	pjt.default_physic = false
	pjt.range = range
	for i, v in ipairs(entity_list)
		enemy_center = entity_get_center(v)
		dist = veclength(vecsub(enemy_center, pjt.pos))
		if atk_enemy and v.layer == LAYER_ENEMIES and dist <= range
			dir = vecnormalized(vecsub(enemy_center, pjt.pos))
			v.external_fvec = vecmul(dir, 3)
			v.hp -= 10

	pjt.exist_for = 20

export projectile_explosion_update = (pjt) ->
	pjt.exist_for -= 1
	if pjt.exist_for <= 0
		pjt.rm_next_frame = true

export projectile_explosion_draw = (pjt) ->
	draw_pos = get_draw_pos(pjt.pos)
	circb(draw_pos.x, draw_pos.y, pjt.range, 12)

export projectile_laser_new = (pos, target, color) ->
	pjt = entity_new(pos, vecnew(0, 0), projectile_laser_update, projectile_laser_draw, nil)
	pjt.target = target
	pjt.default_physic = false
	pjt.color = color
	target.hp -= 10
	pjt.exist_for = 20
	return pjt

export projectile_laser_update = (pjt) ->
	pjt.exist_for -= 1
	if pjt.exist_for <= 0
		pjt.rm_next_frame = true

export projectile_laser_draw = (pjt) ->
	draw_pos = get_draw_pos(pjt.pos)
	target_pos = get_draw_pos(entity_get_center(pjt.target))
	line(draw_pos.x, draw_pos.y, target_pos.x, target_pos.y, pjt.color)

export projectile_new = (pos, dir, atk_player, atk_enemies, color) ->
	pjt = entity_new(pos, vecnew(1, 1), projectile_update, projectile_draw, nil)
	pjt.dir = veccopy(vecnormalized(dir))
	pjt.atk_player = atk_player
	pjt.atk_enemies = atk_enemies
	pjt.color = color

	pjt.gravity_enabled = false
	return pjt

export projectile_update = (pjt) ->
	pjt.fvec = vecmul(pjt.dir, 1.5)
	if entity_col(pjt)
		pjt.rm_next_frame = true

export projectile_draw = (pjt) ->
	draw_pos = get_draw_pos(pjt.pos)
	tail_pos = vecadd(draw_pos, vecmul(pjt.dir, 5))
	line(draw_pos.x, draw_pos.y, tail_pos.x, tail_pos.y, pjt.color)

export water_new = (pos, fvec) ->
	e = entity_new(pos, vecnew(8, 8), water_update, water_draw, nil)
	e.t = 200
	e.layer = LAYER_WATER
	e.external_fvec = fvec
	return e

export water_update = (e) ->
	e.t -= 1
	if e.t == 0
		e.rm_next_frame = true
	
	center = entity_get_center(e)
	for i, v in ipairs(entity_list)
		enemy_center = entity_get_center(v)
		dist = veclength(vecsub(center, enemy_center))
		-- Repel enemies
		if v.layer == LAYER_ENEMIES and dist <= WATER_RADIUS
			dir = vecnormalized(vecsub(center, enemy_center))
			v.external_fvec = vecadd(v.external_fvec, vecmul(dir, -1))
			v.external_fvec.y -= 0.3	-- buoyancy
		if v.layer == LAYER_WATER and dist <= WATER_RADIUS
			dir = vecnormalized(vecsub(center, enemy_center))
			v.external_fvec = vecadd(v.external_fvec, vecmul(dir, -0.3))
	
export water_draw = (e) ->
	draw_pos = get_draw_pos(entity_get_center(e))
	circ(draw_pos.x, draw_pos.y, WATER_RADIUS, 9)

export enemy_flying_critter_new = (pos) ->
	e = entity_new(pos, vecnew(8, 8), enemy_flying_critter_update, enemy_flying_critter_draw, nil)
	e.t = 20
	e.hp = 20
	e.layer = LAYER_ENEMIES
	e.gravity_enabled = false

	e.following = player
	e.following_range = rndf(50, 60)
	e.following_rad_margin = 0.05
	e.following_rad = rndf(PI*e.following_rad_margin, PI - PI*e.following_rad_margin)
	e.following_rad_right = false
	if dice(1, 2)
		e.following_rad_right = true
	e.sight_range = e.following_range + 40

	e.attack_timer_max = 4 * 60
	e.attack_timer = rndf(2 * 60, e.attack_timer_max)

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
	e.t -= 1
	if e.t == 0
		e.t = 20
	if e.hp <= 0
		e.rm_next_frame = true
	e_center = entity_get_center(e)
	following_center = entity_get_center(e.following)
	dist = veclength(vecsub(e_center, following_center))

	if dist <= e.sight_range
		enemy_flying_critter_in_sight(e)
		enemy_flying_critter_attack(e)

export enemy_flying_critter_draw = (e) ->
	draw_pos = get_draw_pos(e.pos)
	spr_id = 448
	if e.t < 10
		spr_id += 2

	spr(spr_id, draw_pos.x - 4, draw_pos.y - 4, 0, 1, 0, 0, 2, 2)

export enemy_new = (pos) ->
	e = entity_new(pos, vecnew(SLIME_W, SLIME_H), enemy_update, enemy_draw, nil)
	e.t = 20
	e.hp = 20
	e.layer = LAYER_ENEMIES
	e.dx = 1
	if math.random(0, 1) == 0
		e.dx = -1
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
			sfx(SFX_IMP_ATTACK)
			timed_ent_new(target.pos, 5, {411}, 5, vecnew(-4, -4), 2, 1, 1)
	
export imp_draw = (imp) ->
	spr_id = 444
	if imp.t % 20 < 10
		spr_id += 2
	flip = 0

	draw_pos = get_draw_pos(imp.pos)
	circb(draw_pos.x, draw_pos.y, IMP_RANGE, 8)
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
			if (map_solid(pos.x//8, pos.y//8) or map_up_col(pos.x//8, pos.y//8)) and pos.y == floor2(pos.y, 8)
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
	-- Wrap left/right world
	if e.pos.x < 0
		e.pos.x += WINDOW_W * 8
	if e.pos.x >= WINDOW_W * 8
		e.pos.x -= WINDOW_W * 8
	
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

export crystal_collectable_new = (pos, crystal_type) ->
	e = entity_new(pos, vecnew(8, 8), crystal_collectable_update, crystal_collectable_draw, nil)
	e.default_physic = false
	e.crystal_type = crystal_type
	e.t = 40

export crystal_collectable_update = (e) ->
	if e.t > 0
		e.t -= 1
	if rect_collide(e.pos, e.sz, player.pos, player.sz) and #inventory < 3
		e.rm_next_frame = true
		table.insert(inventory, e.crystal_type)
		sfx(SFX_CRYSTAL_GET)

export crystal_collectable_draw = (e) ->
	draw_pos = get_draw_pos(e.pos)
	spr_id = 0
	if e.crystal_type == CRYSTAL_YELLOW
		spr_id = 508
	elseif e.crystal_type == CRYSTAL_RED
		spr_id = 509
	elseif e.crystal_type == CRYSTAL_BLUE
		spr_id = 510
	elseif e.crystal_type == CRYSTAL_GREEN
		spr_id = 511
	if e.t == 0 or e.t % 10 < 5
		spr(spr_id, draw_pos.x, draw_pos.y, 0, 1, 0, 0, 1, 1)

export crystal_spawner_new = (pos, crystal_type) ->
	e = entity_new(pos, vecnew(8, 8), crystal_spawner_update, crystal_spawner_draw, nil)
	e.cooldown_max = 3 * 60
	e.cooldown = 60
	e.has_crystal = false
	e.default_physic = false
	e.crystal_type = crystal_type
	e.is_spawner = true

export crystal_spawner_update = (e) ->
	e.cooldown -= 1
	if e.cooldown <= 0 and not e.has_crystal
		e.has_crystal = true
		crystal_collectable_new(e.pos, e.crystal_type)

	if rect_collide(e.pos, e.sz, player.pos, player.sz) and e.has_crystal and #inventory < 3
		e.has_crystal = false
		e.cooldown = e.cooldown_max

export crystal_spawner_draw = (e) ->
	draw_pos = get_draw_pos(e.pos)
	spr(507, draw_pos.x, draw_pos.y + 8, 0, 1, 0, 0, 1, 1)

export change_scene = () ->
	e = entity_new(vecnew(0, WINDOW_H), vecnew(WINDOW_W, WINDOW_H*1.5), change_scene_update, change_scene_draw, nil)
	e.is_change_scene = true

export change_scene_update = (e) ->
	e.pos.y -= 3
	if e.pos.y + e.sz.y < 0
		e.rm_next_frame = true
	e.default_physic = false

export change_scene_draw = (e) ->
	rect(e.pos.x, e.pos.y, e.sz.x, e.sz.y, 0)

export death_animation_new = (pos) ->
	e = entity_new(pos, vecnew(0, 0), death_animation_update, death_animation_draw, nil)
	e.r_max = 40
	e.r = 0
	e.default_physic = false

export death_animation_update = (e) ->
	e.r += 2
	if e.r >= e.r_max
		e.rm_next_frame = true

export death_animation_draw = (e) ->
	draw_pos = get_draw_pos(e.pos)
	circb(draw_pos.x, draw_pos.y, e.r, 2)
	circb(draw_pos.x, draw_pos.y, e.r-1, 2)

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

		-- Keep player in room if there are still enemies
		if not ENDING_MODE and v == player
			room = get_view_room!
			if enemy_in_room(room)
				if player.pos.x < room.pos.x
					player.pos.x = room.pos.x
				if player.pos.x + player.sz.x > room.pos.x + room.sz.x
					player.pos.x = room.pos.x + room.sz.x - player.sz.x
				if player.pos.y < room.pos.y
					player.pos.y = room.pos.y
				if player.pos.y + player.sz.y >= room.pos.y + room.sz.y
					player.pos.y = room.pos.y + room.sz.y - player.sz.y
					v.down_col = true
					v.gravity = 1

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

					sfx(SFX_ANGEL_HIT)

export entity_list_draw = () ->
	for i, v in ipairs(entity_list)
		if v.is_change_scene != nil
			continue
		v.draw(v)

	for i, v in ipairs(entity_list)
		if v.is_change_scene != nil
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
	return m == 1 or m == 17 or m == 33 or m == 49

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
	if len == 0
		return { x: 0, y: 0 }
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

export clamp = (v, min, max) ->
	return math.min(math.max(v, min), max)

-- set c0 to be c1 color, call pal() to reset
export palset=(c0,c1)->
	if(c0==nil and c1==nil)
		for i=0,15
			poke4(0x3FF0*2+i,i)
	else
		poke4(0x3FF0*2+c0,c1)

-- <TILES>
-- 001:fdedffefdfefffedeedfeeddfddffedfeeffedffdffeedfedfeeddfefedfdfef
-- 002:655656566766767677777777fdeedeeff0ee0e0f000000000000000000000000
-- 003:000000000000000000000000000000000f0e0e00fdeedeeffdeedeefffffffff
-- 004:09ba00009ba000009ba000009ba000009ba000009ba000009ba0000009ba0000
-- 005:0000ab9000000ab900000ab900000ab900000ab900000ab900000ab90000ab90
-- 006:0000000000077000007557000755557075f55f57755555577555555707777770
-- 007:000000000000000000999990999444999994f499009444900099999000000000
-- 008:0000000000000000000440000040040000400400000440000000000000000000
-- 009:0000000000000000000880000080080000800800000880000000000000000000
-- 010:0000000000000000000bb00000b00b0000b00b00000bb0000000000000000000
-- 011:0000000000000000000550000050050000500500000550000000000000000000
-- 012:000000000000000000044000000440000000000000000000eeeeeeeeeeeeeeee
-- 013:000000000000000000088000000880000000000000000000eeeeeeeeeeeeeeee
-- 014:0000000000000000000bb000000bb0000000000000000000eeeeeeeeeeeeeeee
-- 015:000000000000000000055000000550000000000000000000eeeeeeeeeeeeeeee
-- 016:0000000000100100011111100111111000111100000110000000000000000000
-- 017:fddefedfdffedefddefddfeefefffeddddeedfdffddffffdeffeddfefeeefdff
-- 019:0000000000000000000000000000000000000000000000000000000000400000
-- 022:0000000000000000000000000000000000000000000000000000000000000300
-- 024:0000000000000000000000000000000000000000000000000000000000b00000
-- 033:655656566766767677777777fddffedfedffedffeffeeffedfdddfeefefffeef
-- 034:0000000000010000001410000001000000060000000600000076000000076000
-- 035:04c400000040000000600b000060b4b000600b00006006000607006706770760
-- 036:0000000000000000000000000006000000060000000060000070600000076000
-- 037:0000000000100000014100000010000000600000060000000600000076700000
-- 038:0000343000000300000006000000060000000600000076000000076000000760
-- 039:0000000000000000000000000000060000060600000600600060076000670767
-- 040:0b4b000000b00000006000000060000000600000000600000076070000767000
-- 041:0c000000c4c000000c0000000600000006000000060000006000000067000000
-- 042:0000000000000000000000000000000000000000000000000700000007700700
-- 043:0000000000000000000000000000000000000000000000700700070007000700
-- 044:0000000000000000000000000000000000000000007000000070000000770000
-- 049:fefdfddfeeddfffddfffeefdfefeedeffdfdfddfddffeffeffeddffdeedffedf
-- </TILES>

-- <SPRITES>
-- 000:000000000000000000000011000001110000011c000001cf000001cc0000120c
-- 001:0000000000000000110000001110000011100000c1f00000cc100000c0210000
-- 002:00000000000000000000000000000011000001110000011c000001cf000001cc
-- 003:000000000000000000000000110000001110000011100000c1f00000cc100000
-- 004:000000000000000000000011000001110000011c000001cf000001cc0001120c
-- 005:00000000000000001100000011100000c1110000ccf00000cc100000c0211000
-- 006:0000000000000011000001110000011c000001cf000001cc0000120c00001065
-- 007:00000000110000001110000011100000c1f00000cc100000c021000056010000
-- 008:0000000000000011000001110000011c000001cf000001cc0000120c00001065
-- 009:00000000110000001110000011100000c1f00000cc100000c021000056010000
-- 010:0000000000000011000001110000011c000001cf000001cc0000120c00001065
-- 011:00000000110000001110000011100000c1f00000cc100000c021000056010000
-- 012:000000000000000000000011000001110000011c000001cf000001cc0001120c
-- 013:00000000000000001100000011100000c1110000ccf00000cc100000c0211000
-- 016:000100550000065500000555000055550000c6ff000000c0000000c0000000f0
-- 017:55001000556000005550000055550000ff6c00000c0000000c0000000f000000
-- 018:0001200c0000005500000655000055550000c655000000ff000000c0000000f0
-- 019:c0021000550000005560000055550000556c0000ff0000000c0000000f000000
-- 020:0000006500000655000006550000006c000000ff0000000c0000000c0000000f
-- 021:56000000550000005500000055000000ff000000d0000000d0000000f0000000
-- 022:00000065000000560000005500000055000000ff0000fcc00000000000000000
-- 023:550000006c000000550000005ff00000ffc0000000c0000000f0000000000000
-- 024:000006550000065500000c5500000055000000ff00000fdd0000000000000000
-- 025:556000005c60000055000000ff000000cd0000000c0000000f00000000000000
-- 026:00000655000065550000655500000c55000000ff000000c000000c000000f000
-- 027:5560000055560000555600005fc00000ff0000000c0000000f00000000000000
-- 028:00000065000066550000c55500000055000000ff0000fdd00000000000000000
-- 029:5600000055660000555c000055000000ff0000000c0000000c0000000f000000
-- 032:00000000000000000000001100000111000001c1000001fc000001cc0000120c
-- 033:000000000000000011000000111000001c1000001f100000cc100000c0210000
-- 048:000100650000065500005555000cc055000000ff000000c0000000c0000000f0
-- 049:560010005560000055550000550cc000ff0000000c0000000c0000000f000000
-- 064:00000000000000000000001100000111000001110000011c0000111c0001120c
-- 065:00000000000000001100000011100000c1100000fcf00000ccc00000cc200c00
-- 066:00000000000000000000001100000111000001110000011c0000001200000012
-- 067:00000000000000001100000011100000c1110000fcf00000ccc00000cc200000
-- 068:000000000000000000000111000011110000111c000011cf0000112c0000122c
-- 069:0000000000000000100000001100000011000000cf000000cc000000c2000000
-- 080:00000065000000550000006600000066000000ff00000fff00000dd000000f00
-- 081:56555600555560005556000066600000fff000000c0000000c0000000f000000
-- 082:00000025000006550000c6650000006600000066000000ff00000dd000000f00
-- 083:565c6000555560005556000065f00000fff000000c0000000c0000000f000000
-- 084:0001065500000555000066550000c6660000066f00000fff00000d0000000f00
-- 085:6500000055c000005660000050000000f0000000cd0000000c0000000f000000
-- 096:000000000000000000000011000001110000011c000001cf0000021c00000021
-- 097:0000000000000000110000001110000011100000c1f00000cc100000c0200000
-- 098:000000000000000000000011000001110000011c000001cf000001cc0000120c
-- 099:0000000000000000110000001110000011100000c1f00000cc100000c2000000
-- 100:000000000000000000000011000001110000011c000001cf000001cc0000120c
-- 101:0000000000000000110000001110000011100000c1f00000cc100000c0200000
-- 112:000000260000065500006555000c50550000006f00000ff000000d0000000f00
-- 113:566600005556000055c0000055000000ff000000cd0000000c0000000f000000
-- 114:00001566000066550000c055000000550000ffff00000df000000d0000000f00
-- 115:556000005556000055600000c6000000f0000000c0000000dc0000000f000000
-- 116:000100660000065500000c5500000055000000ff000000d000000d0000000f00
-- 117:55600000555600005c60000055000000ff0000000c0000000c0000000f000000
-- 128:000004440000000000000000000004444000444434004cbc44404cfc34404ccc
-- 129:4400000000000000000000004400000044400040bc400430fc404440cc404430
-- 130:000004440000000000000000000004440000444400004cbc00004cfc40004ccc
-- 131:4400000000000000000000004400000044400000bc400000fc400000cc400040
-- 132:000000000000009900009999000999990099dcd9009dffcd009cffcc099dcccd
-- 133:00000000b9a00000b9aa0000b9aaa000b99aaa00b999aa0099a9990099ab9990
-- 134:00000000000000000000000000000000000b00000099bb000099dcbb009dffcd
-- 135:0000000000000000000000000000000000000000000bba000bbaaa00b9a9aaa0
-- 144:034040cc00304333000333330000333300000cc000000c000000000000000000
-- 145:c0404300334030003333000033300000cc000000c00000000000000000000000
-- 146:444040cc44304333430333333000333300000cc000000c000000000000000000
-- 147:c0404440334034403333034033300030cc000000c00000000000000000000000
-- 148:9a99dcd99b9999999099a99a00099aa9000099990000099a000099a90009abb9
-- 149:999b99a9999999b99a99a9b999aa900999990000999000009a9900009bba9000
-- 150:099cffcc9a9dcccd9b99dcd990099aa9000099990000099a000099a90009abb9
-- 151:99ab99a0999b99909999999999aa99b9999900b9999000099a9900009bba9000
-- 155:00000000040004000040c40000c44000000c4c000004c440004c004000400000
-- 156:0000000000000000000000000000000000000033000033430000344400033444
-- 157:0000000000000000000000000000000000000000303000003333000044333000
-- 158:0000000000000088000088880000880000080003008830000088304008830400
-- 159:0000000080000000880088000008388030004388004000380004408000008000
-- 172:0003344400003344000033330000033300000000000000000000000000000000
-- 173:4443300044433000444300003433000033300000000000000000000000000000
-- 174:0880000000803000000000000008000000834000008830000008838000008800
-- 175:0000080000000800000040000004000083400380000033808883880000880000
-- 184:00000000000000000000556600004f770006447700067ff70007777806607777
-- 185:00000000000000006550000064f00000644f7700777777708c8c8c7088888000
-- 186:00000000000000000000556600004f770006447700067ff70007777800007777
-- 187:00000000000000006550000064f00000644f7700777777708c8c8c7088c8c000
-- 188:00000000000000000004000000044488000048880000888800008811000888ff
-- 189:000000000000000000004000884440008884000088880000111800001ff88000
-- 190:000000000004000000044488000048880000888800008811000888ff00008111
-- 191:0000000000004000884440008884000088880000111800001ff8800011180000
-- 192:000000000000000000000000000f00000099f00009f9ff999f9ff9449090944f
-- 193:000000000000000000000000000f000000f990009fff990049ff9f9044909090
-- 194:0000000000000000000000000000000000099f99009ff94409ff944f09ff94df
-- 195:000000000000000000000000000000009ff9000049ff9000449ff900d49ff900
-- 200:0766f7770077777700077777000007760000677600007777006676667777f474
-- 201:7c22270077c2c7006677700066660000666674006667770076777000f0770000
-- 202:0000f777000677770067777700670776700064747600f6660776f6660007f777
-- 203:7777770077777000666600006666000066667400f6666000f6777700f0777740
-- 204:00808111008800110828880800022088000800880000088000000f0000000000
-- 205:111808001100880080888280880228008800800088000000f000000000000000
-- 206:000000110000880800088088008880880008088000000f000000000000000000
-- 207:1100000080880000880880008808880088080000f00000000000000000000000
-- 208:009094df0000944f000009440000009900000000000000000000000000000000
-- 209:d490900044900000490000009000000000000000000000000000000000000000
-- 210:09ff944f009f0944000900990000000000000000000000000000000000000000
-- 211:449ff900490f9000900900000000000000000000000000000000000000000000
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
-- 251:cddddeef0ceeeef000cdef0000cdef0000cdef000cddeef0cccccdefddeeeeff
-- 252:433300003cc430003cc343003443343003443343003443c300034cc300003334
-- 253:008888000812288081122888822cc228822cc228888228c808822c8000888800
-- 254:00099000009ba90009bb9a909bbb99a99a99aac909a9ac90009ac90000099000
-- 255:0077770007cc55707cc666576557777c765567c707656c700076c70000077000
-- </SPRITES>

-- <MAP>
-- 000:101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:101010101010101010101000000000000000000000000000000000101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:101000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:100000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:100000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:100000000000000000000000000000000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000001010121200000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:100000000000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000000000000000000000000000000001010101010000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:100000000000000000000000000000000000000000000000000000121010000000000000000000000000000000000000000000000000000000000000000000002020000010111010100000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:100000000000000000000000000000000000000000000000000012101110000000000000000000000000000000000000000000000000000000000000000000000000000010101010100000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:100000000000000000000000000000000000000000000000000010101010000000000000000000000000000000000000000000000000000000000000000020200000000010101310102000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:100000000000000000000000000000000000000000001010101010000050000000000000000000000000000000000000000000000000000000000000000000000000000010111310100000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:100000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000101010101010101010101010101000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:100000000000000000000000000000000000000000000000000000000050000000000000000000000000000060000000000000000000600000001212101010101010101013101010101100000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:10100000000001000000d00000000000000000000000000000000000005000000001000000d000000000121210101000000000121212121210101010101010101313101310101110101010000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:101011111212121212121212121212121200000000000000000000000010101010101010101010101010101010101013101010111111111013131313101010101010101010101111101010000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:101010101010101010101011101010101010101012121200006000001010101013101010101013131110101010131110101010101010131310101010101010101010101111101011111010100000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:101011101010101011101011101010111010101010101010111010101010101010101010101010101010101010101010101110101010131010101010101011101010101010101010101010101010121200000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 017:101010101011101010101010101110101010101010101010101010101110101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 018:101010111010101010101010101010101010131313101010131010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 019:101010101010000000000000001010101010101013131010131313101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 020:101000000000000000000000000000000011111010101111131310131313101010101010101000000000000000001010101010101010101010101010100000000000000000000000000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 021:111000000000000000000000000000000000000010101110101010131010101010101000000000000000000000000000000000000010101010101010100000000000000000000000000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 022:111000000000000000000000000000000000000011101010101010111310101010000000000000000000000000000000000000000000000000101010100000000000000000000000000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 023:111000000000000000000000000000000000000000101010131013111010100000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000001000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 024:100000000000000000000000000000000000000000001010101010101010100000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000001212101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 025:100000000000000000000000000000000000000000000000000010101010100000000000000000000000000000000000000070000000000000000000100000000000000000000000000000000000000000000000001010101010100000000000000000000000000000000000600000000060000000000000000000000000006000000000600000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 026:10000000000000000000000000000000000000000000000000000010101010000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000012101110101110000000000000000000f00000000000121212111010101012000000d000000000001010101110101010101212000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 027:100000000000000000000000000000700000000000000000000000000000100000000000000000000000000000000000000000000000000000000000100000000000007000000000000000000000000000000000101011101011100000000000000010111110101010101010111010101010101110101010101010101010111010101110101010101010101000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 028:100000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000010101010101110100000000000101010111010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 029:100000000000000000700000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000010111010101110100000002020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 030:100000000000000000000000000000000000000000000000000000000000400000000000006000000000000000000000000000000000000000000000400000000000000000000000000000000000000000001010101010111010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 031:1012000000000000000000000000000000000000000000000100000000004000000000101010121212000000000000000000000000000000000000004000000000000000000000000000000000c0000010101011111111111010101212000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 032:10101200000000000000000000000000000000c0000000121212121010101010101212111010101010121200000000000000000000c0000001000000400000000000000000000000000000001212101010101110101010101010101010120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000121010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 033:111110101000000000000000101010101010101010101010101010101010101011101111111110111110101212121212121210101110101111101010101010101010121212121212121212121013101010101010101010101010101111101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000001210101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 034:101010101010000000000000000000000000000000001010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000121010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 035:101010111010000000000000000000000000000000000000001010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000020202000000000000000000000000000000000000000000000000000000000000000000000000000101110111010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 036:101010101010000000000000000000000000000000000000000000101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 037:10101010101000000000000000000000000070000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000002020200000000000000000000000000000000000000000000000000000000000000000c000121210101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 038:101010101010000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 039:101010101011100000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000020202000000000000000000000000000000000000000000000000000000000000010111010100000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 040:101110101010100000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000010111010000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 041:10101110101010100000c000000100000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000012121010000000000000000000000000000000100000000000000000000000000000121210111010100000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 042:10101010101010101010101212121200d000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000010101010100000000000000000000000000000000000100000000000000000101010101010101010101010000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 043:101011101010101010101310131010101010121200000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000000000000000000000000000101010000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 044:101010000000000000000000000000101010101012000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010000000000000000000000000000000000000000000000000001010000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 045:101000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010121212000000000000000000000000000000007000000000001010000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 046:101000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010101000000000000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 047:100000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010111010101010000000000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 048:100000000000000000000000000000000000000000000000000000001210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010101110101012121200000000000000000000000000000010101012120000000000000000000000000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 049:100000000000000000000000000060000000006000006000000000121010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010101111111111101010120000000000000000000000000010101011101010101010101110101012121200000000000000000012101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 050:101010000000000000101010101013101010101013121212121212101010101010101010101000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101011101010101010101010101010101010000000010000001010101010101110101010101010101010101012120000000000000010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 051:101010000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010102020202010101010101010101010101010101010101010000000000000000000000000101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 052:101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010100000000000000000000000000000000000000000000000001010131310101000000000000000000000000000000000101110100000000000000010101000000000000010101000000000000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 053:101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000101010100000000000000000000000000000000000101011101000000000000010100000000000000000101000000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 054:101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000010000000000000000060000060000000000000101011101000000000000010100000000000000000001000000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 055:101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000010000000000020201010101010101000000000101110101010000000000010100000000000000000001000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 056:10100000000001000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000001300f000000000000000001011100000000000101010101010100000000010100000000000000000001000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 057:101000002020202020000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000010101012120000000000001011000000000000101010101110102000000010100000000000000000001000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 058:101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020202000000000000000000050000000000000000000000000000000000000000000000000000000000050000000101200000000001010000000000000100000101010100000000010100000000000000000001000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 059:101000000000000000000000000020000000200000002000000000000000000000000000202000000000200000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000050000000000000000000001000000000000000100000001010100000202010100000000000001000001000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 060:111000000000000000000000000000000000000000000000000000200000000020000000000000000000000000000000000000000000121210101010120000000000000000000000000000000000000000000000000000000050000000000000000020201000000000000012100000000000000000000010100000000000001000001000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 061:101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010131010100001000000000000000000000000000000000000000000000000000050000000000000000000001000000000001210000000000000000000202010100000006000001000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 062:1010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101010101010120000c0000000f00000000000000000000000000000000000121210000000000000000020201000000000000000000000000000000000000010100000002020101000000000000000000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 063:101010100000000000000000000000000000000000000000600000000000000000000060000000000000000000000000000000000000101013131310101010101010101212121200006000006060000060000060000010101010100000000000000000001000000000000000000000000000000000202010100000000000111000000000000000000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 064:101010101000000000000000000000000000000000001010101000000012121212101010101012120000006000000012120000600000101010101013101010111010101010101010101010101010101010121212121010101010100000000000202000001000000000000000000000000000000000000010100000000011100000000000000000000000000000000000000000121010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 065:1011111010000000600000000060000000121210101010101010101010101010101010101010101010101010101010101010101010131010101010101010101010101010101010101010101010101313131010101310111010101000000100000000000010000000f0000000000000000000000000202010100000001110000000000000000000000000000000000000d00012101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 066:101010101010101010101010101010101010101010101010111010101111111011111111101010101010111010131013101310101313101010131010101010101010101011131010101010101311101010101010101110101310101010101010101010101000001010121200006000600000600000000010101000001000000000000000000000000000000001000000121210101110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 067:101010111111101010101110101010101010101010101010101010101010101010101010101010101010101010101111101010101010101110101010101010111010101010101010101010101010101010101010101010101010101010101010101010101010101010111012121212101011111010101010101010101000000000001212121210111010101011111010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 068:000000000000000000000000000000000000000000000000000000000000101010101110101010101010101011101010101010101010101110101110101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000001010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 069:000000000000000000000000000000000000000000000000000000000000111110101111111000000000000000000000000000001010101010101111101000000000000000000000000010101010100000000000101010101010101010101000000000000000100000000000000000000000000000101010101000000000000000001000000000000010000010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 070:000000000000000000000000000000000000000000000000000000000000101011101010000000000000000000000000000000000000000000101010100000000000000000000000000000000000000000000000000000101010101010000000000000000000100000000000000000000000000000000010101000000000000000000000000000000010000000000000000000101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 071:000000000000000000000000000000000000000000000000000000000000101010101000000000000000000000000000000000000000000000001010100000000000000000000000000000000000000000000000000000000010101010000000000000000000100000000013000000000000000000000010101000000000000000000000000000000011000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 072:000000000000000000000000000000000000000000000000000000000000101010100000000000000000000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000010131310000000000000120000000000000010000000000000000000000010100000000000000000000000000000000010000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 073:0000000000000000000000000000000000000000000000000000000000001010000000000000000000000000000000000000000000000000000000101010000000000000000000000000000000000000000070000000000000101013100000000000001000000000000000100000d0000000000000000010100000000000000000000000001200000010000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 074:000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000010101000000000000070000000000000700000000000000000000000000010101010000000000000101010101010131010101020200000000000000000100000000000000000000000001000000000000000120000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 075:000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000010101010000000000000000000000000000000000000000000000000000010101310000000000000000000000000000000101000000000000000000000100000010000000000000000001100000000000000100000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 076:00000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000040000010101000000000000000000000000000000000000000000000101010131000000000000000000000000000000010132020000000000000000010101012120000000000d000001000000000000000100060000010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 077:000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000700000000000000000000000400000000010101010000000000000000000101010202020101010101000101013000000000000000000000000000000101000000000000000000000400011101000002010101010111111111110101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 078:000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000400000000000000010101020202020101010100000000000000000000000101010101000000000000000000000600000101010000000000000000000400000000000000000000000000000000000100000000010000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 079:000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000600000600000000000000000000000100000000000000000000000000000000000000000000000000000000000400000001011111000001212121010101010101310000000000000000000400000000000202000000000000000000000100000000010000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 080:000000000000000000000000000000000000000000000000000000000000100000000000000000000000000020200000202000000000000000000010101000000000000000000000000000000000000000000000000000000000400000000000101010101010101110101113131010120000000000000000400000000000000000000000000000100000100000000000000060001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 081:000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000010101000000000000000000000000000000000000000000000000001000000400000000000000000000000000000000000001010100000010000000010100000000000202000000000000000100000000000000000000012121010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 082:0000000000000000000000000000000000000000000000000000000000001012000000000000000000000000000000000000000000010000121010101010101000000000000000000000000000000000d0000000001010101010101200000000000000000000000000000000000000000020200000000010100000000000000000000000000000100000000000120000000010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 083:000000000000000000000000000000000000000000000000000000000000101012000000000000000000c000000060000000000000121210101011101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000012101010101212000000000000d0000000101010101011111010121210101110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 084:000000000000000000000000000000000000000000000000000000000000101010101000000000001212101010101010101111111010111010101010101010101010101010101010101010101010101010101010101010101010101010101013131313101010101010101313131010101012121212121013101111111010101010101010101010101010101010111110101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 085:000000000000000000000000000000000000000000000000000000000000101010100000000000001010101010101010101010101010111110101010101010101010101110101010101010101010101010101010101010101010101011111111101010101010101010101010111010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 086:000000000000000000000000000000000000000000000000000000000000101000000000000000000000001010101110111110101010101010101110101011101010101110101010101010000000000010101010101010101010100000000000000000000000000000000000000000000000000000101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 087:000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000000010101010101010101010101010101010101010101110101010100000000000000000000000000000101010100000000000000000000000000000000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 088:000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000010101010101010100000000000000000000000000000000000000000001010100000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 089:000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 090:000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 091:000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 092:000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 093:000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 094:000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000007000007000000000000000000000700000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 095:000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000000050000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 096:000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000001210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 097:000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000600000c00000000000000000000000000000000000000000001010000000000000000000000000000000000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 098:000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000000000000000000000000000000012121010101010101010000000000000000000000000000000121010101010120000000000000000000021314151000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 099:000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000000000000000000000000000121010101010101010111010101200000000600000000000001212101010101011101212000000000100000022324252000000617181910000000000121010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 100:00000000000000000000000000000000000000000000000000000000000010101010000001000000000000c0006000000000d0000000000010101010101011101010101011101012121210101010101010111010101011111010101010121212121212121212121212120000627282920000001212111010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 101:000000000000000000000000000000000000000000000000000000000000101010101010101010101110101110101010101010101010101010101010101110101010101010111010101010101011101010101010101010101010101010111010101010101010101011101212121212121212121010111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
-- 001:42704270427052706250825082509200a200a200b200c200c200d200d200d200e200f200f200f200f200f200f200f200f200f200f200f200f200f200480000000000
-- 002:04057404a403c403d403e402f402f401f401f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400c00000000000
-- 003:d4f0b4d0a4b094909480a470b450c440d420d410e400e400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400500000000000
-- 004:e200f201e201e203020302040203020302020200020e020d020d020e020f02070207020702060205020502040203020202020200020002000200020050000004000f
-- 005:8000f000e000e000e000e000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000600000000000
-- 006:04d004c0847065804580359025a035b045c075d0a5f0b500c500d500e500e500f500f400f400f400f400f400f400f400f400f400f400f400f400f400207000000000
-- 007:d4f094e094d0a4b0c480d460e430f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400100000000000
-- 008:62e072b08290b240c200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200300000000000
-- 009:4000f000c000a0c0a0c0a0c0a0c0b0c0b0c0c0c0c0c0d0c0e0c0f0c0f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000600000000000
-- 010:02f012e012d022b032a03280427042d042c052b0529062806270725072b082a082909280a270a260b2a0b290b280c280c260d250d290e280e270f250300000000000
-- 032:010021003100510051005100510051005100510051005100510051005100510051005100510051005100510051005100510051005100510051005100200000000000
-- 033:0305130323024301430073009300b300c300d300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300a00000000000
-- 034:6400b400d400e400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400700000000000
-- 035:04054404540374038403a402b402c401d401e400e400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400b00000000000
-- 036:0500150025003500450045004501450255015500650f75007500850095009500a500a500a500a500b500b500b500b500b500b500b500b500c500c500400000000056
-- 037:360056007600860096009600a600a600a600c600c600c600c600c600c600c600c600c600c600c600c600c600c600c600c600c600c600c600c600c600400000210000
-- 038:47c077009700b700b700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c700c80000320000
-- 039:030523033100510051005100510051005100510051005100510051005100510051005100510051005100510051005100510051005100510051005100a05000000000
-- 040:04f024a03100510051005100510051005100510051005100510051005100510051005100510051005100510051005100510051005100510051005100200000000000
-- 041:360066007600860096009600a600a600a600a600b600b600b600b600c600c600c600c600c600d600d600d600d600e600e600e600e600e600e600f600600000000000
-- 042:050023d043b0639073709350b330d320e310f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300307000000000
-- </SFX>

-- <PATTERNS>
-- 000:40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e400814000000000000000000400814000000000000000000
-- 001:400806400806100800400806100800400806100800400806400804100800400804100800400804000800100800000000800858800858100850800858100850800858100000800858600858100000600858100000400858000000100000000000400806400806100800400806100800400806100800400806400804100800400804100800400804000800100800000000800858800858100850800858100850600858100000600858400858100000000000000000000000000000000000000000
-- 002:4008084008081008004008081008004008081008004008084008061008004008061008004008060008001008000000004f8958400858100000400858100000400858100000400858e00856100000e00856100000d008560000001000000000004ff9084008081008004008081008004008081008004008084008061008004008061008004008060008001008000000004f8958400858100000400858100000e00856100000e00856d008561000008ff948000000900848100840900848b03c48
-- 003:4ff904000000400806b00804100800000000400806100800400806600806400806100800400804000000e00802000000100800000800e00804d00804000000100800900804100800900804b00804900804100800e00802000000d00802000000100800000000d00804800804000000000000d00804100800d00802000000d00804100800d00802100800900806000000000000100800900806100800b00806000000100800000000900806100800b00806100800b00802000000400804000000
-- 004:000400000000000000000000000000000000800848100000b0084800000000000000000040084a000000e00848000000000000000000d00848000000000000000000900848000000000000000000800848000000900848100840900848b03c480004000000000000000000000000000000000000000000000000000000000000000000000000000000008f8958000000000000100000800858100000600858000000100850000000400858100000600858000000100000000000bff948000000
-- 005:1ff95000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000048f958000000000000100000400858100000f00856000000100000000000d00856100000f00856000000100000000000000000000000
-- 006:40081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000000082040082e40081400000040082e00082040083c000000d00856000000000000100000d0085640082e40083c00000040082e40082e40081400000000082040082e40083c00000040082e40082e
-- 007:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b8f956b00856100000b00856100000b00856100000b00856900856100000900856100000800856000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00856b00856100000b00856100000900856100000900856800856100000000000000000000000000000000000000000
-- 008:400804000000400806b00804100800000000400806100800400806600806400806100800400804000000e00802000000100800000800e00804d00804000000100800900804100800900804b00804900804100800e00802000000d00802000000100800000000d00804800804000000000000d00804100800d00802000000d00804100800d00802100800c00806000000000000100800c00806100800b00806000000100800000000900806100800b00806100800b00802000000400804000000
-- 009:000000000000000000000000000000000000800848000000b0084800000000000000000040084a10000040084a60084a000000000000e00848000000000000000000900848000000000000000000800848100000b00848000000405c480004000000000000000000000000000000000000000000000000000000000000000000000000000000000000007f8958000000000000100000700858100000600858000000100000000000700858100000900858000000100000000000bff948000000
-- 010:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000048f958000000000000100000400858100000e00856000000100000000000400858100000600858000000100000000000000000000000
-- 011:40081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c000000b00858000000000000100000b0085840082e90085800000000082040082e40081400000040082e00082040083c00000040082e40082e
-- 012:4f496af0086ab0086a80086a4f896af0086ab0086a80086a4fb96af0086ab0086a80086a4ff96af0086ab0086a80086aebf96ad0086a90086a60086ae8f96ad0086a90086a60086ae4f96ad0086a90086a60086ae8f96ad0086a90086a60086abbf96a80086a40086ad00868bfb96a80086a40086ad00868bf896a80086a40086ad00868bf496a80086a48f95800000090086a80086a400858d00868f0085600000040086ad00868d00856d00868f008560000004f896a80086ab0086ad0086a
-- 013:4f496af0086ab0086a80086a4f896af0086ab0086a80086a4fb96af0086ab0086a80086a4ff96af0086ab0086a80086aebf96ad0086a90086a60086ae8f96ad0086a90086a60086ae4f96ad0086a90086a60086ae8f96ad0086a90086a60086abbf96a80086a40086ad00868bff96a80086a40086ad00868bfb96a80086a40086ad00868bf896a80086a48f958000000000000100000400858100000e008560000001000000000004ff948000000600848000000700848000000900848000000
-- 014:400804000000400806b00804100800000000400806100800400806600806400806100800400804000000e00802000000100800000800e00804d00804000000100800900804100800900804b00804900804100800e00802000000d00802000000100800000000d00804800804000000000000d00804100800d00802000000d00804100800d00802100800900806000000000000100800900806100800b00806000000100800000000e00804000000000000000000e00804000000000000000000
-- 015:40081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c000000b00858000000000000100000b0085840082e90085800000040082e40082e400814000000000000000000400814000000000000000000
-- 016:000000000000000000000000000000000000800848000000b0084800000000000000000040084a00000040084a602c4a000400000000e00848000000000000000000900848000000000000000000800848100000b00848000000404c480004000000000000000000000000000000000000000000000000000000000000000000000000000000000000007f895800000000000010000070085810000060085800000010000000000040086a00000060086a00000070086a00000090086a000000
-- 017:40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040083c40082e
-- 018:c00804000000000000000000100000000000c00804000000b00804000000c00804000000100000000000c00802000000100000000000c00802100000c00802100000000000000000000000000000e00802000000900804000000e00804000000c00804000000100000000000c00804100000700804000000c00804e00804c00804000000100000000000c00802000000100000000000c00802100000c00802100000000000000000000000000000e00802000000900804000000e00804000000
-- 019:b00848000000000000000000000000000000000000000000000000000000000000933948bff948000000900848000000000000000000000000000000000000000000000000000000400848000000600848000000700848000000900848000000b00848000000000000000000000000000000000000000000000000000000000000000000b00848100000900848000000000000000000e00848000000000000000000900848000000000000000000000000000000000000000000000000000000
-- 020:700848000000000000000000000000000000000000000000000000000000000000600848700848000000600848000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700848000000000000000000000000000000000000000000000000000000000000000000700848100000600848000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 021:a00804000000000000000000100000000000900806000000a00806000000a00804000000100000000000a00804000000100000000000a00804100000a00804100000000000000000000000000000900804000000000000000000700804000000600804000000100000000000600804000000100000000000600804100800600804000000100000000000b00804000000000000000000100800000000b00804100000b00804000000100000000000000000000000000000000000000000000000
-- 022:900848000000000000000000000000000000000000000000000000000000000000700848903c48000000700848000400000000000000000000000000000000000000000000000000000000000000500848100000700848000000900848000000000000000000000000000000000000000000000000000000000000000000800848000000900848100000b00848000000000000000000000000000000000000000000000000000000000000000000800848000000900848100000900848b03c48
-- 023:500848000000000000000000000000000000000000000000000000000000000000000000500848000000400848000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600848000000000000000000000000000000000000000000000000000000000000000000000000000000400848000000f00846000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000
-- 024:40081400000000000000000040083c00000000000000000040081400000000000000000040083c00000000000000000040081400000000000000000040083c00000000000000000040081400000000000000000040083c00000000000000000040081400000000000000000040083c00000000000000000040081400000000000000000040083c00000000000000000040081400000000000000000040083c00000000000000000040081400000000000000000040083c00000040082e40082e
-- 025:400806400806100800400806100800400806100800400806400804100800400804100800400804000800100800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000400806400806100800400806100800400806100800400806400804100800400804100800400804000800100800000000000000000000000000000000000000000000000000000000000000000000b00804000000e00804000000400806000000
-- 027:4008084008081008004008081008004008081008004008084008061008004008061008004008060008001008000000004f8958400858100000400858100000400858100000400858e00856100000e008561000004008580000001000000000004ff9084008081008004008081008004008081008004008084008061008004008061008004008060008001008000000004f8958400858100000400858100000e00856100000e00856d00856100000b00806000000e00806000000400808000000
-- 028:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b8f956b00856100000b00856100000b00856100000b00856900856100000900856100000b00856000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00856b00856100000b00856100000900856100000900856800856100000000000000000000000000000000000000000
-- 029:400804000000400806b00804100800000000400806100800400806600806400806100800400804000000e00802000000100800000800e00804d00804000000100800900804100800900804b00804900804100800e00802000000d00802000000100800000000d00804800804000000000000d00804100800d00802000000d00804100800d00802100800900806000000000000100800900806100800b00806000000100800000000b00804000000000000000000b00804000000000000000000
-- 030:000000000000000000000000000000000000800848000000b0084800000000000000000040084a10000040084a602c4a000400000000e00848000000000000000000900848000000000000000000800848100000b00848000000404c480004000000000000000000000000000000000000000000000000000000000000000000000000000000000000007f8958000000000000100000700858100000600858000000100000000000400858000000600858000000e00856000000400858000000
-- 031:40081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c00000040082e00082040081400000000082040082e40083c000000b00858000000000000100000b0085840082e90085800000000082040082e700848000000600848000000400814000000e00846400848
-- 032:4f496af0086ab0086a80086a4f896af0086ab0086a80086a4fb96af0086ab0086a80086a4ff96af0086ab0086a80086aebf96ad0086a90086a60086ae8f96ad0086a90086a60086ae4f96ad0086a90086a60086ae8f96ad0086a90086a60086abbf96a80086a40086ad00868bff96a80086a40086ad00868bfb96a80086a40086ad00868bf896a80086a48f958000000000000100000400858100000e00856000000100000000000cff856000000e00856000000b00856000000000000000000
-- 033:90087400000040082e00000090088400000040082e00000090087400000040082e000820900884000000b00884000820b0087400000040082e000820b0088400000040082e000820b0087400000040082e00082090088400000040082e00082080087400000040082e00082080088400000040082e00082080087400000040082e000820b00884000000d00884000820d0087400000040082e000820d0088400000040082e000820d00874000000d00874000820b0087400000040082e40082e
-- 034:4a8958100840400858100850400858100850400858100850400858100850400858100850400858100850b00856100850b00856100850b00856100850b00856100850b00856100850b00856100850b00856100850900856100850900856100850800856100850800856100850800856100850800856100850800856100850800856100850800856100850d00856100850d00856100850d00856100850d00856100850d00856100850d00856100850d00856100850b00856100850b00856100850
-- 035:000000000000000000000000000000000000900846000000d00846000000800848000000000000000000600848000000000000000000b00848000000000000000000f05c46000400000000000000000000000000000000000000000000000000f00846000000000000000000000000000000b00846000000f00846000000400848100840400848602c48400848000400000000000000f00846000000000000000000d00846000000000000000000000000000000000000000000000000000000
-- 037:88a958100850800858100850800858100850800858100850800858100850800858100850800858100850f00858100850f00858100850f00858100850f00858100850600858100850600858100850600858100850600858100850600858100850600858100850600858100850600858100850600858100850600858100850600858100850600858100850b00858100850b00858100850b00858100850b0085810085040085a10085040085a10085040085a100850f00858100850f00858100850
-- 038:4008084008081008004008081008004008081008004008084008061008004008061008004008060008001008000000004f8958400858100000400858100000400858100000400858e00856100000e00856100000d008560000001000000000004ff9084008081008004008081008004008081008004008084008061008004008061008004008060008001008000000004f8958400858100000400858100000e00856100000e00856d00856100000fff946402c48f00846000400d00846000000
-- 039:800848000000000000000000000000000000400848000000800848000000900848000840900848b02c48f00846000400000000000000b00846000000000000000000800846000000f00846000000400848000840402c48600848500848000400000000000000600848000000800848000000000000000000000000000000000000000000000000000000600848000000000000100000600848100000500848000000000000100000600848100000800848000000100000000000800848000000
-- 040:d8a958100850d00858100850d00858100850d00858100850d00858100850d00858100850d00858100850f00858100850f00858100850f00858100850f00858100850f00858100850f00858100850f00858100850f00858100850800858000850000850000850000850000850500858000000000000000000000000000000000000000000000000000000f00858000000000000100000f00858100000d00858000000000000100000f0085810000050085a000000100850000000800858000000
-- 041:9a8956100850900856100850900856100850900856100850900856100850900856100850900856100850b00856100850b00856100850b00856100850b00856100850b00856100850b00856100850b00856100850800856000000d00856000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d00858000000000000100000d00858100000800856000000000000100000d00858000000d00856000000800856000000900856000000
-- 042:9a8958100820900858100850900858100850900858100850900858100850900858100850900858100850d00858100850d00858100850d00858100850d00858100850d00858100850d00858100850d00858100850d00858100850b00858100850bb8958100850b00858100850bc8958100850b00858100850bd8958100850b00858100850be8958100850d849580b51000d61001f8100da8958100000ff8958000000100000000000b83956d949564a59586b69588c7958bd8958de89584f895a
-- 043:600848000000000000000000000000000000000000000000000000000000800848000000000000000000900848000000000000000000000000000000000000000000000000000000900848000000800848000000400848100000400848000000000000000000000000000000000000000000000000000000000000000000d00846000000400848000000400848602c48000400100000b00846100000b00848000000100000000000000000000000800848000000900848100000900848b02c48
-- 044:d8a958100850d00858100850d00858100850d00858100850d00858100850d00858100850d0085810085040085a10085040085a10085040085a10085040085a10085040085a10085040085a10085040085a10085040085a100850d00858100850d8b958100850d00858100850d8c958100850d00858100850d8d958100850d00858100850d8e95810085044895a05a10006d10018f10048a95a10000068f95a000000100000000000838958949958b5a958d6b95847c95a68d95a88e95ab20b5a
-- 045:e0087400000040082e000000e0088400000040082e000000e0087400000040082e000820900884000000e0087200082040082e000820e00872000820e0088200000040082e000820e0088400000040082e00082090088400000040082e00082090087400000040082e00082090088400000040082e00082090087400000040082e000820900884000000b0087400082040082e000820b00874000820b0088400000040082e00082040082e000820b00884000820d00874000000b00884000000
-- 046:d00848000000000000f0084800000010000040084a100000f00848000000000000b0084800000010000060084a10000050084a60084a80084a000000000000000000000000000000d00848d0084a10000059f99c00000000000000000057999c00000000000000000054699c00000000000000000052399c00000000000000000051299c00000000000000100050199c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 047:900876000000000000000000000000000000000000000000b00876000000000000000000800876000000000000000000d00876000000000000000000000000000000000000000000000000d0087410000000000080f99c00000000000000000080999c00000000000000000080699c00000000000000000080399c00000000000000000080299c00000000000000000080199c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 048:b8f958000000000000000000000000000000000000000000d00858000000000000000000000000000000000000000000f00858000000000000000000000000000000000000000000000000df099a000000000000000000d9099a000000000000000000d6099a000000000000000000d3099a000000000000000000d2099a000000000000000000d1099a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 049:4f895a00000000000000000000000000000000000000000060085a00000000000000000000000000000000000000000050085a000000000000000000000000000000000000000000000000000000ff999a000000000000000000f9799a000000000000000000f6499a000000000000000000f3299a000000000000000000f2199a000000000000000000f1099a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 050:000400000000000000000000000000000000800848000000b00848000000000000000000e00848402c4ae00848000400000000000000d00848000000000000000000900848000000000000000000800848000000900848100840900848b03c480004000000000000000000000000000000000000000000000000000000000000000000000000000000008f8958000000000000100000800858100000600858000000100850000000400858100000600858000000100000000000bff948000000
-- 051:000000000000000000000000000000000000000840000000d00848000000000840000000800848100840600848000000000000000000b00848000000000000000000605c48000400000000000000000000000000000000000000000000000000600848000000000000000000000000000000000840000000b00848000000000840000840600848100840400848000000000000000000600848000000600848802c48d00846000c40000000000000000000000000000000000000000000000000
-- 052:90087400000040082e00000090088400000040082e00000090087400000040082e000820900884000000b00884000820b0087400000040082e000820b0088400000040082e000820b0087400000040082e00082090088400000040082e00082080087400000040082e00082080088400000040082e00082080087400000040082e000820b00884000000d00884000820d0087400000040082e000820d0088400000040082e000820d0087400000040082e000820b0087400000040082e000820
-- 053:40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e40081400000040082e40082e40083c00000040082e40082e4008144008a8d008a6d008a64008148008a64008a64008a6
-- </PATTERNS>

-- <TRACKS>
-- 000:996c57180302701581c42ac27013730d31932d44556b57167015430a7f58996c571807225f84a92aa86a5f84b9eeac6b700000
-- 001:0fb1bc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff0000
-- </TRACKS>

-- <SCREEN>
-- 008:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f7f7f7f7f7f7f7f7f7000000000000000000000000000000000000000
-- 009:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777777777777777700000000000000000000000000000000000000
-- 010:0000000000000000000000000000000000008888888888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f7777777777777777777f7f000000000000000000000000000000000000
-- 011:0000000000000000000000000000000000088888ffffffff88000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f777666666666666666666777700000000000000000000000000000000000
-- 012:000000000000000000000000000000000088f882888828888f80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f77766666666666665555556777f0000000000000000000000000000000000
-- 013:00000000000000000000000000000000088888882228882288880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077776ccccccccccccc555555557777000000000000000000000000000000000
-- 014:0000000000000000000000000000000088f8f1288882828888f88000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f77766ccccccccccccc565656555777f00000000000000000000000000000000
-- 015:00000000000000000000000000000008888811822288888288888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccfccccccc000000000000000000077766ccccccccccccccc666655555557770000000000000000000000000000000
-- 016:00000000000000000000000000000088f8f11188882828288f8f8f8000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccccccccc000000000000000000f77665ccccc666666666666666565655577f000000000000000000000000000000
-- 017:00000000000000000000000000000888881111222888888288888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000fcccccc00fccccc0000000000000000007777ccccccc66666666666666666655555577700000000000000000000000000000
-- 018:000000000000000000000000000088f8f11131888282828888e88f88f000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccf0000ccccf000000d0000000000f7776cccccc666666666666666666665656577700000000000000000000000000000
-- 019:000000000000000000000000000888881111112288888822888ccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000cccc00000cccc000000ccc00000000077776ccccc6666666666666666666666555577700000000000000000000000000000
-- 020:0000000000000000000000000088f8f11131128828282888cccccccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000cccc00000cccc00000cccc000000000f775555555555576776776776776777775cc77f00000000000000000000000000000
-- 021:00000000000000000000000000888811111111288888822ccccccccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000cccc00000cccc0000cccccc00000000777555555555557777777777777777777ccc77700000000000000000000000000000
-- 022:000000000000000000000000008f8288288288ccccccccccccff0fcccccc000000000000000000000000000000000000000000000000000c00000000000000000000000000000cccc00000cccc00000fcccc00000000f77565656565657777777777777777777cc777700000000000000000000000000000
-- 023:00000000000000000000000000888828888882cccccccccccc00000ccccc00000000000000000000000000000000000000000000033331cc00880000000000000000000000000cccc00000cccc000000cccf0000000077775555555555667777777777777777ccc777000000000000000000000000000000
-- 024:000000000000000000000000008f8282828288ccccccccccf0888820ccc00000ec0000ec000000c000000000dcc0000000fcc0002111ccccccccccccccc00000004cc00000000cccc00000cccc000000ecc00000000cc777565cf05656566666665cc0077f77cc777f000000000000000000000000000000
-- 025:00000000000000000000000000888888888822cccccccccc00822280000000cccc000ccc0000ccc000000cccccc00000ccccccccf01cccccccccccccccc0000ccccccc0000000cccc00000cccc0000ecccc00000fccc0077cccccc0055566665ccccccc077ccc77770000000000000000000000000000000
-- 026:000000000000000000000000008f8282828288cccccccccc082888820000eccccccccccccccccccc00004ccccccccfcccccccccccccccccccccccccccc000cccccccccc000000ccccf0000ccccf00ccccccf000cccccccccccccccc00556665ccccccccccc00777700000000000000000000000000000000
-- 027:00000000000000000000000000888888888882cccccccccf08882288880ccccccccccccccccccccc0000000ccccccccccff00ccccccccfcccccffff0000ccccfffccccc000000ccc000000ccc00000fcccc000ccccccccccccccccc005556ccccffccccccc00777000000000000000000000000000000000
-- 028:000000000000000000000000008f8282282828ccccccccc008288828880000cccccccfcccccfccccc000000cccccccccc0000cccf0ff00ccccf000000810ccf0000cccc000000cccf00000cccf00000ccccf0000cccccccf0f0cccc005655cccc00ccccccf00f70000000000000000000000000000000000
-- 029:00000000000000000000000000888888888888ccccccccc008822882880000ccccccc00ff000ccccc000000ccccfcccf00000ccf000088ccc08883331110f003330cccc003000ccc000000ccc000000cccc00000ccccccc0000cccc00555ccc0066cccc00007700000000000000000000000000000000000
-- 030:000000000000000000000000008f8228282828cccccccccf082882888f0000cccccf000000000cccc000000cccc0ccccc0002cc038882cccf082811113130021113ccccf03130ccc000000ccc000000cccc00000cccccf000000ccc0055cccccc5ccf0f00f7f000000000000000000000000000000000000
-- 031:000000000000000000000000008888888888882888cccccc00888822880000fcccc00000000000cccc0000cccf000ccccccccf0111288ccc008881111111331111cfccc001113ccc000000ccc000000cccc00000ccccc0000000ccc0055cccccccc000d67770000000000000000000000000000000000000
-- 032:000000000000000000000000008f88f888f8888228cccccc00882ccc8800000cccf00000000000cccc0000ccc00000ccccccccc00311cccc0082811311131114ccc0ccc003131cccf00000cccf00000cccc00000ccccf0000000ccc0056ccccccf00ccc77770000000000000000000000000000000000000
-- 033:000000000000000000000000000888888888f82882ccccccc0088ccc8800000ccc000000000000ccccf00ecc000000cc00cccccc0011cccc0088111111111cccc001cccc00111ccc000000ccc000000cccc00000cccc00000000cccf055ccccc00cccc777700000000000000000000000000000000000000
-- 034:0000000000000000000000000008f8f8e8f8882828cccccccc008ccc8000eccccc0000000000000ccccccccf000000cc0000fcccc003ccccf01111131311ccc00331cccc00311ccc000000ccc000000cccc00000cccc00000000cccf07cccccfecccc677f000000000000000000000000000000000000000
-- 035:000000000000000000000000000088888888888888fccccccccc00c8004ccccccc0000000000000cccccccc000000cc000000ccccf01ccccc001111111cccc001111cccc00111ccc000000ccc000000cccc00000cccc00000000ccc0077cccc00ccc77770000000000000000000000000000000000000000
-- 036:000000000000000000000000000008f88f8e8f28282cccccccccccccccccccccccf0000000000000ccccccf000000cc000233ccccf03cccccc003131ccccccf0311ccccc00311cccc02000cccc00000cccc00000cccc00000000ccc00f7ccccccfcc7770cc00000000000000000000000000000000000000
-- 037:00000000000000000000000000000088888888888880ccccccccccccccccffcccc00000000000000ccccc0000000cccc02111ccc0031fccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000ccccccccccccccccccccccc00000000000000000000000000000000000000
-- 038:00000000000000000000000000000008f88f882282820ccccccccccccccf00cccccc000000000000cccccf00000ecccccccccccc003120ccccccccccffcccccccccffccccccccccccccccccccccccccccccccccccccccc00000ccccccccf0cccccccccccc000000000000000000000000000000000000000
-- 039:000000000000000000000000000000008888888888880ffcccccccccc00000cccccc000000000000fccc0000000ccccccccccc00031110fccccccccf00cccccccf00fcccccfffccccccfffccccccff0ccccccff0cccccc00000ccccccff000cccccccccf0000000000000000000000000000000000000000
-- 040:0000000000000000000000000000000008f8e888288888000f0f0f0f00000000f0f00000000000000ccc000000df0f0f0ffff003311131000f0f0f00330f0f0f00088f0f0f00200f0f000200f0f000000f0f000000f0f00000000f0f0000000f0f0f0f000000000000000000000000000000000000000000
-- 041:000000000000000000000000000000000088888888888880000000000000000000000000000000000ccf000000000000000002111111113000000033113000000882280000333100000333100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 042:00000000000000000000000000000000000000000000000000000000000000000000000000000000ccf0000000000233333331311313111888813311111333333188888133111133333111130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 043:00000000000000000000000000000000000000000000000000000000000000000000000000000004cc00000000000111111111111111111122281111111111111112222811111111111111113000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 044:0000000000000000000000000000000000000000000000000000000000000000000000000000000ccf00000000002111111113113113131128822113131111111112888281131311111313111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 045:000000000000000000000000000000000000000000000000000000000000000000000000000000ccc000000000001111111111111111111112888111111111111111128888811111111111113300000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 046:00000000000000000000000000000000000000000000000000000000000000000000000000000cccf000000000023131313131131131113112282211311213131311318282822113131131131100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 047:0000000000000000000000000000000000000000000000000000000000000000000000000000eccccc00000000311111111111111111111111888881111111111111111888888111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 048:0000000000000000000000000000000000000000000000000000000000000000000000000000cccccc00000000311131131131131131121131128282211311311211311112828221121131131310000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 049:000000000000000000000000000000000000000000000000000000000000000000000000000cccccc000000003111111111111111111111111318888811111111111111118888881111111111130000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 050:00000000000000000000000000000000000000000000000000000000000000000000000000dcf0f0f000000003113113113113113113113113111282822113113113112111128282211311311110000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 051:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000031111111111111111111111111111888888811111111111111118888811111111130000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 052:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000031131131131131131131131131121128282811131131131131211282822113112113000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 053:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000311111111111111111111111111111118888288111111111111111188888811111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 054:000000000000000000000000000000000000000000000000000000000000000000000000000000000000002113113113113113113113113113111212828828221131131131112112828281131131000000000000000000000000000000000000000000000000000f99900000000000000000000000000000
-- 055:000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111111111111111111132882288881111111111111111888888111111000000000000000000000000000000000000000000000000009999990000000000000000000000000000
-- 056:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000231131131131131131131131131131128282888282822113113112113111128282211312000000000000000000000000000000000000000000000000f9999f99000000000000000000000000000
-- 057:00000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111118881111111111288882288888881111111111111111188888811110000000000000000000000000000000000000000000000099aaa9000900000000000000000000000000
-- 058:00000000000000000000000000000000000000000000000000000000000000000000000000000000000021311311311311311318281113113118828281828282828113113113112131112828288110000000000000000000000000000000000000000000000f9abbb9090999000000000000000000000000
-- 059:000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111111111828211111111828888cc1888888888111111111111111118888228300000000000000000000000000000000000000000000099bbbbb9000099900000000000000000000000
-- 060:0000000000000000000000000000000000000000000000000000000000000000000000000000000000003131131131131131182888221131182882ccccc128282282811311311311121211128882200000000000000000000000000000000000000000000f9abbabb9090f09990000000000000000000000
-- 061:000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111111188822888888888822cccccc1888288888881111111111111111111181000000000000000000000000000000000000000000099bbbbbbb900fff0999000000000000000000000
-- 062:00000002222222222222220000000000000000000000000000000000000000000000000000000000000031311311311311382828828282282828cccccccc112882828282811311313111131211111000000000000000000000000000000000000000000f99ababbab90f00f0999900000000000000000000
-- 063:00000003333333333333332200000000000000000000000000000000000000000000000000000000000011111111111118288888c8888888888cccccccccc122888888888811111111111111111113330000000000000000000000000000000000000099abbbbbbbb9ffffff099999000000000000000000
-- 064:000000022222222222222232200000000000000000000000000000000000000000000000000000000000311311311318288282cccccccccccccccccccccccc12282822828221131112131131112111113330000000000000000000000000000000000f99bbabbabba90f00f0f00999900000000000000000
-- 065:0000000333cccccccccc333332000000000000000000000000000000000000000000000000000000000011111111111882888cccccccccccccccccccccccccc11882888888888111111111111111111111133300000000000000000000000000000099aabbbbbbbbb9fffffffff099990000000000000000
-- 066:0000000223cccccccccc44422320000000000000000000000000000000000000000000000000000000002131131131182882cccccccccccccccccccccccccccc1118828282282881131131121131313111111133333000000000000000000000000f9abbbabbabbab900f00000f009999000000000000000
-- 067:0000000333cccccccccc444433322000000000000000000000000000000000000000000000000000000881111111111882ccccccccccccccccccccccccccccccc1112888888882281111111111111111111111111113330000000000000000000099bbbbbbbbbbbbb9fffff99ffff0999000000000000000
-- 068:0000000222cccccccccc34444223220000000000000000000000000000000000000000000000000000882311311311828ccccccccccccccccccccccccccccccccc112282828288828811131113113112131311311111110000000000000000000f99abbabbabbabba90f0000000f0f99f000000000000000
-- 069:0000000333cccccccccc333443333320000000000000000000000000000000000000000000000000002281111111118ccccccccccccccccccccccccccccccccccccc1188c88822882281111111111111111111111111188800000000000000000999bbbbbbbbbbbbb9fffffffffff0999000000000000000
-- 070:0000000223cccccccccc32224442232200000000000000000000000000000000000000000000000000881113113110ccccccccccccccccccccccccccccccccccccccccccccc28828882881131131131113113113138828280000000000000000009999999999999999999999999999999000000000000000
-- 071:0000000333cccccccccc33333344433322000000000000000000000000000000000000000000000000111111111130ccccccccccccccccccccccccccccccccccccccccccccccc88228822888888811111111111882288888000000000000000000099999999999999999999999ccc9990000000000000000
-- 072:0000000223cccccccccc332232244422322000000000000000000000000000000000000000000000231313113113000ccccccccfeffeffefcccccccccccccccccccccccccccccccc88288822828288288288288288828280000000000000000000009900000000000099f99f99ccc9900000000000000000
-- 073:0000000333ccccccccc4333333333443333200000000000000000000000000000000000000000003111111111111000cccc00000fffffffffffffffccccccccccffffffffffcc0000c28228888882888888882882288800000000000000000000000090fffffffffff9999999cccc9000000000000000000
-- 074:0000000222ccccccccc4323222322342232300000000000000000000000000000000000000000231113111311311000cccc0000000fffeffefefeffecccccccfefefefefeff000000ccc888282828282828288288000000000000000000000000000000f00f0f00f009999f9ccccc9000000000000000000
-- 075:00000003334444444444444333333334333300000000000000000000000000000000000000333111111111111113000cccc000000000000fffffffffcccccccffffffff0000000000ccccc28888888811111111111000000000000000000000000000009ffffffffff9999cccccc90000000000000000000
-- 076:00000002233444444444444422322224422200000000000000000000000000000000000023111113131131131131000cccccc000000000000000000fccccccc00000000000000000cccccc000282828281211121130000000000000000000000000000000000f000f099f9ccccc900000000000000000000
-- 077:00000003333444444444444444444444433300000000000000000000000000000000000311111111111111111111000cccccccc00000000000000000ccccccc000000000000000cccccccc0008888888881111111130000000000000000000000000000000ffffffff999ccccc9000000000000000000000
-- 078:000000022223444444444444444444444223000000000000000000000000000000002331113131311311313113110000ccccccccccccc0000000000cccccccc00000000000cccccccccccc00031282828281121113130000000000000000000000000000000900f00099ccccc90000000000000000000000
-- 079:000000003333344444444444444444444333000000000000000000000000000000331111111111111111111111130000cccccccccccccccccccccccccccccccccccccccccccccccccccccc00011188888888111111113300000000000000000000000000000009ffff99cccc900000000000000000000000
-- 080:0000000002222344444444442323232342220000000000000000000000000000231111131311131131131112111130000cccccccccccccccccccccccccccccccccccccccccccccccccccc000031112822828221131111130000000000000000000000000000000999999cccc000000000000000000000000
-- 081:00000000000333344444444433333333c3330000000000000000000000000333111111111111111111111111111110000ccccccccccccccccccccccccccccccccccccccccccccccccccc0000011121888888811111111113000000000000000000000000000000999999ccc0000000000000000000000000
-- 082:00000000000022224444444422222222c32200000000000000000000002331111131313113131131131121131313100000cccccccccccccccccccccccccccccccccccccccccccccccccc0000231311828282828112131311330000000000000000000000000000009f999900000000000000000000000000
-- 083:00000000000003333244444333333333c333000000000000000000003311111111111111111111111111111111111000000cccccccccccccccccccccccccccccccccccccccccccccccc000001111112888888888111111111133000000000000000000000000000009999900000000000000000000000000
-- 084:00000000000000222324444222323232c3220000000000000000000211113113131131131113113113113113111210000000ccccccccccccccccccccccccccccccccccccccccccccccc000021311121828228282822111311111330000000000000000000000000000000000000000000000000000000000
-- 085:0000000000000003333344433333333cc33300000000000000000031111111111111111111111111111111111111100000000ccccccccccccccccccccccccccccccccccccccccccccc0000011111111088888888888111111111113000000000000000000000000000000000000000000000000000000000
-- 086:000000000000000022222444ccccccccc332000000000000000000311313113113113113112113113113113112113008800000ccccccccccccccccccccccccccccccccccccccccccc00000231131131008282828282882213131111000000000000000000000000000000000000000000000000000000000
-- 087:00000000000000000333334cccccccccc3330000000000000000008888111111111111111111118881111111111110088000000ccccccccccccccccccccccccccccccccccccccccc000000111111111000888888888288881111113000000000000000000000000000000000000000000000000000000000
-- 088:00000000000000000022323333333333332200000000000000000082828811131131131131131828221131131131300828800000cccccccccccccccccccccccccccccccccccccc00000023113113112000002828228828282882211000000000000000000000000000000000000000000000000000000000
-- 089:000000000000000000033333333333333333000000000000000000888822888811111111188888888111111111111008828800000cccccccccccccccccccccccccccccccccccc000000011111111111000000882882888888288888000000000000000000000000000000000000000000000000000000000
-- 090:00000000000000000000022232323232232200000000000000000008288828282882882882822828221131131131100828828000000ccccccccccccccccccccccccccccccc000000002313131131131300000008828828282882828000000000000000000000000000000000000000000000000000000000
-- 091:0000000000000000000000000000000000000000000000000000000002288888828828828888888881111111111130088228880000000ccccccccccccccccccccccccccc00000000031111111111111100000000002280888228882000000000000000000000000000000000000000000000000000000000
-- 092:000000000000000000000000000000000000000000000000000000000000082828828828828208281111311311311008288828200000000ccccccccccccccccccccccc0000000002311311311311311310000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 093:00000000000000000000000000000000000000000000000000000000000000000000000000000082111111111188800888228888000000000ccccccccccccccccccc000000000801888111111111111133000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 094:000000000000000000000000000000000000000000000000000000000000000000000000000000812113113118282008288828288800000000000000000000000000000000088820828221131131131111000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 095:00000000000000000000000000000000000000000000000000000000000000000000000000000811111111111888800882288882228800000ddddddddddddddfff00000008882880888881111111111111300000000000000000000000000000000000000000000000000000000000000000000000000000
-- 096:00000000000000000000000000000000000000000000000000000000000000000000000000008111131131138282800828828288882888880d4d4d4d4d4d4d4fff00008882828288282828113113112131100000000000000000000000000000000000000000000000000000000000000000000000000000
-- 097:000000000000000000000000000000000000000000000000000000000000000000000000000811111111111188882008888888222882222204d4d4d4d4d4dddfff00888288888822088888881111111111330000000000000000000000000000000000000000000000000000000000000000000000000000
-- 098:00000000000000000000000000000000000000000000000000000000000000000000000000211313113113182828000828282888828888880d4dcdcdcdcdc4deff00828828282888002828282211311113113000000000000000000000000000000000000000000000000000000000000000000000000000
-- 099:00000000000000000000000000000000000000000000000000000000000000000000000003111111111111888882008888888222882222280ddddddddddddd4fff00882288888200000088888881111111111300000000000000000000000000000000000000000000000000000000000000000000000000
-- 100:00000000000000000000000000000000000000000000000000000000000000000000000021131131131131282280008282282000000000000d4cd44d4cd4dcdfef00828882800000000082282828112131131130000000000000000000000000000000000000000000000000000000000000000000000000
-- 101:000000000000000000000000000000000000000000000000000000000000000000000083111111111111188888800088880000000000000004dddddddddd4d4fff00000000000000000000888888811111111110000000000000000000000000000000000000000000000000000000000000000000000000
-- 102:00000000000000000000000000000000000000000000000000000000000000000000081113113113113182828200008280000000000000000dd4cdc4dc4dcddeff00000000000000000000082822828811311313000000000000000000000000000000000000000000000000000000000000000000000000
-- 103:0000000000000000000000000000000000000000000000000000000000000000000081111111111111188888880000880000000000000000044dddddddddd44fff00000000000090000000008888882211111111300000000000000000000000000000000000000000000000000000000000000000000000
-- 104:000000000000000000000000000000000000000000000000000000000000000000881131131131131182828280000000000008882888288828dcd44dc4dc4ffffe0f999999999999000000000282828881131131133000000000000000000000000000000000000000000000000000000000000000000000
-- 105:00000000000000000000000000000000000000000000000000000000000000000811111111111111188888880000000000008222822282228444ddffffffffffff99999999999999900000000088888228111111111330000000000000000000000000000000000000000000000000000000000000000000
-- 106:000000000000000000000000000000000000000000000000000000000000000021113113113113118282822800000000000828828288288284442defffefffefff9999f99f99f99f990000000008282888221131131113000000000000000000000000000000000000000000000000000000000000000000
-- 107:0000000000000000000000000000000000000000000000000000000000000003111111111111111888888880000000000088822828222228244444fffffffff66699999999999999999000000000088828888111111111300000000000000000000000000000000000000000000000000000000000000000
-- 108:0000000000000000000000000000000000000000000000000000000000000021131311311311318282822800000000008822288282888844444444444466666666699999f99f99f9999900000000008282828221131131133000000000000000000000000000000000000000000000000000000000000000
-- 109:000000000000000000000000000000000000000000000000000000000000331111111111111118888888800000000008228882222822224444444444446666666666699999999999999990000000000888888881111111111330000000000000000000000000000000000000000000000000000000000000
-- 110:000000000000000000000000000000000000000000000000000000000000311311311311311828282282000000000882882228888282844444444444446666666666666999f999f99f9f99900000000082828282211311311113300000000000000000000000000000000000000000000000000000000000
-- 111:000000000000000000000000000000000000000000000000000000000003111111111111118888888880000000008222228882222228844444444444446666666666666999999999999999990000000008888888811111111111133000000000000000000000000000000000000000000000000000000000
-- 112:00000000000000000000000000000000000000000000000000000000002111311311311382828282800000000008288882822882888244444444444444666666666666669999f999f9999f999000000000028282822113113113111300000000000000000000000000000000000000000000000000000000
-- 113:000000000000000000000000000000000000000000000000000000003311111111111182888888800000000000888222282882282228444444444444446666666666666699999999999999999900000000008888888111111111111130000000000000000000000000000000000000000000000000000000
-- 114:000000000000000000000000000000000000000000000000000000231113131131188288282828000000000008222882828228828824444444444444446666666666666669999f99f99f999f9990000000000822828281131131131113000000000000000000000000000000000000000000000000000000
-- 115:000000000000000000000000000000000000000000000000000333111111111111828828888800000000000082888228882882222284444444444444446666666666666669999999999999999999000000000008888888811111111111330000000000000000000000000000000000000000000000000000
-- 116:000000000000000000000000000000000000000000000088333111113113113182882882828000000000000828228282228228888244444444444444446666666666666667999f999f999f999f99900000000000028282828822113131110000000000000000000000000000000000000000000000000000
-- 117:000000000000000000000000000000000000000000000082111111111111118888288288880000000000008882882888882882222844444444444444446666666666666669999999999999999999990000000000008888882888888888880000000000000000000000000000000000000000000000000000
-- 118:000000000000000000000000000000000000000000000088111313811311382282882828000000000000082228228222828228828444444444444444446666666666666667999f99f99f999f999f999000000000000828288282828228280000000000000000000000000000000000000000000000000000
-- 119:000000000000000000000000000000000000000000000022888882211188288888200000000000000000828888882888222882282444444444444444446666666666666666999999999999999999999900000000000008828888888888880000000000000000000000000000000000000000000000000000
-- 120:00000000000000000000000000000000000000000000008828282888282882828000000000000000000828222228282288822882444444444444444444666666666666666699999f9999f99f99f99f9900000000000000828282822828200000000000000000000000000000000000000000000000000000
-- 121:000000000000000000000000000000000000000000000000888888288882288000000000000000000088828888822288222882284444444444444444446666666666666666999999999999999999999999000000000000088888888880000000000000000000000000000000000000000000000000000000
-- 122:0000000000000000000000000000000000000000000000000000000000000000000000000000000008222822822888228828282444444444444444444466666666666666666999f99f999f999f9999f999000000000000008282828000000000000000000000000000000000000000000000000000000000
-- 123:000000000000000000000000000000000000000000000000000000000000000000000000000000008288888828822288228222844444444444444444446666666666666666699999999999999999999999990000000000000000000000000000000000000000000000000000000000000000000000000000
-- 124:00000000000000000000000000000000000000000000000000000000000000000000000000000088282222282828282288288844444444444444444444666666666666666666999999f99f99f99f999f99999000000000000000000000000000000000000000000000000000000000000000000000000000
-- 125:000000000000000000000000000000000000000000000000000000000000000000000000000088222288888222228888222222444444444444444444446666666666666666666999999999999999999999999900000000000000000000000000000000000000000000000000000000000000000000000000
-- 126:000000000000000000000000000000000000000000000000000000000000000000000000008822888822822888828222888821444444444444444444446666666666666666666999f99f999f9999f99f99f9f990000000000000000000000000000000000000000000000000000000000000000000000000
-- 127:000000000000000000000000000000000000000000000000000000000000000000000000882288222288288222282888222284444444444444444444466666666666666666666999999999999999999999999999900000000000000000000000000000000000000000000000000000000000000000000000
-- 128:0000000000000000000000000000000000000000000000000000000000000000000000882288228828228228828282282882444444444444444444444666666666666666666667999999f99f99f99f999f9999f9999000000000000000000000000000000000000000000000000000000000000000000000
-- 129:000000000000000000000000000000000000000000000000000000000000000000000822882288228888288228882882822444444444444444444444466666666666666666666699999999999999999999999999999900000000000000000000000000000000000000000000000000000000000000000000
-- 130:0000000000000000000000000000000000000000000000000000000000000000008828282288228822282828282282282844444444444444444444444666666666666666666666999f99f999f99f999f999f999f99f990000000000000000000000000000000000000000000000000000000000000000000
-- 131:000000000000000000000000000000000000000000000000000000000000000008228288882288228882222282882882824444444444444444444444466666666666666666666669999999999999999999999999999999900000000000000000000000000000000000000000000000000000000000000000
-- 132:0000000000000000000000000000000000000000000000000000000000000088282828222828228822288882828282282444444444444444444444444666666666666666666666669999f99f9999f99f99f99f999f9999990000000000000000000000000000000000000000000000000000000000000000
-- 133:000000000000000000000000000000000000000000000000000000000000882282888288828888228882222822222888444444444444444444444444466666666666666666666666999999999999999999999999999999999900000000000000000000000000000000000000000000000000000000000000
-- 134:00000000000000000000000000000000000000000000000000000000008822882822282282822288228288282888822444444444444444444444444446666666666666666666666669999f999f99f999f999f99f999f9f9f9990000000000000000000000000000000000000000000000000000000000000
-- 135:000000000000000000000000000000000000000000000000000000008822882222888888222888228828228882222444444444444444444444444444466666666666666666666666669999999999999999999999999999999999000000000000000000000000000000000000000000000000000000000000
-- </SCREEN>

-- <PALETTE>
-- 000:1a1c2cff9696f06c6eef7d57ffcd75a7f07038b764257179a11c003b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

