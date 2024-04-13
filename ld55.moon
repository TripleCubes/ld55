-- title:   game title
-- author:  game developer, email, etc.
-- desc:    short description
-- site:    website link
-- license: MIT License (change this to your license of choice)
-- version: 0.1
-- script:  moon

export t = 0

export BOOT = ->

export TIC = ->
	t += 1

export vecnew = (x, y) ->
	return { x: x, y: y }

-- <TILES>
-- 001:eccccccccc888888caaaaaaaca888888cacccccccacc0ccccacc0ccccacc0ccc
-- 002:ccccceee8888cceeaaaa0cee888a0ceeccca0ccc0cca0c0c0cca0c0c0cca0c0c
-- 003:eccccccccc888888caaaaaaaca888888cacccccccacccccccacc0ccccacc0ccc
-- 004:ccccceee8888cceeaaaa0cee888a0ceeccca0cccccca0c0c0cca0c0c0cca0c0c
-- 017:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 018:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- 019:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 020:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- </TILES>

-- <SPRITES>
-- 000:000000000000000000000011000001110000011c000001cf000001cc0000120c
-- 001:0000000000000000110000001110000011100000c1f00000cc100000c0210000
-- 002:00000000000000000000000000000011000001110000011c000001cf000001cc
-- 003:000000000000000000000000110000001110000011100000c1f00000cc100000
-- 004:000000000000000000000011000001110000011c000001cf000001cc0000120c
-- 005:0000000000000000110000001110000011100000c1f00000cc100000c0210000
-- 016:000100110000021100000111000011110000c211000000ff000000c0000000f0
-- 017:11001000112000001110000011110000112c0000ff0000000c0000000f000000
-- 018:0000120c0001001100000211000001110000c211000000ff000000c0000000f0
-- 019:c0210000110010001120000011100000112c0000ff0000000c0000000f000000
-- 020:000100210000021100001111000cc01100000011000000ff000000c0000000f0
-- 021:120010001120000011110000110cc00011000000ff0000000c0000000f000000
-- 032:00000000000000000000001100000111000001c1000001fc000001cc0000120c
-- 033:000000000000000011000000111000001c1000001f100000cc100000c0210000
-- 048:000100210000021100001111000cc01100000011000000ff000000c0000000f0
-- 049:120010001120000011110000110cc00011000000ff0000000c0000000f000000
-- </SPRITES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2cff9696f06c6eef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

