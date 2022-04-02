-- title:  TBD
-- author: Blind Seer Studios
-- desc:   LD50 - Delay the inevitable
-- script: lua
-- input:  gamepad

--Simplify math operations. Floor will round a decimal.
flr=math.floor
rnd=math.random

--Variables for the screen area
w,h=240,136
hw,hh=w/2,h/2

title=false
indicatorsOn=false
isHuman=true
--Setup camera coordinates
cam={
	x=0,
	y=0,
	mapStart=0,
	mapEnd=472, --Change this for wider levels. This is two map screens
	mapEndY=136
}

--[[Sprite table to hold sprite values so they can be called
by an easier name]]
s={
	pot=240,
	thru=2,
	heart=244,
	pit=3,
	duck=290
}
--Collision detectors
--[[These change where the collision detectors are for
the top and sides of a sprite (Bottom can not be changed
from here. The default is every corner and middle of a 
16x16 sprite. These settings bring the collider detections
in 1 pixel on the sides and top.]]
coll={
	tlx=1, --Defines where the left collider is
	tly=1, --Defines where the top collider is
	trx=14,--Defines where the right collider is
	cly1=7,--Defines where the left top mid collider is 
	cly2=8,--Defines where the left bottom mid collider is
	cry1=7,--Defines where the right top mid collider is
	cry2=8 --Defines where the right bottom mid collider is
}
--Player variables
p={
	idx=256, --Player sprite
	x=hw, --initial player location x
	y=hh, --initial player location y
	vx=0, --Velocity X
	vy=0, --Velocity Y
	vmax=1, --Maximum velocity
	flp=0, --sprite flip
	grounded=true, --set if the player is on the ground
	maxLife=2,
	curLife=2,
	damaged=false,
	ducking=true,
	canMove=true,
	hTime=1000,
	sTime=1000
}
--Enemy variables
e={
	x=112,
	y=16,
	vx=0,
	vy=0,
	l=true
}
--Mapping of control variables
c={
	u=0,
	d=1,
	l=2,
	r=3,
	z=4,
	x=5,
	a=6,
	s=7,
	mxt=0,
	myt=0
}
--[[Sets up animations sprites for the map.
s=animation speed
f=amount of frames]]
tileAnims={
	[240]={s=.05,f=2},
	[244]={s=.1,f=5}
}

spawns={
	[6]=262
}

grav=3.6 --gravity default 3.7
t=0 --timer for animation
timer=0 --timer for blinking damage
win={}
maxCoins=0
notDead=true
--Needed for xprint
dirs={
	{1,0},{-1,0},{0,1},{0,-1},{1,1},
	{-1,-1},{1,-1},{-1,1}
}

--Screen shake variables
screenShake=false

screenShake={
	active=false,
	defaultDuration=15,
	duration=15,
	power=3
}
--Draw the HUD and Debug to the OVR
function OVR()
	if TIC==Update then
		--HUD()
		Debug()
	end
end
--[[Debug Information press I in game to display]]
function Debug()
if indicatorsOn==true then
		print("FPS: "..fps:getValue(),w-23,0,14,false,1,true)
		print("Indicators: " ..tostring(indicatorsOn),0,16,14,false,1,true)
		print("MaxV: "..flr(p.vy),60,24,14,false,1,true)
		print("Grounded: "..tostring(p.grounded),60,16,14,false,1,true)
		print("x: "..p.x,0,24,14,false,1,true)
		print("y: "..p.y,0,32,14,false,1,true)
		print("Speed: "..p.vx,0,40,14,false,1,true)
		print("e.l: "..tostring(e.l),0,48,14,false,1,true)
		print("timer: "..timer,0,56,14,false,1,true)
		print("Ducking: "..tostring(p.ducking),0,64,14,false,1,true)
	
		--[[Collision indicators. 
		These can be moved by changing the variables above in 
		the coll table]]
		pix(p.x+coll.tlx+p.vx-cam.x,p.y%136+coll.tly+p.vy,6) --top left
		pix(p.x+coll.trx+p.vx-cam.x,p.y%136+coll.tly+p.vy,6) --top right
		pix(p.x+7+p.vx-cam.x,p.y%136+coll.tly+p.vy,15) --top mid
		pix(p.x+8+p.vx-cam.x,p.y%136+coll.tly+p.vy,15) --top mid
		pix(p.x+coll.tlx+p.vx-cam.x,p.y%136+15+p.vy,6) --bottom left
		pix(p.x+coll.trx+p.vx-cam.x,p.y%136+15+p.vy,6) --bottom right
		pix(p.x+7+p.vx-cam.x,p.y%136+16+p.vy,7) --bottom mid
		pix(p.x+8+p.vx-cam.x,p.y%136+16+p.vy,7) --bottom mid
		--On ground indicators
		pix(p.x+coll.tlx-cam.x,p.y%136+16+p.vy,12) --bottom left
		pix(p.x+coll.trx-cam.x,p.y%136+16+p.vy,12) --bottom right
		--Middle left indicators
		pix(p.x+coll.tlx+p.vx-cam.x,p.y%136+coll.cly1,8) --left center
		pix(p.x+coll.tlx+p.vx-cam.x,p.y%136+coll.cly2,8) --left center
		--Middle right indicators
		pix(p.x+coll.trx+p.vx-cam.x,p.y%136+coll.cry1,8) --right center
		pix(p.x+coll.trx+p.vx-cam.x,p.y%136+coll.cry2,8) --right center
	end
end

--HUD drawing function
function HUD()
	--Draw the HUD border
	rect(0,0,51,12,0)
	rectb(0,0,51,12,15)
	--Hearts
	for num=1,p.maxLife do
		spr(249,-6+9*num,2)
	end
	for num=1,p.curLife do
		spr(244,-6+9*num,2)
	end
	--Coins
	spr(240,22,2)
	print(string.format("x%02d",p.coins),31,4,15,true,1,false)
end
--[[Init initiates the enemy table (bads) and adds those
enemies to the map then loads the title as TIC. This type
of init system needs to be set up to define what function
TIC will run as...as a cart will not run without a TIC
function.]]
function Init()
	bads={}
	AddEnt()
	if title then
		TIC=Title
	else
		TIC=Update
	end
end

function Title()
	t=t+1
	maxCoins=pmem(0)
	cls()
	map(0,68)
	rect(0,26,256,48,10)
	spr(128,7*8,4*8,8,1,0,0,16,4)
	print("Most Coins Collects: "..maxCoins)
	xprint("Press Z to start",120,96,{6,15},false,1,false,0,false,1)	
	if btnp(c.z) then
		TIC=Update
	end
end
--[[Game Over function that sets certain parameters for when
the player dies]]
function GameOver()
	AddWin(w/2,h/2-30,64,24,15,"You Died!\nPress A to\nreturn to title.")
	--Remove the enemies
	p.idx=294
	p.canMove=false
	for k in pairs(bads) do
		bads[k]=nil
	end
	if btnp(c.a) then
		reset() --not the ideal way of handling but works.
	end
end

function WinScreen()
	t=t+1
	cls()
	--AddWin(w/2,h/2-30,100,24,15,"All coins collected!\nPress A\nto return to title.")
	rect(0,36,256,32,10)
	spr(97,w/2-56,h/2-25,8,1,0,0,14,2)
	xprint("Press Z to return to title",120,100,{6,15},false,1,false,0,false,1)
	if btnp(c.z) then
		reset()
	end
end

function Main()
	--[[Initial placement of the camera. This places the
	camera centered on the player position]]
	cam.x=p.x-120
	--[[Uncomment below if needing smooth scrolling on Y 
	along with	the scrolling in all directions code]]
	cam.y=p.y-113
	--[[This limits the movement of the camera to a bounds of 0 and 464
	(two TIC-80 map screens) to expand change the variables. The -232 
	should not have to be changes as it moves the camera back a full screen]]
	if cam.x<cam.mapStart then
		cam.x=cam.mapStart
	elseif cam.x>cam.mapEnd-232 then
		cam.x=cam.mapEnd-232
	end
	
	if cam.y<cam.mapStart then
		cam.y=cam.mapStart
	elseif cam.y>cam.mapEndY-113 then
		cam.y=cam.mapEndY
	end
	
	cls()
	
	--[[Uncomment for one screen movement.]]
	--map()
	--spr(258,p.x,p.y,0,1,1,0,2,2)
	
	--[[Scrolling in X and full screen load in Y]]
	map(cam.x//8,cam.y//8,31,18,-(cam.x%8),-(cam.y%8),0,1,remap)
	if p.damaged then --If the player is damaged blink the player
		if (time()%300>200) then
			spr(p.idx,p.x-cam.x,p.y-cam.y,7,1,p.flp,0,2,2)
		end
	else
		spr(p.idx,p.x-cam.x,p.y-cam.y,7,1,p.flp,0,2,2)
	end
	--[[Scrolling only along X but loading full map grid 
		on Y. This breaks enemy map placement.]]
	--[[map(cam.x//8,(p.y//136)*17,31,18,-(cam.x%8),-(cam.y%8),0,1,remap)
	if p.damaged then --If the player is damaged blink the player
		if (time()%300>200) then
			spr(p.idx,p.x-cam.x,p.y%136,0,1,p.flp,0,2,2)
		end
	else
		spr(p.idx,p.x-cam.x,p.y%136,0,1,p.flp,0,2,2)
	end]]

	--Press I to turn on information and collision indicators
	if keyp(09) and indicatorsOn==false then
		indicatorsOn=true
	elseif keyp(09) and indicatorsOn==true then
		indicatorsOn=false
	end
	
	if p.coins==16 then
		TIC=WinScreen
	end
	
	t=t+1
end

function Update()
	Main()
	if notDead then
		Player()
	end
	Enemy()
	ShakeScreen()
	Collectiables()
	Blinky()
end

function Player()
	--Set controls to move the player
	if p.canMove and p.grounded then
		if btn(c.l) and not p.ducking then
			p.vx=-p.vmax
			p.idx=288+t%60//10*2
			p.flp=1
			t=time()//9
		elseif btn(c.r) and not p.ducking then
			p.vx=p.vmax
			p.idx=288+t%60//10*2
			p.flp=0
			t=time()//9
		else
			p.vx=0
			p.idx=256+t%40//10*2
		end
	
		if p.vy==0 and btnp(c.z) and not p.ducking then 
			p.vy=p.vy-grav
			p.grounded=false
			p.idx=264
		end
	end
	--Duck	
	if btn(c.d) and p.vx==0 then
		p.idx=266
		p.ducking=true
		--[[Shift the colliders down so the player can crawl
		under walls]] 
		coll.tly=9
		coll.cly1=11
		coll.cly2=12
		coll.cry1=11
		coll.cry2=12
	else
		p.ducking=false
		coll.tly=1
		coll.cly1=7
		coll.cly2=8
		coll.cry1=7
		coll.cry2=8
	end
	--[[Crawl
	if btn(c.l) and p.ducking then
		p.idx=292
		p.vx=-p.vmax
		p.flp=1
	elseif btn(c.r) and p.ducking then
		p.idx=292
		p.vx=p.vmax
		p.flp=0
	end]]
	
	--Check if something is to the side
	if solid(p.x+coll.tlx+p.vx,p.y+coll.tly+p.vy,0) or 
				solid(p.x+coll.trx+p.vx,p.y+coll.tly+p.vy,0) or
				solid(p.x+coll.tlx+p.vx,p.y+15+p.vy,0) or
				solid(p.x+coll.trx+p.vx,p.y+15+p.vy,0) or
				solid(p.x+coll.tlx+p.vx,p.y+coll.cly1,0) or
				solid(p.x+coll.tlx+p.vx,p.y+coll.cly2,0) or
				solid(p.x+coll.trx+p.vx,p.y+coll.cry1,0) or
				solid(p.x+coll.trx+p.vx,p.y+coll.cry2,0) then
		p.vx=0
	end
	--checks if you are on the ground
	if solid(p.x+coll.tlx,p.y+16+p.vy,0) or
				solid(p.x+coll.trx,p.y+16+p.vy,0) or
				solid(p.x+7+p.vx,p.y+16+p.vy,0) or
				solid(p.x+8+p.vx,p.y+16+p.vy,0) or
				solid(p.x+coll.tlx,p.y+16+p.vy,1) or
				solid(p.x+coll.trx,p.y+16+p.vy,1) or
				solid(p.x+7+p.vx,p.y+16+p.vy,1) or
				solid(p.x+8+p.vx,p.y+16+p.vy,1) then
		p.vy=0
		p.grounded=true
	else
		p.vy=p.vy+0.2
		p.grounded=false
	end
	--check if something is above
	if p.vy<0 and (solid(p.x+coll.tlx+p.vx,p.y+coll.tly+p.vy,0) or
																solid(p.x+coll.trx+p.vx,p.y+coll.tly+p.vy,0) or
																solid(p.x+7+p.vx,p.y+coll.tly+p.vy,0) or
																solid(p.x+8+p.vx,p.y+coll.tly+p.vy,0)) then
		p.vy=0
	elseif p.vy<0 and (solid(p.x+coll.tlx+p.vx,p.y+coll.tly+p.vy,1) or
																solid(p.x+coll.trx+p.vx,p.y+coll.tly+p.vy,1) or
																solid(p.x+7+p.vx,p.y+coll.tly+p.vy,1) or
																solid(p.x+8+p.vx,p.y+coll.tly+p.vy,1)) then
		fset(s.thru,1,false)
	end
	
	--[[if the sprite is tile 2 and has flag 2 either set
	as true or false]]
	if p.grounded==true and not btnp(c.d) then
		fset(s.thru,1,true)
	elseif p.grounded==true then
		fset(s.thru,1,false)
	end
	
	if p.vy>=1.5 then
		fset(s.thru,1,true)
	end
 --Apply motion to player
	p.x=p.x+p.vx
	p.y=p.y+p.vy
	--Block the player from leaving the map area
	if p.x<cam.mapStart then
		p.x=cam.mapStart
	elseif p.x>cam.mapEnd-8 then
		p.x=cam.mapEnd-8
	end
	
	if p.hTime>=0 then
		p.hTime=flr(p.hTime-time()//1000)
		print(p.hTime,0,0,7)
	end
	
	if p.hTime<=0 then
		p.idx=320+t%40//10*2
		p.sTime=flr(p.sTime-time()//1000)
		print(p.sTime,0,0,7)
	end
	
	if p.sTime<=0 then
		p.sTime=0
		Dead()
	end
	--Pit()
end

function Dead()
	p.canMove=false
	p.idx=328
	AddWin(w/2,h/2-30,64,24,4,"You Died!\nPress A to\ncontinue.")
	--if p.curLife<=0 then
	--	GameOver()
	--end
end
--Define the variables for the bads table
function AddBad(t)
	table.insert(bads,{
		t=t.t or 0,
		x=t.x,
		y=t.y,
		vx=t.vx or 0,
		vy=t.vy or 0,
		l=t.l,
		flp=t.flp,
		spr=t.spr or 64,
		hp=t.hp or 100,
		type=t.type or "normal",
		mtype=t.mtype or 0,
		bt=t.bt or nil
	})
end

--Add entities into the spawns table
function AddEnt()
	for x=0,240 do
		for y=0,136 do
			if spawns[mget(x,y)] then
				AddBad({spr=(mget(x,y)+256),x=x*8,y=y*8})
			elseif mget(x,y)==4 then
			--if spawns[mget(x,y)] then
				AddBad({spr=(mget(x,y)),x=x*8,y=y*8,type="plat"})
			end
		end
	end
end

--[[Sets up enemies from the AddBad() into a table and
sets them up on the level replacing the placeholder sprite]]
function Enemy()
	for i,v in pairs(bads) do
		--Set initial velocity
		v.vx=0
		--[[if on solid ground move left, if velocity becomes 0
		set moving left to false and move in the other direction]]
		if not solid(v.x-1,v.y+15+v.vy,0) and solid(v.x+1,v.y+16+v.vy) and v.l then
			v.vx=v.vx-0.3
		elseif v.vx==0 then
			v.l=false
		end
		
		if not solid(v.x+14,v.y+15+v.vy,0) and solid(v.x+14,v.y+16+v.vy) and not v.l then
			v.vx=v.vx+0.3
		elseif v.vx==0 then
			v.l=true
		end
		--apply movement to the enemy
		v.x=v.x+v.vx
		
		spr(v.spr,v.x-cam.x,v.y-cam.y,16,1,0,0,2,2)
		mset(v.x/8,v.y/8,0)
		
		if v.x//8+1==p.x//8+1 and v.y//8==p.y//8 and p.curLife>0 and not p.damaged then
			p.curLife=p.curLife-1
			p.damaged=true
			screenShake.active=true
		end
	end
end

function Blinky()
	if p.damaged and timer<=100 then
		timer=timer+1
	elseif timer>=100 then
		p.damaged=false
		timer=0
	end
end

function Pit()
	if mget(p.x//8+1,p.y//8)==s.pit then
		--pit=true
		reset()
	end
end

function Collectiables()
	--[[Collisions with collectibles can be done either with
	flags set on the sprites, or by looking for the actual
	sprite itself.]] 
	--if fget(mget(p.x/8+1,p.y/8+1),1) then
	if mget(p.x//8+1,p.y//8+1)==s.pot or mget(p.x//8,p.y//8)==s.pot then
	 mset(p.x//8+1,p.y//8+1,0)
		mset(p.x//8,p.y//8,0)
		p.hTime=p.hTime+1000
	--sfx(01,'E-6',5)
	end
	if mget(p.x/8+1,p.y/8+1)==s.heart and p.curLife<2 then
	 mset(p.x/8+1,p.y/8+1,0)
		p.curLife=p.curLife+1
	--sfx(01,'E-6',5)
	end
end

--Run the init function
Init()

--Tool functions--
--All of the code below are helper functions.
--[[Animated tile setup]]
function remap(animTile)
	local outTile,flip,rotate=animTile,0,0
	local at=tileAnims[animTile]
	if at then
		outTile=outTile+flr(t*at.s)%at.f
	end
	return outTile,flip,rotate
end
--Setup tiles as solid with a certain flag
function solid(x,y,f)
	return fget(mget(flr(x//8),flr(y//8)),f)
end

--[[Extends the print function to do fancier things with
				it.]]
function xprint(txt,x,y,col,fixed,
																scale,smallfont,align,
																thin,blink)
	--[[
		txt=string 
			this is the only obligatory 
			argument. All others are	optional;
		
		x,y=coordinates;
		
		col=color
			number for borderless,
			table for outlined;
		
		fixed, scale, smallfont:
			same as in the	default TIC-80 
			print function;
			
		align=-1(left),0(center),1(right);
		
		thin=true/false
			outline thickness;
		
		blink=number (frequency of blinking)
	--]]
	
	if blink then
		if t%(60*blink)//(30*blink)==1 then 
			return 
		end
	end
	
	if not x then
		x=120
		align=0
	end
	if not y then 
		y=63
	end
	
	if not col then 
		col={12,0} 
	end
	if type(col)=="number" then
		col={col}
	end
	
	if not scale then scale=1 end
	
	local width=print(txt,0,-100,0,fixed,
														scale,smallfont)
	local posx=x
	if align==0 then
		posx=x-(width//2)
	elseif align==1 then
		posx=x-width
	end
	
	if col[2] then
		local len=8
		if thin then len=4 end
		for o=1,len do
			print(txt,posx+dirs[o][1],
				y+dirs[o][2],col[2],fixed,scale,
				smallfont)
		end
	end
	
	print(txt,posx,y,col[1],fixed,scale,
		smallfont)
end
--Screen Shake function
function ShakeScreen()
 if screenShake.active==true then
		poke(0x3FF9,rnd(-screenShake.power,screenShake.power))
		poke(0x3FF9+1,rnd(-screenShake.power,screenShake.power))
		screenShake.duration=screenShake.duration-1
		
		if screenShake.duration<=0 then
			screenShake.active=false
		end
 else
  memset(0x3FF9,0,2)
  screenShake.active=false
  screenShake.duration=screenShake.defaultDuration
	end
end
--Add
function AddWin(x,y,w,h,col,txt)
	for i=1,#win do
		table.insert(win,i,#win)
	end
	rect(x-w/2,y-h/2,w,h,col)
	rectb(x-w/2+1,y-h/2+1,w-2,h-2,1) --no idea but it works
 print(txt,x-w/2+3,y-h/2+3,0,0,1,true)
end

function DrawWin()
	for w in pairs(win) do
		rect(w.x,w.y,w.w,w.h,0)
	end
end
--Calculate frames per second
FPS={}

function FPS:new(o)
	o=o or {}
	setmetatable(o,self)
	self.__index=self
	self.value=0
	self.frames=0
	self.lastTime=0
	return FPS
end

function FPS:getValue()
	if (time()-self.lastTime<=1000) then
		self.frames=self.frames+1
	else
		self.value=self.frames
		self.frames=0
		self.lastTime=time()
	end
	return self.value
end

fps=FPS:new()
-- <TILES>
-- 000:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 001:7777777777777777777777777777777777777777777777777777777777777777
-- 002:77777777ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 003:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 004:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 005:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 006:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 007:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 008:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 009:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 010:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 011:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 012:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 013:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 014:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 015:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 016:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 017:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 018:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 019:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 020:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 021:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 022:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 023:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 024:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 025:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 026:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 027:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 028:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 029:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 030:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 031:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 032:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 033:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 034:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 035:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 036:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 037:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 038:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 039:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 040:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 041:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 042:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 043:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 044:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 045:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 046:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 047:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 048:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 049:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 050:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 051:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 052:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 053:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 054:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 055:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 056:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 057:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 058:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 059:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 060:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 061:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 062:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 063:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 064:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 065:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 066:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 067:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 068:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 069:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 070:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 071:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 072:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 073:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 074:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 075:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 076:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 077:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 078:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 079:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 080:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 081:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 082:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 083:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 084:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 085:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 086:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 087:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 088:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 089:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 090:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 091:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 092:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 093:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 094:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 095:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 096:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 097:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 098:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 099:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 100:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 101:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 102:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 103:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 104:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 105:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 106:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 107:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 108:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 109:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 110:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 111:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 112:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 113:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 114:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 115:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 116:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 117:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 118:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 119:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 120:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 121:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 122:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 123:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 124:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 125:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 126:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 127:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 128:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 129:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 130:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 131:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 132:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 133:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 134:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 135:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 136:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 137:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 138:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 139:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 140:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 141:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 142:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 143:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 144:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 145:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 146:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 147:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 148:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 149:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 150:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 151:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 152:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 153:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 154:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 155:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 156:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 157:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 158:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 159:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 160:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 161:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 162:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 163:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 164:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 165:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 166:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 167:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 168:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 169:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 170:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 171:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 172:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 173:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 174:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 175:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 176:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 177:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 178:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 179:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 180:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 181:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 182:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 183:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 184:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 185:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 186:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 187:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 188:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 189:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 190:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 191:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 192:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 193:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 194:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 195:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 196:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 197:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 198:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 199:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 200:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 201:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 202:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 203:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 204:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 205:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 206:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 207:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 208:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 209:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 210:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 211:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 212:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 213:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 214:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 215:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 216:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 217:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 218:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 219:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 220:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 221:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 222:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 223:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 224:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 225:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 226:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 227:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 228:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 229:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 230:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 231:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 232:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 233:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 234:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 235:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 236:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 237:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 238:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 239:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 240:fffffffff111111fff1441ffff1221fff124421f1244442112222221f111111f
-- 241:f111111fff1441ffff1221fff124421f1244442112222221f111111fffffffff
-- 242:f23ffffff23ffffff23ffffff23ffffff23ffffff23ffffff11fffff1111ffff
-- 243:f211fffff21311fff213331ff213311ff2111ffff21ffffff11fffff1111ffff
-- 244:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 245:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 246:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 247:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 248:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 249:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 250:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 251:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 252:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 253:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 254:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 255:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- </TILES>

-- <SPRITES>
-- 000:7777777777777777777777777777771177777123777712327777122477771244
-- 001:7777777777777777777777771117777733317777333317774443177744417777
-- 002:7777777777777777777777777777777777777711777771237777123277771224
-- 003:7777777777777777777777777777777711177777333177773333177744431777
-- 004:7777777777777777777777777777777777777711777771237777123277771224
-- 005:7777777777777777777777777777777711177777333177773333177744431777
-- 006:7777777777777777777777777777771177777123777712327777122477771244
-- 007:7777777777777777777777771117777733317777333317774443177744417777
-- 008:7777777777777777777777117777713377771323771112327143122371431244
-- 009:7777777777777777111777773331777733331777333311773333341744443417
-- 010:7777777777777777777777777777777777777777777777117777712377771232
-- 011:7777777777777777777777777777777777777777111777773331777733331777
-- 012:7777777777777777777777777777777777777777777777777777777777777777
-- 013:7777777777777777777777777777777777777777777777777777777777777777
-- 014:7777777777777777777777777777777777777777777777777777777777777777
-- 015:7777777777777777777777777777777777777777777777777777777777777777
-- 016:7777123477771334777132237713322377144223771432227771122177771221
-- 017:4441777744417777332317773323317733244177222341771221177712217777
-- 018:7777124477771234777133347713322377144223771432237771122277771221
-- 019:4441777744417777444317773323317733244177332341772221177712217777
-- 020:7777124477771234777713347771322377133223771442237714322277711221
-- 021:4441777744417777444177773323177733233177332441772223417712211777
-- 022:7777124477771334777712237771322377133223771442227714322177711221
-- 023:4441777744417777332177773323177733233177222441771223417712211777
-- 024:7713333477713223777712237777122377771222777771227777771277777771
-- 025:4443317733231777332177773321777722221777212221771712177777717777
-- 026:7777122477771244777712347771322377133223714412237143122177111221
-- 027:4443177744417777444177773323177733233177332144171221341712211177
-- 028:7777777777777777777777777777777777777777777777777777777777777777
-- 029:7777777777777777777777777777777777777777777777777777777777777777
-- 030:7777777777777777777777777777777777777777777777777777777777777777
-- 031:7777777777777777777777777777777777777777777777777777777777777777
-- 032:7777777777777777777777117777712377771232777712247777124477771234
-- 033:7777777777777777111777773331777733331777444317774441777744417777
-- 034:7777777777777777777777777777777777777711777771237777123277771224
-- 035:7777777777777777777777777777777711177777333177773333177744431777
-- 036:7777777777777777777777777777771177777123777712327777122477771244
-- 037:7777777777777777777777771117777733317777333317774443177744417777
-- 038:7777777777777777777777117777712377771232777712247777124477771234
-- 039:7777777777777777111777773331777733331777444317774441777744417777
-- 040:7777777777777777777777777777777777777711777771237777123277771224
-- 041:7777777777777777777777777777777711177777333177773333177744431777
-- 042:7777777777777777777777777777771177777123777712327777122477771244
-- 043:7777777777777777777777771117777733317777333317774443177744417777
-- 044:7777777777777777777777777777777777777777777777777777777777777777
-- 045:7777777777777777777777777777777777777777777777777777777777777777
-- 046:7777777777777777777777777777777777777777777777777777777777777777
-- 047:7777777777777777777777777777777777777777777777777777777777777777
-- 048:7777133477713223777133447777134377771222777122217771221777771177
-- 049:4441777733217777332317773324177722221777112221777712217777711777
-- 050:7777124477771234777713347771322377713344777713437771222177712217
-- 051:4441777744417777444177773321777733231777332217771122177771221777
-- 052:7777123477771334777132237713322377144223771432227771122177771221
-- 053:4441777744417777332317773323317733244177222341771221177712217777
-- 054:7777133477713223771332237144122371431222771171227777771277777771
-- 055:4441777733231177332344173321341722211177221777772177777717777777
-- 056:7777124477771234777713347771322377133223714412237143122277117122
-- 057:4441777744417777444177773323117733234417332134172221117722177777
-- 058:7777123477771334777132237713322377144223771432227771122177771221
-- 059:4441777744417777332317773323317733244177222341771221177712217777
-- 060:7777777777777777777777777777777777777777777777777777777777777777
-- 061:7777777777777777777777777777777777777777777777777777777777777777
-- 062:7777777777777777777777777777777777777777777777777777777777777777
-- 063:7777777777777777777777777777777777777777777777777777777777777777
-- 064:7777777777777777777777777777777777777777777744447774444477744433
-- 065:7777777777777777777777777777777777777777444477773333377733333777
-- 066:7777777777777777777777777777777777777444777444447774443377334443
-- 067:7777777777777777777777777777777744477777333337773333377733333377
-- 068:7777777777777777777777777777774477774444777443337774443377334444
-- 069:7777777777777777777777774477777733337777333337773333377744433377
-- 070:7777777777777777777777777777777777777444777444447774443377334443
-- 071:7777777777777777777777777777777744477777333337773333377733333377
-- 072:7777777777777777777777777777777777777777777777777777777777777777
-- 073:7777777777777777777777777777777777777777777777777777777777777777
-- 074:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 075:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 076:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 077:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 078:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 079:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 080:7733444377333423733322127322222273222222722222227722222277771121
-- 081:4433337734233377221233372222213722222137222211172211117711117777
-- 082:7733344473332422732222127322222273222222722222227722222277771121
-- 083:4443337724223337221222372222213722221137222111172211117711117777
-- 084:7733242277322212773222227732222277222222772222227771112177777111
-- 085:2422337722122377222213772222137722211277221112771111177711177777
-- 086:7733342473332212732222227322222273222222722222227722222277771121
-- 087:4423337722123337222222372222213722221137222111172211117711117777
-- 088:7777777777777777777777777774444477334443732222227322222277222222
-- 089:7777777777777777777777773333377733333377222222372222113722111177
-- 090:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 091:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 092:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 093:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 094:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 095:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 096:7777777777777777777777777777777777777777777744447774444477744433
-- 097:7777777777777777777777777777777777777777444477773333377733333777
-- 098:7777777777777777777777777777777777777777777774447774444477744433
-- 099:7777777777777777777777777777777777777777444777773333337733333377
-- 100:7777777777777777777777777777777777777777777777777744444474443333
-- 101:7777777777777777777777777777777777777777777777774433377733333377
-- 102:7777777777777777777777777777777777777777777774447774443377444333
-- 103:7777777777777777777777777777777777777777444777773333337733333377
-- 104:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 105:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 106:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 107:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 108:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 109:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 110:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 111:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 112:7733444377333333733322227322222273222222722222227722222277771121
-- 113:4433337733342377222213372222213722222137222211172211117711117777
-- 114:7733444377333333733322227322222273222222722222227722222277771121
-- 115:3443333733334237222221332222221322222213222221122221111711111777
-- 116:3344434333333333332222222222222222222222222222222222222277112111
-- 117:3443333733334237222221332222221322222213222221112221111711111777
-- 118:7334443373333333333222223222222232222222222222227222222277711211
-- 119:3443333733334237222221332222221322222213222221112221111711111777
-- 120:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 121:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 122:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 123:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 124:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 125:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 126:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 127:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 128:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 129:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 130:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 131:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 132:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 133:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 134:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 135:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 136:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 137:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 138:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 139:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 140:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 141:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 142:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 143:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 144:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 145:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 146:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 147:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 148:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 149:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 150:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 151:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 152:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 153:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 154:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 155:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 156:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 157:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 158:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 159:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 160:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 161:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 162:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 163:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 164:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 165:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 166:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 167:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 168:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 169:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 170:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 171:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 172:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 173:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 174:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 175:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 176:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 177:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 178:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 179:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 180:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 181:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 182:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 183:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 184:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 185:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 186:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 187:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 188:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 189:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 190:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 191:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 192:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 193:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 194:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 195:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 196:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 197:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 198:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 199:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 200:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 201:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 202:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 203:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 204:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 205:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 206:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 207:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 208:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 209:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 210:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 211:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 212:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 213:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 214:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 215:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 216:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 217:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 218:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 219:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 220:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 221:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 222:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 223:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 224:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 225:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 226:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 227:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 228:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 229:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 230:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 231:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 232:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 233:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 234:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 235:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 236:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 237:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 238:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 239:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 240:fffffffff22ff21f2222222122222221f222221fff2221fffff21fffffffffff
-- 241:fffffffff11ff11f1331132113333321f133321fff1321fffff11fffffffffff
-- 242:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 243:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 244:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 245:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 246:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 247:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 248:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 249:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 250:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 251:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 252:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 253:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 254:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 255:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- </SPRITES>

-- <MAP>
-- 000:040000000000000000000000000000000000000000000000000000000004040000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:000000000000000000000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:000000000000000000202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 033:040000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 050:000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 072:000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <FLAGS>
-- 000:00102000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </FLAGS>

-- <SCREEN>
-- 026:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 027:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 028:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 029:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 030:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 031:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 032:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 033:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 034:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 035:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 036:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaffffffffffff00aaffffff00aaaaaaaaaaffffffffff00aaffffffffffffff00ffffffffffffff00aaffffffffff00aaffffffffffff00aaffff00aaaaffff00aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 037:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaffffffffffff00aaffffff00aaaaaaaaaaffffffffff00aaffffffffffffff00ffffffffffffff00aaffffffffff00aaffffffffffff00aaffff00aaaaffff00aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 038:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaffffff00ffffff00ffffff00aaaaaaaaffffff00ffffff000000ffffff000000ffffff0000000000ffffff00ffffff00ffffff00ffffff00ffffff00ffffff00aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 039:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaffffff00ffffff00ffffff00aaaaaaaaffffff00ffffff000000ffffff000000ffffff0000000000ffffff00ffffff00ffffff00ffffff00ffffff00ffffff00aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 040:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaffffff00ffffff00ffffff00aaaaaaaaffffff00ffffff00aaaaffffff00aaaaffffffffffff00aaffffff00ffffff00ffffff00ffffff00ffffffffffffff00aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 041:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaffffff00ffffff00ffffff00aaaaaaaaffffff00ffffff00aaaaffffff00aaaaffffffffffff00aaffffff00ffffff00ffffff00ffffff00ffffffffffffff00aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 042:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaffffffffffff0000ffffff00aaaaaaaaffffffffffffff00aaaaffffff00aaaaffffff00000000aaffffff00ffffff00ffffffffffff0000ffff00ff00ffff00aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 043:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaffffffffffff0000ffffff00aaaaaaaaffffffffffffff00aaaaffffff00aaaaffffff00000000aaffffff00ffffff00ffffffffffff0000ffff00ff00ffff00aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 044:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaffffff00000000aaffffffffffffff00ffffff00ffffff00aaffffffffff00aaffffff00aaaaaaaa00ffffffffff0000ffffff00ffffff00ffff000000ffff00aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 045:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaffffff00000000aaffffffffffffff00ffffff00ffffff00aaffffffffff00aaffffff00aaaaaaaa00ffffffffff0000ffffff00ffffff00ffff000000ffff00aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 046:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa00000000aaaaaaaa00000000000000000000000000000000aa000000000000aa00000000aaaaaaaaaa000000000000aa0000000000000000000000aaaa000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 047:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa00000000aaaaaaaa00000000000000000000000000000000aa000000000000aa00000000aaaaaaaaaa000000000000aa0000000000000000000000aaaa000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 048:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 049:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 050:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 051:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 052:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaffffffffffffff00ffff00aaaaffff00aaffffffffff00aaffffff00ffff00aaaaffff00ffffffffffffff00aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 053:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaffffffffffffff00ffff00aaaaffff00aaffffffffff00aaffffff00ffff00aaaaffff00ffffffffffffff00aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 054:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaffffff0000000000ffffffff00ffff00ffffff0000000000ffffff00ffffffff00ffff00ffffff0000000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 055:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaffffff0000000000ffffffff00ffff00ffffff0000000000ffffff00ffffffff00ffff00ffffff0000000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 056:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaffffffffffff00aaffffffffffffff00ffffff00ffffff00ffffff00ffffffffffffff00ffffffffffff00aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 057:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaffffffffffff00aaffffffffffffff00ffffff00ffffff00ffffff00ffffffffffffff00ffffffffffff00aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 058:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaffffff00000000aaffff00ffffffff00ffffff0000ffff00ffffff00ffff00ffffffff00ffffff00000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 059:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaffffff00000000aaffff00ffffffff00ffffff0000ffff00ffffff00ffff00ffffffff00ffffff00000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 060:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaffffffffffffff00ffff000000ffff0000ffffffffff0000ffffff00ffff000000ffff00ffffffffffffff00aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 061:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaffffffffffffff00ffff000000ffff0000ffffffffff0000ffffff00ffff000000ffff00ffffffffffffff00aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 062:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000aaaa000000aa000000000000aa00000000000000aaaa0000000000000000000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 063:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000aaaa000000aa000000000000aa00000000000000aaaa0000000000000000000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 064:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 065:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 066:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 067:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 068:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 069:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 070:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 071:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 072:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 073:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 095:00000000000000000000000000000000000000000000000000000000000000000000000000ffffff0000000000000000000000000000fffffff0000ffff000000000000000000ffff00000000000000ffff00000000000000000000000000000000000000000000000000000000000000000000000000000
-- 096:00000000000000000000000000000000000000000000000000000000000000000000000000f6666fffffff0fffff0ffffffffffff000f66666f000ff66ffffffff00000fffffff66ffffffffffffffff66fff000000000000000000000000000000000000000000000000000000000000000000000000000
-- 097:00000000000000000000000000000000000000000000000000000000000000000000000000f66ff6f6666fff666fff6666ff6666f000fff66ff000f66666ff666ff000ff6666f66666ff6666f6666ff66666f000000000000000000000000000000000000000000000000000000000000000000000000000
-- 098:00000000000000000000000000000000000000000000000000000000000000000000000000f66ff6f66ff6f66f66f666fff666fff000ff66ff0000ff66fff66ff6f000f666ffff66fff6ff66f66ff6ff66fff000000000000000000000000000000000000000000000000000000000000000000000000000
-- 099:00000000000000000000000000000000000000000000000000000000000000000000000000f6666ff66ffff666fffff666fff666f000f66ffff0000f66fff66ff6f000fff666ff66fff6ff66f66fffff66fff000000000000000000000000000000000000000000000000000000000000000000000000000
-- 100:00000000000000000000000000000000000000000000000000000000000000000000000000f66ffff66f00ff666ff6666ff6666ff000f66666f0000ff666ff666ff000f6666ffff666ff6666f66f000ff666f000000000000000000000000000000000000000000000000000000000000000000000000000
-- 101:00000000000000000000000000000000000000000000000000000000000000000000000000ffff00ffff000fffffffffffffffff0000fffffff00000ffffffffff0000ffffff00ffffffffffffff0000fffff000000000000000000000000000000000000000000000000000000000000000000000000000
-- </SCREEN>

-- <PALETTE>
-- 000:1a1c2c0f380f3062308bac0f9bbc0f1a1c2c38b764ff000029366f3b5dc941a6f673eff7f4f4f494b0c2566c86101c2c
-- </PALETTE>

