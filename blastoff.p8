pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- blast/off by air
-- todo:
-- collide birds
-- r.size?
-- latest:
-- x to end space walk
-- tweaked music

function reset()
 timer = 0
 sleep = 0
 readout = "debug"
 state = "attract"
 r = {x=56, y=-26, vx=0, vy=0, size=3, thrust=false}
 power = 0.055
 count = 6
 drawcount = false
 shakeframes = 0
 btnclear = true
 g = 0.05
 car = {x=-10, y=2, vx=0.4, vy=0}
 man = {x=-10, y=2, vx=0, vy=0}
 bird = {}
 birdcap = 10
 smoke = {}
 cam = {x=0, y=-120}
 sky_lut = {12,0xcd,13,0xd5,5,0x52,2,0x21,1,0x10,0}
 starsx = {} starsy = {}
 stars = 60
 for i=1,stars do
  add(starsx, flr(rnd(1+127)))
  add(starsy, flr(rnd(1+127)))
 end
 astro = {x=0, y=0, wavespr=52}
 pilot = {on=false, netacc=0, stoptime=0, stopy=0, alt=0}
 temp = 0 -- temperature!
 gen_clouds()
 puff = {}
 camera(cam.x, cam.y)
 music(0)
end

function gen_clouds()
 clouds = {}  
 -- low clouds
 for i=1,10 do
  local left = -10 + flr(rnd(130))
  local height = -400 - flr(rnd(400))
  add(clouds,{x1=left+10,x2=left+55,y=height-10})
  add(clouds,{x1=left,x2=left+67,y=height})
 end
 -- high clouds
 for i=1,20 do
  local left = -10 + flr(rnd(130))
  local height = -800 - flr(rnd(400))
  add(clouds,{x1=left,x2=left+96,y=height})
 end
end

reset()

function make_smoke(sx, sy)
 local s = {x=sx, y=sy, col=7}
 s.vx = 1.5-rnd(3)
 s.vy = 2+rnd(2)
 s.step = 0
 s.age = 0
 s.limit = 36
 return s
end

function make_puff(px, py)
 local p = {x=px, y=py}
 p.vx = 1.5-rnd(3)
 p.vy = r.vy*0.6
 p.size = 4
 p.age = 0
 p.limit = 10
 return p
end
-->8
-- update
function _update()
 timer += 1
 if (sleep > 0) then
  sleep -= 1
 else
  update_funcs[state]()
 end
end

function autopilot()
 if (not pilot.on) return
 pilot.alt = -(r.y+26)
 pilot.netacc = g
 -- always assume thrust
 pilot.netacc -= power
 -- vf = vi + at
 pilot.stoptime = -r.vy/pilot.netacc
 if (pilot.stoptime < 0) then
  pilot.stoptime = "never"
  pilot.stopy = "never"
 else
  -- d = vt + 0.5(at^2)
  pilot.stopy = (r.vy * pilot.stoptime)
  pilot.stopy += 0.5 * pilot.netacc * (pilot.stoptime^2)
  pilot.stopy = abs(pilot.stopy)
 end
 -- do something
 if (pilot.alt > 0.1 and pilot.stopy != "never") then
  if (pilot.stopy > pilot.alt) r.thrust = true
 end
end

function hotness()
 if (temp > 0) temp -= 1
 if (r.vy > 5) temp = 100
 if (r.vy > 7) temp = 200
 if (r.vy > 9) temp = 360
end

function update_bird(b)
 b.x += b.vx
 b.y += b.vy
 b.step += 1
 if (not b.alive) then
  b.vy += g
  b.step += 3
 end
 if (b.step >= 8) then
  b.frame += 1
  if (b.frame > 1) b.frame = 0
  b.step = 0
 end
 if (b.vx > 0 and b.x > 128) del(bird,b)
 if (b.vx < 0 and b.x < 0) del(bird,b)
 if (b.y > 10) del(bird,b)
 --rect(r.x+4,r.y,r.x+11,r.y+21)
 if (b.vx != 0 and b.x>r.x+4 and b.x<r.x+11) then
  if (b.y>r.y and b.y<r.y+21) then
   b.alive = false
   sfx(6)
   sleep = 2
   b.vx = -b.vx*2
   b.vy = -2
  end
 end
end

function update_smoke(s)
 -- s.size means car smoke
 s.x += s.vx
 s.y += s.vy
 s.age += 1
 if (s.size != nil) then
  s.r = s.size
 else
  s.r = 1+rnd(6)
 end
 if (s.age > 20) s.col=6
 if (s.age > 32) s.col=5
 if (s.age > s.limit) then
  del(smoke, s)
 end
 if (s.size == nil and s.y > 1) s.vy = -s.vy/5
end

function spawnbirds()
 if (#bird >= birdcap) return
 local birdroll = flr(rnd(40))
 if (birdroll == 0) then
  add(bird, {x=0,vx=0.1+rnd(0.3),y=-20-rnd(200),vy=0.04-rnd(0.08),step=0,alive=true,frame=0})
 elseif (birdroll == 1) then
  add(bird, {x=128,vx=-0.1-rnd(0.3),y=-20-rnd(200),vy=0.04-rnd(0.08),step=0,alive=true,frame=0})
 end
end

function update_attract()
 if (btn(2)) then
  countdown()
  state="count"
  music(1)
 end
 spawnbirds()
 foreach(bird, update_bird)
 foreach(smoke, update_smoke)
 car.x += car.vx
 car.y += car.vy
 man.x += man.vx
 man.y += man.vy
 if (car.vx > 0 and (flr(car.x) % 2 == 0)) then
  local s = make_smoke(car.x-2,car.y+1)
  s.vx = -0.5 - (rnd() / 2)
  s.vy = -rnd() / 2
  s.size = 1.5
  s.age=30
  add(smoke, s)
 end
 if (car.x >42) then
  car.x = 42
  car.vx = 0
  man.x = 43
  man.vx = 0.06
 end
 if (man.x > 50 and man.y > -25) then
  man.x = 50
  man.vx = 0
  man.vy = -0.1
 end
 if (man.y < -25) then
  man.y = -25
  man.vy = 0
  man.vx = 0.06
 end
 if (man.y == -25 and man.x > 62) then
  man.x = -20
  state="count"
 end
 readout = "press ⬆️ to count down"
end

function countdown()
 btnclear = false
 count -= 1
 shakeframes = 20
 sfx(4)
 drawcount = true
end

function update_count()
 if (not btn(2)) btnclear = true
 if (btnclear and btn(2)) then
  countdown()
 end
 if (count == 0) then
  state = "takeoff"
  music(-1)
  return
 end
 do_camera()
 if (shakeframes > 0) then
  sfx_roar()
 else
  drawcount = false
 end
 spawnbirds()
 foreach(bird, update_bird)
 foreach(smoke, update_smoke)
 readout = "press ⬆️ to count down"
end

function do_buttons()
 if (btn(2)) then
  r.thrust = true
 else
  r.thrust = false
 end
 if (btnp(4)) then
  if (pilot.on) then
   pilot.on = false
  else
   pilot.on = true
  end
 end
end

function do_camera()
 if ((r.y - cam.y) < 40) cam.y = ceil(r.y) - 40
 if ((r.y - cam.y) > 95) cam.y = ceil(r.y) - 95
 if (cam.y > -120) cam.y = -120
 local camshake = {0,0}
 if (r.thrust and r.y > -540) then
  camshake = shake()
 end
 if (shakeframes > 0) then
  camshake = shake()
  shakeframes -= 1
 end
 camera(cam.x+camshake[1], cam.y+camshake[2])
end

function do_smoke()
 if (r.thrust) then
  for i=1,5 do
   add(smoke, make_smoke(64,1+ceil(r.y)+(8*r.size)))
  end
 end
 foreach(smoke, update_smoke)
end

function rate(i)
 rating = "awful"
 if (i<30) rating = "rough"
 if (i<20) rating = "good"
 if (i<10) rating = "great!"
 if (i<3) rating = "perfect!!"
 if (pilot.on) rating = "autopilot"
end

function collide_ground()
 if (r.y > -26) then
  r.y = -26
  if (r.vy > g) then
   shakeframes=10
   impact=flr(r.vy*10)
   rate(impact)
   sfx(5)
   for i=1,8 do
    local s = make_smoke(64,ceil(r.y)+(8*r.size))
    s.vx=1.5-rnd(3)
    s.vy=0
    add(smoke, s)
   end
  end
  r.vy = 0
  if (state == "land") then
   r.thrust = false
   state = "landed"
   music(0)
  end
 end
end

function push_car()
 if (r.y < 40 and r.thrust and car.x > 0) then
  car.x -= 0.01 * car.x
 end
end

function update_takeoff()
 spawnbirds()
 foreach(bird, update_bird)
 foreach(puff, update_puff)
 r.vy += g
 do_buttons()
 autopilot()
 if (r.thrust) r.vy -= power
 r.y += r.vy
 hotness()
 collide_ground()
 push_car()
 readout = -flr(r.y).."m"
 do_camera()
 do_smoke()
 sfx_engine()
 if -flr(r.y) > 2000 then
  state = "space"
  timer = 0
  r.vy=-g
  r.thrust=false
 end
end

function update_space()
 do_smoke()
 if (btnp(5)) then
  if (timer < 300) timer=300
 end
end

function update_land()
 spawnbirds()
 foreach(bird, update_bird)
 foreach(puff, update_puff)
 r.vy += g
 do_buttons()
 autopilot()
 if (r.thrust) r.vy -= power
 r.y += r.vy
 hotness()
 collide_ground()
 readout = -flr(r.y).."m"
 do_camera()
 do_smoke()
 sfx_engine()
end

function update_landed()
 foreach(bird, update_bird)
 do_smoke()
 hotness()
 if (btn(3)) then
  reset()
 end
end

function update_puff(p)
 p.x += p.vx
 p.y += p.vy
 p.age += 1
 if (p.age == 6) p.size = 3
 if (p.age == 8) p.size = 2
 if (p.age == p.limit) then
  del(puff, p)
 end
end
-->8
-- draw
function _draw()
 draw_funcs[state]()
end

function draw_attract()
 cls(0)
 sky()
 mountains()
 ground()
 rocket()
 foreach(bird, draw_bird)
 foreach(smoke, draw_smoke)
 spr(32,man.x, man.y)
 spr(16, car.x, car.y)
 print(readout, cam.x, cam.y, 7)
end

function draw_count()
 cls(0)
 sky()
 mountains()
 ground()
 rocket()
 foreach(bird, draw_bird)
 foreach(smoke, draw_smoke)
 spr(16, car.x, car.y)
 print(readout, cam.x, cam.y, 7)
 if (drawcount) then
  local x = (count*3)-3
  map(x,0,cam.x+52,cam.y+40,3,5)
 end
end

function draw_smoke(s)
 circfill(s.x, s.y, s.r, s.col)
end

function shake()
 local x, y
 x = flr(rnd(3))-1
 y = flr(rnd(3))-1
 return {x,y}
end

function draw_readout()
 print(readout, cam.x, cam.y, 7)
 dir = "❎"
 if (r.vy < 0) dir = "⬆️"
 if (r.vy > 0) dir = "⬇️"
 local auto = ""
 if (pilot.on) auto = ", autopilot on"
 print(dir..flr(abs(r.vy*10))..auto)
 --print("alt: "..flr(pilot.alt))
 --print("acceleration: "..pilot.netacc)
 --print("ticks to stop: "..flr(pilot.stoptime))
 --print("pixels to stop: "..flr(pilot.stopy))
end

function altimeter()
 palt(0, false)
 palt(1, true)
 spr(29, cam.x+1, cam.y+16)
 pal()
 spr(45, cam.x+1, cam.y+24)
 spr(45, cam.x+1, cam.y+32)
 spr(45, cam.x+1, cam.y+40)
 spr(45, cam.x+1, cam.y+48)
 spr(61, cam.x+1, cam.y+56)
 -- space .y / pix in gauge
 altperpix = 2000 / 40
 alt = -r.y / altperpix
 pset(cam.x+2, cam.y+56-alt, 7)
 pset(cam.x+3, cam.y+56-alt, 7)
end

function draw_takeoff()
 sky()
 mountains()
 ground()
 rocket()
 highclouds()
 altimeter()
 spr(16, car.x, car.y)
 foreach(bird, draw_bird)
 foreach(smoke, draw_smoke)
 foreach(puff, draw_puff)
 draw_readout()
end

function astronaut_wave()
 if (timer % 7 == 0) then
  if (astro.wavespr==53) then
   astro.wavespr=52
  else
   astro.wavespr=53
  end
 end
 spr(astro.wavespr, astro.x, astro.y)
end

function astronaut()
 if (timer>20 and timer<50) spr(32, r.x+14, r.y)
 if (timer>50 and timer<80) spr(32, r.x+16, r.y)
 if (timer>80 and timer<110) spr(32, r.x+18, r.y)
 if (timer>110 and timer<140) then
  spr(48, r.x+18, r.y)
 end
 if (timer>140 and timer<170) then 
  spr(49, r.x+20, r.y)
 end
 if (timer>170 and timer<200) then
  spr(50, r.x+22, r.y)
 end
 if (timer>200 and timer<230) spr(51, r.x+24, r.y)
 if (timer>230) then
  if (astro.x == 0) then
   astro.x = r.x+24
   astro.y = r.y
  end
  astronaut_wave()
 end
 if (timer>300) then
  power=0.06
  state = "land"
 end
end

function draw_space()
 sky()
 rocket()
 astronaut() -- state is here
 foreach(smoke, draw_smoke)
 print("★ space walk! ★", cam.x, cam.y, 7)
end

function draw_land()
 sky()
 mountains()
 ground()
 rocket()
 highclouds()
 astronaut_wave()
 altimeter()
 foreach(bird, draw_bird)
 foreach(smoke, draw_smoke)
 foreach(puff, draw_puff)
 draw_readout()
end

function draw_landed()
 sky()
 mountains()
 ground()
 rocket()
 foreach(bird, draw_bird)
 foreach(smoke, draw_smoke)
 print("★ you did it! ★", cam.x, cam.y, 7)
 print("\nlanding speed: "..impact.." ("..rating..")")
 print("\n".."press ⬇️ to launch again")
end

function draw_bird(b)
 if (b.frame == 0) spr(3, b.x, b.y)
 if (b.frame == 1) spr(4, b.x, b.y)
end

function sky()
 cls(0)
 if (r.thrust) then
  sky_lut[1] = 12
  sky_lut[2] = 0xcd
 else
  sky_lut[1] = 1
  sky_lut[2] = 0x1d
 end
 for i=0,#sky_lut do
  if (i % 2 != 0) fillp(0xa5a5)
  rectfill(0,i*-140,128,-140-(i*140),sky_lut[i+1])
  fillp(0)
 end
 for s=1,#starsx do
  local scol = 6+flr(rnd(2))
  if (s % 4 == 0) scol = 7
  pset(cam.x+starsx[s], cam.y+starsy[s], scol)
 end
end

function ground()
 local gcol = 3
 if (r.thrust) gcol = 11
 rectfill(0,0,128,8,gcol)
 local pcol = 5
 if (r.thrust) pcol = 6
 rectfill(48,-3,80,0,pcol)
 if (state == "attract") spr(6,56,-25)
 spr(5,48,-25)
 spr(21,48,-17)
 spr(21,48,-11)
end

function rocket()
 if (temp >= 100) then
  pal(7,10)
  pal(10,9)
 end
 if (temp >= 200) then
  pal(7,9)
  pal(10,8)
 end
 if (temp >= 300) then
  pal(7,8)
  pal(10,8)
 end
 --rect(r.x+4,r.y,r.x+11,r.y+21)
 local x = ceil(r.x)
 local y = ceil(r.y)
 spr(1, x, y)
 spr(2, x+8, y)
 spr(17, x, y+8)
 spr(18, x+8, y+8)
 spr(33, x, y+16)
 spr(34, x+8, y+16)
 if (r.thrust) then
  circfill(x+6, y+23, 1, 7+flr(rnd(4)))
  circfill(x+9, y+23, 1, 7+flr(rnd(4)))
 end
 pal()
end

function mountains()
 if (r.thrust) pal(2, 4)
 local y1 = cam.y+73-(r.y/10)
 draw_cloud({x1=10, x2=120, y=y1+24})
 map(0, 5, 0, y1, 17, 8)
 pal()
end

function highclouds()
 foreach(clouds, draw_cloud)
end

function draw_cloud(z)
 local steps = 4
 if ((z.x2 - z.x1) > 50) steps = 13
 local stepx = (z.x2 - z.x1) / steps
 for step=0,steps do
  local drawx = z.x1 + (step * stepx)
  cloudblob(drawx, z.y)
 end
end

function cloudblob(x, y)
 local bump = (1 - (x % 3))
 circfill(x+1, y+bump+1, 8+bump, 6)
 circfill(x, y+bump, 7, 7)
 if (r.y < -100) then
  if (closer_than({x=x-8,y=y}, r, 10)) then
   add(puff, make_puff(x, y+bump))
  end
 end
end

function draw_puff(p)
 circfill(p.x, p.y, p.size, 7)
end
-->8
-- sfx
function sfx_engine()
 if (r.thrust) then
  sfx_roar()
 else
  if (r.vy >0.3) then
   sfx(3, -1, 32+ceil(r.y/20), 1)
  end
 end
end

function sfx_roar()
 sfx(0, -1, -flr(r.vy*60), 1)
 sfx(1)
end
-->8
-- maths
function closer_than(a,b,d)
 dx = a.x - b.x
 dy = a.y - b.y
 -- fast check
 if abs(dx) < d and abs(dy) < d then
  -- precise check
  if dx*dx + dy*dy < d*d then
   return true
  end  
 end
 return false
end

-->8
-- post_init
update_funcs = {}
update_funcs.attract = update_attract
update_funcs.count = update_count
update_funcs.takeoff = update_takeoff
update_funcs.space = update_space
update_funcs.land = update_land
update_funcs.landed = update_landed

draw_funcs = {}
draw_funcs.attract = draw_attract
draw_funcs.count = draw_count
draw_funcs.takeoff = draw_takeoff
draw_funcs.space = draw_space
draw_funcs.land = draw_land
draw_funcs.landed = draw_landed
__gfx__
00000000000000077000000004000000404000000000000000000000000000070000000007777770077777700000000000000000000000000000000000000000
00000000000000777700000040400000040000000000000000000000000000770000000077777777077777707777770000000000000000000000000000000000
00000000000007777770000000000000000000000766666666666000666667770000000077777777077777707777777000000000000000000000000000000000
00000000000007675570000000000000000000000707070000000000070707670000000077777777077777707777777000000000000000000000000000000000
00000000000007675770000000000000000000000767700000000000000007670000000077777777077777707777777000000000000000000000000000000000
00000000000007675570000000000000000000000707000000000000000007670000000077777777077777707777777000000000000000000000000000000000
00000000000007675770000000000000000000000767000000000000000007670000000077777777077777707777777000000000000000000000000000000000
00000000000007675770000000000000000000000707000000000000000007670000000000000000077777700777777000000000000000000000000000000000
07000000000007677770000000000767777000000767000000000000000007670000000007777770077777700000000000000000607011110000000000000000
66700000000007675770000000000767777000000707000000000000000007670000000077777777077777777777777700000000670711110000000000000000
50500000000007675770000000000767777000000767000000000000000007670000000077777777077777777777777700000000611111110000000000000000
00000000000007675770000000000767777000000707000000000000000007670000000077777777077777777777777700000000111111110000000000000000
00000000000007675770000000000767777000000767000000000000000007670000000077777777077777777777777700000000611111110000000000000000
00000000000007677770000000000767777000000707000000000000000007670000000077777777077777777777777700000000111111110000000000000000
00000000000007675570000000000767777000000767000000000000000007670000000077777777007777777777777700000000611111110000000000000000
00000000000007675570000000000767777000000707000000000000000007670000000007777770000000000000000000000000111111110000000000000000
700000000000a767557a0000000000000000000000000000000000000000a7670000000007777770000000000777777000000000600000000000000000000000
60000000000aa767557aa00000000000000000000000000000000000000aa7670000000077777770007777777777777000000000000000000000000000000000
00000000000aa767777aa00000000000000000000000000000000000000aa7670000000077777770077777777777777000000000600000000000000000000000
0000000000aaa767777aaa000000000000000000000000000000000000aaa7670000000077777770077777777777777000000000000000000000000000000000
00000000000007777770000000000000000000000000000000000000000007770000000077777770077777777777777000000000600000000000000000000000
00000000000000600600000000000000000000000000000000000000000000600000000077777770077777777777777000000000000000000000000000000000
00000000000006066060000000000000000000000000000000000000000006060000000077777770077777777777770000000000600000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000007777770077777700000000000000000000000000000000000000000
00070000000700000007700000077000700770000757700000000000000000020000000022222222200000020000000000000000330000000000000000000000
00565000005950000059700000599600705996000759960000000000000000222200000022222222220000620000000000000000000000000000000000000000
00575000006760000005600000056500570565000705650000000000000006222220000022222222222002220000000000000000000000000000000000000000
00050000007770000057760005777760057777600577776000000000000022222222000022222222222262220000000000000000000000000000000000000000
00000000005650000066560006767650005676500056765000000000000022222222200022222222222222220000000000000000000000000000000000000000
00000000000000000057600000677000006770000067700000000000006222222222220022222222222222220000000000000000000000000000000000000000
00000000000000000007070000755700007557000075570000000000062222222222222022222222222222220000000000000000000000000000000000000000
00000000000000000000000007706700077067000770670000000000222222222222222222222222222222220000000000000000000000000000000000000000
__label__
05d7d7d7d5d7d777d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5
0d7757775d7757575d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d575d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d
0dd7d7d7ddd7d7d7ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd6dddddddddddddddddd
0777d777d777d7d7ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd6dddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddd6ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0d77777dd77dd777dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0777d777dd7dd7d7dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd6dddddddddddddddddddddd7dddddddddddddddddddd
077ddd77dd7dd777dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
077ddd77dd7dd7d7dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0d77777dd777d7777ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0d6070dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0d6707dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0d6ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0d6ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0d6ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0d6ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0d6ddddddddddddddddddddddddddddddddddddddddddddddddddddddddd6ddddddddddddddddddddddddddddddddddddddddd6ddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0d6ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0d6ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0d6dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd6dddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0d6ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0d6ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0d6ddddddddddddddddddddddddddddddddddd7ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0d6ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd77dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd7777ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0d6ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd777777dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddd7dddddddddddddddddddddddddddddddddddddddddddd767557dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0d6ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd767577dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd767557dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0d6ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd767577dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd767577dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0d677dddddddddddd7dddddddddddddddddddddddddddddddddddddddddddd767777dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddd7ddddddddddddddddd767577dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0d6dddddddddddddddddddddddddd6dddddddddddddddddddddddddddddddd767577dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd767577dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0d6ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd767577dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddd7ddddddddddddddddddddddddddddddddddddddddddddddddddddddd767777dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0d6ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd767557dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd767557dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0d33ddddddddddddddddddddddddddddddddddddddddddddddddddddddddda767557addddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddaa767557aadddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddaa767777aadddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddaaa767777aaaddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd777777dddddddddddddddddddddddddddddddddd7ddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddd6ddddddddddd6dd6ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd6a66a6dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd77777adddddddddddddddddddddddddddddddd7ddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddd6ddddddddddddddddddddddddd7777777dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd777777777ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddddddddddd77777777777dddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddd6ddddddddddddddddddddddddd77777777777dddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddddddddddd77777777777dddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddd7ddddddd77777777777dddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
07d7dddddddddddddddddddddddddddddddddddddddddddddddddddddd7777777777777dddddddddddddddddddddddddddddd7dddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddd6ddddddddddddd777777777777777dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddddddddd7777777777777777ddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddddddddd7777777777777777dddddddddddddddddddddddddddddddddddddddddddddddd6dddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddd77777777777777777ddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddddddd777777777777777777ddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddddddd777777777777777777ddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddddddd77777777777777777dddddddddddddddddddddddddddddddddd6ddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddddddd7777777777777777ddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddd7ddddddddddddddddddddd777777777777777dddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddddddd7777777777777777ddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddddddd777777777777777dddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddd777777777777777ddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddddddd77777777777777777dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddd7777777777777777777ddddddddddddddddddddddd7ddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddddd77777777777777777777ddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddd7777777777777777777777dddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddd77777777777777777777777ddddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddd777777777777777777777777dddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddd777777777777777777777777ddddddddddddddddddddddddddddddddddddddddddddddddd7dd
0ddddddddddddddddddddddddddddddddddddddddddddddddddd777777777777777777777777dddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddd7dddddddddddddddddddddddddddddddddd77777777777777777777777dddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddd7777777777777777777777ddddddd6dddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddddddd77777777777777777777ddddddddddddddddddddd7ddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddd777777777777777777d7ddddddddddddddddddddddddddddddddddddddddd6ddddddddd7
0dddddddddddddddddddddddddddddddddddddddddddddddddddddddd7777777777777777d777ddddddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddd777d777777777777777dd7dddddddddddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddddd7777777777777777777ddd77777dddddddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddddd7777777777777777777dd7777777dddddd7dddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddd7d7777777777777777777d777777777ddddddddddddddddddd6dddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddd777d7777777777777777777777777ddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddd77777777777777777777777777dddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd777777777777777777777777dddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd777777777d7777777777777dddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddddddd77777dd7777777dd7777777777777dddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddd777dddd7777777dd77777ddd7777777777777dddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddd7777777d777777777ddd777dddd77777777777ddddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddd777777777777777777d77777d76d777777777dddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddd7ddddddddddddddddddddddddddddd7777777777777777777777777777777777777ddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddd777777777777777777777777777777777777dddddddddddddddddddddddddddddddddddddddddddddddd
fdddddddddddddddddddddddddddddddddddddd7dddd7777777777777777777777777777777777777ddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddd6dddddddddddddddddddddddd777777777777777777777777d77777777777ddddddddddddddddddddddddd7ddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddd7777777d777777777777777d777777777777ddddddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddd777dddd777777777777dd7777777777777ddddddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddddddd77777777777dd7777777777777ddddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddd7dd777777777dd7777777777777dddddddddddddddddddddddddddddddddddddd7dddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddddddd777777777777dddd77777777777777ddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddd77777777777ddddd7777777777777ddddddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddddddd777777777dddddd77777777777777777dddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddd7ddddddddddddddddddddddddddddddddddd777777777777dddd7777777777777777777ddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddd6dddddddddddddddd77777777777777ddd77777777777777777777dddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddddddddd777777777777777ddd77777777777777777777dddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddddddddddd777777777777777777777777777777777777777dddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddddd7777777777777777777777777777777777777777777ddddddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddd7dddddddddddd7777777777777777777777777777777777777777777ddd7dddddddddddddddddddddddddddddddddddddd
0ddddddddddddddddddddddddddddddddddddddddd7777777777777777777777777777777777777777dddddddddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddd7777777777777777777777777777777777777777ddd777ddddddddddddddddddddddddddddddddddddddddd
0dddddddddd7ddddddddddddddddddddddddddddd7777777777777777777777777777777777777777d7777777ddddddddddddddddddddddddddddddddddddddd
0dddddddddddddddddddddddddddddddddddddddd7777777777777777777777777777777777777777d7777777ddddddddddddddddddddddddddddddddddddddd

__map__
1b0b001b1b0b1b1b0b0a000a2a1b1b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a0000000a00000a0a000a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a002a1b2b001b291a1b291a1b0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a000a000000000a00000a00000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b091b1a1b1b1b1b2b00000a1b1b2b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000373800000000000000000037000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3800000037393938000000373800003739000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3938003739393939380037393938373939000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
39393a3939393939393a39393939393939000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3939393939393939393939393939393939000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3939393939393939393939393939393939000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3939393939393939393939393939393939000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3939393939393939393939393939393939000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3939393939393939393939393939393939000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000202003020050200602008020090200b0200d0200e0200f0201102013020150201602017020180201a0201b0201c0201d0201e0201e0201f0201f0201f02020020200202002020020200202002020020
000100000166001650016600165001660016500166001650016600165001660016500166001650016600165001660016500166001650016600165001660016500166001650016600165001660016500166001650
000100001762017620176201762017620176201762017620176201762017620176201762017620176201762017620176201762017620176201762017620176201762017620176201762017620176201762017620
000900003f5103e5103d5103b5103a5103851037510355103451031510305102e5102c51029510275102651024510225101f5101e5101c5101a510175101551013510115100e5100d5100b510085100651003510
000100003f4203f4203f4203e4203d4203c4203c4203b4203a4203942038420374203542033420314202f4202e4202c4202b42029420274202542023420214201f4201c4201a42017420134200f4200942003420
0001000023650227501d650206501a650207501a7500f6500f650176501d7500e6401a7401a7400d640147401774012640167400c7401474008740167300f630137300e630127300c63010730076300761005610
00040000335502e5502a5502355000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000
2d0f00000015000000002500000000353000000045000000002500000000350000000045300000005500000000450000000025000000003530000000150000000035000000001500000000253000000045000000
110f00000015000000001500000000150000000015000000001500000000150000000015000000001500000000150000000015000000001500000000150000000015000000001500000000150000000215000000
__music__
02 07424344
03 08424344

