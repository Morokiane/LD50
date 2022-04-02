-- title:  Hexed
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

releaseBuild=false
indicatorsOn=false
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
	heart=246,
	pit=3,
	duck=290,
	check=242,
	checkact=243,
	water=224,
	cure=244
}
--Collision detectors
--[[These change where the collision detectors are for
the top and sides of a sprite (Bottom can not be changed
from here. The default is every corner and middle of a 
16x16 sprite. These settings bring the collider detections
in 1 pixel on the sides and top.]]
coll={
	tlx=3, --Defines where the left collider is
	tly=1, --Defines where the top collider is
	trx=11,--Defines where the right collider is
	cly1=7,--Defines where the left top mid collider is 
	cly2=8,--Defines where the left bottom mid collider is
	cry1=7,--Defines where the right top mid collider is
	cry2=8 --Defines where the right bottom mid collider is
}
--Player variables
p={
	idx=256, --Player sprite
	x=16, --initial player location x
	y=88, --initial player location y
	vx=0, --Velocity X
	vy=0, --Velocity Y
	vmax=1, --Maximum velocity for jumping
	flp=0, --sprite flip
	grounded=true, --set if the player is on the ground
	maxLife=2,
	curLife=2,
	damaged=false,
	ducking=true,
	canMove=true,
	hTime=500,
	sTime=500,
	cpX=16,
	cpY=88,
	cpF=0,
	cpA=false,
	human=true
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
	myt=0,
}
--[[Sets up animations sprites for the map.
s=animation speed
f=amount of frames]]
tileAnims={
	[240]={s=.05,f=2},
	[244]={s=.05,f=2},
	[208]={s=.1,f=4},
	[224]={s=.1,f=4},
	[246]={s=.1,f=5}
}

spawns={
	[255]=262
}

grav=3.6 --gravity default 3.7
t=0 --general timer
ct=0 --timer for character animation
timer=0 --timer for blinking damage
win={}
maxCoins=0
notDead=true
cTime=0
atEnd=false
lvl=0
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
		print("idx: "..p.idx,60,32,14,false,1,true)
		print("Lives: "..p.curLife,60,40,14,false,1,true)
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
	if releaseBuild then
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
			spr(p.idx,p.x-cam.x,p.y-cam.y,0,1,p.flp,0,2,2)
		end
	else
		spr(p.idx,p.x-cam.x,p.y-cam.y,0,1,p.flp,0,2,2)
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
	ct=ct+1
end

function Update()
	Main()
	if notDead then
		Player()
	end
	CheckPoint()
	--Enemy()
	ShakeScreen()
	Collectiables()
	Blinky()
	Dead()
	LevelEnd()
end

function Player()
	--Set controls to move the player
	if p.canMove then
		if btn(c.l) and not p.ducking then
			p.vx=-p.vmax
			p.idx=288+t%60//10*2
			p.flp=1
			ct=time()//9
		elseif btn(c.r) and not p.ducking then
			p.vx=p.vmax
			p.idx=288+t%60//10*2
			p.flp=0
			ct=time()//9
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
		fset(2,1,false)
		fset(3,1,false)
		fset(4,1,false)
		fset(5,1,false)
	end
	
	--[[if the sprite is tile 2 and has flag 2 either set
	as true or false]]
	if p.grounded==true and not btnp(c.d) then
		fset(2,1,true)
		fset(3,1,true)
		fset(4,1,true)
		fset(5,1,true)
	elseif p.grounded==true then
		fset(2,1,false)
		fset(3,1,false)
		fset(4,1,false)
		fset(5,1,false)
	end
	
	if p.vy>=1.5 then
		fset(2,1,true)
		fset(3,1,true)
		fset(4,1,true)
		fset(5,1,true)
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

	if p.hTime>=0 and not atEnd then
		p.hTime=flr(p.hTime-1/1000)
		print(p.hTime,0,0,7)
	end
	
	if p.hTime<=0 and not atEnd then
		p.human=false
		p.idx=320+t%40//10*2
		p.sTime=flr(p.sTime-1/1000)
		print(p.sTime,0,0,7)
	end
	
	if p.sTime<=0 then
		p.sTime=0
		Dead()
		notDead=false
	end
	--Pit()
end

function Dead()
	if not notDead then
		p.canMove=false
		p.idx=328
		AddWin(w/2,h/2-30,64,24,2,"You Died!\nPress A to\ncontinue.")
		if btnp(c.z) then
			p.curLife=p.curLife-1
			p.x=p.cpX
			p.y=p.cpY
			p.canMove=true
			notDead=true
			p.human=true
			if p.cpA then
				p.hTime=cTime
				p.sTime=500
			else
				p.hTime=500
				p.sTime=500
			end
		end
	end
	if p.curLife<=0 then
		GameOver()
	end
end

function CheckPoint()
	if mget(p.x//8+1,p.y//8+1)==s.check and p.human then
		mset(p.x//8+1,p.y//8+1,s.checkact)
		p.cpX=flr(p.x)
		p.cpY=flr(p.y)
		p.cpF=p.flp
		p.cpA=true
		cTime=p.hTime
	end
end

function LevelEnd()
	if fget(mget(p.x//8+1,p.y//8+1),2) then
		atEnd=true
		p.vx=0
		p.canMove=false
		print("Level End",0,8,3)
		AddWin(w/2,h/2-30,64,24,2,"Press Z to\ncontinue to\nnext level.")
		if btnp(c.z) then
			lvl=lvl+1
			NextLevel()
			--next level code
		end
		--spr(498,p.x-cam.x+4,p.y-cam.y-8+math.sin(time()//90),0)		
	end
end

function NextLevel()
	if lvl==1 then
		--Replace all of this with MapCoord
		--MapCoord()
		p.x=16
		p.y=88+128
		p.canMove=true
		atEnd=false
	end
	if lvl==2 then
	
	end
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
	if mget(p.x//8+1,p.y//8+1)==s.pot or mget(p.x//8,p.y//8)==s.pot then
	 mset(p.x//8+1,p.y//8+1,0)
		mset(p.x//8,p.y//8,0)
		if p.human then
			p.hTime=p.hTime+100
		else
			p.sTime=p.sTime+100
		end
	--sfx(01,'E-6',5)
	end
	
	if (mget(p.x/8+1,p.y/8+1)==s.cure or mget(p.x/8,p.y/8)==s.cure) and not p.human then
		mset(p.x//8,p.y/8,0)
		mset(p.x//8+1,p.y/8+1,0)
		p.hTime=200
		p.human=true
	end
	
	if (mget(p.x/8+1,p.y/8+1)==s.heart or mget(p.x/8,p.y/8)==s.heart) and p.curLife<2 then
	 mset(p.x/8+1,p.y/8+1,0)
	 mset(p.x/8,p.y/8,0)
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

function MapCoord(ms,me,myt,myb,px,py)
	mapStart=ms*8
	mapEnd=me*8
	mapY=myt*8
	mapEndY=myb*8 --this is the top of the map screen of the bottom y map screen
	p.x=px*8
	p.y=py*8
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
	rectb(x-w/2+1,y-h/2+1,w-2,h-2,0) --no idea but it works
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
-- 002:c6656665c55c6c6ccccc555fc66fffff56ffffff5fffffffffffffffffffffff
-- 003:66656665555c555cffffffffffffffffffffffffffffffffffffffffffffffff
-- 004:666566656c6c555c555fffffffffffffffffffffffffffffffffffffffffffff
-- 005:c665566cc55c666cffccccccfffff66cffffff65fffffff5ffffffffffffffff
-- 006:3ffffff3f3ffff3fff3ff3fffff33ffffff33fffff3ff3fff3ffff3f3ffffff3
-- 007:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 008:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 009:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 010:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 011:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 012:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 013:fffffffffffffffffffffffffffffffffffffff2ffffff2ffff2f2f2ff222f22
-- 014:fff2ffffff2f2ffff2f2f2ff2f222f22f2f2f2f22f2f222ff2f2f2f22f222222
-- 015:ffffffffffffffffffffffff22fffffff2ffffff222ffffff2ffffff222ff22f
-- 016:aaaaababbaaaaaaaaaa00000aa000c00aa00c0c0ba0c0000aa00c000ba000000
-- 017:abaababbaaabaaaaaaaaaaaa0000000000c0c0c0000000000000000000000000
-- 018:abbbabbbaaaaaaaa000000000c0c0c0000c0c0c0000000000000000000000000
-- 019:aabbabbaabbaabba0000aaaa0c00000000c0c0c0000000000000000000000000
-- 020:aaababaababbabaabaaa0aaa000000ab00c000aa0c0c00aa00c000aa000000aa
-- 021:6767566677665666665000006600005566000055560000006605500066055000
-- 022:6676665666666666056665005000000550000000000000000000000000000000
-- 023:6656666666666666056665000000005500000005000000000000000000000000
-- 024:6666676566666666056665005000005550000055000000000000000000000000
-- 025:6666766566666655005665555000055550000055000000560000006500055055
-- 026:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 027:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 028:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 029:f2f2f2f2ff2f2f2ffff2f2f2ff222f22f2f2fff2ff2f22f2fff2f2fffff2222f
-- 030:f2f2f2f2222f2222f2f2f22222222222f2f2f2f22f222222fff2f22222f22222
-- 031:f2f222f222222222f222f222222ff22f2fffffff2fffffff2fffffffffffffff
-- 032:aa000000aa0c0000ba000000ba0c0000aa000000ba0c0000aa000000ba000000
-- 033:00000000000c0c0000c0c0c00c000c0000c0c0c00c0c0c0000c000c000000000
-- 034:000000000c0c0000000000000c000000000000c000000c000000c0c000000000
-- 035:000000000c000c000000c0c000000c00000000c00c00000000c0000000000000
-- 036:00000abb000c0aab00c00aaa000c0aab00c00aaa000c0aaa00c00aaa00000aaa
-- 037:6605500066500000666000006660000066600000565000006605500066055000
-- 038:0000000005550000055500000565000000000000000005500000055000000000
-- 039:0000000000000000000500000000000000550000005500500000000000000000
-- 040:0000000000000000000005500005055000000000000000000005000000000000
-- 041:0005505500055056000006550000055500000556000005550000065500055055
-- 042:ffffaafafaa9aaaafaaa9bbaf9aaabbbaa9aaaaaaaaabbbaaaabbbabfabbbabb
-- 043:affbbfaaaaabbbaaaaaabbaaabbaaaaaabbbabbabbbbbbbabbbbbbaabbbbbbba
-- 044:ffaaffffa9aaa9ffaa9aa99faaaaa99faaaa999faaaaa999bbbbaa99bbbbaa9f
-- 045:fffff2f2fffffff2ffffffffffffffffffffffffffffffffffffffffffffffff
-- 046:222f22ff222f222222ff2222fffff22fffffffffffffffffffffffffffffffff
-- 047:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 048:aa000000aa0c0000aaa0c000baac0000aaa0c000baac0000aaa0c000ba000000
-- 049:fffffffffffffffffffffffffffffffffffbfffffffbfffffbfbfbfffafafaff
-- 050:ffffffffffff4ffffff323ffff24744ffff323ffffff1ffffffabfffffffafff
-- 051:fffffffffffffffffffffffffffffffffffffffffaaafffffaaaabafaaaaaaa9
-- 052:000000aa000c00aa00c000aa000000aa000000aa000c00aa00c000aa000000aa
-- 053:7605500076000000650000005600005566000055665000006555555556555555
-- 054:0000000000000000000000005000000050000005055555005555555555655555
-- 055:0000000000000000000000005000005550000055055555005555555555565555
-- 056:0000000000000000000000000000005550000055055555005555555555555565
-- 057:0005505600055065000000565000005550000055000005665565566550000000
-- 058:faaaabbbaaaabbbaaa9bbbaaf9abbaaaaaaaaaabaaaa9aaaaaa9aaaaf99aaaaa
-- 059:bbbbbbbbbbbbbbaaabbabbabaaabbbabbbabbaaabbabaabbabaaaabbaaaaaaab
-- 060:abbba9ffaabb999fba9a999fbbacc99fbbaa99ffaaaaa99fb9aaaa99baccc999
-- 061:ff6655ffff6666ffff6666ffff6666ffff6666ffff6766ffff6766ffff6766ff
-- 062:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 063:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 064:aa000000aa0c0000ba00c000ba000000aa00c000ba0c0000aa00c000ba000000
-- 068:000000aa000c00aa000000aa000c0aaa00000aaa000c0aaa00c00aaa000000aa
-- 069:ffffffffffffffffffbbfffffafffbbffaffffaffaffffaffafaffaff9f9ff9f
-- 070:fffffffffffffffffffffffffffbffffffafffffffafffffffafafffff9fafff
-- 071:fffffffffffffffffffaffffffbfafffffffafffffffafffffff9fffffff9fff
-- 072:0000000000000000000000000000000000000000000000000000009a000000aa
-- 073:000000000000000000000000000000000000000000000000a9000000aa000000
-- 074:f99aacaa999999ca99999aa999f99aaaff9999aaf999f999f99ffff9ffffffff
-- 075:999aaaca9aa9aa9c9aaa999999aa99aa9cc999aaccc9959acc5995f9ff6555ff
-- 076:aac9aaffaaa9aaafcaa99aafccc999ffacc99ccfa999cccf999fccffffffffff
-- 077:ff6766ffff7766ffff7766ffff7776ffff6776ffff6766ffff6766ffff6766ff
-- 078:ff6766ffff7766ffff7776ffff7776ffff7766fff777677f7776677777666677
-- 079:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 080:aa000000aa0c0000ba00c000ba0c0c00aa00c0c0baa00000baaaaaaaaaaabbaa
-- 081:00000000000000000000000000c0c0c00c0c0c0000000000aaaaaaaaaaaaaaaa
-- 082:00000000000000000000000000c0c0c0000000000a0aaaa0aaaaaaaaaaabaaaa
-- 083:00000000000000000000000000c0c0c00c0c0c0000000000aaaaaaaaaaaaaaab
-- 084:000000aa00c00aaa000c0aab00c00aaa0c0c00aa00000caaaaaaaaaaaaaaaaaa
-- 085:ffffffffffffffffffffffffffffffffffffffffffff677ff276766f67766655
-- 086:ffffffffffffffffffffffffffffffffffffffffffff155ff251511f15511155
-- 087:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 088:000000aa0000009a000000000000000000000000000000000000000000000000
-- 089:990000009a000000000000000000000000000000000000000000000000000000
-- 090:fffffffffffffff9fffffff9ffff9ff9ffff99ffffff999bffff9a9bffff9aab
-- 091:fffafffffffaafff9ffaaaff99faaaafa999abaaaa99bbaabaabbbabbbabbaaa
-- 092:fafffffffbaffffafbbaffababbbaabbaabbabbbaaababbabbaaabaabbbaaaab
-- 093:affaffffaffaafff9f9aaaff999aaaafa999abaaaa99bbaaaaabbbabbbabbaaa
-- 094:fafffffffbaffffffbbaffffabbbaffaaabbafabaaabaabbbbaaabbbbbbaabba
-- 095:ffffffffffffffffafffffffaff9ffffaf99ffffa999ffffa999afffaa9aafff
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
-- 106:f9999aaaff9999aafff99bbbfffaaabb9999aaabf9999aaaff999999ffffff99
-- 107:bbabaaaaabaaabbbaaaabbbabaabbb99bb9aaaa999aaaaaa9aaa99aa99999999
-- 108:abbbaabbaaaaabbbaabbbaaaabbbaabbbbbaaaab9999aaaaa99aaaaa99aaa999
-- 109:baabaaaaaaaaabbbaaaabbbabaabbbaabbaaaaaabbbaaaaa9aaa99aa99999999
-- 110:abbbabaaaaaaaaaba9aaaabba9aa9bbb99a9a99a9999aaaaa99aaaaa99aaa999
-- 111:aaaaa99fbbaa99ffb9a99fffa999aaafa99aaaff99aaa999a999999f999999ff
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
-- 208:ffffffffffffffffffffffffffffffff992999299999999999999999a9a9a9a9
-- 209:ffffffffffffffffffffffffffffffff999299929999999999999999a9a9a9a9
-- 210:ffffffffffffffffffffffffffffffff299929999999999999999999a9a9a9a9
-- 211:ffffffffffffffffffffffffffffffff992999929999999999999999a9a9a9a9
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
-- 224:99999999a9a9a9a99a9a9a9aaaa9aaa99a929a9aaaaaaaaaaaaaaa2aa2aaaaaa
-- 225:99999999a9a9a9a99a9a9a9aaaa2aaa99a9a9a9aa2aaaa2aaaaaaa9aaaaaaaaa
-- 226:99999999a9a9a9a99a929a9aaaa9aaa9929a9a2aaaaaaaaaaaaaaa9aaaaaaaaa
-- 227:99999999a9a2a9a99a9a9a9aa2a9aa299a9a9a9aaaaaaaaaaaaaaa9aaaaaaaaa
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
-- 240:fffffffffccccccfffcffcffffc77cfffc7887cfc788887cc777777cfccccccf
-- 241:fccccccfffcffcffffc77cfffc7887cfc788887cc777777cfccccccfffffffff
-- 242:f12ffffff12ffffff12ffffff12ffffff12ffffff12ffffffccfffffccccffff
-- 243:f1ccfffff1c2ccfff1c222cff1c22ccff1cccffff1cffffffccfffffccccffff
-- 244:fffffffffccccccfffcffcffffc33cfffc3443cfc344443cc333333cfccccccf
-- 245:fccccccfffcffcffffc33cfffc3443cfc344443cc333333cfccccccfffffffff
-- 246:fffffffff33ff3cf3333333c3333333cf33333cfff333cfffff3cfffffffffff
-- 247:fffffffff33ff3cf3333332c3333322cf33322cfff322cfffff2cfffffffffff
-- 248:fffffffff33ff2cf3333223c3332233cf32233cfff233cfffff3cfffffffffff
-- 249:fffffffff33ff3cf3322333c3223333cf23333cfff333cfffff3cfffffffffff
-- 250:fffffffff22ff3cf2233333c2333333cf33333cfff333cfffff3cfffffffffff
-- 251:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 252:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 253:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 254:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 255:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- </TILES>

-- <SPRITES>
-- 000:0000000000000000000000cc00000c560000c5650000c5580000c5880000c5e8
-- 001:0000000000000000ccc00000666c00006666c0008886c000888c0000888c0000
-- 002:000000000000000000000000000000cc00000c560000c5650000c5580000c588
-- 003:000000000000000000000000ccc00000666c00006666c0008886c000888c0000
-- 004:000000000000000000000000000000cc00000c560000c5650000c5580000c588
-- 005:000000000000000000000000ccc00000666c00006666c0008886c000888c0000
-- 006:0000000000000000000000cc00000c560000c5650000c5580000c5880000c5e8
-- 007:0000000000000000ccc00000666c00006666c0008886c000888c0000888c0000
-- 008:00000000000000cc00000c660000c65600ccc5650c8ec5560c8ec58800ceeee8
-- 009:00000000ccc00000666c00006666c0006666cc00666668c0888868c088866c00
-- 010:0000000000000000000000000000000000000000000000cc00000c560000c565
-- 011:0000000000000000000000000000000000000000ccc00000666c00006666c000
-- 016:0000cee8000cedde00ceedde00c88dde00c87ddd000ccddc0000cddc00000cc0
-- 017:888c0000eedec000eedeec00eed88c00ddd78c00cddcc000cddc00000cc00000
-- 018:0000c5e8000ceee800ceedde00c88dde00c87dde000ccddd0000cddc00000cc0
-- 019:888c0000888ec000eedeec00eed88c00eed78c00dddcc000cddc00000cc00000
-- 020:0000c5e80000cee8000cedde00ceedde00c88dde00c87ddd000ccddc00000cc0
-- 021:888c0000888c0000eedec000eedeec00eed88c00ddd78c00cddcc0000cc00000
-- 022:0000cee80000cdde000cedde00ceedde00c88ddd00c87ddc000ccddc00000cc0
-- 023:888c0000eedc0000eedec000eedeec00ddd88c00cdd78c00cddcc0000cc00000
-- 024:000cedde0000cdde0000cdde0000cddd00000cdd000000cd0000000c00000000
-- 025:eed6c000eedc0000eedc0000ddddc000dcdddc00c0cdc000000c000000000000
-- 026:0000c5580000c5880000c5e8000cedde00ceedde0c88cdde0c87cddc00cccccc
-- 027:8886c000888c0000888c0000eedec000eedeec00eedc88c0cddc78c0cccccc00
-- 032:00000000000000cc00000c560000c5650000c5580000c5880000c5e80000cee8
-- 033:00000000ccc00000666c00006666c0008886c000888c0000888c0000888c0000
-- 034:000000000000000000000000000000cc00000c560000c5650000c5580000c588
-- 035:000000000000000000000000ccc00000666c00006666c0008886c000888c0000
-- 036:0000000000000000000000cc00000c560000c5650000c5580000c5880000c5e8
-- 037:0000000000000000ccc00000666c00006666c0008886c000888c0000888c0000
-- 038:00000000000000cc00000c560000c5650000c5580000c5880000c5e80000cee8
-- 039:00000000ccc00000666c00006666c0008886c000888c0000888c0000888c0000
-- 040:000000000000000000000000000000cc00000c560000c5650000c5580000c588
-- 041:000000000000000000000000ccc00000666c00006666c0008886c000888c0000
-- 042:0000000000000000000000cc00000c560000c5650000c5580000c5880000c5e8
-- 043:0000000000000000ccc00000666c00006666c0008886c000888c0000888c0000
-- 048:000cedde000cee880000ce870000cddd000cdddc000cddc00000cc0000000000
-- 049:eedc0000eedec000eed8c000ddddc000ccdddc0000cddc00000cc00000000000
-- 050:0000c5e80000cee8000cedde000cee880000ce8e000cdddc000cddc00000cc00
-- 051:888c0000888c0000eedc0000eed7c000eeddc000ccddc0000cddc00000cc0000
-- 052:0000cee8000cedde00ceedde00c88dde00c87ddd000ccddc0000cddc00000cc0
-- 053:888c0000eedec000eedeec00eed88c00ddd78c00cddcc000cddc00000cc00000
-- 054:000cedde00ceedde0c88cdde0c87cddd00cc0cdd000000cd0000000c00000000
-- 055:eedecc00eede88c0eedc78c0dddccc00ddc00000dc000000c000000000000000
-- 056:0000c5e80000cee8000cedde00ceedde0c88cdde0c87cddd00cc0cdd000000cc
-- 057:888c0000888c0000eedecc00eede88c0eedc78c0dddccc00ddc00000cc000000
-- 058:0000cee8000cedde00ceedde00c88dde00c87ddd000ccddc0000cddc00000cc0
-- 059:888c0000eedec000eedeec00eed88c00ddd78c00cddcc000cddc00000cc00000
-- 064:000000000000000000000000000000000000cccc000c888800c8888800c888bb
-- 065:00000000000000000000000000000000cccc00008888c000bbbbbc00bbbbbc00
-- 066:00000000000000000000000000000ccc000cc88800c8888800c888bb0cbb888b
-- 067:000000000000000000000000ccc00000888cc000bbbbbc00bbbbbc00bbbbbbc0
-- 068:0000000000000000000000cc0000cc88000c888800c88bbb00c888bb0cbb8888
-- 069:0000000000000000cc00000088cc0000bbbbc000bbbbbc00bbbbbc00888bbbc0
-- 070:00000000000000000000000000000ccc000cc88800c8888800c888bb0cbb888b
-- 071:000000000000000000000000ccc00000888cc000bbbbbc00bbbbbc00bbbbbbc0
-- 080:0cbb888b0cbbb8abcbbbaacacbaaaaaacbaaaaaacaaaaaaa0caaaaaa00ccccac
-- 081:88bbbbc0b8abbbc0aacabbbcaaaaacbcaaaaacbcaaaaccc0aacccc00cccc0000
-- 082:0cbbb888cbbba8aacbaaaacacbaaaaaacbaaaaaacaaaaaaa0caaaaaa00ccccac
-- 083:888bbbc0a8aabbbcaacaaabcaaaaacbcaaaaccbcaaacccc0aacccc00cccc0000
-- 084:0cbba8aa0cbaaaca0cbaaaaa0cbaaaaa0caaaaaa0caaaaaa00ccccac00000ccc
-- 085:a8aabbc0aacaabc0aaaacbc0aaaacbc0aaaccac0aacccac0cccccc00ccc00000
-- 086:0cbbb8a8cbbbaacacbaaaaaacbaaaaaacbaaaaaacaaaaaaa0caaaaaa00ccccac
-- 087:88abbbc0aacabbbcaaaaaabcaaaaacbcaaaaccbcaaacccc0aacccc00cccc0000
-- 088:0000000000000000000ccccc00c888880cbb888bcbaaaaaacbaaaaaa0caaaaaa
-- 089:0000000000000000ccccc000bbbbbc00bbbbbbc0aaaaaabcaaaaccbcaaccccc0
-- 096:00000000000000000000000000000000000000000000888800088888000888ee
-- 097:000000000000000000000000000000000000000088880000eeeee000eeeee000
-- 098:00000000000000000000000000000000000000000000088800088888000888ee
-- 099:000000000000000000000000000000000000000088800000eeeeee00eeeeee00
-- 100:000000000000000000000000000000000000000000000000008888880888eeee
-- 101:00000000000000000000000000000000000000000000000088eee000eeeeee00
-- 102:000000000000000000000000000000000000000000000888000888ee00888eee
-- 103:000000000000000000000000000000000000000088800000eeeeee00eeeeee00
-- 112:00ee888e00eeeeee0eeedddd0edddddd0edddddd0ddddddd00dddddd0000ccdc
-- 113:88eeee00eee8de00ddddcee0dddddce0dddddce0ddddccc0ddcccc00cccc0000
-- 114:00ee888e00eeeeee0eeedddd0edddddd0edddddd0ddddddd00dddddd0000ccdc
-- 115:e88eeee0eeee8de0dddddceeddddddceddddddcedddddccddddcccc0ccccc000
-- 116:ee888e8eeeeeeeeeeedddddddddddddddddddddddddddddddddddddd00ccdccc
-- 117:e88eeee0eeee8de0dddddceeddddddceddddddcedddddcccdddcccc0ccccc000
-- 118:0ee888ee0eeeeeeeeeedddddedddddddeddddddddddddddd0ddddddd000ccdcc
-- 119:e88eeee0eeee8de0dddddceeddddddceddddddcedddddcccdddcccc0ccccc000
-- 240:0000000004400430444444434444444304444430004443000004300000000000
-- 241:000000000cc00cc0c11cc19cc111119c0c1119c000c19c00000cc00000000000
-- </SPRITES>

-- <MAP>
-- 001:0000000000000000000000000000d1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:000000000000000000d0d1e00000000000e2d0e0f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:000000000000000000d1e1f10000000000c1d1e1f1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:000000000000000000000000000000000000d2e2f2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:00000000000000000000000000000000000000000000000000000000005400330055002f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:000000000000000000000000000000000000000000000000000000000001112131616141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:000000000000000000000000000000000000000000000000000000000002101210103293000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:000000000000000000000000000000000000000000000000000030405003108383839300000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:0000000000000000a5f5000000006f00004f000000000000000000000004920000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:0000002313131313a6f6230033001300540000000000000000005474640292000f006500000000000000011121311121310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:11213111213111213111213111213111213111410d0d0d0d0d0111213195106171817191000000000001950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:10101010321010101010321010101010321010420e0e0e0e0e0210101010106210107292000000000195000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:101210321010121072101010101210821010101210101010101010121010101010221092000000019500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:101010101010101010101010101012101032101010108210103210106210101082101085112131950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 029:000000110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 030:000000001111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 031:000000000000111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 033:040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 050:000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
-- 000:00102020202040000000000000000000101010101010101010100000000000001010101010101010101000000000000010000000101010101010000000000000100000001000000000000000000000001010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
-- 000:0000009d9d9dffffffbe2633e06f8b493c2ba46422eb8931f7e26b2f484e44891aa3ce271b263200578431a2f2b2dcef
-- </PALETTE>

