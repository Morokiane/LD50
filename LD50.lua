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
	pit=131,
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
	tly=3, --Defines where the top collider is
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
	x=0,
	y=0,
	vx=0,
	vy=0,
	l=true,
	flp=true
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

sp=.4
fr=4
--[[Sets up animations sprites for the map.
s=animation speed
f=amount of frames]]
tileAnims={
	[240]={s=.05,f=2},
	[244]={s=.05,f=2},
	[220]={s=.1,f=4}, --water
	[236]={s=.1,f=4},	--water
	[246]={s=.1,f=5},
	--Waterfall
	[176]={s=sp,f=fr},--column 1
	[180]={s=sp,f=fr},--column 2
	[184]={s=sp,f=fr},--column 3
	[192]={s=sp,f=fr},--column 1
	[196]={s=sp,f=fr},--column 2
	[200]={s=sp,f=fr},--column 3
	[208]={s=sp,f=fr},--column 1
	[212]={s=sp,f=fr},--column 2
	[216]={s=sp,f=fr},--column 3
	[224]={s=sp,f=fr},--column 1
	[228]={s=sp,f=fr},--column 2
	[232]={s=sp,f=fr} --column 3
}

spawns={
	[128]=324
}

col=0
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
mapStart=0
mapEnd=472
mapY=0
mapEndY=136

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

wavelimit=136/16
w1=5 --reduce
w2=0 --increase
function scanline(row)
	-- skygradient
	--poke(0x3fc0,190-row)
	--poke(0x3fc1,140-row)
	--poke(0x3fc2,0)
	 --screen wave
	if lvl==3 then
		if row>wavelimit then
			poke(0x3ff9,math.sin((time()/200+row/5))*2) --200 5 2
		else
			poke(0x3ff9,0)
		end
	end
end
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
		print("MapX: "..mapEnd,0,56,14,false,1,true)
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
	cam.x=p.x-120
	cam.y=p.y-113

	if cam.x<mapStart then
		cam.x=mapStart
	elseif cam.x>mapEnd-232 then
		cam.x=mapEnd-232
	end
	
	if cam.y<mapY then
		cam.y=mapY
	--[[113 may have to change to a variable if the map
	does not process correcly when starting on a lower screen]]
	elseif cam.y>mapEndY-113 then
		cam.y=mapEndY
	end
	
	cls()
	--[[Scrolling in X and full screen load in Y]]
	map(cam.x//8,cam.y//8,31,18,-(cam.x%8),-(cam.y%8),col,1,remap)
	if p.damaged then --If the player is damaged blink the player
		if (time()%300>200) then
			spr(p.idx,p.x-cam.x,p.y-cam.y,0,1,p.flp,0,2,2)
		end
	else
		spr(p.idx,p.x-cam.x,p.y-cam.y,0,1,p.flp,0,2,2)
	end

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
	--if btnp(c.s) then
	--	sync(0,2,true)
	--end
end

function Update()
	Main()
	if notDead then
		Player()
	end
	CheckPoint()
	SwitchTiles()
	Enemy()
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
		coll.tly=3
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
	if p.x<mapStart then
		p.x=mapStart
	elseif p.x>mapEnd-8 then
		p.x=mapEnd-8
	end
--[[
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
	end]]
	Pit()
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
			sync(0,0,false)
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
		MapCoord(0,89,17,34,3,28)
		--MapCoord(mapStartX,MapEndX,MapY,MapEndY,p.x,p.y)
		p.cpX=p.x
		p.cpY=p.y
		p.canMove=true
		atEnd=false
	end
	if lvl==2 then
		sync(0,0,false)
		MapCoord(60,179,0,17,63,13)
		p.cpX=p.x
		p.cpY=p.y
		p.canMove=true
		atEnd=false
	end
	if lvl==3 then
		sync(0,2,false)
		MapCoord(0,179,0,17,4,31)
		p.cpX=p.x
		p.cpY=p.y
		p.canMove=true
		atEnd=false
		AddEnt()
	end
end

function SwitchTiles()
	if fget(mget(p.x//8,p.y//8),3) or fget(mget(p.x//8+1,p.y//8+1),3) then
		sync(0,1,false)
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
		spr=t.spr,
		hp=t.hp,
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
			--elseif mget(x,y)==4 then
			--if spawns[mget(x,y)] then
				--AddBad({spr=(mget(x,y)),x=x*8,y=y*8,type="plat"})
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
			v.flp=1
		end
		
		if not solid(v.x+14,v.y+15+v.vy,0) and solid(v.x+14,v.y+16+v.vy) and not v.l then
			v.vx=v.vx+0.3
		elseif v.vx==0 then
			v.l=true
			v.flp=0
		end
		--apply movement to the enemy
		v.x=v.x+v.vx
		
		spr(v.spr+t%60//10*2,v.x-cam.x,v.y-cam.y,0,1,v.flp,0,2,2)
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
		p.x=p.cpX
		p.y=p.cpY
		p.curLife=p.curLife-1
	end
end

function Collectiables()
	if mget(p.x//8+1,p.y//8+1)==s.pot or mget(p.x//8,p.y//8)==s.pot then
	 mset(p.x//8+1,p.y//8+1,0)
		mset(p.x//8,p.y//8,0)
		if p.human then
			p.hTime=p.hTime+200
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
-- 008:cccccccccccccccccccc335cccc32593ccc359c9cc35778cccc39c73ccccc999
-- 009:ccccccccc33ccccc3323cccc99993ccc9879ccccc73cccccc399cccc999999cc
-- 010:ff22222ff2222222222f2f222f22f2f2f22f2f22f2f2f2ffff2ffffffff2ff22
-- 011:2f2222ff2222222f2f2f2222f2f2f222ffff2f22fffff2f22fff2ffffff2ffff
-- 012:ffffffffffffffffffffffff222fffff2f22fffff2f2ffffff2ffffff2ffffff
-- 013:fffffffffffffffffffffffffffffffffffffff2ffffff2ffff2f2f2ff222f22
-- 014:ffffffffff2f2ffff2f2f2ff2f222f22f2f2f2f22f2f222ff2f2f2f22f222222
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
-- 026:ffffffffff222ffff2f2f2ff2f2f2ff2f2ffff222f2fff2ff2fffff2ff2fffff
-- 027:ffffffffff222f2f22f2f2f22f2fff2ff2fffff22fffffffffffffff2fffffff
-- 028:ffffffff2ffffffff2f2ffff2f2f2ffff2f2ff2fff2ff2f2ffffff2fffffffff
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
-- 062:ffffffff1f1f1f1ff1f1f1f1111f111ff1f1f1f111111111111111f111111111
-- 063:ffffffff1f1f1f1ff1f1f1f1111f111ff1f1f1f111111111111111f111111111
-- 064:aa000000aa0c0000ba00c000ba000000aa00c000ba0c0000aa00c000ba000000
-- 065:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 066:ffffffffffcfffcffffffcffcfcfcfcffcfcfcfccccccfccccfcccfccccccccc
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
-- 096:0000000000000000000000000000000000000000000000000000005600000066
-- 097:0000000000000000000000000000000000000000000000006500000066000000
-- 100:5776755677765556775055505500000055005550660050505700550077000000
-- 101:7565775555655556000000000000000005000505000000000050505000000000
-- 102:5775775577765556555000000000000005050505000000005050505000000000
-- 103:5776775655567756000055700000000005050500000000000050500000000000
-- 104:7757757655577555000006550000006605550077050500750055006600000065
-- 105:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 106:f9999aaaff9999aafff99bbbfffaaabb9999aaabf9999aaaff999999ffffff99
-- 107:bbabaaaaabaaabbbaaaabbbabaabbb99bb9aaaa999aaaaaa9aaa99aa99999999
-- 108:abbbaabbaaaaabbbaabbbaaaabbbaabbbbbaaaab9999aaaaa99aaaaa99aaa999
-- 109:baabaaaaaaaaabbbaaaabbbabaabbbaabbaaaaaabbbaaaaa9aaa99aa99999999
-- 110:abbbabaaaaaaaaaba9aaaabba9aa9bbb99a9a99a9999aaaaa99aaaaa99aaa999
-- 111:aaaaa99fbbaa99ffb9a99fffa999aaafa99aaaff99aaa999a999999f999999ff
-- 112:0000006600000056000000000000000000000000000000000000000000000000
-- 113:5500000056000000000000000000000000000000000000000000000000000000
-- 116:7500500056000050770050007500005066005000750000505500500075000000
-- 117:0000000005000050000000000000000000000000000000000500005000000000
-- 118:0000000000000000050505000000000000505050000000000505050000000000
-- 119:0000000005500000055000000000000000005500000055000000000000000000
-- 120:0050006550000065000000650000006500500055500000660050005650000055
-- 121:fffffffffffffffffffffffffffffffffffffffffffffffffffffff7fff77888
-- 122:fffffff7ffffff77ffffff76fffff776ffff7766ff7876667887666687666666
-- 123:7777ffff778877ff677888776677888866777888667778886677788867778888
-- 124:ffffffffffffffffffffffff7fffffff87ffffff887fffff8887ffff888777ff
-- 125:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 126:ffffffffffffffffffffffffffffffffffffff77f7777766f6666666f6666666
-- 127:777fffff776fffff666fffff655fffff7777777f6666666f6566666f6556655f
-- 128:0000000000222200022222200202202002222220002222000020200000000000
-- 129:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 130:ffffffffff0fff0ffffff0ff0f0f0f0ff0f0f0f000000f0000f000f000000000
-- 132:7500500075000000750000007500000066000000750000505500500066000000
-- 133:0055500005550550000005550055055505555000055550550055005500000000
-- 134:0055000005555055055550550055005000000005500555005505555055005500
-- 136:0050006550000065005000655000006600500065500000650050006600000065
-- 137:ababbabdbb7bba7ddabbbabdabbb7abda7bbabdfddaab7dfaa7bddffddddffff
-- 138:ffdaadfffdabbadfd7a88a7ddbb88bbddbb7bbbdd7abba7ddbabbabddbabbabd
-- 139:8877777788888877888888888888888888888888778888777777777755777766
-- 140:7777778877888888888888888888888888777788776666776666555566555555
-- 141:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 142:f5566555ff666777ff666577ff666555fff66666fff55666fff66666fff55555
-- 143:5775666f7777566f7777666f57756666575666666566666666555555555fffff
-- 144:6777777767666666575777775757555657575555575655775756667557555575
-- 145:77777765666666605777776056c5565055555650766556505566665055655550
-- 146:06777777c6666666c5666666c5655555c5656555c5655775c565676505656765
-- 147:7775677666655765666567655765576557655765576557655765576557655765
-- 148:7500500075000050550050007500005075005000550000507500500075000000
-- 149:0000000000000000000005000000000005500000000000000005550055500555
-- 150:0000000005000000055000000050055000000055000000000000000000050000
-- 152:0050006550000065000000550000056600000556000007550050006650000065
-- 153:dbabbabad7abb7bbdbabbbaddba7bbbafdbabb7afd7baaddffddb7aaffffdddd
-- 154:dbab7abdd7abba7ddbabbabddbabbabddba7babdd7abba7ddbabbabddbabbabd
-- 155:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 156:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 157:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 158:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 159:555fffff555fffff665f67ff665665ff66665fff6755ffff675fffff676fffff
-- 160:575776655757c566575755555656555657566666565555555555555500000000
-- 161:5566775066655650555556505655565056666650555555505555555000000000
-- 162:c5655767c5655766c5655555c6655555c6677777c5666666c555555500000000
-- 163:77655765666557655555576555555765777777656666666555555555000000c0
-- 164:6600500077500000775055505550505066000550756000007665665665556655
-- 165:0005050000000000505050500000000000000000007550006655656656566555
-- 166:0000050000000000500050500000000000000000000000006666666656556555
-- 167:0505050000000000505050500000000000000000000000005565666656655555
-- 168:0050005500000056505550660050505500550065000006655555566555565556
-- 169:cc5c5c5c06677777c6677777c666666656665556c656557756665766c6565757
-- 170:5c5c5c5c77777777777777776666666677777765665567767776567755575567
-- 171:5c5c5c5c77777777777777776666666655777777577655667755677775557555
-- 172:5c5c5c5c77777660777776606666665065556550775565506675655075756550
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
-- 185:55565756c6565676c5565567c556555555567777c5555555c55555550c0c0c00
-- 186:7757555755775557777655775555555577777777555555555555555c0c0c0c0c
-- 187:755575777555775577556777555555557777777755555555555555550000000c
-- 188:657565506765655076556550555565507777655055555550555555500c0ccc00
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
-- 220:ffffffffffffffffffffffffffffffffee2eee2eeeeeeeeeeeeeeeeedededede
-- 221:ffffffffffffffffffffffffffffffffeee2eee2eeeeeeeeeeeeeeeedededede
-- 222:ffffffffffffffffffffffffffffffff2eee2eeeeeeeeeeeeeeeeeeedededede
-- 223:ffffffffffffffffffffffffffffffffee2eeee2eeeeeeeeeeeeeeeedededede
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
-- 236:eeeeeeeededededeededededdddedddeede2ededdddddddddddddd2dd2dddddd
-- 237:eeeeeeeededededeededededddd2dddeededededd2dddd2dddddddeddddddddd
-- 238:eeeeeeeededededeede2ededdddedddee2eded2dddddddddddddddeddddddddd
-- 239:eeeeeeeeded2dedeededededd2dedd2eededededddddddddddddddeddddddddd
-- 240:fffffffffccccccfffcffcffffc77cfffc7887cfc788887cc777777cfccccccf
-- 241:fccccccfffcffcffffc77cfffc7887cfc788887cc777777cfccccccfffffffff
-- 242:f12ffffff12ffffff12ffffff12ffffff12ffffff12ffffffccfffffccccffff
-- 243:f1ccfffff1c2ccfff1c222cff1c22ccff1cccffff1cffffffccfffffccccffff
-- 244:fffffffffccccccfffcffcffffc33cfffc3443cfc344443cc333333cfccccccf
-- 245:fccccccfffcffcffffc33cfffc3443cfc344443cc333333cfccccccfffffffff
-- 246:fffffffff33ff3cf3333333c3333333cf33333cfff333cfffff3cfffffffffff
-- 247:fffffffff22ff3cf2233333c2333333cf33333cfff333cfffff3cfffffffffff
-- 248:fffffffff33ff3cf3322333c3223333cf23333cfff333cfffff3cfffffffffff
-- 249:fffffffff33ff2cf3333223c3332233cf32233cfff233cfffff3cfffffffffff
-- 250:fffffffff33ff3cf3333332c3333322cf33322cfff322cfffff2cfffffffffff
-- 251:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 252:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 253:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 254:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 255:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- </TILES>

-- <TILES1>
-- 000:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 002:c6656665c55c6c6ccccc555cc66ccccc56cccccc5ccccccccccccccccccccccc
-- 003:66656665555c555ccccccccccccccccccccccccccccccccccccccccccccccccc
-- 004:666566656c6c555c555ccccccccccccccccccccccccccccccccccccccccccccc
-- 005:c665566cc55c666cccccccccccccc66ccccccc65ccccccc5cccccccccccccccc
-- 006:3cccccc3c3cccc3ccc3cc3ccccc33cccccc33ccccc3cc3ccc3cccc3c3cccccc3
-- 007:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 008:cccccccccccccccccccc335cccc32593ccc359c9cc35778cccc39c73ccccc999
-- 009:ccccccccc33ccccc3323cccc99993ccc9879ccccc73cccccc399cccc999999cc
-- 010:cc22222cc2222222222c2c222c22c2c2c22c2c22c2c2c2cccc2cccccccc2cc22
-- 011:2c2222cc2222222c2c2c2222c2c2c222cccc2c22ccccc2c22ccc2cccccc2cccc
-- 012:cccccccccccccccccccccccc222ccccc2c22ccccc2c2cccccc2cccccc2cccccc
-- 013:ccccccccccccccccccccccccccccccccccccccc2cccccc2cccc2c2c2cc222c22
-- 014:ccc2cccccc2c2cccc2c2c2cc2c222c22c2c2c2c22c2c222cc2c2c2c22c222222
-- 015:cccccccccccccccccccccccc22ccccccc2cccccc222cccccc2cccccc222cc22c
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
-- 026:cccccccccc222cccc2c2c2cc2c2c2cc2c2cccc222c2ccc2cc2ccccc2cc2ccccc
-- 027:cccccccccc222c2c22c2c2c22c2ccc2cc2ccccc22ccccccccccccccc2ccccccc
-- 028:cccccccc2cccccccc2c2cccc2c2c2cccc2c2cc2ccc2cc2c2cccccc2ccccccccc
-- 029:c2c2c2c2cc2c2c2cccc2c2c2cc222c22c2c2ccc2cc2c22c2ccc2c2ccccc2222c
-- 030:c2c2c2c2222c2222c2c2c22222222222c2c2c2c22c222222ccc2c22222c22222
-- 031:c2c222c222222222c222c222222cc22c2ccccccc2ccccccc2ccccccccccccccc
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
-- 042:ccccaacacaa9aaaacaaa9bbac9aaabbbaa9aaaaaaaaabbbaaaabbbabcabbbabb
-- 043:accbbcaaaaabbbaaaaaabbaaabbaaaaaabbbabbabbbbbbbabbbbbbaabbbbbbba
-- 044:ccaacccca9aaa9ccaa9aa99caaaaa99caaaa999caaaaa999bbbbaa99bbbbaa9c
-- 045:ccccc2c2ccccccc2cccccccccccccccccccccccccccccccccccccccccccccccc
-- 046:222c22cc222c222222cc2222ccccc22ccccccccccccccccccccccccccccccccc
-- 047:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 048:aa000000aa0c0000aaa0c000baac0000aaa0c000baac0000aaa0c000ba000000
-- 049:cccccccccccccccccccccccccccccccccccbcccccccbcccccbcbcbcccacacacc
-- 050:cccccccccccc4cccccc323cccc24744cccc323cccccc1ccccccabcccccccaccc
-- 051:cccccccccccccccccccccccccccccccccccccccccaaacccccaaaabacaaaaaaa9
-- 052:000000aa000c00aa00c000aa000000aa000000aa000c00aa00c000aa000000aa
-- 053:7605500076000000650000005600005566000055665000006555555556555555
-- 054:0000000000000000000000005000000050000005055555005555555555655555
-- 055:0000000000000000000000005000005550000055055555005555555555565555
-- 056:0000000000000000000000000000005550000055055555005555555555555565
-- 057:0005505600055065000000565000005550000055000005665565566550000000
-- 058:caaaabbbaaaabbbaaa9bbbaac9abbaaaaaaaaaabaaaa9aaaaaa9aaaac99aaaaa
-- 059:bbbbbbbbbbbbbbaaabbabbabaaabbbabbbabbaaabbabaabbabaaaabbaaaaaaab
-- 060:abbba9ccaabb999cba9a999cbbacc99cbbaa99ccaaaaa99cb9aaaa99baccc999
-- 061:cc6655cccc6666cccc6666cccc6666cccc6666cccc6766cccc6766cccc6766cc
-- 062:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 063:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 064:aa000000aa0c0000ba00c000ba000000aa00c000ba0c0000aa00c000ba000000
-- 065:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 066:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 068:000000aa000c00aa000000aa000c0aaa00000aaa000c0aaa00c00aaa000000aa
-- 069:ccccccccccccccccccbbcccccacccbbccaccccaccaccccaccacaccacc9c9cc9c
-- 070:cccccccccccccccccccccccccccbccccccacccccccacccccccacaccccc9caccc
-- 071:cccccccccccccccccccaccccccbcacccccccacccccccaccccccc9ccccccc9ccc
-- 072:0000000000000000000000000000000000000000000000000000009a000000aa
-- 073:000000000000000000000000000000000000000000000000a9000000aa000000
-- 074:c99aacaa999999ca99999aa999c99aaacc9999aac999c999c99cccc9cccccccc
-- 075:999aaaca9aa9aa9c9aaa999999aa99aa9cc999aaccc9959acc5995c9cc6555cc
-- 076:aac9aaccaaa9aaaccaa99aacccc999ccacc99ccca999cccc999ccccccccccccc
-- 077:cc6766cccc7766cccc7766cccc7776cccc6776cccc6766cccc6766cccc6766cc
-- 078:cc6766cccc7766cccc7776cccc7776cccc7766ccc777677c7776677777666677
-- 079:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 080:aa000000aa0c0000ba00c000ba0c0c00aa00c0c0baa00000baaaaaaaaaaabbaa
-- 081:00000000000000000000000000c0c0c00c0c0c0000000000aaaaaaaaaaaaaaaa
-- 082:00000000000000000000000000c0c0c0000000000a0aaaa0aaaaaaaaaaabaaaa
-- 083:00000000000000000000000000c0c0c00c0c0c0000000000aaaaaaaaaaaaaaab
-- 084:000000aa00c00aaa000c0aab00c00aaa0c0c00aa00000caaaaaaaaaaaaaaaaaa
-- 085:cccccccccccccccccccccccccccccccccccccccccccc677cc276766c67766655
-- 086:cccccccccccccccccccccccccccccccccccccccccccc155cc251511c15511155
-- 087:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 088:000000aa0000009a000000000000000000000000000000000000000000000000
-- 089:990000009a000000000000000000000000000000000000000000000000000000
-- 090:ccccccccccccccc9ccccccc9cccc9cc9cccc99cccccc999bcccc9a9bcccc9aab
-- 091:cccacccccccaaccc9ccaaacc99caaaaca999abaaaa99bbaabaabbbabbbabbaaa
-- 092:cacccccccbaccccacbbaccababbbaabbaabbabbbaaababbabbaaabaabbbaaaab
-- 093:accaccccaccaaccc9c9aaacc999aaaaca999abaaaa99bbaaaaabbbabbbabbaaa
-- 094:cacccccccbaccccccbbaccccabbbaccaaabbacabaaabaabbbbaaabbbbbbaabba
-- 095:ccccccccccccccccacccccccacc9ccccac99cccca999cccca999acccaa9aaccc
-- 096:0000000000000000000000000000000000000000000000000000005600000066
-- 097:0000000000000000000000000000000000000000000000006500000066000000
-- 098:cccccccccccc335cccc32355cc333cc2ccc23cccccccc77cccccc788cccccc77
-- 099:ccccccccc533cccc55323ccc2cc333ccccc32cccc77ccccc887ccccc77cccccc
-- 100:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 101:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 102:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 103:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 104:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 105:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 106:c9999aaacc9999aaccc99bbbcccaaabb9999aaabc9999aaacc999999cccccc99
-- 107:bbabaaaaabaaabbbaaaabbbabaabbb99bb9aaaa999aaaaaa9aaa99aa99999999
-- 108:abbbaabbaaaaabbbaabbbaaaabbbaabbbbbaaaab9999aaaaa99aaaaa99aaa999
-- 109:baabaaaaaaaaabbbaaaabbbabaabbbaabbaaaaaabbbaaaaa9aaa99aa99999999
-- 110:abbbabaaaaaaaaaba9aaaabba9aa9bbb99a9a99a9999aaaaa99aaaaa99aaa999
-- 111:aaaaa99cbbaa99ccb9a99ccca999aaaca99aaacc99aaa999a999999c999999cc
-- 112:0000006600000056000000000000000000000000000000000000000000000000
-- 113:5500000056000000000000000000000000000000000000000000000000000000
-- 114:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 115:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 116:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 117:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 118:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 119:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 120:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 121:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 122:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 123:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 124:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 125:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 126:cccccccccccccccccccccccccccccccccccccc77c7777766c6666666c6666666
-- 127:777ccccc776ccccc666ccccc655ccccc7777777c6666666c6566666c6556655c
-- 128:9c9cccc99cacccc999acccc99c9cacc99c9cacc9ac99acca9ccccccc9cacccc9
-- 129:ccc9cc9cccc9c9ccccc9cac9ccc9c9caccc9ccacccccaccccccc9ccccccc9ccc
-- 130:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 131:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 132:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 133:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 134:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 135:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 136:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 137:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 138:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 139:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 140:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 141:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 142:c5566555cc666777cc666577cc666555ccc66666ccc55666ccc66666ccc55555
-- 143:5775666c7777566c7777666c57756666575666666566666666555555555ccccc
-- 144:accaccc9caacccc9cccccac9ccccaccaccccca9ccccccccccccccccccccccccc
-- 145:cccc9cccccccc9cccccccacccc9acaccccaccaccccaaaccccccccccccccccccc
-- 146:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 147:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 148:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 149:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 150:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 151:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 152:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 153:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 154:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 155:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 156:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 157:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 158:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 159:555ccccc555ccccc665c67cc665665cc66665ccc6755cccc675ccccc676ccccc
-- 160:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 161:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 162:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 163:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 164:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 165:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 166:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 167:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 168:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 169:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 170:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 171:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 172:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 173:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 174:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 175:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 176:cefefececefeefeceeecefeceeeccefefccecefefcceecefecefecefeceffece
-- 177:efefecefefeffececffefececffeefeceeecefeceeeccefefececefefeceecef
-- 178:fececefefeceecefeeefecefeeeffececffefececffeefecefecefecefeccefe
-- 179:ececefecececcefefccecefefcceecefeeefecefeeeffececefefececefeefec
-- 180:eeccecceecececcfeceececfcefecececeffefeecfefefeccfeefeeceecefeee
-- 181:ffeefeecfecefeeefecceceeecececefeceececfeefececeeeffefcecfefefcc
-- 182:eeffeffeefefeffcefeefefcfecefefefecceceefcececeffceeceefeefeceee
-- 183:cceeceefcefeceeeceffefeeefefefecefeefefceecefefeeeccecfefcececff
-- 184:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 185:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 186:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 187:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 188:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 189:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 190:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 191:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 192:cefefececefeefeceeecefeceeeccefeffcecefeffceecefefefecefefeffece
-- 193:ecefecefeceffececcfefececcfeefeceeecefeceeeccefefececefefeceecef
-- 194:fececefefeceecefeeefecefeeeffececcfefececcfeefecececefecececcefe
-- 195:efecefecefeccefeffcecefeffceecefeeefecefeeeffececefefececefeefec
-- 196:eeccecfeecececfffceecefffefeceeefeffefeeffefefecffeefeeceecefece
-- 197:cfeefeeccecefeeeeecceceeecececffeceeceffeefecefeeeffeffeffefefec
-- 198:eeffefceefefefcccfeefecccecefeeececceceeccececefcceeceefeefecefe
-- 199:fceeceeffefeceeeeeffefeeefefefccefeefecceecefeceeeccecceccececef
-- 200:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 201:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 202:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 203:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 204:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 205:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 206:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 207:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 208:fecefcfeeccefcfeececeeecceeceeeccefececeeffececeefefefeffeefefef
-- 209:efefeeeffeefeeeffecefcfeeccefcfeececececceecececcefececeeffecece
-- 210:cefecfceeffecfceefefeeeffeefeeeffecefefeeccefefeececececceececec
-- 211:ececeeecceeceeeccefecfceeffecfceefefefeffeefefeffecefefeeccefefe
-- 212:cececefecececefeefecefefefecefefffecefceffecefceeefefeeceefefeec
-- 213:ecefecececefececcececefecececefeeececeefeececeefcfecefcecfecefce
-- 214:fefefecefefefeceecefecececefececccefecfeccefecfeeececeefeececeef
-- 215:efecefefefecefeffefefecefefefeceeefefeeceefefeecfcefecfefcefecfe
-- 216:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 217:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 218:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 219:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 220:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 221:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 222:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 223:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 224:fecefffeeccefffeececeeecceeceeeccefececeeffececeefefeceffeefecef
-- 225:efefeeeffeefeeeffecefffeeccefffeececefecceecefeccefececeeffecece
-- 226:cefeccceeffeccceefefeeeffeefeeeffecefefeeccefefeececefecceecefec
-- 227:ececeeecceeceeeccefeccceeffeccceefefeceffeefeceffecefefeeccefefe
-- 228:cefefefecefefefeecefecefecefeceffcefeccefcefecceeececeeceececeec
-- 229:efecefecefecefeccefefefecefefefeeefefeefeefefeeffcefeccefcefecce
-- 230:fecececefecececeefecefecefecefeccfeceffecfeceffeeefefeefeefefeef
-- 231:ecefecefecefeceffecececefecececeeececeeceececeeccfeceffecfeceffe
-- 232:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 233:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 234:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 235:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 236:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 237:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 238:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 239:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 240:ccccccccc999999ccc9cc9cccc9779ccc978879c9788887997777779c999999c
-- 241:c999999ccc9cc9cccc9779ccc978879c9788887997777779c999999ccccccccc
-- 242:c12cccccc12cccccc12cccccc12cccccc12cccccc12cccccc99ccccc9999cccc
-- 243:c199ccccc19299ccc192229cc192299cc1999cccc19cccccc99ccccc9999cccc
-- 244:ccccccccc999999ccc9cc9cccc9339ccc934439c9344443993333339c999999c
-- 245:c999999ccc9cc9cccc9339ccc934439c9344443993333339c999999ccccccccc
-- 246:ccccccccc33cc39c3333333933333339c333339ccc3339ccccc39ccccccccccc
-- 247:ccccccccc22cc39c2233333923333339c333339ccc3339ccccc39ccccccccccc
-- 248:ccccccccc33cc39c3322333932233339c233339ccc3339ccccc39ccccccccccc
-- 249:ccccccccc33cc29c3333223933322339c322339ccc2339ccccc39ccccccccccc
-- 250:ccccccccc33cc39c3333332933333229c333229ccc3229ccccc29ccccccccccc
-- 251:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 252:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 253:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 254:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 255:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- </TILES1>

-- <TILES2>
-- 000:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 002:c6656665c55c6c6ccccc555fc66fffff56ffffff5fffffffffffffffffffffff
-- 003:66656665555c555cffffffffffffffffffffffffffffffffffffffffffffffff
-- 004:666566656c6c555c555fffffffffffffffffffffffffffffffffffffffffffff
-- 005:c665566cc55c666cffccccccfffff66cffffff65fffffff5ffffffffffffffff
-- 006:3ffffff3f3ffff3fff3ff3fffff33ffffff33fffff3ff3fff3ffff3f3ffffff3
-- 007:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 008:cccccccccccccccccccc335cccc32593ccc359c9cc35778cccc39c73ccccc999
-- 009:ccccccccc33ccccc3323cccc99993ccc9879ccccc73cccccc399cccc999999cc
-- 010:ff22222ff2222222222f2f222f22f2f2f22f2f22f2f2f2ffff2ffffffff2ff22
-- 011:2f2222ff2222222f2f2f2222f2f2f222ffff2f22fffff2f22fff2ffffff2ffff
-- 012:ffffffffffffffffffffffff222fffff2f22fffff2f2ffffff2ffffff2ffffff
-- 013:fffffffffffffffffffffffffffffffffffffff2ffffff2ffff2f2f2ff222f22
-- 014:ffffffffff2f2ffff2f2f2ff2f222f22f2f2f2f22f2f222ff2f2f2f22f222222
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
-- 026:ffffffffff222ffff2f2f2ff2f2f2ff2f2ffff222f2fff2ff2fffff2ff2fffff
-- 027:ffffffffff222f2f22f2f2f22f2fff2ff2fffff22fffffffffffffff2fffffff
-- 028:ffffffff2ffffffff2f2ffff2f2f2ffff2f2ff2fff2ff2f2ffffff2fffffffff
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
-- 062:ffffffff1f1f1f1ff1f1f1f1111f111ff1f1f1f111111111111111f111111111
-- 063:ffffffff1f1f1f1ff1f1f1f1111f111ff1f1f1f111111111111111f111111111
-- 064:aa000000aa0c0000ba00c000ba000000aa00c000ba0c0000aa00c000ba000000
-- 065:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 066:ffffffffffcfffcffffffcffcfcfcfcffcfcfcfccccccfccccfcccfccccccccc
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
-- 096:0000000000000000000000000000000000000000000000000000005600000066
-- 097:0000000000000000000000000000000000000000000000006500000066000000
-- 098:5555555555555555050505055550555000050005505050500000000000000000
-- 099:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 100:5776755677765556775055505500000055005550660050505700550077000000
-- 101:7565775555655556000000000000000005000505000000000050505000000000
-- 102:5775775577765556555000000000000005050505000000005050505000000000
-- 103:5776775655567756000055700000000005050500000000000050500000000000
-- 104:7757757655577555000006550000006605550077050500750055006600000065
-- 105:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 106:f9999aaaff9999aafff99bbbfffaaabb9999aaabf9999aaaff999999ffffff99
-- 107:bbabaaaaabaaabbbaaaabbbabaabbb99bb9aaaa999aaaaaa9aaa99aa99999999
-- 108:abbbaabbaaaaabbbaabbbaaaabbbaabbbbbaaaab9999aaaaa99aaaaa99aaa999
-- 109:baabaaaaaaaaabbbaaaabbbabaabbbaabbaaaaaabbbaaaaa9aaa99aa99999999
-- 110:abbbabaaaaaaaaaba9aaaabba9aa9bbb99a9a99a9999aaaaa99aaaaa99aaa999
-- 111:aaaaa99fbbaa99ffb9a99fffa999aaafa99aaaff99aaa999a999999f999999ff
-- 112:0000006600000056000000000000000000000000000000000000000000000000
-- 113:5500000056000000000000000000000000000000000000000000000000000000
-- 114:fffff221ffff2222ffff22ccffff22ccffff9221fff73912ff739991f3cccfcf
-- 115:9fffffff19ffffff1ccfffff1ccfffffc1c7ffff11993fffc99cfcfffcccccff
-- 116:7500500056000050770050007500005066005000750000505500500075000000
-- 117:0000000005000050000000000000000000000000000000000500005000000000
-- 118:0000000000000000050505000000000000505050000000000505050000000000
-- 119:0000000005500000055000000000000000005500000055000000000000000000
-- 120:0050006550000065000000650000006500500055500000660050005650000055
-- 121:fffffffffffffffffffffffffffffffffffffffffffffffffffffff7fff77888
-- 122:fffffff7ffffff77ffffff76fffff776ffff7766ff7876667887666687666666
-- 123:7777ffff778877ff677888776677888866777888667778886677788867778888
-- 124:ffffffffffffffffffffffff7fffffff87ffffff887fffff8887ffff888777ff
-- 125:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 126:ffffffffffffffffffffffffffffffffffffff77f7777766f6666666f6666666
-- 127:777fffff776fffff666fffff655fffff7777777f6666666f6566666f6556655f
-- 128:0000000000222200022222200202202002222220002222000020200000000000
-- 129:0000000000111100011111100101101001111110001111000010100000000000
-- 130:ffffffffff0fff0ffffff0ff0f0f0f0ff0f0f0f000000f0000f000f000000000
-- 132:7500500075000000750000007500000066000000750000505500500066000000
-- 133:0055500005550550000005550055055505555000055550550055005500000000
-- 134:0055000005555055055550550055005000000005500555005505555055005500
-- 136:0050006550000065005000655000006600500065500000650050006600000065
-- 137:ababbabdbb7bba7ddabbbabdabbb7abda7bbabdfddaab7dfaa7bddffddddffff
-- 138:ffdaadfffdabbadfd7a88a7ddbb88bbddbb7bbbdd7abba7ddbabbabddbabbabd
-- 139:8877777788888877888888888888888888888888778888777777777755777766
-- 140:7777778877888888888888888888888888777788776666776666555566555555
-- 141:6688885577888877788888878888888788888887888888877788887077777700
-- 142:f5566555ff666777ff666577ff666555fff66666fff55666fff66666fff55555
-- 143:5775666f7777566f7777666f57756666575666666566666666555555555fffff
-- 144:6777777767666666575777775757555657575555575655775756667557555575
-- 145:77777765666666605777776056c5565055555650766556505566665055655550
-- 146:06777777c6666666c5666666c5655555c5656555c5655775c565676505656765
-- 147:7775677666655765666567655765576557655765576557655765576557655765
-- 148:7500500075000050550050007500005075005000550000507500500075000000
-- 149:0000000000000000000005000000000005500000000000000005550055500555
-- 150:0000000005000000055000000050055000000055000000000000000000050000
-- 152:0050006550000065000000550000056600000556000007550050006650000065
-- 153:dbabbabad7abb7bbdbabbbaddba7bbbafdbabb7afd7baaddffddb7aaffffdddd
-- 154:dbab7abdd7abba7ddbabbabddbabbabddba7babdd7abba7ddbabbabddbabbabd
-- 155:ff777777f7888877788888887888888878888888788888877788887755888866
-- 156:777777ff7788887f888888878888888788888887788888877788887766888855
-- 157:5588886677888877788888877888888878888888788888880788887700777777
-- 158:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 159:555fffff555fffff665f67ff665665ff66665fff6755ffff675fffff676fffff
-- 160:575776655757c566575755555656555657566666565555555555555500000000
-- 161:5566775066655650555556505655565056666650555555505555555000000000
-- 162:c5655767c5655766c5655555c6655555c6677777c5666666c555555500000000
-- 163:77655765666557655555576555555765777777656666666555555555000000c0
-- 164:6600500077500000775055505550505066000550756000007665665665556655
-- 165:0005050000000000505050500000000000000000007550006655656656566555
-- 166:0000050000000000500050500000000000000000000000006666666656556555
-- 167:0505050000000000505050500000000000000000000000005565666656655555
-- 168:0050005500000056505550660050505500550065000006655555566555565556
-- 169:cc5c5c5c06677777c6677777c666666656665556c656557756665766c6565757
-- 170:5c5c5c5c77777777777777776666666677777765665567767776567755575567
-- 171:5c5c5c5c77777777777777776666666655777777577655667755677775557555
-- 172:5c5c5c5c77777660777776606666665065556550775565506675655075756550
-- 173:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 174:c5cccc5cc6677777c5666677c5556666c6677777c5556667cc55555555567777
-- 175:c55ccccc7777766c7766665c66665555777776657666555c5555555c77776555
-- 176:c78786c7c787786c677c786c677cc7868cc6c7868cc66c787c686c787c6886c7
-- 177:78686c78786886c7c88786c7c887786c677c786c677cc78687c6c78687c66c78
-- 178:86c6c78686c66c7876686c78766886c7c88786c7c887786c687c786c687cc786
-- 179:6c7c786c6c7cc7868cc6c7868cc66c7876686c78766886c7c68786c7c687786c
-- 180:77cc7cc67c6c7cc87c66c6c8c686c6c7c6886867c878686cc877876c67c78766
-- 181:8877877c87c7877687cc7c767c6c7c787c66c6c87686c6c7768868c7c87868cc
-- 182:668868876878688c6877878c87c7878687cc7c768c6c7c788c66c6787686c677
-- 183:cc66c668c686c667c68868676878686c6877878c67c7878667cc7c868c6c7c88
-- 184:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 185:55565756c6565676c5565567c556555555567777c5555555c55555550c0c0c00
-- 186:7757555755775557777655775555555577777777555555555555555c0c0c0c0c
-- 187:755575777555775577556777555555557777777755555555555555550000000c
-- 188:657565506765655076556550555565507777655055555550555555500c0ccc00
-- 189:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 190:c5776655576677765757555757567757c7656657c6765577c5677776cccccccc
-- 191:55667755677766757555757575776575756656757755676567777655cccccccc
-- 192:c68786c7c687786c667c786c667cc78688c6c78688c66c7878686c78786886c7
-- 193:7c686c787c6886c7cc8786c7cc87786c667c786c667cc78686c6c78686c66c78
-- 194:87c6c78687c66c7877686c78776886c7cc8786c7cc87786c6c7c786c6c7cc786
-- 195:687c786c687cc78688c6c78688c66c7877686c78776886c7c78786c7c787786c
-- 196:67cc7c866c6c7c888c66c6888686c677868868778878687c8877877c77c787c6
-- 197:c877876cc7c7876667cc7c666c6c7c886c66c6886686c687668868878878687c
-- 198:768868c7787868ccc87787ccc7c78766c7cc7c66cc6c7c68cc66c6686686c687
-- 199:8c66c6788686c67776886877787868cc787787cc77c787c677cc7cc6cc6c7c68
-- 200:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 201:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 202:5656775656567756565677565656775656567756565677565656776656567766
-- 203:7755756577557565775575657755756577667565776575657755756577557565
-- 204:5656675656567756565677565656775656567756565677565656776655556666
-- 205:7755656577557565775575657755756577567565776675657755756566656655
-- 206:c5c555c5c5c555c5c5c55555c5c55656c5c56656555666565656665656566656
-- 207:55c55c5c56555c5c6655655c6655655566556555665565556755656577556565
-- 208:87c78c877cc78c877c6c767cc66c767cc686c6c66886c6c66878686887786868
-- 209:687867688778676887c78c877cc78c877c6c7c7cc66c7c7cc686c6c66886c6c6
-- 210:c686c8c66886c8c6687867688778676887c787877cc787877c6c7c7cc66c7c7c
-- 211:7c6c767cc66c767cc686c8c66886c8c6687868688778686887c787877cc78787
-- 212:c6c7c686c6c7c686686c6878686c6878886c68c7886c68c76786876c6786876c
-- 213:7c787c6c7c787c6cc6c7c686c6c7c68666c7c67866c7c678c86c68c7c86c68c7
-- 214:878687c7878687c77c787c6c7c787c6ccc787c86cc787c8676c7c67876c7c678
-- 215:686c6878686c6878878687c7878687c77786876c7786876c8c787c868c787c86
-- 216:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 217:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 218:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 219:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 220:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 221:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 222:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 223:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 224:87c788877cc788877c6c777cc66c777cc686c7c66886c7c668786c6887786c68
-- 225:687866688778666887c788877cc788877c6c787cc66c787cc686c7c66886c7c6
-- 226:c686ccc66886ccc6687866688778666887c786877cc786877c6c787cc66c787c
-- 227:7c6c777cc66c777cc686ccc66886ccc668786c6887786c6887c786877cc78687
-- 228:c7868786c78687866c787c786c787c788c787cc78c787cc776c7c66c76c7c66c
-- 229:786c686c786c686cc7868786c786878667868778678687788c787cc78c787cc7
-- 230:86c7c6c786c7c6c7786c686c786c686cc86c6886c86c68866786877867868778
-- 231:6c787c786c787c7886c7c6c786c7c6c776c7c66c76c7c66cc86c6886c86c6886
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
-- 247:fffffffff22ff3cf2233333c2333333cf33333cfff333cfffff3cfffffffffff
-- 248:fffffffff33ff3cf3322333c3223333cf23333cfff333cfffff3cfffffffffff
-- 249:fffffffff33ff2cf3333223c3332233cf32233cfff233cfffff3cfffffffffff
-- 250:fffffffff33ff3cf3333332c3333322cf33322cfff322cfffff2cfffffffffff
-- 251:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 252:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 253:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 254:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 255:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- </TILES2>

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
-- 128:00000000000cc00000c76ccc00cc7667000766660c063763c2c7ccccc22c7767
-- 129:000000000000cc00cccc76c067667cc066666c0066c66c007c2c6c00c22c6c00
-- 130:000cc00000c76c0000c7cccc00cc7667000766660c063763c2c7ccccc22c7767
-- 131:0000cc00000c76c0ccccc7c067667cc066666c0066c66c007c2c6c00c22c6c00
-- 132:00cc00000c77c0000c67cccc0ccc667700c766660cc63763c2c7ccccc22c7767
-- 133:0000cc00000c76c0cccc77c06766ccc066665c00766c5c0077c25c00cc225c00
-- 134:00cc00000c77cccc0ccc667700c7666600c663760c2c7ccc0c22c7760c12cc66
-- 135:0000cc00cccc76c06766ccc066665c0037665c00c77ccc007cc2cc00cc12cc00
-- 136:00cc00000c77c0000c67cccc0ccc667700c7666600cc63760c2c7ccc0c22c776
-- 137:0000cc00000c76c0cccc77c06766ccc066665c0037666c00c77ccc007cc2cc00
-- 138:00cc00000c77c0000c67cccc0ccc667700c766660cc63763c2c7ccccc22c7767
-- 139:0000cc00000c76c0cccc77c06766ccc066665c00766c5c0077c25c00cc225c00
-- 144:c12cc66c0c1c76670ccccccc0c67555500c5576600c6666700c7cccc00cc0000
-- 145:121c6c00c1c767c0cc76666c5766677c66666cc077667000ccc55c00000ccc00
-- 146:0c1c76670ccccccc0c67555500c557660005666700067ccc0007c000000c0000
-- 147:c1c767c0cc76666c5766677c66666cc077667000cc55700000ccc00000000000
-- 148:0c1c76670cccccccc6c75555c6c576660cc56676000c7ccc000cc000000c0000
-- 149:cc1c6c00ccc767c05576c66c6666c77c77665cc0cc55c0000ccc000000000000
-- 150:0cc1c766c6ccccccc6c755550cc5766600c56676000ccccc000c5c000000c000
-- 151:7cc167c0cccc666c5576777c6666ccc07666c000cc75c0000c7c000000cc0000
-- 152:0cc1c766c6ccccccc6c755550cc5766600c56676000c5ccc0000c00000000000
-- 153:7cc167c0cccc666c5576777c6666ccc07766c000cc75c00000c70000000c0000
-- 154:0c1c76670cccccccc6c75555c6c576660cc56676000c6ccc0000cc0000000000
-- 155:cc1c6c00ccc767c05576c66c6666c77c77665cc0ccc5c000000cc0000000c000
-- 240:0000000004400430444444434444444304444430004443000004300000000000
-- 241:000000000cc00cc0c11cc19cc111119c0c1119c000c19c00000cc00000000000
-- </SPRITES>

-- <SPRITES1>
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
-- </SPRITES1>

-- <SPRITES2>
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
-- 128:00000000000cc00000c76ccc00cc7667000766660c063763c2c7ccccc22c7767
-- 129:000000000000cc00cccc76c067667cc066666c0066c66c007c2c6c00c22c6c00
-- 130:000cc00000c76c0000c7cccc00cc7667000766660c063763c2c7ccccc22c7767
-- 131:0000cc00000c76c0ccccc7c067667cc066666c0066c66c007c2c6c00c22c6c00
-- 132:00cc00000c77c0000c67cccc0ccc667700c766660cc63763c2c7ccccc22c7767
-- 133:0000cc00000c76c0cccc77c06766ccc066665c00766c5c0077c25c00cc225c00
-- 134:00cc00000c77cccc0ccc667700c7666600c663760c2c7ccc0c22c7760c12cc66
-- 135:0000cc00cccc76c06766ccc066665c0037665c00c77ccc007cc2cc00cc12cc00
-- 136:00cc00000c77c0000c67cccc0ccc667700c7666600cc63760c2c7ccc0c22c776
-- 137:0000cc00000c76c0cccc77c06766ccc066665c0037666c00c77ccc007cc2cc00
-- 138:00cc00000c77c0000c67cccc0ccc667700c766660cc63763c2c7ccccc22c7767
-- 139:0000cc00000c76c0cccc77c06766ccc066665c00766c5c0077c25c00cc225c00
-- 144:c12cc66c0c1c76670ccccccc0c67555500c5576600c6666700c7cccc00cc0000
-- 145:121c6c00c1c767c0cc76666c5766677c66666cc077667000ccc55c00000ccc00
-- 146:0c1c76670ccccccc0c67555500c557660005666700067ccc0007c000000c0000
-- 147:c1c767c0cc76666c5766677c66666cc077667000cc55700000ccc00000000000
-- 148:0c1c76670cccccccc6c75555c6c576660cc56676000c7ccc000cc000000c0000
-- 149:cc1c6c00ccc767c05576c66c6666c77c77665cc0cc55c0000ccc000000000000
-- 150:0cc1c766c6ccccccc6c755550cc5766600c56676000ccccc000c5c000000c000
-- 151:7cc167c0cccc666c5576777c6666ccc07666c000cc75c0000c7c000000cc0000
-- 152:0cc1c766c6ccccccc6c755550cc5766600c56676000c5ccc0000c00000000000
-- 153:7cc167c0cccc666c5576777c6666ccc07766c000cc75c00000c70000000c0000
-- 154:0c1c76670cccccccc6c75555c6c576660cc56676000c6ccc0000cc0000000000
-- 155:cc1c6c00ccc767c05576c66c6666c77c77665cc0ccc5c000000cc0000000c000
-- 240:0000000004400430444444434444444304444430004443000004300000000000
-- 241:000000000cc00cc0c11cc19cc111119c0c1119c000c19c00000cc00000000000
-- </SPRITES2>

-- <MAP>
-- 001:0000000000000000000000000000c1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0b0c000000000000000000000000000000000000000000000000000000000000000a0b0c0000000a0b0c000d0e0f0000000000000a0b0c000000000000000d0e0f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:00000000000000000000000000000000000000000000c100000000000000000000000000a0b0c000a1000000000000000000a1000000000000000000000000000000000000000000a1b1c10000a0b0c0000000a1b1c10000000000000000a0b0c00000000000000000000000a0b0c00000000000a0b0c00000000000a1b1c100000000000000d1e1f1000000000000a1b1c100000000000000d1e1f1000000000000a0b0c00000000000000000a0b0c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:000000000000000000d0d1e00000000000e2d0e0f000000000000000000000000000000000a1a0b0c0000000000000000000b1c10000a100000000000000000000a0b0c0a0b0c0000000000000a1a0b0c0000000000000a2b2c200000000a1b1c10000000000a0b0c0000000a1b1c10000000000000000000000000000000000000000000000d2e2f200a0b0c0000000000000000000000000d2e2f2000000000000a1b1c10000000000000000a1b1c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:000000000000000000d1e1f10000000000c1d1a0b0c0000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000a1b1c100000000000000000000000000000000000000a3b3c3000000000000000000a0b0c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:000000000000000000000000000000000000d2a0b0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0b0c0000000000000000000000000000000a4b4c40000000000000000000000000000000000000000000000a0b0c0000000000000000000000000000000000000000000000000004f006f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005100000000a0b0c00000000000000000000000a1b1c100000000000000d3000000000000000000000000000000a1b1c1000000000000000000000000000000000000000800000f0000002f00000000000055005500000000000000000000000000000065000000650000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:00000000000000000000000000000000000000000000000000000000005400330055002f000000000000a2b2c200000000000000000000000000005200000000000000000000000000000000000000000000000000000000d4000000000000000000000000000000000000a1b1c10000000000000000000000000000000000000065005551719100a1b1c10051617181910000a1b1a1b1c1000000000000466676566686006500000000000f0000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:000000000000000000000000000000000000000000000000000000000001112131616141000000000000a3b3c300000000000000000000000000005200000000000000000000000000000000000000000000000000000000d4000000000008000000000000000000000000000000000000000000000000a1b1c100005500517181617181171087000000000052627282920000a1b1c1000000000000d40048581010101056668600000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:0000000000000000000000000000000000a2b2c2000000000000000000021012103206930000b1c10000a4b4c40000000000000000a5b5c5d5f500520000000000a1b1c100000000000000000000000000000000a5b5f533e40074000000007454004f006423540000000000000000000000000000000000006500517181175767771010101088000000000053637383930000d2e2f2000000000000e400495977105767771087000000000000e7f70000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:0000000000000000000000000000000000a3b3c30000000000003040500306838383930000000000000000d3000000000000000000a6b6c6d6f60052000000000000000000000000000000000000000000000000a6b6f60121314100000001112111213111214100000000000000000000000000000065655171816272821058687862728210890000000000000000000000000000000000000000466676175767775868771088091900000000e8f80000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:0000000000000000a5f500000000000000a4b4c40000000000000000000492000000000000000000000000e4002355005400000001112131112131170000000000000000000000000000000000000f00000000000121319522324200000002122212223212224200000000000000000000000f000051718117101057677710596979586878108700000000000000000000000000000000000000504858101058687859697910890a1a97a7b7c765f997a7b7c760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:0000002313131313a6f62300000013005400e4000000000000005474640292000f00650000000000007401112131112131412050536373839363737300000000000000000000546423547400080000000000542302223210101043000000051525352515253545200000000000000000000000000052066a7a161058687862728210596979108800000f00000000000000000000080000000f000049591069596979101010690756667656667656667656667666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:1121311121311121311121311121311121311141cdcdcdcdcd0111213195076171817191000000006401951010101010109100000000e7f700000060000000000000005474012131112141545400643300012131951010101010440000000000000000000000000000000000a5e5f50074005120504a8a0000471059627282771010576777108900000000e400650000000000000000000000000047101010101069576777101010101010105767771010576777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:1010101032101010101032101010101032101042cecececece0210101010106210107292000000540195121032101262109200000f00e8f80000006000005474006401213195223212228511213111213195221010101210321042000000000000000f000000000000000000a6e6f60121319200000000006f4810101058687877106272821087006500004666860000000065004666765666766617576777586910586878106957676910695868781077586878000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:101210321010121072101010101210821222320761718171811710121010101010221092006500019510101062101032629200000000e9f90000006011213111213195223210103210101010223210223210101232101010101043740033743354746564743354006401213111213195223292e3f3e3f3e3f34910627282697910105969791007765666761710890055004666761710101010105810586878101010596979101058687869105969797769596979000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:101010101010101010101010101012101032122232221222323210106210101082101085112131951010101010101010100711213111213111112131122232121032101010321010121032101010121010101010101010321010851121311121311121311121311121951222321012223210075666765666761710101010101010101010101010101010101077075666761777101058101058101010596969105810101010691059697910771010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 018:000000a0b0c00000000000000000000000000000000000a0b0c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 019:00000000d0e0f00000000000a1c000c100000000a1b0c000a1b1c10000000000a0b0c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 020:00000000d1e1f10000000000d1c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 021:00000000d2e2f20000000000000000000000000000000000000000a1b1c1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 022:0000000000000000000000000000000000000000000000000000a1b1c1a1b1c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 023:0000000000000000000000000000a0b0c000000000000000000000000000000000000000005121213111213100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 024:0000000000000000a2b2c2000000a1b1c100000000000000000000000000000000000000005210101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 025:00000000a2b2c200a3b3c300000000000000000000000000000000000000000000000000005210101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 026:00000000a3b3c300a4b4c400000000000000000000000000000000000000000000000000005210101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 027:00000000a4b4c40000d30000000000000000000000000000000000000000000000000000005210101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 028:f500000000d3000000d4000000a5f50000000000000000000000a5b5c5d5e5f5a5b5f54f005210101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 029:f633005400e4647400e4547433a6f6000000006574000f005400a6b6c6d6e6f6a6b6f600005210101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 030:211121112131112131112131112141203040500121311121311121311121311121311121319510101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 031:101010101010101010101010101092000000005210101010101010101010101010101010101010101010101000000000000000000092000000000052000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 032:101010101010101010101010101092242424245210101010101010101010101010101010101010101010101000000000000000000092000000000052000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 033:101010101010101010101010101092141414145210101010101010101010101010101010101010101010101000000000000000000092141414141452000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 034:101010101010101010101010101092707070705210101010101010101010101010101010101010101010101000000000000000008393203030405052000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 035:101010101010101010101010101092141414145210101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 036:101010101010101010101010101092141414145210101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 037:101010101010101010100663738393141414145210101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 038:101010101010101010109214141414141414145210101006637383637383101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 039:101010101010101010109214141414141414145210101092141414141414000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 040:101010101010101010109214141414141480145210101092140f14141414000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 041:101010101010101010109214141414516171811710101092141414141414000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 042:101010101010101010109214141414521010101010101092203014141414000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 043:101010101010066373839314141414536373836373838393141414141414000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 044:101010101010921414141414141414141414141414141414141414141414000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 045:10101010101092146f141480901414140f14141414141414141414141414000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 046:101010101010076171617181617181617181617181617181617181101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 047:101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 048:101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 049:101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 050:101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <MAP1>
-- 001:0000000000000000000000000000c1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:00000000000000000000000000000000000000000000c100000000000000000000000000a0b0c000a1000000000000000000a1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:000000000000000000d0d1e00000000000e2d0e0f000000000000000000000000000000000a1a0b0c0000000000000000000b1c10000a10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:000000000000000000d1e1f10000000000c1d1a0b0c0000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:000000000000000000000000000000000000d2a0b0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000051000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:00000000000000000000000000000000000000000000000000000000005400330055002f000000000000a2b2c2000000000000000000000000000052000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:000000000000000000000000000000000000000000000000000000000001112131616141000000000000a3b3c3000000000000000000000000000052000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:0000000000000000000000000000000000000000000000000000000000021012103206930000b1c10000a4b4c40000000000000000a5b5c5d5f50052000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:00000000000000000000000000000000000000000000000000003040500306838383930000000000000000d3000000000000000000a6b6c6d6f60052000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:0000000000000000a5f5000000006f00004f00000000000000000000000492000000000000000000000000e400235500540000000111213111213117000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:0000002313131313a6f6230033001300540000000000000000005474640292000f006500000000000074011121311121314120505363738393637373000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:11213111213111213111213111213111213111410d0d0d0d0d0111213195076171817191000000006401951010101010109100000000e7f700000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:10101010321010101010321010101010321010420e0e0e0e0e0210101010106210107292000000540195121032101262109200000f00e8f800000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:101210321010121072101010101210821010101210101010101010121010101010221092006500019510101062101032629200000000e9f900000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:101010101010101010101010101012101032101010108210103210106210101082101085112131951010101010101010100711213111213111112131000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 023:000000000000000000000000000000000000000000000000000000000000000000000000005121213111213111213111213111213141000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 024:000000000000000000000000000000000000000000000000000000000000000000000000005210101010102210101022101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 025:000000000000000000000000000000000000000000000000000000000000000000000000005210821010101062101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 026:000000000000000000000000000000000000000000000000000000000000000000000000005210101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 027:000000000000000000000000000000000000000000000000000000000000000000000000005210101010101010101010101010101010107210101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 028:00000000000000000000000000000000000000000000000000000000000000000000004f005210101010101010101010106210101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 029:000000000000000000000000000000000000000000000f00000000000000000000000000005210108210101010101010101010821010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 030:211121112131112131112131112141203040500121311121311121311121311121311121319510101010107210101010101010101010621010101082000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 031:102210101010101012101010321092000000005210221032101010101010101210101010102210101010101010106210101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 032:101010121010101010103210101092242424245210101010102210101210101010101010101010101062101010101082101072101010101010621010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 033:101010101010101022101010321092141414145232101012101010221010101022101012101010101010101010101010101010101010348234101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 034:101010101010101010101010101092000000005210101010101082101010101010067383637383637383637383637383637383736373837363736373836373836373831610101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 035:821010101010101010101010101092000000005210106210101010107210101010920000080000180000000000000000000008000000000000000000000008180000005210107210101010108210101072101010101072101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 036:10101062107210101010721010109236000000521010101072101062101010821092000009000019004f0000000000000f0009000000000000809000000009190000265210101010101062101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 037:101010101010101010100663738393141414145210821010101010101010101010920000000000516171910000000000000000000000517181617161719100000f00005210101010721010101010101082101010728210106210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 038:10101010101010101010920814181414141414521010100663738363738363731692000f003050526282920000005161718191000000521082107210109200000000005262100663637383637383637383161010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 039:108210101072101062109209141914141414145210621092141414140818000052920000000000536373930000265363738393000050520663637383169200005161611710109200000000000000000000521010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 040:101010101010101010109214141414141480145210101092140f1414091900005393203000000000000000000000000008000000000052920b4b0d4d529200005210821010109200000000004f00000000521010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 041:10101010101010101010921414141451617181171010109236141414141400001800000000000000809000000000000009000000000052920b4b0d4d529200005363738363739300000000000000000000521010621010107210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 042:10721010621010101010923614141452108210101082109200001414141400001900000000000051617161718161718191000000005052920b4b0d4d529200000008180000000000000000000000000000521010107210101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 043:10101010101006637383931414141453637383637383839320301414141400000000000000005117171072101010101092809000000052920b4b0d4d529200000009190000000000000000000000000000521010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 044:10101010101092141414141414141414141414141414141414141414141400000000000000511710101010101010621007719100002652920b4b0d4d520761718161718191000000000000000000004050537383637383637383000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 045:10101072101092146f141480901414140f141414142f1414141400141414000090000000511710101010621010101010101092000f0052920b4b0d4d52101010101010100791000000000000000000000000000000e7f7000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 046:10101010101007617161718161718161718161718161718161718161718161718161718117101082101010101010101082100781617117920b4b0d4d52106210821010101007910000000000000000000000000000e8f8000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 047:10101010108210101010101010107210101010101010721010101010101010106210101010101010101010101010721010101010621010920b4b0d4d52101010101062101010079100000000000000000000000000e9f9000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 048:10621010101010101010108210101010101062101010101010101062101010101010101010101010107210101010101010101010101010920b4b0d4d521010101010101010101007617181617181617181617181617181617181000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 049:10101010101010101010101010721010101010101010101062101010101010101010621072101010101010101010101010621010101010920b4b0d4d521010101010101062101010101010108210101010101010101082101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 050:10101010101010621010101010101010101010821010101010101072101010101010101010101010101010108210101010101010107210920b4b0d4d521082101010101010101010101010101010101010106210101010101082000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP1>

-- <MAP2>
-- 010:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eafa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ebfb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ecfc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000acbc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:56667656667656667656667656667656667656667656667656667600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000acbc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000acbc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccdc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 017:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a5a6a6a7a5a6a7a5a6a7a5a6a7a5a6a7a5a6a7a5a6a7a160919000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 018:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000470a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 019:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000475787000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 020:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000000080000000000000046665666766676566676860000486788000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 021:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a800000000000000000000000000000000000000000000000000000047101057105a6a7a7a10870000497789000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 022:000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000a8a9000000000009192939000000000000b9c89aaabaca56667656667617106710100b4b0d4d10880000475787000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 023:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000099a9a7b7c700000a1a2a3a00000000b9c8d8269babbbcb10106810101010101010770b4b0d4d77890000486788000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 024:00000000000000000000000000000000000000000000000000000000000000000000009aaabaca00000000b9b8c8b8c8b8c8b8c8b8c8b8c8b8c8b8c8d826261010101010101010065a6a7a8a5a6a160b4b0d4d10870000497789000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 025:00000000000000000000000000000000000000000000000000000000000000000000009babbbcb000000004726262626262626262626262626262626101010106810101067101088000000000000470b4b0d4d10880000476787000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 026:000000000000000000000000000000000000000000000000000000000000eafa000000465666860000000048571010101010101010101010101010105810105710106710101010890000000000004a6a7a5a6a7a8a0000485788000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 027:000000000000000000000000000000000000000000000000000000000000ebfb00000047576787000000004910676710671010105810101077106710101010101057101010571088000009190000000b4b0d4d00000000495789000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 028:0000000000000000000000000000000000000000000000000000eafa0000ecfc00000048586887000000004710101010105810101010571057101010101057101010105810101089006f0a1a0027370b4b0d4d000f00004a5a8a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 029:00000000000000000000000000000000000000000000eafa0000ebfb0000acbc0000004958688800000000481010571010105a5a6a7a101010101010101010101010101018101007566676566676566676566676860000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 030:000000000000000000000000000000000000eafa0000ebfb0000ecfc0000acbc0000004759698900000000491010101010100b4b0d4d581010101010101010101067101010106710101010101010100b4b0d4d10872000000000000000000000000000000000eafa000000eafa0000000000eafa0000000000eafa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 031:000000000000a800000000000000eafa0000ebfb0000ecfc0000acbc0000acbc0000004779778700000000471067101010570b4b0d4d101010571010105810571010101057101010101010105710100b4b0d4d10880000000000000000000000000000000000ebfb000000ebfb0000000000ebfb0000000000ebfb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 032:0097a7b7c700a9000055eafa0000ebfb0000ecfc0000ccdc0000ccdc0000ccdc0000004877798800000000481010107710100b4b0d4d101010101010101010581010101010101010775710101010770b4b0d4d778900000000000097a7b7c797a7b7c700a800ecfc282828ecfc2828282828ecfc2828282828ecfc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 033:46566676566676667656667656667686282846862828468628284686282846862828284979798928282828491010101010100b4b0d4d105810101010107710101010106710101010101010101010100b4b0d4d1007566676566686b8c8c8b8c8b8b8c8b8c8b8468638383846863838383838468638383838384686000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 034:000000000000000000000000000000383838383838383838383838383838383838383838383838383838383800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP2>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <WAVES1>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES1>

-- <WAVES2>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES2>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <SFX1>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX1>

-- <SFX2>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX2>

-- <FLAGS>
-- 000:00102020202040800000000000000000101010101010101010100000000000001000000010101010101000000000000010000000101010101010000000000000100000001000000000000000000000001010101010000000000000000000000000000000101010101000000000000000000000001000000010000000000000000000000010000000100000000000000010101010100000001000000000000000101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </FLAGS>

-- <FLAGS1>
-- 000:00102020202040800000000000000000101010101010101010100000000000001000000010101010101000000000000010000000101010101010000000000000100000011000000000000000000000001010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </FLAGS1>

-- <FLAGS2>
-- 000:00102020202040800000000000000000101010101010101010100000000000001000000010101010101000000000000010000000101010101010000000000000100000001000000000000000000000001010101010000000000000000000000000000000101010101000000000000000000000001000000010000000000000000000000010000000100000101000000010101010100000001000001010000000101010101010101010101010100010100000000000000000001010101000101000000000000000000000101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </FLAGS2>

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

-- <SCREEN1>
-- 000:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 001:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 002:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 003:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 004:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 005:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 006:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 007:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 008:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 009:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 010:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 011:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 012:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2ff2fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 013:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2ff2f2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 014:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 015:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 016:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 017:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 018:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 019:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 020:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2ff2fffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 021:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2ff2f2ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 022:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2fffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 023:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 024:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2f2fff2ffffffffffffffffffffffffffffffffffffffffffff222f22fffffffffffff2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 025:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2fff2f2fffffffffffffffffffffffffffffffffffffffffff222f2222ffffffffff2f2fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 026:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2f2f2f2ffffffffffffffffffffffffffffffffffffffffff22ff2222fffffffff2f2f2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 027:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff222f222f222f22fffffffffffffffffffffffffffffffffffffffffffff22fffffffff2f222f2222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 028:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2fff2f2f2f2f2fffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2f2f2f2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 029:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2fff2f22f22f2f222fffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2f222f222fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 030:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2fff2f2fff2f2f2f2fffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2f2f2f2f2f2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 031:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff222f22fff2222f2f222222ffffffffffffffffffffffffffffffffffffffffffffffffff222f222f222222222ff22fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 032:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2f2f2f2f2f2f2f222f2fffffffffffffffffffffffffffffffffffffffffffffffff2f2f2f2ff22222f2f2222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 033:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2f222f222222222222ffffffffffffffffffffffffffffffffffffffff2fffffffff2f2f2ff22222222222222fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 034:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2f2f2f222f222f222fffffffffffffffffffffffffffffffffffffffff2f2fffffff2f2f2222f2f222f2f2222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 035:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff222f2222222222222ff22fffffffffffffffffffffffffffffffffffffffff2f2f2fffff222f222f22f2f2f2f2f222222fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 036:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2fff2f2f2f2f22ffffffffffffffffffffffffffffffffffffffffffffffff2f2ff2ff2f2fff2f22f2f22ffff2f222f22ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 037:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f22f22f2222222fffffffffffffffffffffffffffffffffffffffffffffffff2ff2f2ff2f22f2f2f2f2fffffff2f2f2f2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 038:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2fffff2f2222fffffffffffffffffffffffffffffffffffffffffffffffffffff2ffff2f2ffff2fffff2fff2fffff2fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 039:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222f22f22222fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222ffff2ff22fff2fffff2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 040:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2ff22222f2f2222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 041:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f22222222222222fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 042:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff222f2f222f2f2222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 043:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f22f2f2f2f2f222222fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 044:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22f2f22ffff2f222f22ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 045:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2fffffff2f2f2f2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 046:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2fffff2fff2fffff2fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 047:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2ff22fff2fffff2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 048:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 049:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 050:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 051:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 052:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 053:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 054:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 055:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 056:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 057:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 058:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbffff
-- 059:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffafffbbf
-- 060:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaffffaf
-- 061:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaffffaf
-- 062:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffafaffaf
-- 063:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9f9ff9f
-- 064:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaaaabab
-- 065:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbaaaaaaa
-- 066:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaa00000
-- 067:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa000c00
-- 068:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa00c0c0
-- 069:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba0c0000
-- 070:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa00c000
-- 071:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba000000
-- 072:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa000000
-- 073:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa0c0000
-- 074:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba000000
-- 075:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba0c0000
-- 076:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa000000
-- 077:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba0c0000
-- 078:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa000000
-- 079:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba000000
-- 080:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6665666566656665c665566caa000000
-- 081:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff555c555c6c6c555cc55c666caa0c0000
-- 082:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff555fffffffccccccaaa0c000
-- 083:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff66cbaac0000
-- 084:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff65aaa0c000
-- 085:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5baac0000
-- 086:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaa0c000
-- 087:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba000000
-- 088:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffccccccfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa000000
-- 089:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9fffffffffffffffffffffffffffffffffffffffff33ff2cfffffffffffffffffffcffcffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa0c0000
-- 090:ffffffffffffffffffffffcccccffffffffffffffffffffffffffffffffffffffffffff9afffffffffffffffffffffffffffffffffffffff3333223cffffffffffffffffffc33cffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba00c000
-- 091:fffffffffffffffffffffc56666cffffffffffffffffffffffffffffffffffffffff9ff9aff9ffffffffffffffffffffffffffffffffffff3332233cfffffffffffffffffc3443cfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba000000
-- 092:ffffffffffffffffffffc5656666cfffffffffffffffffffffffffffffffffffffff99ffaf99fffffffffffffffffffffffffffffffffffff32233cfffffffffffffffffc344443cffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa00c000
-- 093:ffffffffffffffffffffc5588886cfffffffffffffffffffffffffffffffffffffff999ba999ffffffffffffffffffffffffffffffffffffff233cffffffffffffffffffc333333cffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba0c0000
-- 094:ffffffffffffffffffffc588888cffffffffffffffffffffffffffffffffffffffff9a9ba999affffffffffffffffffffffffffffffffffffff3cffffffffffffffffffffccccccfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa00c000
-- 095:ffffffffffffffffffffc5e8888cffffffffffffffffffffffffffffffffffffffff9aabaa9aafffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba000000
-- 096:ffffffffffffffffffffcee8888cfffffffffffffffffffffffffffffffffffff9999aaaaaaaa99fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa000000
-- 097:ffffffffffffffffffffcddeeedc4fffffffffffffffffffffffffffffffffffff9999aabbaa99ffffff4fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa0c0000
-- 098:fffffffffffffffffffceddeeedec3fffffffffffffffffffffffffffffffffffff99bbbb9a99ffffff323ffffffffffffffffffffffffffffffffffffffffffffbbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbfffffffaffffffffffffba000000
-- 099:ffffffffffffffffffceeddeeedeec4ffffffffffffffffffffffffffffffffffffaaabba999aaafff24744ffffffffffffffffffffffffffffffffffffffffffafffbbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffafffbbfffbfaffffffbffffba0c0000
-- 100:ffffffffffffffffffc88dddddd88cfffffbfffffffbfffffffbfffffffbffff9999aaaba99aaafffff323fffffffffffffffffffffffffffffbfffffffffffffaffffaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaffffafffffafffffafffffaa000000
-- 101:ffffffffffffffffffc87ddccdd78cfffffbfffffffbfffffffbfffffffbfffff9999aaa99aaa999ffff1ffffffffffffaaafffffffffffffffbfffffffffffffaffffaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaffffafffffafffffafffffba0c0000
-- 102:fffffffffffffffffffccddccddccffffbfbfbfffbfbfbfffbfbfbfffbfbfbffff999999a999999ffffabffffffffffffaaaabaffffffffffbfbfbfffffffffffafaffaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffafaffafffff9fffffafafffaa000000
-- 103:fffffffffffffffffffffccffccfaffffafafafffafafafffafafafffafafaffffffff99999999ffffffafffffffffffaaaaaaa9fffffffffafafafffffffffff9f9ff9ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9f9ff9fffff9fffff9fafffba000000
-- 104:abaababbabbbabbbaabbabbaabaababbabbbabbbaabbabbaabaababbabbbabbbaabbabbaabaababbabbbabbbaabbabbaabaababbabbbabbbaabbabbaabaababbabbbabbbaabbabbaabaababbaaababaaffffffffffffffffffffffffffffffffffffffffaaaaabababaababbabbbabbbaabbabba99000000
-- 105:aaabaaaaaaaaaaaaabbaabbaaaabaaaaaaaaaaaaabbaabbaaaabaaaaaaaaaaaaabbaabbaaaabaaaaaaaaaaaaabbaabbaaaabaaaaaaaaaaaaabbaabbaaaabaaaaaaaaaaaaabbaabbaaaabaaaababbabaaffffffffffffffffffffffffffffffffffffffffbaaaaaaaaaabaaaaaaaaaaaaabbaabba9a000000
-- 106:aaaaaaaa000000000000aaaaaaaaaaaa000000000000aaaaaaaaaaaa000000000000aaaaaaaaaaaa000000000000aaaaaaaaaaaa000000000000aaaaaaaaaaaa000000000000aaaaaaaaaaaabaaa0aaaffffffffffffffffffffffffffffffffffffffffaaa00000aaaaaaaa000000000000aaaa00000000
-- 107:000000000c0c0c000c000000000000000c0c0c000c000000000000000c0c0c000c000000000000000c0c0c000c000000000000000c0c0c000c000000000000000c0c0c000c00000000000000000000abffffffffffffffffffffffffffffffffffffffffaa000c00000000000c0c0c000c00000000000000
-- 108:00c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c000aaee2eeee2ee2eeee2ee2eeee2ee2eeee2ee2eeee2aa00c0c000c0c0c000c0c0c000c0c0c000000000
-- 109:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c00aaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeba0c000000000000000000000000000000000000
-- 110:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000aaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaa00c00000000000000000000000000000000000
-- 111:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aadedededededededededededededededededededeba00000000000000000000000000000000000000
-- 112:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000abbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaa00000000000000000000000000000000000000
-- 113:000000000000000000000000000000000c000c0000000000000000000000000000000000000000000c000c0000000000000000000000000000000000000000000c000c000000000000000000000c0aabded2dededed2dededed2dededed2dededed2dedeaa0c000000000000000000000000000000000000
-- 114:000000000000000000000000000000000000c0c000000000000000000000000000000000000000000000c0c000000000000000000000000000000000000000000000c0c0000000000000000000c00aaaededededededededededededededededededededba00000000000000000000000000000000000000
-- 115:0000000000000000000000000000000000000c00000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000c000000000000000000000c0aabd2dedd2ed2dedd2ed2dedd2ed2dedd2ed2dedd2eba0c000000000000000000000000000000000000
-- 116:00000000000000000000000000000000000000c00000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000c0000000000000000000c00aaaededededededededededededededededededededaa00000000000000000000000000000000000000
-- 117:000000000000000000000000000000000c00000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000c0000000000000000000000000c0aaaddddddddddddddddddddddddddddddddddddddddba0c000000000000000000000000000000000000
-- 118:0000000000000000000000000000000000c00000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000c00000000000000000000000c00aaaddddddedddddddedddddddedddddddedddddddedaa00000000000000000000000000000000000000
-- 119:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaddddddddddddddddddddddddddddddddddddddddba00000000000000000000000000000000000000
-- 121:00000000000c0c00000000000c000c000000000000000000000c0c00000000000000000000000000000000000000000000000000000c0c000000000000000000000000000000000000000000000c0c0000000000000000000000000000000000000000000000000000000000000c0c000000000000000000
-- 122:0000000000c0c0c0000000000000c0c0000000000000000000c0c0c000000000000500000000000000000000000000000000000000c0c0c0000000000000055000000000000000000000000000c0c0c00000000000000000000000000000000000000000000000000000000000c0c0c00000000000000000
-- 123:000000000c000c000000000000000c0000000000000000000c000c000000000000000000000000000000000000000000000000000c000c0000000000000505500000000000000000000000000c000c00000000000000000000000000000000000000000000000000000000000c000c000000000000000000
-- 124:0000000000c0c0c000000000000000c0000000000000000000c0c0c000000000005500000000000000000000000000000000000000c0c0c0000000000000000000000000000000000000000000c0c0c00000000000000000000000000000000000000000000000000000000000c0c0c00000000000000000
-- 125:000000000c0c0c00000000000c00000000000000000000000c0c0c000000000000550050000000000000000000000000000000000c0c0c0000000000000000000000000000000000000000000c0c0c00000000000000000000000000000000000000000000000000000000000c0c0c000000000000000000
-- 126:0000000000c000c00000000000c00000000000000000000000c000c000000000000000000000000000000000000000000000000000c000c0000000000005000000000000000000000000000000c000c00000000000000000000000000000000000000000000000000000000000c000c00000000000000000
-- 129:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c0000000000000000000c000c00000000000000000000000000000000000000000000000000000000000c000c0000000000000000000555000000000000
-- 130:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c0c000000000000000000000c0c0000000000000000000000000000000000000055000000000000000000000c0c000000000000000000555000000000000
-- 131:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000c00000000000000000000000c000000000000000000000000000000000000050550000000000000000000000c0000000000000000000565000000000000
-- 132:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c0c00000000000000000000000c000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000
-- 133:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c0c0000000000000000000c000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000055000000000
-- 134:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000c0000000000000000000c000000000000000000000000000000000000000050000000000000000000000c0000000000000000000000000055000000000
-- </SCREEN1>

-- <SCREEN2>
-- 000:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 001:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 002:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 003:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 004:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 005:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 006:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 007:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 008:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 009:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 010:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 011:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 012:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2ff2fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 013:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2ff2f2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 014:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 015:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 016:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 017:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 018:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 019:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 020:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2ff2fffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 021:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2ff2f2ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 022:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2fffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 023:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 024:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2f2fff2ffffffffffffffffffffffffffffffffffffffffffff222f22fffffffffffff2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 025:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2fff2f2fffffffffffffffffffffffffffffffffffffffffff222f2222ffffffffff2f2fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 026:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2f2f2f2ffffffffffffffffffffffffffffffffffffffffff22ff2222fffffffff2f2f2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 027:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff222f222f222f22fffffffffffffffffffffffffffffffffffffffffffff22fffffffff2f222f2222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 028:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2fff2f2f2f2f2fffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2f2f2f2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 029:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2fff2f22f22f2f222fffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2f222f222fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 030:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2fff2f2fff2f2f2f2fffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2f2f2f2f2f2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 031:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff222f22fff2222f2f222222ffffffffffffffffffffffffffffffffffffffffffffffffff222f222f222222222ff22fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 032:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2f2f2f2f2f2f2f222f2fffffffffffffffffffffffffffffffffffffffffffffffff2f2f2f2ff22222f2f2222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 033:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2f222f222222222222ffffffffffffffffffffffffffffffffffffffff2fffffffff2f2f2ff22222222222222fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 034:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2f2f2f222f222f222fffffffffffffffffffffffffffffffffffffffff2f2fffffff2f2f2222f2f222f2f2222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 035:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff222f2222222222222ff22fffffffffffffffffffffffffffffffffffffffff2f2f2fffff222f222f22f2f2f2f2f222222fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 036:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2fff2f2f2f2f22ffffffffffffffffffffffffffffffffffffffffffffffff2f2ff2ff2f2fff2f22f2f22ffff2f222f22ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 037:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f22f22f2222222fffffffffffffffffffffffffffffffffffffffffffffffff2ff2f2ff2f22f2f2f2f2fffffff2f2f2f2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 038:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2fffff2f2222fffffffffffffffffffffffffffffffffffffffffffffffffffff2ffff2f2ffff2fffff2fff2fffff2fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 039:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222f22f22222fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222ffff2ff22fff2fffff2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 040:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2ff22222f2f2222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 041:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f22222222222222fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 042:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff222f2f222f2f2222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 043:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f22f2f2f2f2f222222fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 044:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22f2f22ffff2f222f22ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 045:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2fffffff2f2f2f2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 046:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2fffff2fff2fffff2fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 047:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2ff22fff2fffff2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 048:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 049:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 050:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 051:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 052:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 053:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 054:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 055:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 056:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 057:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 058:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbffff
-- 059:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffafffbbf
-- 060:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaffffaf
-- 061:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaffffaf
-- 062:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffafaffaf
-- 063:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9f9ff9f
-- 064:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaaaabab
-- 065:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbaaaaaaa
-- 066:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaa00000
-- 067:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa000c00
-- 068:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa00c0c0
-- 069:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba0c0000
-- 070:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa00c000
-- 071:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba000000
-- 072:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa000000
-- 073:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa0c0000
-- 074:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba000000
-- 075:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba0c0000
-- 076:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa000000
-- 077:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba0c0000
-- 078:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa000000
-- 079:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba000000
-- 080:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6665666566656665c665566caa000000
-- 081:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff555c555c6c6c555cc55c666caa0c0000
-- 082:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff555fffffffccccccaaa0c000
-- 083:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff66cbaac0000
-- 084:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff65aaa0c000
-- 085:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5baac0000
-- 086:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaa0c000
-- 087:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba000000
-- 088:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa000000
-- 089:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9fffffffffffffffffffffffffffffffffffffffff33ff3cffffffffffffffffffccccccfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa0c0000
-- 090:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9afffffffffffffffffffffffffffffffffffffff3333333cffffffffffffffffffcffcffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba00c000
-- 091:ffffffffffffffffffffffcccccfffffffffffffffffffffffffffffffffffffffff9ff9aff9ffffffffffffffffffffffffffffffffffff3333333cffffffffffffffffffc33cffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba000000
-- 092:fffffffffffffffffffffc56666cffffffffffffffffffffffffffffffffffffffff99ffaf99fffffffffffffffffffffffffffffffffffff33333cffffffffffffffffffc3443cfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa00c000
-- 093:ffffffffffffffffffffc5656666cfffffffffffffffffffffffffffffffffffffff999ba999ffffffffffffffffffffffffffffffffffffff333cffffffffffffffffffc344443cffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba0c0000
-- 094:ffffffffffffffffffffc5588886cfffffffffffffffffffffffffffffffffffffff9a9ba999affffffffffffffffffffffffffffffffffffff3cfffffffffffffffffffc333333cffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa00c000
-- 095:ffffffffffffffffffffc588888cffffffffffffffffffffffffffffffffffffffff9aabaa9aaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffccccccfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba000000
-- 096:ffffffffffffffffffffc5e8888cfffffffffffffffffffffffffffffffffffff9999aaaaaaaa99fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa000000
-- 097:fffffffffffffffffffceee8888ecfffffffffffffffffffffffffffffffffffff9999aabbaa99ffffff4fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa0c0000
-- 098:ffffffffffffffffffceeddeeedeecfffffffffffffffffffffffffffffffffffff99bbbb9a99ffffff323ffffffffffffffffffffffffffffffffffffffffffffbbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbfffffffaffffffffffffba000000
-- 099:ffffffffffffffffffc88ddeeed88c4ffffffffffffffffffffffffffffffffffffaaabba999aaafff24744ffffffffffffffffffffffffffffffffffffffffffafffbbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffafffbbfffbfaffffffbffffba0c0000
-- 100:ffffffffffffffffffc87ddeeed78cfffffbfffffffbfffffffbfffffffbffff9999aaaba99aaafffff323fffffffffffffffffffffffffffffbfffffffffffffaffffaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaffffafffffafffffafffffaa000000
-- 101:fffffffffffffffffffccddddddccffffffbfffffffbfffffffbfffffffbfffff9999aaa99aaa999ffff1ffffffffffffaaafffffffffffffffbfffffffffffffaffffaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaffffafffffafffffafffffba0c0000
-- 102:ffffffffffffffffffffcddccddcbffffbfbfbfffbfbfbfffbfbfbfffbfbfbffff999999a999999ffffabffffffffffffaaaabaffffffffffbfbfbfffffffffffafaffaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffafaffafffff9fffffafafffaa000000
-- 103:fffffffffffffffffffffccffccfaffffafafafffafafafffafafafffafafaffffffff99999999ffffffafffffffffffaaaaaaa9fffffffffafafafffffffffff9f9ff9ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9f9ff9fffff9fffff9fafffba000000
-- 104:abaababbabbbabbbaabbabbaabaababbabbbabbbaabbabbaabaababbabbbabbbaabbabbaabaababbabbbabbbaabbabbaabaababbabbbabbbaabbabbaabaababbabbbabbbaabbabbaabaababbaaababaaffffffffffffffffffffffffffffffffffffffffaaaaabababaababbabbbabbbaabbabba99000000
-- 105:aaabaaaaaaaaaaaaabbaabbaaaabaaaaaaaaaaaaabbaabbaaaabaaaaaaaaaaaaabbaabbaaaabaaaaaaaaaaaaabbaabbaaaabaaaaaaaaaaaaabbaabbaaaabaaaaaaaaaaaaabbaabbaaaabaaaababbabaaffffffffffffffffffffffffffffffffffffffffbaaaaaaaaaabaaaaaaaaaaaaabbaabba9a000000
-- 106:aaaaaaaa000000000000aaaaaaaaaaaa000000000000aaaaaaaaaaaa000000000000aaaaaaaaaaaa000000000000aaaaaaaaaaaa000000000000aaaaaaaaaaaa000000000000aaaaaaaaaaaabaaa0aaaffffffffffffffffffffffffffffffffffffffffaaa00000aaaaaaaa000000000000aaaa00000000
-- 107:000000000c0c0c000c000000000000000c0c0c000c000000000000000c0c0c000c000000000000000c0c0c000c000000000000000c0c0c000c000000000000000c0c0c000c00000000000000000000abffffffffffffffffffffffffffffffffffffffffaa000c00000000000c0c0c000c00000000000000
-- 108:00c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c000aaeee2eee2eee2eee2eee2eee2eee2eee2eee2eee2aa00c0c000c0c0c000c0c0c000c0c0c000000000
-- 109:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c00aaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeba0c000000000000000000000000000000000000
-- 110:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000aaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaa00c00000000000000000000000000000000000
-- 111:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aadedededededededededededededededededededeba00000000000000000000000000000000000000
-- 112:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000abbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaa00000000000000000000000000000000000000
-- 113:000000000000000000000000000000000c000c0000000000000000000000000000000000000000000c000c0000000000000000000000000000000000000000000c000c000000000000000000000c0aabdedededededededededededededededededededeaa0c000000000000000000000000000000000000
-- 114:000000000000000000000000000000000000c0c000000000000000000000000000000000000000000000c0c000000000000000000000000000000000000000000000c0c0000000000000000000c00aaaededededededededededededededededededededba00000000000000000000000000000000000000
-- 115:0000000000000000000000000000000000000c00000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000c000000000000000000000c0aabddd2dddeddd2dddeddd2dddeddd2dddeddd2dddeba0c000000000000000000000000000000000000
-- 116:00000000000000000000000000000000000000c00000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000c0000000000000000000c00aaaededededededededededededededededededededaa00000000000000000000000000000000000000
-- 117:000000000000000000000000000000000c00000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000c0000000000000000000000000c0aaad2dddd2dd2dddd2dd2dddd2dd2dddd2dd2dddd2dba0c000000000000000000000000000000000000
-- 118:0000000000000000000000000000000000c00000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000c00000000000000000000000c00aaaddddddedddddddedddddddedddddddedddddddedaa00000000000000000000000000000000000000
-- 119:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaddddddddddddddddddddddddddddddddddddddddba00000000000000000000000000000000000000
-- 120:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006666766656665666666666676566566666666667655500000000000000000000000000000000000000
-- 121:00000000000c0c00000000000c000c000000000000000000000c0c00000000000000000000000000000000000000000000000000000c0c000000000000000000000c0c000c0c00000c000c000000005666666666666666666666666666666666666666665600000000000000000c0c000000000000000000
-- 122:0000000000c0c0c0000000000000c0c0000000000000000000c0c0c000000000000500000000000000000000000000000000000000c0c0c0000000000000055000c0c0c0000000000000c0c0000000000566650005666500056665000566650005666500000000000000000000c0c0c00000000000000000
-- 123:000000000c000c000000000000000c0000000000000000000c000c000000000000000000000000000000000000000000000000000c000c0000000000000505500c000c000c00000000000c0000000000500000050000005550000055000000555000005500000000000000000c000c000000000000000000
-- 124:0000000000c0c0c000000000000000c0000000000000000000c0c0c000000000005500000000000000000000000000000000000000c0c0c0000000000000000000c0c0c0000000c0000000c0000000005000000000000005500000550000000550000055000000000000000000c0c0c00000000000000000
-- 125:000000000c0c0c00000000000c00000000000000000000000c0c0c000000000000550050000000000000000000000000000000000c0c0c0000000000000000000c0c0c0000000c000c00000000000000000000000000000000000000000000000000000000000000000000000c0c0c000000000000000000
-- 126:0000000000c000c00000000000c00000000000000000000000c000c000000000000000000000000000000000000000000000000000c000c0000000000005000000c000c00000c0c000c00000000000000000000000000000000000000000000000000000000000000000000000c000c00000000000000000
-- 129:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c0000000000000000000c000c00000c0c000c0c00000c000c000c0c0000000c0c000c0c00000c000c000c000c0000000000000000000555000000000000
-- 130:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c0c000000000000000000000c0c000c0c0c0000000000000c0c00000000000c0c0c0000000000000c0c00000c0c000000000000000000555000000000000
-- 131:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000c00000000000000000000000c000c000c000c00000000000c000c0000000c000c000c00000000000c0000000c0000000000000000000565000000000000
-- 132:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c0c00000000000000000000000c000c0c0c0000000c0000000c0000000c000c0c0c0000000c0000000c0000000c000000000000000000000000000000000
-- 133:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c0c0000000000000000000c0000000c0c0c0000000c000c00000000000c000c0c0c0000000c000c0000000c00000000000000000000000000055000000000
-- 134:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000c0000000000000000000c0000000c000c00000c0c000c000000000c0c000c000c00000c0c000c0000000c0000000000000000000000000055000000000
-- </SCREEN2>

-- <PALETTE>
-- 000:0000009d9d9dffffffbe2633e06f8b493c2ba46422eb8931f7e26b2f484e44891aa3ce271b263200578431a2f2b2dcef
-- </PALETTE>

-- <PALETTE1>
-- 000:0000009d9d9dffffffbe2633e06f8b493c2ba46422eb8931f7e26b2f484e44891aa3ce271b263200578431a2f2b2dcef
-- </PALETTE1>

-- <PALETTE2>
-- 000:0000009d9d9dffffffbe2633e06f8b493c2ba46422eb8931f7e26b2f484e44891aa3ce271b263200578431a2f2b2dcef
-- </PALETTE2>

