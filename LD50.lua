-- title:  Hex'd
-- author: Blind Seer Studios
-- desc:   LD50 - Delay the inevitable - Try to stave off the curse by finding a cure
-- script: lua
-- input:  gamepad

flr=math.floor
rnd=math.random

--Variables for the screen area
w,h=240,136
hw,hh=w/2,h/2

releaseBuild=true
indicatorsOn=false
--Setup camera coordinates
cam={
	x=0,
	y=0,
	--Think these are depricated...not sure so leaving
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
	idx=256,
	x=16,
	y=88,
	vx=0,
	vy=0,
	vmax=1,
	flp=0,
	grounded=true,
	maxLife=3,
	curLife=3,
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
notDead=true
cTime=0
atEnd=false
lvl=0
mapStart=0
mapEnd=472
mapY=0
mapEndY=136
meterY=16
meterC=11
pt=0

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
	if lvl==3 and notDead then
		if row>wavelimit then
			poke(0x3ff9,math.sin((time()/200+row/3))*3) --200 5 2
		else
			poke(0x3ff9,0)
		end
	end
end
--Draw the HUD and Debug to the OVR
function OVR()
	if TIC==Update then
		HUD()
		Debug()
	end
	if lvl==3 and p.curLife==0 then
		AddWin(w/2,h/2-30,68,24,2,"Out of hearts!\nPress A to\nreturn to title.")
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

	rect(1,1,65,14,2)
	rectb(1,1,65,14,0)
	--Timer
	rect(0,135,p.hTime,2,meterC)

	--rect(x y w h color)
	spr(498,32,4,13)
	print(p.hTime,43,6,meterC)

	if p.curLife==0 then
		
	elseif p.hTime<50 then
		meterC=3
	elseif p.hTime<100 then
		meterC=7
	elseif p.hTime<200 then
		meterC=8
	else
		meterC=10
	end
	
 --xprint(txt,x,y,col,fixed,scale,smallfont,align,thin,blink)
 if--[[(time()%500>250) and]] p.hTime<=100 and p.curLife>0 then
 	xprint("WARNING!",120,5,{0,3},false,1,false,0,false,0.5)
  --print('Warning!',18,18,3)
	end
	--Hearts
	for num=1,p.maxLife do
		spr(497,-6+9*num,4,0)
	end
	
	for num=1,p.curLife do
		spr(496,-6+9*num,4,0)
	end
end

function Init()
	bads={}
	AddEnt()
	if releaseBuild then
		sync(0,7,false)
		TIC=Title
	else
		TIC=Update
	end
end

menu=false

function Title()
	t=t+1
	cls(2)
	--music(0)
	if timer<=100 then
		map()
		timer=timer+1
	elseif timer>=100 then
		spr(256,w/2-64,h/2-64,2,1,0,0,16,16)
		print("Ludem Dare 50",1,1,1)
		if not menu then
			xprint("Press Z to Start",75,122,{0,3},false,1,false,2,false,1)
		end
		if btnp(c.z) and not menu then
			menu=true
		end
	end
	
	if menu then
		AddWin(w/2,h/2,64,24,2,"  New Game\n  Help\n  Exit")
		xprint("Press A to select",75,82,{2,0},false,1,false,2,false)
		tri(92,58+pt,92,64+pt,95,61+pt,0)
	
		if btnp(c.d) and pt~=12 then
			pt=pt+6
		elseif pt==12 then
			pt=12
		end
		
		if btnp(c.u) and pt~=0 then
			pt=pt-6
		elseif pt==0 then
			pt=0
		end
		
		if btnp(c.a) and pt==0 then
			sync(0,0,false)
			music(0)
			TIC=Update
		elseif btnp(c.a) and pt==6 then
			TIC=Help
		elseif btnp(c.a) and pt==12 then
			exit()
		end
	end
end

function Help()
	sync(0,6,false)
	map()
	rectb(54,7,131,126,0)
	print("A to go back")
	if btnp(c.a) then
		sync(0,7,false)
		TIC=Title
	end
end
--[[Game Over function that sets certain parameters for when
the player dies]]
function GameOver()
	AddWin(w/2,h/2-30,68,24,2,"Out of hearts!\nPress A to\nreturn to title.")	
	--Remove the enemies
	p.idx=328
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
			sfx(16)
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

	if p.hTime>=0 and not atEnd then
		p.hTime=flr(p.hTime-1/1000)
		--meterY=meterY-20
	end
	
	if p.hTime<=0 and not atEnd then
		p.human=false
		p.idx=320+t%40//10*2
		p.sTime=flr(p.sTime-1/1000)
	end
	
	if p.sTime<=0 then
		p.sTime=0
		p.curLife=p.curLife-1
		Dead()
		notDead=false
	end
	Pit()
end

function Dead()
	if p.curLife==0 then
		GameOver()
	elseif not notDead then
		p.canMove=false
		p.idx=328
		AddWin(w/2,h/2-30,64,24,2,"Out of time!\nPress A to\ncontinue.")
		if btnp(c.a) then
			p.x=p.cpX
			p.y=p.cpY
			p.canMove=true
			notDead=true
			p.human=true
			if lvl==3 then
				sync(0,2,false)
			else
				sync(0,0,false)
			end
			if p.cpA then
				p.hTime=cTime
				p.sTime=500
			else
				p.hTime=500
				p.sTime=500
			end
		end
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
		sfx(19)
	end
end

function LevelEnd()
	if fget(mget(p.x//8+1,p.y//8+1),2) then
		atEnd=true
		p.vx=0
		p.canMove=false
		--print("Level End",0,8,3)
		AddWin(w/2,h/2-30,64,24,2,"Press Z to\ncontinue to\nnext level.")
		if btnp(c.z) then
			lvl=lvl+1
			NextLevel()
			--next level code
		end
		--spr(498,p.x-cam.x+4,p.y-cam.y-8+math.sin(time()//90),0)		
	end
	if fget(mget(p.x//8+1,p.y//8+1),7) then
		atEnd=true
		p.vx=0
		p.canMove=false
		AddWin(w/2,h/2-30,100,64,2,"It appears it was all\nfor naught, and you'll\njust be another corpse\nfor the pile.\n\nThank you for playing.\n\nPress A to return.")
		if btnp(c.a) then
			reset()
		end
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
			sfx(18)
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
	if mget(p.x/8+1,p.y/8+1)==s.pot or mget(p.x/8,p.y/8)==s.pot	then
	 mset(p.x/8+1,p.y/8+1,0)
		mset(p.x/8,p.y/8,0)
		sfx(17)
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
		sfx(21)
	end
	
	if (mget(p.x/8+1,p.y/8+1)==s.heart or mget(p.x/8,p.y/8)==s.heart) and p.curLife<3 then
	 mset(p.x/8+1,p.y/8+1,0)
	 mset(p.x/8,p.y/8,0)
		p.curLife=p.curLife+1
		sfx(20)
	end
end

--Run the init function
Init()

--Tool functions--

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
-- 006:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
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
-- 006:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
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
-- 069:fffffff9ffffff91fffffcc1fffffcc1ffff7c1cfff39911ffcfc99cffcccccf
-- 070:122fffff2222ffffcc22ffffcc22ffff1229ffff21937fff199937fffcfccc3f
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

-- <TILES6>
-- 000:ccccccccccccc000cccc00ccccc00c56ccc0c565ccc0c558ccc0c588ccc0c5e8
-- 001:cccccccc0000ccccccc00ccc666c00cc6666c0cc8886c0cc888c00cc888c0ccc
-- 002:ccccccccccccccccccccccccccccccccccccccccccccccccccc222c2cccc2cc2
-- 003:cccccccccccccccccccccccccccccccccccccccccccccccccccc2ccc2ccccccc
-- 004:cccccccccccccccccccccccccccccccccccccccccccccccccccccccc22cccccc
-- 005:cccccccccccccccccccccccccccccccccccccccccccccccc2ccccccccccc22cc
-- 006:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2c2cc
-- 007:cccccccccccccccccccccccccccccccccccccccccccccccccccccccc2cc2c2cc
-- 008:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 009:ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0
-- 010:cccccccccc000000c0222222c0222222c0222222c0222220c0222200c0222200
-- 011:cccccccc000000cc2222220c2222220c0022220c0022220c0022220c0022220c
-- 012:cccccccccc000000c0222222c0222222c0222200c0222200c0222200c0222200
-- 013:cccccccc000000cc2222220c2222220c2222220c0222220c0022220c0022220c
-- 014:cccccccccc000000c0222222c0222222c0222000c0222220c0222200c0222000
-- 015:cccccccc000000cc2222220c2222220c0022220c0222220c2222220c0022220c
-- 016:cc00cee8c00ceddec0ceeddec0c88ddec0c87dddc00ccddccc00cddcccc00cc0
-- 017:888c00cceedec00ceedeec0ceed88c0cddd78c0ccddcc00ccddc00cc0cc00ccc
-- 018:cccc2cc2cccc2cc2cccc2cc2cccccccccccccccccccccccccccccccccccccccc
-- 019:c2cc2cc2c2cc2cccc2cc2cc2cccccccccccccccccccccccccccccccccccccccc
-- 020:2cccccccc2cccccc2ccccccccccccccccccccccccccccccccccccccccccccccc
-- 021:2cc22ccc2cccc2cc2cc22ccccccccccccccccccccccccccccccccccccccccccc
-- 022:ccc2c2c2cccc22c2ccccc2cccccc2ccccccccccccccccccccccccccccccccccc
-- 023:c2c2c2ccc2c2c2cc2ccc22cccccccccccccccccccccccccccccccccccccccccc
-- 024:cccccccccccccccc2ccccccccccccccccccccccccccccccccccccccccccccccc
-- 025:ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0
-- 026:c0222220c0222222c0222222c0022222c0000000c0000000cc000000cccccccc
-- 027:0022220c0022220c2222220c2222200c0000000c0000000c000000cccccccccc
-- 028:c0222200c0222200c0222222c0022222c0000000c0000000cc000000cccccccc
-- 029:0222220c2222220c2222220c2222200c0000000c0000000c000000cccccccccc
-- 030:c0222222c0222222c0222222c0022222c0000000c0000000cc000000cccccccc
-- 031:2222220c2222220c2222220c2222200c0000000c0000000c000000cccccccccc
-- 032:cccc0000ccccccccccccccccccc00000cc00ccccc00c8888c0c8888800c888bb
-- 033:0000cccccccccccccccccccc00000ccccccc00cc8888c00cbbbbbc0cbbbbbc00
-- 034:ccccccccccccccccccccccccccccccccccccccccccc222c2cccc2cc2cccc2cc2
-- 035:cccccccccccccccccccccccccccccccccccccccccccc2ccc2cccccccc2cc2cc2
-- 036:cccccccccccccccccccccccccccccccccccccccccccccccc22cccccc2ccccccc
-- 037:cccccccccccccccccccccccccccccccccccccccc2ccccccccccc22cc2cc22ccc
-- 038:ccccccccccccccccccccccccccccccccccccccccccccccccccc2c2ccccc2c2c2
-- 039:cccccccccccccccccccccccccccccccccccccccccccccccc2cc2c2ccc2c2c2cc
-- 040:ccccccccccccccccccccccccccccccccccccccccccccccccccc22ccccccc22c2
-- 041:ccccccc0cccccccccccccccccccccccccccccccccccccccc22ccccc22ccccccc
-- 042:00000000cccccccccccccccccccccccccccccccccccccccc2ccccccc22ccccc2
-- 043:00000000ccccccccccccccccccccccccccccccccccc22ccc22cc2ccc2ccc2ccc
-- 044:00000000cccccccccccccccccccccccccccccccc2cccccccccc222cc2cc222c2
-- 045:00000000ccccccc0ccccccc0ccccccc0ccccccc0ccccccc022ccccc0c2ccccc0
-- 046:cc000000c0222222c0222222c0222222c0222000c0222000c0222200c0222220
-- 047:000000cc2222220c2222220c2222220c0002220c0002220c0022220c0222220c
-- 048:0cbb888b0cbbb8ab0bbbaaca0baaaaaa0baaaaaa0aaaaaaa0caaaaaa00ccccac
-- 049:88bbbbc0b8abbbc0aacabbbcaaaaacbcaaaaacbcaaaaccc0aacccc00cccc000c
-- 050:cccc2cc20ccc2cc20ccccccc0ccccccc0ccccccc0ccccccccccccccccccccccc
-- 051:c2cc2cccc2cc2cc2cccccccccccccccccccccccccccccccccccccccccccccccc
-- 052:c2cccccc2ccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 053:2cccc2cc2cc22ccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 054:cccc22c2ccccc2cccccc2ccccccccccccccccccccccccccccccccccccccccccc
-- 055:c2c2c2cc2ccc22cccccccccccccccccccccccccccccccccccccccccccccccccc
-- 056:ccc2c2ccccc222c2cccccccccccccccccccccccccccccccccccccccccccccccc
-- 057:c2ccccc22cccccc2cccccccccccccccccccccccccccccccccccccccccccccccc
-- 058:c2cccccc22ccccc2cccccccccccccccccccccccccccccccccccccccccccccccc
-- 059:c2cc2ccc2cc222cccccccccccccccccccccccccccccccccccccccccccccccccc
-- 060:2cc2c2c22cc2c2cccccccccccccccccccccccccccccccccccccccccccccccccc
-- 061:2cccccc022cc2cc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0
-- 062:c0222222c0222222c0022222c0000000c0000000cc000000cccccccc00000000
-- 063:2222220c2222220c2222200c0000000c0000000c000000cccccccccc00000000
-- 064:c0000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 065:00000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 066:ccccccccccccccccccccccccccccccccccccccccccc222ccccc2ccc2ccc22ccc
-- 067:cccccccccccccccccccccccccccccccccccccccccccc2cccc2c222cc2ccc2cc2
-- 068:cccccccccccccccccccccccccccccccccccccccccccccccc22c22cccc2c2c2c2
-- 069:ccccccccccccccccccccccccccccccccccccccccc2cccccc22cc22ccc2c22ccc
-- 070:cccccccccccccccccccccccccccccccccccccccccccccccc2c2cc2cc2c2c2c2c
-- 071:cccccccccccccccccccccccccccccccccccccccccccccccc2c2c2c2c2c2c22cc
-- 072:ccccccccccccccccccccccccccccccccccccccccccccc2cccccc222cccccc2cc
-- 073:ccccccccccccccccccccccccccccccccccccccccc2cccccccccc222cc2cc222c
-- 074:ccccccccccccccccccccccccccccccccccccccccccccccccc22ccccc2c2ccccc
-- 075:cccccccccccccccccccccccccccccccccccccccc2ccccccc22ccc22c2c2c2c2c
-- 076:cccccccccccccccccccccccccccccccccccccccccc2cccccc2ccc2cc222c2c2c
-- 077:cccccccccccccccccccccccccccccccccccccccccccccccc2c2cc22c22cc2c2c
-- 078:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 079:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 080:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 081:ccccccccc000000ccc0cc0cccc0770ccc078870c0788887007777770c000000c
-- 082:ccc2ccc2ccc222c2cccccccccccc2cc2ccc222c2cccc2cc2cccc2cc2ccccc2c2
-- 083:c2cc2cc2c2ccc2cccccccccccccccccc2ccc22ccc2c2c2ccc2c22cccc2cc22cc
-- 084:2cc2c2c222c2c2ccccccccccccc2ccccccc22cccccc2c2c2ccc2c2c2ccc2c2cc
-- 085:c2ccc2cc22c22ccccccccccccccccccc22c2c2ccc2cc2ccc2cc2c2cc22c2c2cc
-- 086:c22c2c2ccc2cc2ccccccccccc2cccccc222c2c2cc2cc2c2cc2cc2c2ccc2cc22c
-- 087:2c2c2cccc22c2ccccccccccccccccccc2c2c22cc22cc2c2c2ccc2c2c2ccc2c2c
-- 088:ccccc2cccccccc2cccccccccccccccccc22ccccc22cccccccc2ccccc22cccccc
-- 089:c2cc2c2cc2cc2c2ccccccc2ccccccccc2c2cc2cc2c2c2c2cc22c2c2ccc2cc2cc
-- 090:22ccccccc22ccccccccccccccccccccc2c2ccccc2c2ccccc2c2cccccc22ccccc
-- 091:2c2c22cc22ccc22cccccccccc2cccccccccc22ccc2cc2c2cc2cc2c2cc2cc2c2c
-- 092:c2cc2c2cc2ccc2ccccccccccc2cccccc222cc2ccc2cc2c2cc2cc2c2ccc2cc2cc
-- 093:2ccc22cc2cccc22ccccccccccccccccccccc22ccccccc22ccccc2c2ccccc222c
-- 094:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 095:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 096:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 097:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 098:ccccccccccccccccccccc22ccccc22cccccccc2ccccc22cccccccccccccccccc
-- 099:cccccccc22ccc2ccc2ccccccc2ccc2ccc2ccc2cc222cc2cccccccccccccccccc
-- 100:cccccccccccccccc222cc22c222c2c2c2c2c22cc2c2cc22ccccccccccccccccc
-- 101:ccccccccccccccccccccccccccccccccccccccccc2cccccccccccccccccccccc
-- 102:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 103:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 104:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 105:c2cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 106:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 107:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 108:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 109:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 110:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 111:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 112:cc12cccccc12cccccc12cccccc12cccccc12cccccc12cccccc00ccccc0000ccc
-- 113:cc100ccccc10200ccc102220cc102200cc1000cccc10cccccc00ccccc0000ccc
-- 114:ccccccccccccccccccccccccccccc22ccccc2ccccccc2ccccccc2cccccccc22c
-- 115:cccccccccccccccccccccccc2ccccccc22ccc22c2c2c2c2c2c2c22cc2c2cc22c
-- 116:cccccccccccccccccccccccccccc2cccc22c2c2c2ccc22cc2ccc22ccc22c2c2c
-- 117:cccccccccccccccccccccccccccccccc22ccc2cc2c2c2c2c2c2c2c2c22ccc2cc
-- 118:ccccccccccccccccccccccccc2cccccccccc22ccc2cc2c2cc2cc2c2cc2cc2c2c
-- 119:ccccccccccccccccccccccccc2cccccc222cccccc2ccccccc2cccccccc2ccccc
-- 120:cccccccccccccccccccccccccccc2ccc2c2c22cc2c2c2c2c222c2c2c222c2c2c
-- 121:ccccccccccccccccccccccccccccccccc22c2c2c2c2c22cc22cc2cccc22c2ccc
-- 122:ccccccccccccccccccccccccccccccccc22ccccc2c2ccccc22ccccccc22ccccc
-- 123:cccccccccccccccccccccccccccccccc2c2cc2cc2c2c2c2cc22c2c2ccc2cc2cc
-- 124:cccccccccccccccccccccccccccccccc2c2ccccc2c2ccccc2c2cccccc22ccccc
-- 125:ccccccccccccccccccccccccccccccccc22c22cc22cc2c2ccc2c2c2c22cc22cc
-- 126:cccccccccccccccccccccccccccccccc22cc2c2cc22c2c2c2c2c222c222c222c
-- 127:cccccccccccccccccccccccccccccccc22cccccc2c2ccccc2c2ccccc2c2ccccc
-- 128:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 129:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 130:cccccccccccccccccccc2ccccccccccccccc2cc2cccc2ccccccc2ccccccccccc
-- 131:ccccccccccccccccc2cccccc2cccccc222ccccc22ccccccc2ccccccccccccccc
-- 132:ccccccccccccccccccccccccc2cc2cc2c2c2c2c222c2c2c2c2cc2ccc2ccccccc
-- 133:2cccccccccccccccccccccccc2ccccccc2ccccc2c2ccccc222cccccccccccccc
-- 134:ccccccccccccccccc2cc2ccc22ccccccc2cc2cc2c2cc2cc222cc2ccccccccccc
-- 135:cccccccccccccccccccccccc22ccccccc2cccccc2ccccccc22cc2ccccccccccc
-- 136:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 137:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 138:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 139:c2cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 140:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 141:cccc2ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 142:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 143:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 144:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 145:ccccccccc000000ccc0cc0cccc0330ccc034430c0344443003333330c000000c
-- 146:ccccccccccccccccccc222cccccc2cc2cccc2cc2cccc2cc2cccc2ccccccccccc
-- 147:ccccccccccccccccccccccccc2c2c2c2c2c22cc2c2c2ccc222c2ccc2cccccccc
-- 148:cccccccccccccccccccccccc2ccc22ccc2c22cccc2ccc2ccc2c22ccccccccccc
-- 149:ccccccccccccccccccccccccccc2c2ccccc2c2c2cccc22c2ccccc2cccccc2ccc
-- 150:cccccccccccccccccccccccc2cc2c2ccc2c2c2ccc2c2c2cc2ccc22cccccccccc
-- 151:ccccccccccccccccccc2ccccccc22cc2ccc2c2ccccc2c2c2ccc22cc2cccccccc
-- 152:ccccccccccccccccccccccc22ccc22c222c2ccc2c2c2ccc222cc22c2cccccccc
-- 153:ccccccccccccccccccccccccc2ccccc22ccccccc2cccccccc2cccccccccccccc
-- 154:cccccccccccccccc2ccccccc22cc2ccc2cc2c2cc2cc2c2ccc2cc2ccccccccccc
-- 155:ccccccccccccccccccc2ccccccc22cc2ccc2c2c2ccc2c2c2ccc2c2cccccccccc
-- 156:ccccccccccccccccccccccccc2c222c2c2c222ccc2c2c2c222c2c2c2cccccccc
-- 157:cccccccccccccccccccccccc2cc22ccc22c2c2ccc2c2c2cc22c2c2cccccccccc
-- 158:cccccccccccccccccccccccccccccccccccccccccccccccc2ccccccccccccccc
-- 159:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 160:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 161:ccccccccccccccccccccccccccccccccccccccccc33cc30c3333333033333330
-- 162:cccccccccccccccccccccccccccccccccccccccccccc22ccccc2ccccccc2c2cc
-- 163:cccccccccccccccccccccccccccccccccccccccc2cccccccccc2c2cc2cc2c2c2
-- 164:cccccccccccccccccccccccccccccccccccccccccccccccc22cc22ccc2c22ccc
-- 165:ccccccccccccccccccccccccccccccccccccccccccccccccccc22cc2cccc22c2
-- 166:cccccccccccccccccccccccccccccccccccccccccccccccc2ccc2cc2c2c2c2cc
-- 167:cccccccccccccccccccccccccccccccccccccccc2cc2cccc22c22ccc2cc2c2c2
-- 168:cccccccccccccccccccccccccccccccccccccccccccccccc22c2c2ccc2c22ccc
-- 169:ccccccccccccccccccccccccccccccccccccccccccc22ccccccc2ccccccc2ccc
-- 170:cccccccccccccccccccccccccccccccccccccccc2cccc2cccccc2ccc2cc222c2
-- 171:cccccccccccccccccccccccccccccccccccccccccccccccc22ccccccc2cccccc
-- 172:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 173:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 174:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 175:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 176:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 177:c333330ccc3330ccccc30ccccccccccccccccccccccccccccccccccccccccccc
-- 178:ccc2c2cccccc22cccccccccccccccccccccccccccccccccccccccccccccccccc
-- 179:2cc2c2c22ccc2ccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 180:2cccc2cc22c22ccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 181:ccc2c2c2ccc222c2cccccccccccccccccccccccccccccccccccccccccccccccc
-- 182:c2c2c2ccc2cc2ccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 183:2cc2c2c2c2c2c2cccccccccccccccccccccccccccccccccccccccccccccccccc
-- 184:2cc2cccc22c2cccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 185:cccc2cccccc222cccccccccccccccccccccccccccccccccccccccccccccccccc
-- 186:2ccc2cc22ccc2ccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 187:2ccccccc22cc2ccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 188:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 189:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 190:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 191:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 192:ccccccccccccccccccccccc2cccccc2ccccccc2ccccccc2cccccccc2cccccccc
-- 193:cccccccccccccccc2cccccccccc2cccc2c2c2ccc2c2c2ccc2cc2cccccccccccc
-- 194:ccccccccccccccccccc2cccccc222cc2ccc2cc2cccc2cc2ccccc2cc2cccccccc
-- 195:ccccccccccccccccccccccc2cccccc222cccccc22cccccc2cccccccccccccccc
-- 196:cccccccccccccccccc2ccccc2c22ccc2cc2c2c2ccc2c2c222c2c2cc2cccccccc
-- 197:cccccccccccccccccccccc222cccccc22cccccc2ccccccc22cccccc2cccccccc
-- 198:cccccccccccccccc2cccccccccc22c22cc2c2c22cc22cc2cccc22c2ccccccccc
-- 199:cccccccccccccccccccccc222c22ccc22c2c2cc22c2c2cc22c22cc22cc2ccccc
-- 200:ccccccccccccccccccccccccccc22ccccc2c2ccccc22cccc2cc22ccccccccccc
-- 201:ccccccccccccccccccccccccccc2ccc2cc2c2c22cc2c2cc2ccc2ccc2cccccccc
-- 202:cccccccccccccccc2cccccc2cccccc2c2ccccc22cccccc2ccccccc2ccccccccc
-- 203:cccccccccccccccccccccccc2c2c2c222c22cc2c2c2ccc2c2c2ccc2ccccccccc
-- 204:ccccccccccccccccccccccccccc2cc2c2c2c2cc22c2c2c2c2cc2cc2ccccccccc
-- 205:cccccccccccccccccc2ccccc2c2c2ccccc22cccc2c22cccc2c2c2ccccccccccc
-- 206:ccccccccccccccccccc2cccccc222cc2ccc2cc2cccc2cc2ccccc2cc2cccccccc
-- 207:cccccccccccccccccccccccccccccccc2ccccccc2ccccccccccccccccccccccc
-- 208:ccccccccccccccc2cccccc22ccccccc2ccccccc2cccccccccccccccccccccccc
-- 209:2cc2cccccccccc222cc2cc2cccc2cc2cccc2cc2ccccccccccccccccccccccccc
-- 210:cccc2cccccc22ccc2c2c2ccc2c2c2ccc2cc22ccccccccccccccccccccccccccc
-- 211:cccccccccc22ccccccc22ccccc2c2ccccc222ccccccccccccccccccccccccccc
-- 212:ccccccccccc22c2ccc2ccc2ccc2ccc2cccc22cc2cccccccccccccccccccccccc
-- 213:cccccccc2c2c2cc22c22cc2c2c2ccc222c2cccc2cccccccccccccccccccccccc
-- 214:ccccc2cc2ccc2ccc2cc222c2cccc2cc22ccc2ccccccccccccccccccccccccccc
-- 215:cccccccc2cc2c2ccc2c22cccc2c2cccc2cc2cccccccccccccccccccccccccccc
-- 216:cccc2cc2ccc222c2cccc2cc2cccc2cc2ccccc2c2cccccccccccccccccccccccc
-- 217:cccccccc2ccc22ccc2c2c2ccc2c22cccc2cc22cccccccccccccccccccccccccc
-- 218:ccc2ccccccc22cccccc2c2c2ccc2c2c2ccc2c2cccccccccccccccccccccccccc
-- 219:cccccccc22c2c2ccc2cc2ccc2cc2c2cc22c2c2cccccccccccccccccccccccccc
-- 220:cccccccccccccccccccccccccccccccc2ccccccccccccccccccccccccccccccc
-- 221:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 222:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 223:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 224:cccccc2ccccccc2cccccccc2ccccccc2ccccccc2ccccccccccccccc2cccccc22
-- 225:2ccccccc2cc2cc2ccc2c2c2ccc2c2c2cccc2ccc2cccccccccccccccc2c2c2c2c
-- 226:cccccc2c2ccccc222ccccc2c2ccccc2c2ccccc2ccccccccccccccccc2c22cccc
-- 227:cccccccccc22cc2c2cc22c2c2c2c2c2c2c222cc2ccccccccccc2cccccccccc22
-- 228:cccccccc2cc22ccc2c2c2ccc2c22ccccccc22cccccccccccccc2cccccc222cc2
-- 229:cc2ccccccc22ccc2cc2c2c2ccc2c2c22cc22ccc2ccccccccccccccccccccc22c
-- 230:cccccccc2cc22c222c2c2c2ccc22cc2c2cc22c2ccccccccc22ccc2ccc2cccccc
-- 231:cccccc2ccccccc222ccccc2c2ccccc2c2ccccc2ccccccccccccccccc222cc22c
-- 232:ccccccccccc22c2c2c2c2cc22c22cc2c2cc22c2cccccccccccccc2cccccc222c
-- 233:cccccccc2cc22cc2cc2c2c2c2c22cc2c2cc22cc2cccccccc2ccccccc22ccc22c
-- 234:2ccccccc2ccccc222cccccc22ccccc2c2ccccc22cccccccccccccccc22cccccc
-- 235:cccccccccc22ccc22c2c2c2c2c2c2c2c2c2c2cc2cccccccccc2cc2ccc22ccccc
-- 236:2ccccccc2ccccc2c2ccccc2c2ccccc222ccccc22ccccccccccccccccc22ccccc
-- 237:ccc2cc222cccccc22cc2ccc22cc2ccc22cc2cc22cccccccccccccccccccccccc
-- 238:cc22ccccccc2ccccccc2ccccccc2cccc2c222ccccccccccccccccccccccccccc
-- 239:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 240:ccccccc2ccccccc2cccccccccccccccccccccccccccccccccccccccccccccccc
-- 241:cc2c2c22cc2c2c2c2cc22c2ccccccccccccccccccccccccccccccccccccccccc
-- 242:cc2c2ccccc2c2ccccc2c2ccccccccccccccccccccccccccccccccccccccccccc
-- 243:ccc2cc2cccc2cc2cccc2cc2ccccccccccccccccccccccccccccccccccccccccc
-- 244:2cc2cc2c2cc2cc2c2ccc2cc2cccccccccccccccccccccccccccccccccccccccc
-- 245:2ccc22cc2ccccc2ccccc22cccccccccccccccccccccccccccccccccccccccccc
-- 246:c2ccc2ccc2ccc2cc222cc2cccccccccccccccccccccccccccccccccccccccccc
-- 247:222c2c2c2c2c22cc2c2cc22ccccccccccccccccccccccccccccccccccccccccc
-- 248:ccccc2ccccccc2cccccccc2ccccccccccccccccccccccccccccccccccccccccc
-- 249:2c2c2c2c2c2c22cc2c2cc22ccccccccccccccccccccccccccccccccccccccccc
-- 250:2c2ccccc2c2ccccc2c2ccccccccccccccccccccccccccccccccccccccccccccc
-- 251:2c2cc2cc2c2cc2ccc22cc2cccccccccccccccccccccccccccccccccccccccccc
-- 252:2c2ccccc22ccccccc22cc2cccccccccccccccccccccccccccccccccccccccccc
-- 253:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 254:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 255:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- </TILES6>

-- <TILES7>
-- 000:9999999999999999999999999999999999999999999999999999999999999999
-- 001:222222222222222225ccccc225ccccc225ccccc225ccccc225ccccc225ccccc2
-- 002:222222222222222222cccf2222ccc52222ccc12222cc12222251222f221fc122
-- 003:22222222222222222ccc122c2ccc122c2ccc122c2ccc122ccccc122c2ccc122c
-- 004:2222222222222222cf22fcccccffccccccccccccc5f2fcc1c2221cf2cc221cc2
-- 005:2222222222222222cccccccccccccccccccccccc2fc122fc2222222122fcf222
-- 006:2222222222222222ccccccccccccccccccccccccccccf121ccc1221255222fcc
-- 007:2222222222222222122ccccc122ccccc122ccccc122ccccc222ccccc122ccccc
-- 008:2222222222222222cccc1222cccc2222cccc2222cccc2222cccc1222ccccccf1
-- 009:2222222222222222cccc52cccccccfcc1ccccccc21fccccc22221fcc2222221c
-- 010:2222222222222222cccccccccccccccccccccccccccf1221ccf22122522fcc52
-- 011:2222222222222222cccccccccccccccccccccccccccccf121ccc222125c222cc
-- 012:2222222222222222cccccccccccccccccccccccc2fcccc121225c122c221cc22
-- 013:2222222222222222cccccccccccccccccccccccc5c11cccc1122cccc22cccccc
-- 014:2299999922999999529999995299999952999999529999995299999952999999
-- 015:9999999999999999999999999999999999999999999999999999999999999999
-- 016:9999999999999999999999999999999999999999999999999999999999999999
-- 017:25ccccc225ccccc225ccccc225ccccc225cc222225cc222225cc222225cc2222
-- 018:22cccc2222ccccf222cccc5222cccc1222222222222222222222222222222222
-- 019:21cc122c22cc122c22cc122c22cc122c22222222222222222222222222222222
-- 020:cc221cc2cc221cc2cc221cc2cc221cc222222222222222222222222222222222
-- 021:22cc522222ccc22222ccc22222ccc2222222122222211222225ccccc25cccccc
-- 022:ff2225ccf1222cccf12225ccff222fcc222222221cf12222cccccc5ccccccccc
-- 023:122ccccc122ccccc122ccccc122ccccc22225ccc1221cccccccccccccccccccc
-- 024:cccccccccccccccccccc1ccccccc22ccccccf222ccccccf1cccccccccccccccc
-- 025:c122222ccccf222ccccc222ccccc221c2222222222222222ccccf222cccccc22
-- 026:1225cc2212212222122221fcf221cccc22222222222222222222222222222222
-- 027:2cc221ccccf22212cc5222215cc222cc22222222222222222222222222222222
-- 028:f225cc22225ccc221ccccc22cccfcc2222222222222222222222222222222222
-- 029:2fcccccc25cccccc2ccccccc2ccccccc222225cc222225cc222225cc222225cc
-- 030:5299999952999999529999995299999952999999529999995299999952999999
-- 031:9999999999999999999999999999999999999999999999999999999999999999
-- 032:9999999999999999999999999999999999999999999999999999999999999999
-- 033:25cc222225cc222225cc222225cc222225cc222225cc222225cc222225cc2222
-- 034:2222222222222222222222222222222222222222222222222222222222222222
-- 035:2222222222222222222222222222222222222222222222222222222222222222
-- 036:222222222222222c2222222c2222222c222222fc222222cc222225cc22221ccc
-- 037:5ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 038:cccccccccccccccccccccccccccccccccccccccccccccc88cf888888c8888888
-- 039:cccccccccccccccccccccccccccccccccf1f5ccc888881cc8888888c8888888c
-- 040:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 041:cccccc12cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 042:222222222222222212222222c2222222c1222222c5222222ccf22222ccc22222
-- 043:2222222222222222222222222222222222222222222222222222222222222222
-- 044:2222222222222222222222222222222222222222222222222222222222222222
-- 045:222225cc222225cc222225cc222225cc222225cc222225cc222225cc222225cc
-- 046:5299999952999999529999995299999952999999529999995299999952999999
-- 047:9999999999999999999999999999999999999999999999999999999999999999
-- 048:9999999999999999999999999999999999999999999999999999999999999999
-- 049:25cc222225cc222225cc222225cc222225cc222225cc222225cc222225cc2222
-- 050:22222222222222252222221c2222221c2222222c2222222c2222222122222222
-- 051:fc512222c21c222212211222125c8222c2222222c2222221cc5ff5cc2f5cccc5
-- 052:2222fccc2222cccc222ccccc228ccccc2fcccccccccccccccccccccc12222fcc
-- 053:ccccccccccccccccccccccccccccccccccccccccccccccc5ccccccc7cccccc58
-- 054:c8888888c8888888f888888818888888888888888888888888888888888881ce
-- 055:8888888c8888888c8888888888888888888888888888888888888888eeeeeccc
-- 056:cccccccccccccccccccccccc1ccccccc8fcccccc88fccccc8881ccccf1888fcc
-- 057:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 058:ccc22222ccc22222ccccf222cccccc22cccccccfcccccccccccccccccccccccc
-- 059:222222222222222222222222222222222222222212222222cf222222ccccccf2
-- 060:2222222222222222222222222222222222222222222222222222222222222222
-- 061:222225cc222225cc222225cc222225cc222225cc222225cc222225cc222225cc
-- 062:5299999952999999529999995299999952999999529999995299999952999999
-- 063:9999999999999999999999999999999999999999999999999999999999999999
-- 064:9999999999999999999999999999999999999999999999999999999999999999
-- 065:25cc222225cc222225cc222225cc222225cc222225cc222225cc222225cc2222
-- 066:2222222222222222222222222222222222222222222222222222222222222222
-- 067:2222222222222222222222222222222222222222222222222222222222222222
-- 068:222225cc22222ccc22221ccc2222fccc222fcccc222ccccc221ccccc21cccccc
-- 069:cccccc78cccccc88ccccc588cccccf81cccccccecccccceeccccceeecccceeee
-- 070:8888fcee887cccce8cccccce5ccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 071:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 072:eccf8885eeeecf88eeeeeccfeeeeeecceeeeeeeeeeeeeeeeeeeeeeeeeeeeeecc
-- 073:cccccccc1ccccccc8fccccccc885ccccecc588cceeeccf7ceeeeecccceeeeecc
-- 074:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 075:cccccccccccccccccccccccccccccccccccc1222cccc2222cccc2222cccc2222
-- 076:c2222222c1222222cc122222ccc222222ccc222221cc122222cc522222fcc222
-- 077:222225cc222225cc222225cc222225cc222225cc222225cc222225cc222225cc
-- 078:5299999952999999529999995299999952999999529999995299999952999999
-- 079:9999999999999999999999999999999999999999999999999999999999999999
-- 080:9999999999999999999999999999999999999999999999999999999999999999
-- 081:25cc222225cc222225cc222225cc222225cc222225cc222225cc222225cc2221
-- 082:22222222222222212222fccc222fcccc22fccccc2fcccccc5ccc1222ccffccc5
-- 083:22222222111111cccccccccccccccccccccccccccccccccc222225ccf22222cc
-- 084:fccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 085:cccceeeecccceeeecccceeeecccceeeecccceeeecccceeeeccccecccccccccce
-- 086:eeeeeeeeeeeeeeeeeeeeeeeeeeeccceeeccceeeecceeeeeeeeeeeeeceeeeeec1
-- 087:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeccceeeccf75ccc8888888888888888
-- 088:ecceeeeeeeeeeeeeeeeeeeeceeeeeeeceeeeeeeecceeeeee88fccccc8888ffff
-- 089:cccccccceecccccecccccccceeeeeecceeeeeecceeeeec5ccccc78fc711888fc
-- 090:cccccccccccccccceccccccceccccccceccccccceccccccccccccccccccccccc
-- 091:cccc2222cccc2222ccccc1f1ccccccc2cccc5122ccccf222ccccc122cccccc22
-- 092:222ccf22222fcc222221cc222221cc222222cc222222cc22222fcf22222fc122
-- 093:222225cc222225cc222225cc222225cc222225cc222225cc222225cc222225cc
-- 094:5299999952999999529999995299999952999999529999995299999952999999
-- 095:9999999999999999999999999999999999999999999999999999999999999999
-- 096:9999999999999999999999999999999999999999999999999999999999999999
-- 097:25cc222525cc222c25cc222c25cc222c25cc222c25cc222225cc222225cc2222
-- 098:cf1cf5ccc2cc222cc25f2221cf222222ccc1221ccccc55cc25cccccc22222222
-- 099:c22222ccc22222ccc12222ccc12222ccc12222ccc22222ccf22221cc22222ccc
-- 100:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 101:ccccceeeccccceeeccccceeecccccceecccccccccccccccccccccccccccccccc
-- 102:eeeeecf8eeeecf88eecf8888c888888818888888888888888888888818888888
-- 103:8888888888888888888888888888818f8881cc77f5881cc17cf881f888888888
-- 104:8888888888888888888888888888888888888888888888888888888888888888
-- 105:888888cc888888ce888888ce888881cc88888fec88888cec88881ccc8881ccce
-- 106:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 107:cccccc12ccccccf2ccccccc2cccccccfcccccccfcccccccfcccccccfccccccc1
-- 108:222cc222221c522222fc122221cf22222fc222222c5222222c1222222f222222
-- 109:222225cc222225cc222225cc222225cc222225cc222225cc222225cc222225cc
-- 110:5299999952999999529999995299999952999999529999995299999952999999
-- 111:9999999999999999999999999999999999999999999999999999999999999999
-- 112:9999999999999999999999999999999999999999999999999999999999999999
-- 113:25cc222225cc222225cc222225cc222225cc222225cc222225cc222225cc2222
-- 114:22222222222222222222222222222222222222222222222c22222fcc22225ccc
-- 115:22221ccc2221cccc222ccccc22ccccccfccccccccccc11cccc5222cccf221ccc
-- 116:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 117:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 118:f888888858888888c8888888c8888888c1888888c5888888cc188888ccf88888
-- 119:888888888888887888333cc383c333353833333788888888838888838353333c
-- 120:88888888888888888888888858888888353888888588888855888888c3888881
-- 121:8885cecc881ccecc885cceec81cceeec8cceeccc8ccecccc7ceecccccceececc
-- 122:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 123:ccccccc2ccccccf2cccccc22cccccf22ccccf222cccc2222cccc2222cccc2222
-- 124:2222222212222222f2222222f222222212252222212c12222ccf222222222222
-- 125:222225cc222225cc222225cc222225cc222225cc222225cc222225cc222225cc
-- 126:5299999952999999529999995299999952999999529999995299999952999999
-- 127:9999999999999999999999999999999999999999999999999999999999999999
-- 128:9999999999999999999999999999999999999999999999999999999999999999
-- 129:25cc222225cc222225cc222525cc222c25cc22fc25cc21cf25cc5cc225ccccc2
-- 130:222fcc511ccc2221ccc21fccc521cccff2fc512221cc22222ccf22251cc1225c
-- 131:221ccccc5ccccccccccccccc11cccccc2ccccccc2ccccccccccccccccccccccc
-- 132:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 133:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 134:ccc88888cccc7888ccccc188cccccc88cccccc88ccccccc1cccccccccccccccc
-- 135:8853cccc8888888888888888888888888888888888888888c5888888ccc88888
-- 136:3888888c88888fcc88881ccc8888cccc8888cccc888cccce85ccceeeccccceee
-- 137:ccecceccceccecccceccccccecceccccecceccccececcccceecccccccecccccc
-- 138:ccccccccccccccccccccccccccccccccccccccccccccccccccccccc575ccccc2
-- 139:ccc12222cc222222cf222222c2222222f2222222222222222222222222222222
-- 140:2222222222222222222222222222222222222222222222222222222222222222
-- 141:222225cc222225cc222225cc222225cc222225cc222225cc222225cc222225cc
-- 142:5299999952999999529999995299999952999999529999995299999952999999
-- 143:9999999999999999999999999999999999999999999999999999999999999999
-- 144:9999999999999999999999999999999999999999999999999999999999999999
-- 145:25ccccf225cccc1225cccc1225cccc5225ccccc225ccfcc525cccccc25cc222f
-- 146:1cc225cc1cc2cccc1cc1cccc1ccccccc1cccccccccccccccccccccfccccc85cc
-- 147:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 148:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc5ccccc
-- 149:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 150:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 151:ccccf88cccccccccccccccccccccccccccccccccccccccceccccccceccccceee
-- 152:cccceeeecccceeecccceeeeccceeeececeeeecceeeeecceeeeeecceceeecceec
-- 153:cecccccccccccccfecccccc8eccccc18cccccc88cccccc88cccccc88cccccc88
-- 154:8fccccf281cccc1288cccc1288fccc22887ccc22888ccc12888cccc28885cccc
-- 155:22222222222222222222222222222222222222222fcc2222252252222222c122
-- 156:2222222222222222222222222222222222222222222222222222222222222222
-- 157:222225cc222225cc222225cc222225cc222225cc222225cc222225cc222225cc
-- 158:5299999952999999529999995299999952999999529999995299999952999999
-- 159:9999999999999999999999999999999999999999999999999999999999999999
-- 160:9999999999999999999999999999999999999999999999999999999999999999
-- 161:25cc222225cc222125cc222f25cc222c25cc228825cc22f825cc225825cc2178
-- 162:5c58cccccf88cccc588815cc888888cc8888888c888888858888888588888885
-- 163:ccccccccccccccccccccccccccccccccccccccccccccccc1cccccc88ccccc188
-- 164:cc1fcccccc888fcccc88888cc5888887f8888888888888888888888888888888
-- 165:cccccccccccccccccccccccccccccccc81cccccc888ccccc88881ff588888888
-- 166:cccccccccccccccccccccccccccccccccccccceeccccceeecccceeee1ceeeeee
-- 167:cccceeeeccceeeeecceeeeeeceeeeeeeeeeeeeeceeeeeeeceeeeeecceeeeecce
-- 168:eeeceecceecceeccecccecccecceecccceeeccccceeecccceeeecccceeeccccc
-- 169:cccccc88cccccc88cccccc88cccccc88cccccc88cccccc88cccccc88cccccc88
-- 170:8881cccc8888fccc888885cc888888cc88888888888888888888888888888888
-- 171:2221c222fffc1222cccc2222cccf2222cccccccf7ccccf228fcccccc5ccccccc
-- 172:2f2222222f22222221222222122222222222222222222222ccccccc5ccccc5cc
-- 173:222225cc222225cc222225cc222225cc222225cc222225ccff1125cccccccccc
-- 174:5299999952999999529999995299999952999999529999995299999952999999
-- 175:9999999999999999999999999999999999999999999999999999999999999999
-- 176:9999999999999999999999999999999999999999999999999999999999999999
-- 177:25cc258825cc178825ccf88825ccc88825ccc18825cccc5f25cccccc25cccccc
-- 178:8888888c888888cc88888fcc88881ccc8888cccffffccc57cccccccccccccccc
-- 179:ccc58888cf888888c8888888f88888888888882277777122cccc122ccccc2225
-- 180:8888888888888888888cf888888c88812221f7fc222221cccccc22cccccc51cc
-- 181:8888888f8888ccee88fceeee5cceeeeeceeeeeeecccccccccc22cccccf22cccc
-- 182:ceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeceeeeeecccccccccccccccccccccccccc
-- 183:eeecccceeeccceeeeccceeeeccceeeeeeeceeeeecccccccecccccccccccccccc
-- 184:eeeccccceecccccceccccccceccccccce122cccc2222cc515222cc12c222cccf
-- 185:cccccc88cccccc17cccccccccccccccccccccccc2ccccccc2cccccccfccccccc
-- 186:8888888f777fcccccccccccccccccceeccceeeeecccccccccccccccccccccccc
-- 187:cccecccceeecccceeccccceecccccceecccecceecccccccccccccccccccccccc
-- 188:cccc1888ccc88888ccf88888cc888888c7888888c7777777cccccccccccccccc
-- 189:1ffccccc888885cc888885cc888885cc888885cc77777ccccccccccccccccccc
-- 190:5299999952999999529999995299999952999999529999995299999952999999
-- 191:9999999999999999999999999999999999999999999999999999999999999999
-- 192:9999999999999999999999999999999999999999999999999999999999999999
-- 193:25cccccc25cccccc25cccccc25cccccc25cccccc25cccccc25cccccc25cccccc
-- 194:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 195:cccc2222cccc2222ccccf222ccccccf2cccccccccccccccccccf2fcccccf22cc
-- 196:fccccccc221cccc222221cc12222222ccf12222cccc2222cccc1222cccc2221c
-- 197:5222cccc222221cf22221fc2f222ccc5f222ccc5f222ccc5f222ccc5f222cccc
-- 198:cccccccc12cccf2222fcc12222fccc2222fccc2222fccc2222fccc2222fccf22
-- 199:ccccccccfcccf122fcc12221fcc222ccfcc221ccfcf22fccfc5221ccfcc222cc
-- 200:c222cccc1222ccf12222cf225222ccf2c222ccf2c222ccf2c222ccf2f222ccf2
-- 201:cccccccc2ccccc2225ccc22225cf225c25c122cc25c122cc25c1225c25cf22fc
-- 202:cccccccc222cccccf122ccccccf22fc1ccc221cfccc221cccc522fccccf22ccf
-- 203:cccccccc12222fcc221f22cc2215cccc2222fccc2222225c5122221ccccf221c
-- 204:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 205:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 206:5299999952999999529999995299999952999999529999995299999952999999
-- 207:9999999999999999999999999999999999999999999999999999999999999999
-- 208:9999999999999999999999999999999999999999999999999999999999999999
-- 209:2222222222222222999999999999999999999999999999999999999999999999
-- 210:2222222222222222999999999999999999999999999999999999999999999999
-- 211:2222222222222222999999999999999999999999999999999999999999999999
-- 212:2222222222222222999999999999999999999999999999999999999999999999
-- 213:2222222222222222999999999999999999999999999999999999999999999999
-- 214:2222222222222222999999999999999999999999999999999999999999999999
-- 215:2222222222222222999999999999999999999999999999999999999999999999
-- 216:2222222222222222999999999999999999999999999999999999999999999999
-- 217:2222222222222222999999999999999999999999999999999999999999999999
-- 218:2222222222222222999999999999999999999999999999999999999999999999
-- 219:2222222222222222999999999999999999999999999999999999999999999999
-- 220:2222222222222222999999999999999999999999999999999999999999999999
-- 221:2222222222222222999999999999999999999999999999999999999999999999
-- 222:2299999922999999999999999999999999999999999999999999999999999999
-- 223:9999999999999999999999999999999999999999999999999999999999999999
-- 224:9999999999999999999999999999999999999999999999999999999999999999
-- 225:9999999999999999999999999999999999999999999999999999999999999999
-- 226:9999999999999999999999999999999999999999999999999999999999999999
-- 227:9999999999999999999999999999999999999999999999999999999999999999
-- 228:9999999999999999999999999999999999999999999999999999999999999999
-- 229:9999999999999999999999999999999999999999999999999999999999999999
-- 230:9999999999999999999999999999999999999999999999999999999999999999
-- 231:9999999999999999999999999999999999999999999999999999999999999999
-- 232:9999999999999999999999999999999999999999999999999999999999999999
-- 233:9999999999999999999999999999999999999999999999999999999999999999
-- 234:9999999999999999999999999999999999999999999999999999999999999999
-- 235:9999999999999999999999999999999999999999999999999999999999999999
-- 236:9999999999999999999999999999999999999999999999999999999999999999
-- 237:9999999999999999999999999999999999999999999999999999999999999999
-- 238:9999999999999999999999999999999999999999999999999999999999999999
-- 239:9999999999999999999999999999999999999999999999999999999999999999
-- 240:9999999999999999999999999999999999999999999999999999999999999999
-- 241:9999999999999999999999999999999999999999999999999999999999999999
-- 242:9999999999999999999999999999999999999999999999999999999999999999
-- 243:9999999999999999999999999999999999999999999999999999999999999999
-- 244:9999999999999999999999999999999999999999999999999999999999999999
-- 245:9999999999999999999999999999999999999999999999999999999999999999
-- 246:9999999999999999999999999999999999999999999999999999999999999999
-- 247:9999999999999999999999999999999999999999999999999999999999999999
-- 248:9999999999999999999999999999999999999999999999999999999999999999
-- 249:9999999999999999999999999999999999999999999999999999999999999999
-- 250:9999999999999999999999999999999999999999999999999999999999999999
-- 251:9999999999999999999999999999999999999999999999999999999999999999
-- 252:9999999999999999999999999999999999999999999999999999999999999999
-- 253:9999999999999999999999999999999999999999999999999999999999999999
-- 254:9999999999999999999999999999999999999999999999999999999999999999
-- 255:9999999999999999999999999999999999999999999999999999999999999999
-- </TILES7>

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
-- 242:dd8888ddd882288d88222087822202278220222787220277d772277ddd7777dd
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
-- 242:dd8888ddd882288d88222087822202278220222787220277d772277ddd7777dd
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
-- 242:dd8888ddd882288d88222087822202278220222787220277d772277ddd7777dd
-- </SPRITES2>

-- <SPRITES7>
-- 000:2222222222222222222222222222222222222222222222222222222222222222
-- 001:2222222222222222222222222222222222222222222222212222222222222222
-- 002:222222222222222222222222222222222f19c222c000c2220000922290001222
-- 003:2222222222222222222222222222222222222222222222222222222222222222
-- 004:2222222222222222222222222222222222222222222222222222222222222222
-- 005:2222222222222222222222222222222222222222222222222222222222222222
-- 006:2222222222222222222222222222222222222222222222222222222222222222
-- 007:2222222222222222222222222222222222222222222222222222222222222222
-- 008:2222222222222222222222222222222222222222222222222222222222222222
-- 009:2222222222222222222222222222222222222222222222222222222222222222
-- 010:2222222222222222222222222222222222222222222222222222222222222222
-- 011:2222222222222222222222222222222222222222222222222222222222222222
-- 012:2222222222222222222222222222222222222222222222222222222222222222
-- 013:2222222222222222222222222222222222222222222222222222222222222222
-- 014:2222222222222222222222222222222222222222222222222222222222222222
-- 015:2222222222222222222222222222222222222222222222222222222222222222
-- 016:2222222222222222222222222222222222222222222222222222222222222222
-- 017:2222222222222222222222222222222222222222222222222222222222222222
-- 018:100012221000f222100022221000222210002222100c222290092222900c2221
-- 019:2222222222222222222222222222222222222f22221c0005f500000000000000
-- 020:2222222222222222222222222222222222222222122222220122222f00f222f0
-- 021:222222222222222222222222222221912221c92221009222c0092222000f2222
-- 022:222222222222222222f11ff212f1500022222100222222102222222122222222
-- 023:222222222222222222f11111cf210000c222100012222100222222902222222c
-- 024:22222222222222221112222200f222220922222200f222220092222200012222
-- 025:22222222222222222222111122221000222220002222200122221012222f0122
-- 026:222222222222222f11f22f11012222f112222210222222102222221022222290
-- 027:2222222211199911119c000022222f19f2222222f2222222f2222ff2f2221c22
-- 028:22222222f2222222000911f2000000002f119c002222222f2222222222222222
-- 029:2222222222222222222222220591f2220000009f19000000222100002222fc00
-- 030:222222222222222222222222222222222222222212222222012222220c222222
-- 031:2222222222222222222222222222222222222222222222222222222222222222
-- 032:2222222222222222222222222222222222222222222222222222222222222222
-- 033:22222222222222222222222222222222222222222222222f2222222f22222221
-- 034:c0002290000015cf000009220000c2220000f2220009222200012222000f2222
-- 035:91f1c0002222210022222250222222f022222229222222212222222f22222222
-- 036:009222c000022900000ff000000f10000002500000c200000052000000920000
-- 037:0012222200222222001222220009222200000c110cc9111f92222222c2222222
-- 038:22222222222222222222222222222222f2222222222222222222222222222222
-- 039:2222222f22222222222222222222222222222222222222222222222222222222
-- 040:000c2222100092222900012222c000f222f0000c222100002222900022229000
-- 041:222c122222512222291222229922222292222222f22222225222222201222222
-- 042:222222902222229022222250222222c022222299222222222222222222222222
-- 043:f2210122f2100122f2500f22f20002222f0002222100022221000f222f000122
-- 044:2222222222222222222222222222222222222222222222222222222222222222
-- 045:22222f0022222290222222f0222222202222222c22222229222222252222222c
-- 046:00f2222200122222001222220012222200122222001222220012222200f22222
-- 047:2222222222222222222222222222222222222222222222222222222222222222
-- 048:2222222222222222222222222222222222222222222222222222222222222222
-- 049:222222212222222122222221222222292222222022222220222222f022222210
-- 050:0002222200522222009222220052222200022222000222220001222200092222
-- 051:2222222222222222222222222222222222222222222222222222222122222221
-- 052:00c200000002c000000290000002100000c2f0000012250000f2229009222229
-- 053:02222222012222220922222200122222000122220000f222000009f200000009
-- 054:22222222222222222222222222222f19221900001000000019c00c911f222222
-- 055:2222222222222222222222229c0000cf00000cf1cf90cf1022ccf10010cf1009
-- 056:22215f50221522fc21c2222f1cf100920f1000091fc000002900000020000000
-- 057:00122222000f22220005222210009222290001221f0000ffc21000c209200009
-- 058:2222222222222222222222222222222222222222f22222221922222221c12222
-- 059:2200092222c0002222900092222000012221000c222290002222f50022222290
-- 060:22222222222222222222222222222222f22222220922222200c122220000091f
-- 061:222222202222222022222210222222902222220922222112222222222ff22222
-- 062:00f222220c222222012222225222222222222222222222222222222222222222
-- 063:2222222222222222222222222222222222222222222222222222222222222222
-- 064:2222222222222222222222222222222222222222222222222222222222222222
-- 065:222222c022222f00222222222222222222222222222222222222222222222222
-- 066:0000f22200cc9222222222222222222222222222222222222222222222222222
-- 067:2222222c222222f02222229022222f09222229c222221c2222225f2222212222
-- 068:01222222c22222221222222222222222222222212222222c2222229022222f00
-- 069:f900000022f119992991ff2f9000000000000000000000000000000000000000
-- 070:000912f911f2f90cf11c00010000000000000000000000000000000000000000
-- 071:0521000c121ccccc222222220000000000000000000000000000000000000000
-- 072:29000000121900092222c00f0000000000000000000000000000000000000000
-- 073:01f00000f2999999222222220000000000000000000000000000000000000000
-- 074:921c922299f2f12222222f920000000900000000000000000000000000000000
-- 075:2222222122222222222222222222222212222222c22222220922222200f22222
-- 076:00000000219c0c91222222222222222222222222222222222222222222222222
-- 077:c122222222222222222222222222222222222222222222222222222222222222
-- 078:2222222222222222222222222222222222222222222222222222222222222222
-- 079:2222222222222222222222222222222222222222222222222222222222222222
-- 080:2222222222222222222222222222222222222222222222222222222222222222
-- 081:2222222222222222222210052221000022290000222c000022f0000022100000
-- 082:22222222222222221222222200c91f22000000f200000092000000020000000f
-- 083:2222222222222222222222222222222222222222222222222222222222222222
-- 084:2222290022222000222210002222500022220000222100002221000022290000
-- 091:0092222200022222000122220005222200002222000012220000122200009222
-- 092:2222222222222222222222222222222222222222222222222222222222222222
-- 093:22222222222222222222222122f19c002f0000002900000020000000f0000000
-- 094:22222222222222225001222200001222000092220000c22200000f2200000122
-- 095:2222222222222222222222222222222222222222222222222222222222222222
-- 096:222222222222222222222222222222f922222100222210002222000022210000
-- 097:229000002f000000fc0000000000000000000000000000000000000000000000
-- 098:0000000900000000000000000000000000000000000000000000000000000000
-- 099:22222222f2222222922222220f22222200f2222200c22222000c1222000009f2
-- 100:22290000222c00002220000022200000222c0000222500002229000022290000
-- 107:000092220000c22200000222000002220000c222000052220000922200009222
-- 108:222222222222222f22222229222222f022222f0022222c002221c0002f900000
-- 109:9000000000000000000000000000000000000000000000000000000000000000
-- 110:00000922000000f2000000cf0000000000000000000000000000000000000000
-- 111:2222222222222222222222229f22222200122222000122220000222200001222
-- 112:222f0000222200002222100022222100222222902222222c2222222f22222222
-- 113:000000000000000000000000000000000000000000000000000000001000005f
-- 114:00000000000000000000000000000000000000000000000055c000002222f1c0
-- 115:0000000c00000000000000000000000000000000000000000000000000000000
-- 116:1f2100000c2f000000f2c000001290000092100000c21000000f100000011000
-- 117:000000000000000000000000000009990009f22200c222220012222200222222
-- 118:00000000000000000000000090000000221500002222f900222222f922222222
-- 119:000000000000000000000000000000000000000000000000000000001c000000
-- 120:00000000000000000000000000000000000000000000000000000000000000c1
-- 121:000000000000000000000000000000c100009f22001f22229222222222222222
-- 122:000000000000000000000000111000002222900022222c0022222f0022222200
-- 123:000012f10000f2c0000c2f00000921000001290000012c000001f00000011000
-- 124:c000000000000000000000000000000000000000000000000000000000000000
-- 125:00000000000000000000000000000000000000000000000000000c550c1f2222
-- 126:00000000000000000000000000000000000000000000000000000000f5000001
-- 127:0000f22200002222000122220012222209222222c2222222f222222222222222
-- 128:2222222222222222222222222222222222222222222222222222222222222222
-- 129:219009222222f222222222222222222222222222222222222222222222222222
-- 130:2222222f22222222222222222222222222222222222222222222222222222222
-- 131:1500000022219000222222192222222222222222222222222222222222222222
-- 132:000910000009f000c00110002f12100022221000222210002222900022225000
-- 133:0c222222092222220922222209222222092222220c22222200122222000f2222
-- 134:222222222222222222222222222222222222222222222222222222222222221c
-- 135:22900000222000002221000022210000222c0000221000001c00000000000000
-- 136:000009220000022200001222000012220000c22200000122000000c100000000
-- 137:22222222222222222222222222222222222222222222222222222222c1222222
-- 138:222222c022222290222222902222229022222290222222002222210022221000
-- 139:000f9000000f90000001100c000121f200012222000122220009222200052222
-- 140:0000005100091222912222222222222222222222222222222222222222222222
-- 141:f222222222222222222222222222222222222222222222222222222222222222
-- 142:22900912222f2222222222222222222222222222222222222222222222222222
-- 143:2222222222222222222222222222222222222222222222222222222222222222
-- 144:2222222222222222222222222222222222222222222222222222222222222222
-- 145:2222222222222222222222222222222222222222222222222222222222222222
-- 146:2222222222222222222222222222222222222222222222222222222222222222
-- 147:2222222222222222222222222222222222222222222222222222222222222222
-- 148:2222c00022220000222f0000222100002221000022290000222c0000222c0000
-- 149:0000122200000c99000000000000000000000000000000000000000000000000
-- 150:2222f90095c00000000000000000000000000000000000000000000000000000
-- 151:0000005100000022000001220000c222000012220000222200092222000f2222
-- 152:10000000290000002f000000221000002220000022290000222f00002222c000
-- 153:0051f222000000c5000000000000000000000000000000000000000000000000
-- 154:222900009c000000000000000000000000000000000000000000000000000000
-- 155:000c2222000022220000f2220000122200001222000092220000c2220000c222
-- 156:2222222222222222222222222222222222222222222222222222222222222222
-- 157:2222222222222222222222222222222222222222222222222222222222222222
-- 158:2222222222222222222222222222222222222222222222222222222222222222
-- 159:2222222222222222222222222222222222222222222222222222222222222222
-- 160:2222222222222222222222222222222222222222222222222222222222222222
-- 161:2222222222222222222222222222222222222222222222222222222222222222
-- 162:2222222222222222222222222222222222222222222222222222222222222222
-- 163:2222222222222222222222222222222222222222222222222222222222222222
-- 164:22250000222100002222c00022222100222222102222222122219ccff1c0000c
-- 165:000000000000000000000000000000000000012200001222f112222212222222
-- 166:00000000000000000000000000000000f1500000222100002222c00022229000
-- 167:00022222000f2222000f2222000922190000c000000000000000000000000000
-- 168:2222900022229000222210001f22000000500000000000000000000000000000
-- 169:000000000000000000000000000000000000051f00001222000c222200012222
-- 170:0000000000000000000000000c00000022100000222100002222211222222221
-- 171:0000522200001222000c2222001222220122222212222222fcc91222c0000c1f
-- 172:2222222222222222222222222222222222222222222222222222222222222222
-- 173:2222222222222222222222222222222222222222222222222222222222222222
-- 174:2222222222222222222222222222222222222222222222222222222222222222
-- 175:2222222222222222222222222222222222222222222222222222222222222222
-- 176:222222222222222222222222222222222222222122222210222222c022222900
-- 177:22222222222222222f500c221000009200000001000000000000000000000000
-- 178:2222222222222222222222222222221511119000000000000000000000000000
-- 179:2222221522219000f1c000000000000000000000000000000000000000000000
-- 180:000000000000000000000000000000000000000000000000000000c100000922
-- 181:00f2222200f2222200f2222200f2222200f222225f2222222222222222222222
-- 182:222210002222f0002211f0002200c0002200000022500c9c2210012922100129
-- 183:00000000000000000000000000000000000000000059000900f2c00200f2c002
-- 184:0000000000000000000000000000000000000000c00c9c001009290010092900
-- 185:00012222000f2222000f11220000002200000022590009221f00c2221f00c222
-- 186:22222f0022222f0022222f0022222f0022222f00222222f52222222222222222
-- 187:0000000000000000000000000000000000000000000000001000000022900000
-- 188:512222220009122200000c1f0000000000000000000000000000000000000000
-- 189:2222222222222222222222225122222200091111000000000000000000000000
-- 190:222222222222222222c005f22900000110000000000000000000000000000000
-- 191:2222222222222222222222222222222212222222012222220022222200922222
-- 192:22221000222290002222000022220000222290002222f00022222fc022222229
-- 195:0000000000000000000000000000009f0000c1220001222200f22222cf222222
-- 196:0005f2220c122222122222222222222222222222222222222222222222222222
-- 197:2222222222222222222222222222222222222222222222222222222222222222
-- 198:2210012922100129222222292222222222222222222222222222222222222222
-- 199:00f2c00200f2c00200f2c0022222111222222222222222222222222222222222
-- 200:100929001009290010092900f11f222222222222222222222222222222222222
-- 201:1f00c2221f00c222f21112222222222222222222222222222222222222222222
-- 202:2222222222222222222222222222222222222222222222222222222222222222
-- 203:222f5000222221c0222222212222222222222222222222222222222222222222
-- 204:000000000000000000000000f9000000221c00002222100022222f00222222fc
-- 207:0001222200092222000022220000222200092222000f22220cf2222292222222
-- 208:2222222222222222222222222222222222222222222222222222222222222222
-- 209:fc00000022c00000221000002210000022200000222c00002229000022210000
-- 210:000000000000000c000000090000000f0000000200000052000000120000c122
-- 211:f222222222222222222222222222222222222222222222222222222222222222
-- 212:2222222222222222222222222222222222222222222222222222222222222222
-- 213:2222222222222222222222222222222222222222222222222222222222222222
-- 214:2222222222222222222222222222222222222222222222222222222222222222
-- 215:2222222222222222222222222222222222222222222222222222222222222222
-- 216:2222222222222222222222222222222222222222222222222222222222222222
-- 217:2222222222222222222222222222222222222222222222222222222222222222
-- 218:2222222222222222222222222222222222222222222222222222222222222222
-- 219:2222222222222222222222222222222222222222222222222222222222222222
-- 220:2222222f22222222222222222222222222222222222222222222222222222222
-- 221:00000000c00000009000000010000000200000002c00000021000000221c0000
-- 222:000000cf00000c220000012200000122000002220000c2220000922200001222
-- 223:2222222222222222222222222222222222222222222222222222222222222222
-- 224:2222222222222222222222222222222222222222222222222222222222222222
-- 225:2222900c22222ff2222222222222222222222222222222222222222222222222
-- 226:11ff222222222222222222222222222222222222222222222222222222222222
-- 227:2222222222222222222222222222222222222222222222222222222222222222
-- 228:2222222222222222222222222222222222222222222222222222222222222222
-- 229:2222222222222222222222222222222222222222222222222222222222222222
-- 230:2222222222222222222222222222222222222222222222222222222222222222
-- 231:2222222222222222222222222222222222222222222222222222222222222222
-- 232:2222222222222222222222222222222222222222222222222222222222222222
-- 233:2222222222222222222222222222222222222222222222222222222222222222
-- 234:2222222222222222222222222222222222222222222222222222222222222222
-- 235:2222222222222222222222222222222222222222222222222222222222222222
-- 236:2222222222222222222222222222222222222222222222222222222222222222
-- 237:2222ff1122222222222222222222222222222222222222222222222222222222
-- 238:c00922222ff22222222222222222222222222222222222222222222222222222
-- 239:2222222222222222222222222222222222222222222222222222222222222222
-- 240:2222222222222222222222222222222222222222222222222222222222222222
-- 241:2222222222222222222222222222222222222222222222222222222222222222
-- 242:2222222222222222222222222222222222222222222222222222222222222222
-- 243:2222222222222222222222222222222222222222222222222222222222222222
-- 244:2222222222222222222222222222222222222222222222222222222222222222
-- 245:2222222222222222222222222222222222222222222222222222222222222222
-- 246:2222222222222222222222222222222222222222222222222222222222222222
-- 247:2222222222222222222222222222222222222222222222222222222222222222
-- 248:2222222222222222222222222222222222222222222222222222222222222222
-- 249:2222222222222222222222222222222222222222222222222222222222222222
-- 250:2222222222222222222222222222222222222222222222222222222222222222
-- 251:2222222222222222222222222222222222222222222222222222222222222222
-- 252:2222222222222222222222222222222222222222222222222222222222222222
-- 253:2222222222222222222222222222222222222222222222222222222222222222
-- 254:2222222222222222222222222222222222222222222222222222222222222222
-- 255:2222222222222222222222222222222222222222222222222222222222222222
-- </SPRITES7>

-- <MAP>
-- 001:0000000000000000000000000000c1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0b0c000000000000000000000000000000000000000000000000000000000000000a0b0c0000000a0b0c000d0e0f0000000000000a0b0c000000000000000d0e0f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:00000000000000000000000000000000000000000000c100000000000000000000000000a0b0c000a1000000000000000000a1000000000000000000000000000000000000000000a1b1c10000a0b0c0000000a1b1c10000000000000000a0b0c00000000000000000000000a0b0c00000000000a0b0c00000000000a1b1c100000000000000d1e1f1000000000000a1b1c100000000000000d1e1f1000000000000a0b0c00000000000000000a0b0c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:000000000000000000d0d1e00000000000e2d0e0f000000000000000000000000000000000a1a0b0c0000000000000000000b1c10000a100000000000000000000a0b0c0a0b0c0000000000000a1a0b0c0000000000000a2b2c200000000a1b1c10000000000a0b0c0000000a1b1c10000000000000000000000000000000000000000000000d2e2f200a0b0c0000000000000000000000000d2e2f2000000000000a1b1c10000000000000000a1b1c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:000000000000000000d1e1f10000000000c1d1a0b0c0000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000a1b1c100000000000000000000000000000000000000a3b3c3000000000000000000a0b0c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:000000000000000000000000000000000000d2a0b0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0b0c0000000000000000000000000000000a4b4c40000000000000000000000000000000000000000000000a0b0c0000000000000000000000000000000000000000000000000004f006f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005100000000a0b0c00000000000000000000000a1b1c100000000000000d3000000000000000000000000000000a1b1c1000000000000000000000000000000000000000800000f000000002f000000000055005500000000000000000000000000000065000000650000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:00000000000000000000000000000000000000000000000000000000005400330055002f000000000000a2b2c200000000000000000000000000005200000000000000000000000000000000000000000000000000000000d4000000000000000000000000000000000000a1b1c10000000000000000000000000000000000000065005551719100a1b1c10051617181910000a1b1a1b1c1000000000000466676566686006500000000000f0000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:000000000000000000000000000000000000000000000000000000000001112131616141000000000000a3b3c300000000000000000000000000005200000000000000000000000000000000000000000000000000000000d4000000000008000000000000000000000000000000000000000000000000a1b1c100005500517181617181171087000000000052627282920000a1b1c1000000000000d40048581010101056668600000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:0000000000000000000000000000000000a2b2c2000000000000000000021012103206930000b1c10000a4b4c40000000000000000a5b5c5d5f500520000000000a1b1c100000000000000000000000000000000a5b5f533e40074000000007454004f006423540000000000000000000000000000000000006500517181175767771010101088000000000053637383930000d2e2f2000000000000e400495977105767771087000000000000e7f70000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:0000000000000000000000000000000000a3b3c30000000000003040500306838383930000000000000000d3000000000000000000a6b6c6d6f60052000000000000000000000000000000000000000000000000a6b6f60121314100000001112111213111214100000000000000000000000000000065655171816272821058687862728210890000000000000000000000000000000000000000466676175767775868771088091900000000e8f80000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:0000000000000000a5f500000000000000a4b4c40000000000000000000492000000000000000000000000e4002355005400000001112131112131170000000000000000000000000000000000000f00000000000121319522324200000002122212223212224200000000000000000000000f000051718117101057677710596979586878108700000000000000000000000000000000000000504858101058687859697910890a1a97a7b7c765f997a7b7c760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:0000002313131313a6f62300330013005400e4000000000000005474640292000f00650000000000007401112131112131412050536373839363737300000000000000000000546423547400080000000000542302223210101043000000051525352515253545200000000000000000000000000052066a7a5a6a16687862728210596979108800000f00000000000000000000080000000f000049591069596979101010690756667656667656667656667666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:1121311121311121311121311121311121311141cdcdcdcdcd0111213195076171817191000000006401951010101010109100000000e7f700000060000000000000005474012131112141545400643300012131951010101010440000000000000000000000000000000000a5e5f50074005120504a8a0000000047627282771010576777108900000000e400650000000000000000000000000047101010101069576777101010101010105767771010576777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:1010101032101010101032101010101032101042cecececece0210101010106210107292000000540195121032101262109200000f00e8f80000006000005474006401213195223212228511213111213195221010101210321042000000000000000f000000000000000000a6e6f6012131920000000000006f00481058687868686272821087006500004666860000000065004666765666766617576777586910586878106957676910695868781077586878000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:101210321010121072101010101210821222320761718171811710121010101010221092006500019510101062101032629200000000e9f90000006011213111213195223210103210101010223210223210101232101010101043740033743354746564743354006401213111213195223292e3f3e3f3f3f3e3f3497282697910685969791007765666761710890055004666761710101010105810586878101010596979101058687869105969797769596979000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:101010101010101010101010101012101032122232221222323210106212101082101085112131951010101010101010100711213111213111112131122232121032101010321010121032101010121010101010101010321010851121311121311121311121311121951222321012223210075666765666765666171010101010671010101010101010101077075666761777101058101058101010596969105810101010691059697910771010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
-- 044:10101010101092146f14141414141414141414141414141414141414141400000000000000511710101010101010621007719100002652920b4b0d4d520761718161718191000000000000000000004050537383637383637383000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 045:101010721010921400141480901414140f141414142f1414141400141414000090000000511710101010621010101010101092000f0052920b4b0d4d52101010101010100791000000000000000000000000000000e7f7000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
-- 014:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000acbc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000acbc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccdc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 017:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a6a7a5a6a7a5a6a7a6a7a8a4a5a6a6a7a5a6a7a5a6a7a5a6a7a5a6a7a5a6a7a5a6a7a160919000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000919000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 018:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000470a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 019:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000475787000000000000a0b00000000000000000d0e00000a0b000000000a0b0c0000000a0b00000000000000000000000000000000000000000000000002939000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 020:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000000000008000000000000004666566676667656667686000048678800000000000000000000000000000000d1e1f100000000000000a1b1c100000000000000000000000000000000000000000000000000000000002a3a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 021:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a80000000000002f000000000000000000000000000000000000000047101057105a6a7a7a1087000049778900000000000000000000a0b0c0b00000000000000000000000000000000000000000000000000000a0b0000000000000000000000000000000000919000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 022:000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000a8a9000000000009192939000000000000b9c89aaabaca56667656667617106710100b4b0d4d1088000047578700000000000000000000a1b1c10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 023:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000099a9a7b7c700000a1a2a3a00000000b9c8d8269babbbcb10106810101010101010770b4b0d4d77890000486788000000000000000000000000000000000000a0b0c0000000000000000000000000000000000000000000000000000000000000000000000000002939000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 024:00000000000000000000000000000000000000000000000000000000000000000000009aaabaca00000000b9b8c8b8c8b8c8b8c8b8c8b8c8b8c8b8c8d826261010101010101010065a6a7a8a5a6a160b4b0d4d10870000497789000000000000000000000000000000000000a1b1c1000000000000000000000000000000000000000000000000000000000000000000000000002a3a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 025:00000000000000000000000000000000000000000000000000000000000000000000009babbbcb000000004726262626262626262626262626262626101010106810101067101088000000000000470b4b0d4d10880000476787000000000000000000000000000000000000000000000000000000a0b000000000000000000000000000000000000000360000000000000000000919000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 026:00000000000000000000000000000000000000000000000000004f000000eafa000000465666860000000048571010101010101010101010101010105810105710106710101010890000000000004a6a7a5a6a7a8a0000485788000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000360000000000000054640a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 027:000000000000000000000000000000000000000000000f00000000000000ebfb00000047576787000000004910676710671010105810101077106710101010101057101010571088000009190000000b4b0d4d000000004957890000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003600000000000000eafa2939000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 028:0000000000000000000000000000000000000000000000000000eafa0000ecfc00000048586887000000004710101010105810101010571057101010101057101010105810101089006f0a1a0027370b4b0d4d000f00004a5a8a0000000000000000000000000000000000000f0000000000000000000000000f000000000000000000000000000000003654642737546427ebfb2a3a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 029:00000000000000000000000000000000000000000000eafa0000ebfb0000acbc0000004958688800000000481010571010105a5a6a7a1010101010101010101010101010181010075666765666765666765666768600000000000000000000000000000000000000000000000000000000000000000000000000000000000000eafa0000000000009aaabaca9aaabaca9aaabaca0919000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 030:000000000000000000000000000000000000eafa0000ebfb0000ecfc0000acbc0000004759698900000000491010101010100b4b0d4d581010101010101010101067101010106710101010101010100b4b0d4d10870000000000000000000000000000000000eafa000000eafa0000000000eafa0000000000eafa0000000000ebfb0000000000009babbbcb9babbbcb9babbbcb0a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 031:000000000000a800000000000000eafa0000ebfb0000ecfc0000acbc0000acbc0000004779778700000000471067101010570b4b0d4d101010571010105810571010101057101010101010105710100b4b0d4d10882000000000000000000000000000000000ebfb000000ebfb0000000000ebfb0000000000ebfb0000000000ecfc0000000000500919065a6a7a6a16776877771877000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 032:0097a7b7c700a9000055eafa0000ebfb0000ecfc0000ccdc0000ccdc0000ccdc0000004877798800000000481010107710100b4b0d4d101010101010101010581010101010101010775710101010770b4b0d4d778900000000000097a7b7c797a7b7c700a800ecfc282828ecfc2828282828ecfc2828282828ecfc2828282828acbc2828282828280a1a880b4b0d4d48771877687777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 033:46566676566676667656667656667686282846862828468628284686282846862828284979798928282828491010101010100b4b0d4d105810101010107710101010106710101010101010101010100b4b0d4d1007566676566686b8c8c8b8c8b8b8c8b8c8b8468638383846863838383838468638383838384686383838383846863838383838380919890b4b0d4d49777777187777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 034:000000000000000000000000000000383838383838383838383838383838383838383838383838383838383800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP2>

-- <MAP6>
-- 000:f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:f5f5f5f5f5f5f500102030405060708090a0b0c0d0e0f0f5f5f5f5f5f5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:f5f5f5f5f5f5f501112131415161718191a1b1c1d1e1f1f5f5f5f5f5f5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:f5f5f5f5f5f5f502122232425262728292a2b2c2d2e2f2f5f5f5f5f5f5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:f5f5f5f5f5f5f503132333435363738393a3b3c3d3e3f3f5f5f5f5f5f5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:f5f5f5f5f5f5f504142434445464748494a4b4c4d4e4f4f5f5f5f5f5f5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:f5f5f5f5f5f5f505152535455565758595a5b5c5d5e5f5f5f5f5f5f5f5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:f5f5f5f5f5f5f506162636465666768696a6b6c6d6e6f6f5f5f5f5f5f5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:f5f5f5f5f5f5f507172737475767778797a7b7c7d7e7f7f5f5f5f5f5f5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:f5f5f5f5f5f5f508182838485868788898a8b8c8d8e8f8f5f5f5f5f5f5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:f5f5f5f5f5f5f509192939495969798999a9b9c9d9e9f9f5f5f5f5f5f5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:f5f5f5f5f5f5f50a1a2a3a4a5a6a7a8a9aaabacadaeafaf5f5f5f5f5f5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:f5f5f5f5f5f5f50b1b2b3b4b5b6b7b8b9babbbcbdbebfbf5f5f5f5f5f5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:f5f5f5f5f5f5f50c1c2c3c4c5c6c7c8c9cacbcccdcecfcf5f5f5f5f5f5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:f5f5f5f5f5f5f50d1d2d3d4d5d6d7d8d9dadbdcdddedfdf5f5f5f5f5f5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:f5f5f5f5f5f5f50e1e2e3e4e5e6e7e8e9eaebecedeeefef5f5f5f5f5f5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:f5f5f5f5f5f5f50f1f2f3f4f5f6f7f8f9fafbfcfdfeffff5f5f5f5f5f5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 017:000000000000000f1f2f3f4f5f6f7f8f9fafbfcfdfefff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 034:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008393203030405052000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 038:000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP6>

-- <MAP7>
-- 002:0000000000000000102030405060708090a0b0c0d0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:0000000000000000112131415161718191a1b1c1d1e10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:0000000000000000122232425262728292a2b2c2d2e20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:0000000000000000132333435363738393a3b3c3d3e30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:0000000000000000142434445464748494a4b4c4d4e40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:0000000000000000152535455565758595a5b5c5d5e50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:0000000000000000162636465666768696a6b6c6d6e60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:0000000000000000172737475767778797a7b7c7d7e70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:0000000000000000182838485868788898a8b8c8d8e80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:0000000000000000192939495969798999a9b9c9d9e90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:00000000000000001a2a3a4a5a6a7a8a9aaabacadaea0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:00000000000000001b2b3b4b5b6b7b8b9babbbcbdbeb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:00000000000000001c2c3c4c5c6c7c8c9cacbcccdcec0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:00000000000000001d2d3d4d5d6d7d8d9dadbdcddded0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 034:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP7>

-- <WAVES>
-- 000:fffff000000000000000000000000000
-- 001:ffffff00000000000000000000000000
-- 002:fffffff0000000000000000000000000
-- 003:ffffffff000000000000000000000000
-- 004:fffffffff00000000000000000000000
-- 005:ffffffffff0000000000000000000000
-- 006:fffffffffff000000000000000000000
-- 007:ffffffffffff00000000000000000000
-- 008:fffffffffffff0000000000000000000
-- 009:ffffffffffffff000000000000000000
-- 010:fffffffffffffff00000000000000000
-- 011:ffffffffffffffff0000000000000000
-- 012:00112233445566778899aabbccddeeff
-- 013:0123456789abcdeffedcba9876543210
-- 014:ffffffffffffffffffffffffffffffff
-- </WAVES>

-- <WAVES1>
-- 000:fffff000000000000000000000000000
-- 001:ffffff00000000000000000000000000
-- 002:fffffff0000000000000000000000000
-- 003:ffffffff000000000000000000000000
-- 004:fffffffff00000000000000000000000
-- 005:ffffffffff0000000000000000000000
-- 006:fffffffffff000000000000000000000
-- 007:ffffffffffff00000000000000000000
-- 008:fffffffffffff0000000000000000000
-- 009:ffffffffffffff000000000000000000
-- 010:fffffffffffffff00000000000000000
-- 011:ffffffffffffffff0000000000000000
-- 012:00112233445566778899aabbccddeeff
-- 013:0123456789abcdeffedcba9876543210
-- 014:ffffffffffffffffffffffffffffffff
-- </WAVES1>

-- <WAVES2>
-- 000:fffff000000000000000000000000000
-- 001:ffffff00000000000000000000000000
-- 002:fffffff0000000000000000000000000
-- 003:ffffffff000000000000000000000000
-- 004:fffffffff00000000000000000000000
-- 005:ffffffffff0000000000000000000000
-- 006:fffffffffff000000000000000000000
-- 007:ffffffffffff00000000000000000000
-- 008:fffffffffffff0000000000000000000
-- 009:ffffffffffffff000000000000000000
-- 010:fffffffffffffff00000000000000000
-- 011:ffffffffffffffff0000000000000000
-- 012:00112233445566778899aabbccddeeff
-- 013:0123456789abcdeffedcba9876543210
-- 014:ffffffffffffffffffffffffffffffff
-- </WAVES2>

-- <WAVES6>
-- 000:fffff000000000000000000000000000
-- 001:ffffff00000000000000000000000000
-- 002:fffffff0000000000000000000000000
-- 003:ffffffff000000000000000000000000
-- 004:fffffffff00000000000000000000000
-- 005:ffffffffff0000000000000000000000
-- 006:fffffffffff000000000000000000000
-- 007:ffffffffffff00000000000000000000
-- 008:fffffffffffff0000000000000000000
-- 009:ffffffffffffff000000000000000000
-- 010:fffffffffffffff00000000000000000
-- 011:ffffffffffffffff0000000000000000
-- 012:00112233445566778899aabbccddeeff
-- 013:0123456789abcdeffedcba9876543210
-- 014:ffffffffffffffffffffffffffffffff
-- </WAVES6>

-- <SFX>
-- 000:70009100a230b330c470c570d6c0d7c0e800e900fa00fb00fb00fa00f900f800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 001:70009100a240a340b470b570b6c0b7c0c800c900da00db00eb00ea00e900f800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 002:800091009250a350a480b580c6c0c7c0d800d900ea00eb00eb00fa00f900f800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 003:8000810092509350a490a590a6c0b7c0b800c900da00db00eb00ea00f900f800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 004:80008100824093409490a590b6c0b7c0c800c900da00db00eb00ea00e900e800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 005:90009100a230b330b480c580c6c0d7c0d800d900ea00eb00eb00fa00f900f800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 006:80009100a230a330b460b560c6c0d7c0d800e900ea00fb00fb00fa00f900f800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 007:90009100a220a320b470b570b6c0c7c0c800c900da00db00db00ea00e900e800e700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 008:9000910092509350a470a570a6c0a7c0b800b900ba00bb00cb00ca00c900d800d700d600d500e400e300e200e100f000f000f100f200f300f400f500405000000800
-- 009:9fce9fce9b909b70fb60fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00a00000000000
-- 010:af0faf0fabc0abb0ab90aff6aff6aff6aff6bff6cff6dff6dff6eff6eff6fff6fff6fff6fff6fff6fff6fff6fff6fff6fff6fff6fff6fff6fff6fff6b00000000000
-- 011:9d009d009d009d00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00502000000000
-- 012:8b009b009b009b009b00ab00ab00ab00bb00bb00bb00bb00bb00cb00cb00db00db00eb00eb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00205000000000
-- 013:a0c0a1c0a200a300a400b500b600b700b800c900ca00cb00cb00ca00c900c800c700c600c500c400c300c200c100c000ff00ff00ff00ff00ff00ff00407000000000
-- 014:b000b100b200b300b400b500b600b700b800b900ba00bb00bb00ba00b900b800b700b600b500b400b300b200b100b000ff00ff00ff00ff00ff00ff00400000000000
-- 015:af00bf00bf00cf00df00df00ef00ef00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00707000000000
-- 016:0d001d102d103d303d304d404d504d705d805d906d906da06db07dc07dd08dd08de08dd09dd09dd09dc09dd0add0ad50ad50bd00bd00bd00bd00fd0030b000000000
-- 017:000010101000201020102020203030303040306040705080509050a060b070c080c080d090d0a0e0b0e0c0f0d0f0e0b0f090f050f040f040f020f010404000000000
-- 018:1fe01fe02fc03fb04fa04fa05f906f806f706f706f607f509f50af40bf30cf30ef20ef20ef20ef10ef10ef00ef00ff00ff00ff00ff00ff00ff00ff00434000000000
-- 019:0bf01be02bc03bb04ba04b805b706b607b508b409b20ab10ab10bb00cb00cb00db00db00db00eb00eb00fb00fb00fb00fb00fb00fb00fb00fb00fb00509000000000
-- 020:0b002b605b807ba0abc0cbc0ebc0fbb0eba09b704b201b100b000b003b205b807bb09bc0bbc0ebb03ba00b800b600b401b202b106b00bb00fb00fb0030b000000000
-- 021:300030104020503060406040704070508070808090b090b0a0a0b090b08090708070706060606050704080309030902030102010f000f000f000f000402000000000
-- 022:00e000e000d000d000c000c000b000a0009000900080008000700060006000600050005000400040004000300020002000109010b010f000f000f000105000000000
-- 023:0c00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc0050b0000f0000
-- </SFX>

-- <SFX1>
-- 000:70009100a230b330c470c570d6c0d7c0e800e900fa00fb00fb00fa00f900f800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 001:70009100a240a340b470b570b6c0b7c0c800c900da00db00eb00ea00e900f800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 002:800091009250a350a480b580c6c0c7c0d800d900ea00eb00eb00fa00f900f800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 003:8000810092509350a490a590a6c0b7c0b800c900da00db00eb00ea00f900f800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 004:80008100824093409490a590b6c0b7c0c800c900da00db00eb00ea00e900e800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 005:90009100a230b330b480c580c6c0d7c0d800d900ea00eb00eb00fa00f900f800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 006:80009100a230a330b460b560c6c0d7c0d800e900ea00fb00fb00fa00f900f800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 007:90009100a220a320b470b570b6c0c7c0c800c900da00db00db00ea00e900e800e700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 008:9000910092509350a470a570a6c0a7c0b800b900ba00bb00cb00ca00c900d800d700d600d500e400e300e200e100f000f000f100f200f300f400f500405000000800
-- 009:9fce9fce9b909b70fb60fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00a00000000000
-- 010:af0faf0fabc0abb0ab90aff6aff6aff6aff6bff6cff6dff6dff6eff6eff6fff6fff6fff6fff6fff6fff6fff6fff6fff6fff6fff6fff6fff6fff6fff6b00000000000
-- 011:9d009d009d009d00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00502000000000
-- 012:8b009b009b009b009b00ab00ab00ab00bb00bb00bb00bb00bb00cb00cb00db00db00eb00eb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00205000000000
-- 013:a0c0a1c0a200a300a400b500b600b700b800c900ca00cb00cb00ca00c900c800c700c600c500c400c300c200c100c000ff00ff00ff00ff00ff00ff00407000000000
-- 014:b000b100b200b300b400b500b600b700b800b900ba00bb00bb00ba00b900b800b700b600b500b400b300b200b100b000ff00ff00ff00ff00ff00ff00400000000000
-- 015:af00bf00bf00cf00df00df00ef00ef00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00707000000000
-- 016:0d001d102d103d303d304d404d504d705d805d906d906da06db07dc07dd08dd08de08dd09dd09dd09dc09dd0add0ad50ad50bd00bd00bd00bd00fd0030b000000000
-- 017:000010101000201020102020203030303040306040705080509050a060b070c080c080d090d0a0e0b0e0c0f0d0f0e0b0f090f050f040f040f020f010404000000000
-- 018:1fe01fe02fc03fb04fa04fa05f906f806f706f706f607f509f50af40bf30cf30ef20ef20ef20ef10ef10ef00ef00ff00ff00ff00ff00ff00ff00ff00434000000000
-- 019:0bf01be02bc03bb04ba04b805b706b607b508b409b20ab10ab10bb00cb00cb00db00db00db00eb00eb00fb00fb00fb00fb00fb00fb00fb00fb00fb00509000000000
-- 020:0b002b605b807ba0abc0cbc0ebc0fbb0eba09b704b201b100b000b003b205b807bb09bc0bbc0ebb03ba00b800b600b401b202b106b00bb00fb00fb0030b000000000
-- 021:300030104020503060406040704070508070808090b090b0a0a0b090b08090708070706060606050704080309030902030102010f000f000f000f000402000000000
-- 022:00e000e000d000d000c000c000b000a0009000900080008000700060006000600050005000400040004000300020002000109010b010f000f000f000105000000000
-- 023:0c00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc0050b0000f0000
-- </SFX1>

-- <SFX2>
-- 000:70009100a230b330c470c570d6c0d7c0e800e900fa00fb00fb00fa00f900f800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 001:70009100a240a340b470b570b6c0b7c0c800c900da00db00eb00ea00e900f800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 002:800091009250a350a480b580c6c0c7c0d800d900ea00eb00eb00fa00f900f800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 003:8000810092509350a490a590a6c0b7c0b800c900da00db00eb00ea00f900f800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 004:80008100824093409490a590b6c0b7c0c800c900da00db00eb00ea00e900e800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 005:90009100a230b330b480c580c6c0d7c0d800d900ea00eb00eb00fa00f900f800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 006:80009100a230a330b460b560c6c0d7c0d800e900ea00fb00fb00fa00f900f800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 007:90009100a220a320b470b570b6c0c7c0c800c900da00db00db00ea00e900e800e700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 008:9000910092509350a470a570a6c0a7c0b800b900ba00bb00cb00ca00c900d800d700d600d500e400e300e200e100f000f000f100f200f300f400f500405000000800
-- 009:9fce9fce9b909b70fb60fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00a00000000000
-- 010:af0faf0fabc0abb0ab90aff6aff6aff6aff6bff6cff6dff6dff6eff6eff6fff6fff6fff6fff6fff6fff6fff6fff6fff6fff6fff6fff6fff6fff6fff6b00000000000
-- 011:9d009d009d009d00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00502000000000
-- 012:8b009b009b009b009b00ab00ab00ab00bb00bb00bb00bb00bb00cb00cb00db00db00eb00eb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00205000000000
-- 013:a0c0a1c0a200a300a400b500b600b700b800c900ca00cb00cb00ca00c900c800c700c600c500c400c300c200c100c000ff00ff00ff00ff00ff00ff00407000000000
-- 014:b000b100b200b300b400b500b600b700b800b900ba00bb00bb00ba00b900b800b700b600b500b400b300b200b100b000ff00ff00ff00ff00ff00ff00400000000000
-- 015:af00bf00bf00cf00df00df00ef00ef00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00707000000000
-- 016:0d001d102d103d303d304d404d504d705d805d906d906da06db07dc07dd08dd08de08dd09dd09dd09dc09dd0add0ad50ad50bd00bd00bd00bd00fd0030b000000000
-- 017:000010101000201020102020203030303040306040705080509050a060b070c080c080d090d0a0e0b0e0c0f0d0f0e0b0f090f050f040f040f020f010404000000000
-- 018:1fe01fe02fc03fb04fa04fa05f906f806f706f706f607f509f50af40bf30cf30ef20ef20ef20ef10ef10ef00ef00ff00ff00ff00ff00ff00ff00ff00434000000000
-- 019:0bf01be02bc03bb04ba04b805b706b607b508b409b20ab10ab10bb00cb00cb00db00db00db00eb00eb00fb00fb00fb00fb00fb00fb00fb00fb00fb00509000000000
-- 020:0b002b605b807ba0abc0cbc0ebc0fbb0eba09b704b201b100b000b003b205b807bb09bc0bbc0ebb03ba00b800b600b401b202b106b00bb00fb00fb0030b000000000
-- 021:300030104020503060406040704070508070808090b090b0a0a0b090b08090708070706060606050704080309030902030102010f000f000f000f000402000000000
-- 022:00e000e000d000d000c000c000b000a0009000900080008000700060006000600050005000400040004000300020002000109010b010f000f000f000105000000000
-- 023:0c00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc0050b0000f0000
-- </SFX2>

-- <SFX6>
-- 000:70009100a230b330c470c570d6c0d7c0e800e900fa00fb00fb00fa00f900f800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 001:70009100a240a340b470b570b6c0b7c0c800c900da00db00eb00ea00e900f800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 002:800091009250a350a480b580c6c0c7c0d800d900ea00eb00eb00fa00f900f800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 003:8000810092509350a490a590a6c0b7c0b800c900da00db00eb00ea00f900f800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 004:80008100824093409490a590b6c0b7c0c800c900da00db00eb00ea00e900e800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 005:90009100a230b330b480c580c6c0d7c0d800d900ea00eb00eb00fa00f900f800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 006:80009100a230a330b460b560c6c0d7c0d800e900ea00fb00fb00fa00f900f800f700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 007:90009100a220a320b470b570b6c0c7c0c800c900da00db00db00ea00e900e800e700f600f500f400f300f200f100f000f000f100f200f300f400f500402000000800
-- 008:9000910092509350a470a570a6c0a7c0b800b900ba00bb00cb00ca00c900d800d700d600d500e400e300e200e100f000f000f100f200f300f400f500405000000800
-- 009:9fce9fce9b909b70fb60fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00a00000000000
-- 010:af0faf0fabc0abb0ab90aff6aff6aff6aff6bff6cff6dff6dff6eff6eff6fff6fff6fff6fff6fff6fff6fff6fff6fff6fff6fff6fff6fff6fff6fff6b00000000000
-- 011:9d009d009d009d00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00502000000000
-- 012:8b009b009b009b009b00ab00ab00ab00bb00bb00bb00bb00bb00cb00cb00db00db00eb00eb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00fb00205000000000
-- 013:a0c0a1c0a200a300a400b500b600b700b800c900ca00cb00cb00ca00c900c800c700c600c500c400c300c200c100c000ff00ff00ff00ff00ff00ff00407000000000
-- 014:b000b100b200b300b400b500b600b700b800b900ba00bb00bb00ba00b900b800b700b600b500b400b300b200b100b000ff00ff00ff00ff00ff00ff00400000000000
-- 015:af00bf00bf00cf00df00df00ef00ef00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00707000000000
-- 016:0d001d102d103d303d304d404d504d705d805d906d906da06db07dc07dd08dd08de08dd09dd09dd09dc09dd0add0ad50ad50bd00bd00bd00bd00fd0030b000000000
-- 017:000010101000201020102020203030303040306040705080509050a060b070c080c080d090d0a0e0b0e0c0f0d0f0e0b0f090f050f040f040f020f010404000000000
-- 018:1fe01fe02fc03fb04fa04fa05f906f806f706f706f607f509f50af40bf30cf30ef20ef20ef20ef10ef10ef00ef00ff00ff00ff00ff00ff00ff00ff00434000000000
-- 019:0bf01be02bc03bb04ba04b805b706b607b508b409b20ab10ab10bb00cb00cb00db00db00db00eb00eb00fb00fb00fb00fb00fb00fb00fb00fb00fb00509000000000
-- 020:0b002b605b807ba0abc0cbc0ebc0fbb0eba09b704b201b100b000b003b205b807bb09bc0bbc0ebb03ba00b800b600b401b202b106b00bb00fb00fb0030b000000000
-- 021:300030104020503060406040704070508070808090b090b0a0a0b090b08090708070706060606050704080309030902030102010f000f000f000f000402000000000
-- 022:00e000e000d000d000c000c000b000a0009000900080008000700060006000600050005000400040004000300020002000109010b010f000f000f000105000000000
-- 023:0c00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc0050b0000f0000
-- </SFX6>

-- <PATTERNS>
-- 000:4ff1d80000000000004ff1e80000000000004ff1e80000000000004ff1e80000000000006ff1d80000007ff1d80000007ff1d80000000000007ff1e80000000000007ff1e80000000000007ff1e80000000000009ff1d8000000bff1d8000000bff1d8000000000000bff1e80000000000009ff1d80000000000009ff1e80000000000007ff1d80000000000007ff1e89ff1d80000000000009ff1e87ff1d80000000000007ff1e86ff1d80000000000006ff1e8fff1d6000000000000fff1e6
-- 001:aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000
-- 002:4ff1c40000000000004ff1c40000000000004ff1c40000000000004ff1c40000000000004ff1c40000004ff1c40000007ff1c40000000000007ff1c40000000000007ff1c40000000000007ff1c40000000000007ff1c40000007ff1c4000000cff1c2000000000000cff1c2000000000000cff1c2000000000000cff1c2000000000000cff1c2000000cff1c2000000eff1c2000000000000eff1c2000000000000eff1c2000000000000fff1c2000000000000fff1c2000000fff1c2000000
-- 003:4ff1940000004ff1080000004ff1a60000004ff1080000004ff1940000004ff1080000004ff1a60000004ff1080000004ff194000000eff1360000004ff1a6000000eff1360000004ff194000000eff1360000004ff1a6000000eff1360000004ff1940000004ff1580000004ff1a60000004ff1580000004ff1940000004ff1580000004ff1a60000004ff1580000004ff194000000eff1860000004ff1a6000000eff1860000004ff194000000fff1660000004ff1a6000000fff166000000
-- </PATTERNS>

-- <PATTERNS1>
-- 000:4ff1d80000000000004ff1e80000000000004ff1e80000000000004ff1e80000000000006ff1d80000007ff1d80000007ff1d80000000000007ff1e80000000000007ff1e80000000000007ff1e80000000000009ff1d8000000bff1d8000000bff1d8000000000000bff1e80000000000009ff1d80000000000009ff1e80000000000007ff1d80000000000007ff1e89ff1d80000000000009ff1e87ff1d80000000000007ff1e86ff1d80000000000006ff1e8fff1d6000000000000fff1e6
-- 001:aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000
-- 002:4ff1c40000000000004ff1c40000000000004ff1c40000000000004ff1c40000000000004ff1c40000004ff1c40000007ff1c40000000000007ff1c40000000000007ff1c40000000000007ff1c40000000000007ff1c40000007ff1c4000000cff1c2000000000000cff1c2000000000000cff1c2000000000000cff1c2000000000000cff1c2000000cff1c2000000eff1c2000000000000eff1c2000000000000eff1c2000000000000fff1c2000000000000fff1c2000000fff1c2000000
-- 003:4ff1940000004ff1080000004ff1a60000004ff1080000004ff1940000004ff1080000004ff1a60000004ff1080000004ff194000000eff1360000004ff1a6000000eff1360000004ff194000000eff1360000004ff1a6000000eff1360000004ff1940000004ff1580000004ff1a60000004ff1580000004ff1940000004ff1580000004ff1a60000004ff1580000004ff194000000eff1860000004ff1a6000000eff1860000004ff194000000fff1660000004ff1a6000000fff166000000
-- </PATTERNS1>

-- <PATTERNS2>
-- 000:4ff1d80000000000004ff1e80000000000004ff1e80000000000004ff1e80000000000006ff1d80000007ff1d80000007ff1d80000000000007ff1e80000000000007ff1e80000000000007ff1e80000000000009ff1d8000000bff1d8000000bff1d8000000000000bff1e80000000000009ff1d80000000000009ff1e80000000000007ff1d80000000000007ff1e89ff1d80000000000009ff1e87ff1d80000000000007ff1e86ff1d80000000000006ff1e8fff1d6000000000000fff1e6
-- 001:aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000
-- 002:4ff1c40000000000004ff1c40000000000004ff1c40000000000004ff1c40000000000004ff1c40000004ff1c40000007ff1c40000000000007ff1c40000000000007ff1c40000000000007ff1c40000000000007ff1c40000007ff1c4000000cff1c2000000000000cff1c2000000000000cff1c2000000000000cff1c2000000000000cff1c2000000cff1c2000000eff1c2000000000000eff1c2000000000000eff1c2000000000000fff1c2000000000000fff1c2000000fff1c2000000
-- 003:4ff1940000004ff1080000004ff1a60000004ff1080000004ff1940000004ff1080000004ff1a60000004ff1080000004ff194000000eff1360000004ff1a6000000eff1360000004ff194000000eff1360000004ff1a6000000eff1360000004ff1940000004ff1580000004ff1a60000004ff1580000004ff1940000004ff1580000004ff1a60000004ff1580000004ff194000000eff1860000004ff1a6000000eff1860000004ff194000000fff1660000004ff1a6000000fff166000000
-- </PATTERNS2>

-- <PATTERNS6>
-- 000:4ff1d80000000000004ff1e80000000000004ff1e80000000000004ff1e80000000000006ff1d80000007ff1d80000007ff1d80000000000007ff1e80000000000007ff1e80000000000007ff1e80000000000009ff1d8000000bff1d8000000bff1d8000000000000bff1e80000000000009ff1d80000000000009ff1e80000000000007ff1d80000000000007ff1e89ff1d80000000000009ff1e87ff1d80000000000007ff1e86ff1d80000000000006ff1e8fff1d6000000000000fff1e6
-- 001:aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000aff1fe000000
-- 002:4ff1c40000000000004ff1c40000000000004ff1c40000000000004ff1c40000000000004ff1c40000004ff1c40000007ff1c40000000000007ff1c40000000000007ff1c40000000000007ff1c40000000000007ff1c40000007ff1c4000000cff1c2000000000000cff1c2000000000000cff1c2000000000000cff1c2000000000000cff1c2000000cff1c2000000eff1c2000000000000eff1c2000000000000eff1c2000000000000fff1c2000000000000fff1c2000000fff1c2000000
-- 003:4ff1940000004ff1080000004ff1a60000004ff1080000004ff1940000004ff1080000004ff1a60000004ff1080000004ff194000000eff1360000004ff1a6000000eff1360000004ff194000000eff1360000004ff1a6000000eff1360000004ff1940000004ff1580000004ff1a60000004ff1580000004ff1940000004ff1580000004ff1a60000004ff1580000004ff194000000eff1860000004ff1a6000000eff1860000004ff194000000fff1660000004ff1a6000000fff166000000
-- </PATTERNS6>

-- <TRACKS>
-- 000:180301000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020
-- </TRACKS>

-- <TRACKS1>
-- 000:180301000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020
-- </TRACKS1>

-- <TRACKS2>
-- 000:180301000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020
-- </TRACKS2>

-- <TRACKS6>
-- 000:180301000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020
-- </TRACKS6>

-- <FLAGS>
-- 000:00102020202040800000000000000000101010101010101010100000000000001000000010101010101000000000000010000000101010101010000000000000100000001000000000000000000000001010101010000000000000000000000000000000101010101000000000000000000000001000000010000000000000000000000010000000100000000000000010101010100000001000080000000000101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </FLAGS>

-- <FLAGS1>
-- 000:00102020202040800000000000000000101010101010101010100000000000001000000010101010101000000000000010000000101010101010000000000000100000011000000000000000000000001010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </FLAGS1>

-- <FLAGS2>
-- 000:00102020202040800000000000000000101010101010101010100000000000001000000010101010101000000000000010000000101010101010000000000000100000001000000000000000000000001010101010000000000000000000000000000008101010101000000000000000000000001000000010000000000000000000000010000000100000101000000010101010100000001000001010000000101010101010101010101010100010100000000000000000001010101000101000000000000000000000101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </FLAGS2>

-- <FLAGS6>
-- 000:00102020202040800000000000000000101010101010101010100000000000001000000010101010101000000000000010000000101010101010000000000000100000001000000000000000000000001010101010000000000000000000000000000000101010101000000000000000000000001000000010000000000000000000000010000000100000000000000010101010100000001000080000000000101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </FLAGS6>

-- <FLAGS7>
-- 000:00102020202040800000000000000000101010101010101010100000000000001000000010101010101000000000000010000000101010101010000000000000100000001000000000000000000000001010101010000000000000000000000000000000101010101000000000000000000000001000000010000000000000000000000010000000100000000000000010101010100000001000000000000000101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </FLAGS7>

-- <SCREEN>
-- 000:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 001:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 002:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 003:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 004:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 005:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 006:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 007:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 008:2222222222222222222222222222222222222222222222222222222222222222222222222f19c2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 009:222222222222222222222222222222222222222222222222222222222222222222222221c000c2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 010:222222222222222222222222222222222222222222222222222222222222222222222222000092222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 011:222222222222222222222222222222222222222222222222222222222222222222222222900012222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 012:222222222222222222222222222222222222222222222222222222222222222222222222100012222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 013:2222222222222222222222222222222222222222222222222222222222222222222222221000f222222222222222222222222222222222222222222222222222222222222222222f11199911f222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 014:2222222222222222222222222222222222222222222222222222222222222222222222221000222222222222222222222222222222f11ff222f11111111222222222111111f22f11119c0000000911f222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 015:2222222222222222222222222222222222222222222222222222222222222222222222221000222222222222222222222222219112f15000cf21000000f2222222221000012222f122222f19000000000591f222222222222222222222222222222222222222222222222222222222222222222222222222
-- 016:2222222222222222222222222222222222222222222222222222222222222222222222221000222222222f22222222222221c92222222100c2221000092222222222200012222210f22222222f119c000000009f222222222222222222222222222222222222222222222222222222222222222222222222
-- 017:222222222222222222222222222222222222222222222222222222222222222222222222100c2222221c00051222222221009222222222101222210000f222222222200122222210f22222222222222f19000000122222222222222222222222222222222222222222222222222222222222222222222222
-- 018:22222222222222222222222222222222222222222222222222222222222222222222222290092222f50000000122222fc00922222222222122222290009222222222101222222210f2222ff22222222222210000012222222222222222222222222222222222222222222222222222222222222222222222
-- 019:222222222222222222222222222222222222222222222222222222222222222222222222900c22210000000000f222f0000f2222222222222222222c00012222222f012222222290f2221c22222222222222fc000c2222222222222222222222222222222222222222222222222222222222222222222222
-- 020:222222222222222222222222222222222222222222222222222222222222222222222222c000229091f1c000009222c000122222222222222222222f000c2222222c122222222290f22101222222222222222f0000f222222222222222222222222222222222222222222222222222222222222222222222
-- 021:222222222222222222222222222222222222222222222222222222222222222222222222000015cf2222210000022900002222222222222222222222100092222251222222222290f21001222222222222222290001222222222222222222222222222222222222222222222222222222222222222222222
-- 022:2222222222222222222222222222222222222222222222222222222222222222222222220000092222222250000ff000001222222222222222222222290001222912222222222250f2500f2222222222222222f0001222222222222222222222222222222222222222222222222222222222222222222222
-- 023:2222222222222222222222222222222222222222222222222222222222222222222222220000c222222222f0000f100000092222222222222222222222c000f299222222222222c0f20002222222222222222220001222222222222222222222222222222222222222222222222222222222222222222222
-- 024:2222222222222222222222222222222222222222222222222222222222222222222222220000f222222222290002500000000c11f22222222222222222f0000c92222222222222992f000222222222222222222c001222222222222222222222222222222222222222222222222222222222222222222222
-- 025:22222222222222222222222222222222222222222222222222222222222222222222222f000922222222222100c200000cc9111f222222222222222222210000f222222222222222210002222222222222222229001222222222222222222222222222222222222222222222222222222222222222222222
-- 026:22222222222222222222222222222222222222222222222222222222222222222222222f000122222222222f0052000092222222222222222222222222229000522222222222222221000f222222222222222225001222222222222222222222222222222222222222222222222222222222222222222222
-- 027:222222222222222222222222222222222222222222222222222222222222222222222221000f22222222222200920000c222222222222222222222222222900001222222222222222f000122222222222222222c00f222222222222222222222222222222222222222222222222222222222222222222222
-- 028:222222222222222222222222222222222222222222222222222222222222222222222221000222222222222200c2000002222222222222222222222222215f50001222222222222222000922222222222222222000f222222222222222222222222222222222222222222222222222222222222222222222
-- 029:22222222222222222222222222222222222222222222222222222222222222222222222100522222222222220002c000012222222222222222222222221522fc000f22222222222222c0002222222222222222200c2222222222222222222222222222222222222222222222222222222222222222222222
-- 030:22222222222222222222222222222222222222222222222222222222222222222222222100922222222222220002900009222222222222222222222221c2222f0005222222222222229000922222222222222210012222222222222222222222222222222222222222222222222222222222222222222222
-- 031:2222222222222222222222222222222222222222222222222222222222222222222222290052222222222222000210000012222222222f199c0000cf1cf100921000922222222222222000012222222222222290522222222222222222222222222222222222222222222222222222222222222222222222
-- 032:222222222222222222222222222222222222222222222222222222222222222222222220000222222222222200c2f000000122222219000000000cf10f10000929000122222222222221000cf222222222222209222222222222222222222222222222222222222222222222222222222222222222222222
-- 033:2222222222222222222222222222222222222222222222222222222222222222222222200002222222222222001225000000f22210000000cf90cf101fc000001f0000fff2222222222290000922222222222112222222222222222222222222222222222222222222222222222222222222222222222222
-- 034:2222222222222222222222222222222222222222222222222222222222222222222222f0000122222222222100f22290000009f219c00c9122ccf10029000000c21000c2192222222222f50000c1222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 035:222222222222222222222222222222222222222222222222222222222222222222222210000922222222222109222229000000091f22222210cf1009200000000920000921c12222222222900000091f2ff22222222222222222222222222222222222222222222222222222222222222222222222222222
-- 036:2222222222222222222222222222222222222222222222222222222222222222222222c00000f2222222222c01222222f9000000000912f90521000c2900000001f00000921c92222222222100000000c1222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 037:222222222222222222222222222222222222222222222222222222222222222222222f0000cc9222222222f0c222222222f1199911f2f90c121ccccc12190009f299999999f2f12222222222219c0c9122222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 038:2222222222222222222222222222222222222222222222222222222222222222222222222222222222222290122222222991ff2ff11c0001222222222222c00f2222222222222f92222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 039:2222222222222222222222222222222222222222222222222222222222222222222222222222222222222f0922222222900000000000000000000000000000000000000000000009222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 040:22222222222222222222222222222222222222222222222222222222222222222222222222222222222229c222222221000000000000000000000000000000000000000000000000122222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 041:2222222222222222222222222222222222222222222222222222222222222222222222222222222222221c222222222c000000000000000000000000000000000000000000000000c22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 042:2222222222222222222222222222222222222222222222222222222222222222222222222222222222225f2222222290000000000000000000000000000000000000000000000000092222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 043:222222222222222222222222222222222222222222222222222222222222222222222222222222222221222222222f0000000000000000000000000000000000000000000000000000f222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 044:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222900000000000000000000000000000000000000000000000000009222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 045:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222000000000000000000000000000000000000000000000000000000222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 046:222222222222222222222222222222222222222222222222222222222222222222221005122222222222222222221000000000000000000000000000000000000000000000000000000122222222222222222221500122222222222222222222222222222222222222222222222222222222222222222222
-- 047:22222222222222222222222222222222222222222222222222222222222222222221000000c91f222222222222225000000000000000000000000000000000000000000000000000000522222222222222f19c00000012222222222222222222222222222222222222222222222222222222222222222222
-- 048:222222222222222222222222222222222222222222222222222222222222222222290000000000f2222222222222000000000000000000000000000000000000000000000000000000002222222222222f000000000092222222222222222222222222222222222222222222222222222222222222222222
-- 049:2222222222222222222222222222222222222222222222222222222222222222222c00000000009222222222222100000000000000000000000000000000000000000000000000000000122222222222290000000000c2222222222222222222222222222222222222222222222222222222222222222222
-- 050:222222222222222222222222222222222222222222222222222222222222222222f0000000000002222222222221000000000000000000000000000000000000000000000000000000001222222222222000000000000f222222222222222222222222222222222222222222222222222222222222222222
-- 051:2222222222222222222222222222222222222222222222222222222222222222221000000000000f22222222222900000000000000000000000000000000000000000000000000000000922222222222f0000000000001222222222222222222222222222222222222222222222222222222222222222222
-- 052:222222222222222222222222222222222222222222222222222222222222222222900000000000092222222222290000000000000000000000000000000000000000000000000000000092222222222290000000000009222222222222222222222222222222222222222222222222222222222222222222
-- 053:22222222222222222222222222222222222222222222222222222222222222222f00000000000000f2222222222c00000000000000000000000000000000000000000000000000000000c2222222222f00000000000000f22222222222222222222222222222222222222222222222222222222222222222
-- 054:2222222222222222222222222222222222222222222222222222222222222222fc000000000000009222222222200000000000000000000000000000000000000000000000000000000002222222222900000000000000cf2222222222222222222222222222222222222222222222222222222222222222
-- 055:22222222222222222222222222222222222222222222222222222222222222f900000000000000000f2222222220000000000000000000000000000000000000000000000000000000000222222222f000000000000000009f22222222222222222222222222222222222222222222222222222222222222
-- 056:2222222222222222222222222222222222222222222222222222222222222100000000000000000000f22222222c00000000000000000000000000000000000000000000000000000000c22222222f0000000000000000000012222222222222222222222222222222222222222222222222222222222222
-- 057:2222222222222222222222222222222222222222222222222222222222221000000000000000000000c22222222500000000000000000000000000000000000000000000000000000000522222222c0000000000000000000001222222222222222222222222222222222222222222222222222222222222
-- 058:22222222222222222222222222222222222222222222222222222222222200000000000000000000000c122222290000000000000000000000000000000000000000000000000000000092222221c00000000000000000000000222222222222222222222222222222222222222222222222222222222222
-- 059:22222222222222222222222222222222222222222222222222222222222100000000000000000000000009f222290000000000000000000000000000000000000000000000000000000092222f90000000000000000000000000122222222222222222222222222222222222222222222222222222222222
-- 060:22222222222222222222222222222222222222222222222222222222222f000000000000000000000000000c1f210000000000000000000000000000000000000000000000000000000012f1c000000000000000000000000000f22222222222222222222222222222222222222222222222222222222222
-- 061:22222222222222222222222222222222222222222222222222222222222200000000000000000000000000000c2f00000000000000000000000000000000000000000000000000000000f2c00000000000000000000000000000222222222222222222222222222222222222222222222222222222222222
-- 062:222222222222222222222222222222222222222222222222222222222222100000000000000000000000000000f2c000000000000000000000000000000000000000000000000000000c2f000000000000000000000000000001222222222222222222222222222222222222222222222222222222222222
-- 063:22222222222222222222222222222222222222222222222222222222222221000000000000000000000000000012900000000999900000000000000000000000000000c111100000000921000000000000000000000000000012222222222222222222222222222222222222222222222222222222222222
-- 064:2222222222222222222222222222222222222222222222222222222222222290000000000000000000000000009210000009f22222150000000000000000000000009f2222229000000129000000000000000000000000000922222222222222222222222222222222222222222222222222222222222222
-- 065:222222222222222222222222222222222222222222222222222222222222222c00000000000000000000000000c2100000c222222222f9000000000000000000001f222222222c0000012c00000000000000000000000000c222222222222222222222222222222222222222222222222222222222222222
-- 066:222222222222222222222222222222222222222222222222222222222222222f0000000055c0000000000000000f100000122222222222f900000000000000009222222222222f000001f0000000000000000c5500000000f222222222222222222222222222222222222222222222222222222222222222
-- 067:22222222222222222222222222222222222222222222222222222222222222221000005f2222f1c0000000000001100000222222222222221c000000000000c1222222222222220000011000000000000c1f2222f50000012222222222222222222222222222222222222222222222222222222222222222
-- 068:2222222222222222222222222222222222222222222222222222222222222222219009222222222f15000000000910000c22222222222222229000000000092222222222222222c0000f900000000051f2222222229009122222222222222222222222222222222222222222222222222222222222222222
-- 069:22222222222222222222222222222222222222222222222222222222222222222222f22222222222222190000009f000092222222222222222200000000002222222222222222290000f90000009122222222222222f22222222222222222222222222222222222222222222222222222222222222222222
-- 070:2222222222222222222222222222222222222222222222222222222222222222222222222222222222222219c00110000922222222222222222100000000122222222222222222900001100c9122222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 071:22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222f121000092222222222222222210000000012222222222222222290000121f22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 072:2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222210000922222222222222222c00000000c2222222222222222290000122222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 073:2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222210000c2222222222222222100000000001222222222222222200000122222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 074:22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222900000122222222222221c000000000000c12222222222222100000922222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 075:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222225000000f22222222221c0000000000000000c122222222221000000522222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 076:22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222c000000012222222f90000000051100000000051f22222290000000c22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 077:22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222000000000c9995c000000000002229000000000000c59c000000000022222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 078:2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222f00000000000000000000000001222f00000000000000000000000000f2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 079:22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222221000000000000000000000000c222221000000000000000000000000012222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 080:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222210000000000000000000000001222222000000000000000000000000012222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 081:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222290000000000000000000000002222222900000000000000000000000092222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 082:2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222c0000000000000000000000092222222f000000000000000000000000c2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 083:2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222c00000000000000000000000f22222222c00000000000000000000000c2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 084:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222250000000000000000000000022222222290000000000000000000000052222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 085:2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222100000000000000000000000f2222222290000000000000000000000012222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 086:22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222c0000000000000000000000f2222222210000000000000000000000c22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 087:2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222221000000000000000000000922191f220000000000000c000000001222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 088:22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222221000000122f15000000000c000005000000000051f22100000012222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 089:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222221000012222221000000000000000000000000122222210000122222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 090:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222219ccff11222222222c0000000000000000000000c222222222112fcc912222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 091:2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222f1c0000c122222222222900000000000000000000001222222222221c0000c1f2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 092:22222222222222222222222222222222222222222222222222222222222222222222222222222222222222150000000000f222222222100000000000000000000001222222222f00000000005122222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 093:22222222222222222222222222222222222222222222222222222222222222222222222222222222222190000000000000f222222222f0000000000000000000000f222222222f00000000000009122222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 094:22222222222222222222222222222222222222222222222222222222222222222f500c2222222222f1c000000000000000f222222211f0000000000000000000000f112222222f000000000000000c1f2222222222c005f22222222222222222222222222222222222222222222222222222222222222222
-- 095:22222222222222222222222222222222222222222222222222222222222222221000009222222215000000000000000000f222222200c00000000000000000000000002222222f00000000000000000051222222290000012222222222222222222222222222222222222222222222222222222222222222
-- 096:22222222222222222222222222222222222222222222222222222222222222210000000111119000000000000000000000f222222200000000000000000000000000002222222f00000000000000000000091111100000001222222222222222222222222222222222222222222222222222222222222222
-- 097:2222222222222222222222222222222222222222222222222222222222222210000000000000000000000000000000005f22222222500c9c00590009c00c9c0059000922222222f5000000000000000000000000000000000122222222222222222222222222222222222222222222222222222222222222
-- 098:22222222222222222222222222222222222222222222222222222222222222c0000000000000000000000000000000c1222222222210012900f2c002100929001f00c22222222222100000000000000000000000000000000022222222222222222222222222222222222222222222222222222222222222
-- 099:222222222222222222222222222222222222222222222222222222222222290000000000000000000000000000000922222222222210012900f2c002100929001f00c22222222222229000000000000000000000000000000092222222222222222222222222222222222222222222222222222222222222
-- 100:22222222222222222222222222222222222222222222222222222222222210000000000000000000000000000005f222222222222210012900f2c002100929001f00c22222222222222f50000000000000000000000000000001222222222222222222222222222222222222222222222222222222222222
-- 101:22222222222222222222222222222222222222222222222222222222222290000000000000000000000000000c122222222222222210012900f2c002100929001f00c22222222222222221c00000000000000000000000000009222222222222222222222222222222222222222222222222222222222222
-- 102:222222222222222222222222222222222222222222222222222222222222000000000000000000000000000012222222222222222222222900f2c00210092900f211122222222222222222210000000000000000000000000000222222222222222222222222222222222222222222222222222222222222
-- 103:222222222222222222222222222222222222222222222222222222222222000000000000000000000000009f22222222222222222222222222221112f11f2222222222222222222222222222f900000000000000000000000000222222222222222222222222222222222222222222222222222222222222
-- 104:222222222222222222222222222222222222222222222222222222222222900000000000000000000000c1222222222222222222222222222222222222222222222222222222222222222222221c000000000000000000000009222222222222222222222222222222222222222222222222222222222222
-- 105:222222222222222222222222222222222222222222222222222222222222f0000000000000000000000122222222222222222222222222222222222222222222222222222222222222222222222210000000000000000000000f222222222222222222222222222222222222222222222222222222222222
-- 106:2222222222222222222222222222222222222222222222222222222222222fc0000000000000000000f22222222222222222222222222222222222222222222222222222222222222222222222222f0000000000000000000cf2222222222222222222222222222222222222222222222222222222222222
-- 107:22222222222222222222222222222222222222222222222222222222222222290000000000000000cf2222222222222222222222222222222222222222222222222222222222222222222222222222fc00000000000000009222222222222222222222222222222222222222222222222222222222222222
-- 108:2222222222222222222222222222222222222222222222222222222222222222fc00000000000000f222222222222222222222222222222222222222222222222222222222222222222222222222222f00000000000000cf2222222222222222222222222222222222222222222222222222222222222222
-- 109:222222222222222222222222222222222222222222222222222222222222222222c000000000000c22222222222222222222222222222222222222222222222222222222222222222222222222222222c000000000000c222222222222222222222222222222222222222222222222222222222222222222
-- 110:222222222222222222222222222222222222222222222222222222222222222222100000000000092222222222222222222222222222222222222222222222222222222222222222222222222222222290000000000001222222222222222222222222222222222222222222222222222222222222222222
-- 111:2222222222222222222222222222222222222222222222222222222222222222221000000000000f2222222222222222222222222222222222222222222222222222222222222222222222222222222210000000000001222222222222222222222222222222222222222222222222222222222222222222
-- 112:222222222222222222222222222222222222222222222222222222222222222222200000000000022222222222222222222222222222222222222222222222222222222222222222222222222222222220000000000002222222222222222222222222222222222222222222222222222222222222222222
-- 113:2222222222222222222222222222222222222222222222222222222222222222222c000000000052222222222222222222222222222222222222222222222222222222222222222222222222222222222c0000000000c2222222222222222222222222222222222222222222222222222222222222222222
-- 114:222222222222222222222222222222222222222222222222222222222222222222290000000000122222222222222222222222222222222222222222222222222222222222222222222222222222222221000000000092222222222222222222222222222222222222222222222222222222222222222222
-- 115:2222222222222222222222222222222222222222222222222222222222222222222100000000c12222222222222222222222222222222222222222222222222222222222222222222222222222222222221c0000000012222222222222222222222222222222222222222222222222222222222222222222
-- 116:22222222222222222222222222222222222222222222222222222222222222222222900c11ff2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222ff11c00922222222222222222222222222222222222222222222222222222222222222222222
-- 117:222222222222222222222222222222222222222222222222222222222222222222222ff22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222ff222222222222222222222222222222222222222222222222222222222222222222222
-- 118:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 119:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 120:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 121:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 122:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 123:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 124:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 125:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 126:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 127:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 128:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 129:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 130:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 131:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 132:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 133:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 134:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 135:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
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

-- <SCREEN6>
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
-- 024:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2f2ffffffffffffffffffffffffffffffffffffffffffffffff222f22ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
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
-- 072:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaafaaffbbfaaffaaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa000000
-- 073:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa9aaaaaaabbbaaa9aaa9ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa0c0000
-- 074:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaa9bbaaaaabbaaaa9aa99fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba000000
-- 075:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9aaabbbabbaaaaaaaaaa99fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba0c0000
-- 076:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa9aaaaaabbbabbaaaaa999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa000000
-- 077:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaaabbbabbbbbbbaaaaaa999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba0c0000
-- 078:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaabbbabbbbbbbaabbbbaa99ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa000000
-- 079:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffabbbabbbbbbbbbabbbbaa9fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba000000
-- 080:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaaabbbbbbbbbbbabbba9ffffffffffffffffffffffffffffffffffffffffffffffffff6665666566656665c665566caa000000
-- 081:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaaabbbabbbbbbaaaabb999fffffffffffffffffffffffffffffffffffffffffffffffff555c555c6c6c555cc55c666caa0c0000
-- 082:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa9bbbaaabbabbabba9a999fffffffffffffffffffffffffffffffffffffffffffffffffffffffff555fffffffccccccaaa0c000
-- 083:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9abbaaaaaabbbabbbacc99ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff66cbaac0000
-- 084:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaaaaaabbbabbaaabbaa99ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff65aaa0c000
-- 085:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaaa9aaabbabaabbaaaaa99ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5baac0000
-- 086:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaa9aaaaabaaaabbb9aaaa99ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaa0c000
-- 087:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff99aaaaaaaaaaaabbaccc999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba000000
-- 088:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff99aacaa999aaacaaac9aaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa000000
-- 089:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff999999ca9aa9aa9caaa9aaafffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa0c0000
-- 090:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9afffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff99999aa99aaa9999caa99aafffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba00c000
-- 091:ffffffffffffffffffffffcccccfffffffffffffffffffffffffffffffffffffffff9ff9aff9ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff99f99aaa99aa99aaccc999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba000000
-- 092:fffffffffffffffffffffc56666cffffffffffffffffffffffffffffffffffffffff99ffaf99ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9999aa9cc999aaacc99ccfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa00c000
-- 093:ffffffffffffffffffffc5656666cfffffffffffffffffffffffffffffffffffffff999ba999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff999f999ccc9959aa999cccfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba0c0000
-- 094:ffffffffffffffffffffc5588886cfffffffffffffffffffffffffffffffffffffff9a9ba999affffffffffffffffffffffffffffffffffffffffffffffffffffffffffff99ffff9cc5995f9999fccffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa00c000
-- 095:ffffffffffffffffffffc588888cffffffffffffffffffffffffffffffffffffffff9aabaa9aafffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6555ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba000000
-- 096:ffffffffffffffffffffc5e8888cfffffffffffffffffffffffffffffffffffff9999aaaaaaaa99fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6766ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa000000
-- 097:ffffffffffffffffffffcee8888c4fffffffffffffffffffffffffffffffffffff9999aabbaa99ffffff4fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7766ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa0c0000
-- 098:fffffffffffffffffffceddeeedec3fffffffffffffffffffffffffffffffffffff99bbbb9a99ffffff323ffffffffffffffffffffffffffffffffffffffffffffbbffffffffffffff7776ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbfffffffaffffffffffffba000000
-- 099:ffffffffffffffffffceeddeeedeec4ffffffffffffffffffffffffffffffffffffaaabba999aaafff24744ffffffffffffffffffffffffffffffffffffffffffafffbbfffffffffff7776fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffafffbbfffbfaffffffbffffba0c0000
-- 100:ffffffffffffffffffc88ddeeed88cfffffbfffffffbfffffffbfffffffbffff9999aaaba99aaafffff323fffffffffffffffffffffffffffffbfffffffffffffaffffafffffffffff7766fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaffffafffffafffffafffffaa000000
-- 101:ffffffffffffffffffc87dddddd78cfffffbfffffffbfffffffbfffffffbfffff9999aaa99aaa999ffff1ffffffffffffaaafffffffffffffffbfffffffffffffaffffaffffffffff777677ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaffffafffffafffffafffffba0c0000
-- 102:fffffffffffffffffffccddccddccffffbfbfbfffbfbfbfffbfbfbfffbfbfbffff999999a999999ffffabffffffffffffaaaabaffffffffffbfbfbfffffffffffafaffafffffffff77766777fffffffffffffffffffffffffffffffffffffffffffffffffffffffffafaffafffff9fffffafafffaa000000
-- 103:fffffffffffffffffffffccffccfaffffafafafffafafafffafafafffafafaffffffff99999999ffffffafffffffffffaaaaaaa9fffffffffafafafffffffffff9f9ff9fffffffff77666677fffffffffffffffffffffffffffffffffffffffffffffffffffffffff9f9ff9fffff9fffff9fafffba000000
-- 104:abaababbabbbabbbaabbabbaabaababbabbbabbbaabbabbaabaababbabbbabbbaabbabbaabaababbabbbabbbaabbabbaabaababbabbbabbbaabbabbaabaababbabbbabbbaabbabbaabaababbaaababaaffffffffffffffffffffffffffffffffffffffffaaaaabababaababbabbbabbbaabbabba99000000
-- 105:aaabaaaaaaaaaaaaabbaabbaaaabaaaaaaaaaaaaabbaabbaaaabaaaaaaaaaaaaabbaabbaaaabaaaaaaaaaaaaabbaabbaaaabaaaaaaaaaaaaabbaabbaaaabaaaaaaaaaaaaabbaabbaaaabaaaababbabaaffffffffffffffffffffffffffffffffffffffffbaaaaaaaaaabaaaaaaaaaaaaabbaabba9a000000
-- 106:aaaaaaaa000000000000aaaaaaaaaaaa000000000000aaaaaaaaaaaa000000000000aaaaaaaaaaaa000000000000aaaaaaaaaaaa000000000000aaaaaaaaaaaa000000000000aaaaaaaaaaaabaaa0aaaffffffffffffffffffffffffffffffffffffffffaaa00000aaaaaaaa000000000000aaaa00000000
-- 107:000000000c0c0c000c000000000000000c0c0c000c000000000000000c0c0c000c000000000000000c0c0c000c000000000000000c0c0c000c000000000000000c0c0c000c00000000000000000000abffffffffffffffffffffffffffffffffffffffffaa000c00000000000c0c0c000c00000000000000
-- 108:00c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c000aa2eee2eee2eee2eee2eee2eee2eee2eee2eee2eeeaa00c0c000c0c0c000c0c0c000c0c0c000000000
-- 109:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c00aaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeba0c000000000000000000000000000000000000
-- 110:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000aaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaa00c00000000000000000000000000000000000
-- 111:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aadedededededededededededededededededededeba00000000000000000000000000000000000000
-- 112:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000abbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaa00000000000000000000000000000000000000
-- 113:000000000000000000000000000000000c000c0000000000000000000000000000000000000000000c000c0000000000000000000000000000000000000000000c000c000000000000000000000c0aabdedededededededededededededededededededeaa0c000000000000000000000000000000000000
-- 114:000000000000000000000000000000000000c0c000000000000000000000000000000000000000000000c0c000000000000000000000000000000000000000000000c0c0000000000000000000c00aaaede2ededede2ededede2ededede2ededede2ededba00000000000000000000000000000000000000
-- 115:0000000000000000000000000000000000000c00000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000c000000000000000000000c0aabdddedddedddedddedddedddedddedddedddedddeba0c000000000000000000000000000000000000
-- 116:00000000000000000000000000000000000000c00000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000c0000000000000000000c00aaae2eded2de2eded2de2eded2de2eded2de2eded2daa00000000000000000000000000000000000000
-- 117:000000000000000000000000000000000c00000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000c0000000000000000000000000c0aaaddddddddddddddddddddddddddddddddddddddddba0c000000000000000000000000000000000000
-- 118:0000000000000000000000000000000000c00000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000c00000000000000000000000c00aaaddddddedddddddedddddddedddddddedddddddedaa00000000000000000000000000000000000000
-- 119:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaddddddddddddddddddddddddddddddddddddddddba00000000000000000000000000000000000000
-- 120:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006666766656665666666666676566566666666667655500000000000000000000000000000000000000
-- 121:00000000000c0c00000000000c000c000000000000000000000c0c00000000000000000000000000000000000000000000000000000c0c000000000000000000000c0c000c0c00000c000c000000005666666666666666666666666666666666666666665600000000000000000c0c000000000000000000
-- 122:0000000000c0c0c0000000000000c0c0000000000000000000c0c0c000000000000500000000000000000000000000000000000000c0c0c0000000000000055000c0c0c0000000000000c0c0000000000566650005666500056665000566650005666500000000000000000000c0c0c00000000000000000
-- 123:000000000c000c000000000000000c0000000000000000000c000c000000000000000000000000000000000000000000000000000c000c0000000000000505500c000c000c00000000000c0000000000500000050000005550000055000000555000005500000000000000000c000c000000000000000000
-- 124:0000000000c0c0c000000000000000c0000000000000000000c0c0c000000000005500000000000000000000000000000000000000c0c0c0000000000000000000c0c0c0000000c0000000c0000000005000000000000005500000550000000550000055000000000000000000c0c0c00000000000000000
-- 125:000000000c0c0c00000000000c00000000000000000000000c0c0c000000000000550050000000000000000000000000000000000c0c0c0000000000000000000c0c0c0000000c000c00000000000000000000000000000000000000000000000000000000000000000000000c0c0c000000000000000000
-- 126:0000000000c000c00000000000c00000000000000000000000c000c000000000000000000000000000000000000000000000000000c000c0000000000005000000c000c00000c0c000c00000000000000000000000000000000000000000000000000000000000000000000000c000c00000000000000000
-- 129:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c0000000000000000000c000c00000c0c000c0c00000c000c000c0c0000000c0c000c0c00000c000c000c000c00000000000000000005550000000c0c00
-- 130:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c0c000000000000000000000c0c000c0c0c0000000000000c0c00000000000c0c0c0000000000000c0c00000c0c000000000000000000555000000c0c0c0
-- 131:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000c00000000000000000000000c000c000c000c00000000000c000c0000000c000c000c00000000000c0000000c000000000000000000056500000c000c00
-- 132:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c0c00000000000000000000000c000c0c0c0000000c0000000c0000000c000c0c0c0000000c0000000c0000000c000000000000000000000000000c0c0c0
-- 133:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c0c0000000000000000000c0000000c0c0c0000000c000c00000000000c000c0c0c0000000c000c0000000c0000000000000000000000000005500c0c0c00
-- 134:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000c0000000000000000000c0000000c000c00000c0c000c000000000c0c000c000c00000c0c000c0000000c0000000000000000000000000055000c000c0
-- </SCREEN6>

-- <SCREEN7>
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
-- 024:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f2f2f2ffffffffffffffffffffffffffffffffffffffffffffffff222f22ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
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
-- 072:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaafaaffbbfaaffaaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa000000
-- 073:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa9aaaaaaabbbaaa9aaa9ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa0c0000
-- 074:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaa9bbaaaaabbaaaa9aa99fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba000000
-- 075:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9aaabbbabbaaaaaaaaaa99fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba0c0000
-- 076:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa9aaaaaabbbabbaaaaa999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa000000
-- 077:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaaabbbabbbbbbbaaaaaa999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba0c0000
-- 078:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaabbbabbbbbbbaabbbbaa99ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa000000
-- 079:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffabbbabbbbbbbbbabbbbaa9fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba000000
-- 080:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaaabbbbbbbbbbbabbba9ffffffffffffffffffffffffffffffffffffffffffffffffff6665666566656665c665566caa000000
-- 081:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaaabbbabbbbbbaaaabb999fffffffffffffffffffffffffffffffffffffffffffffffff555c555c6c6c555cc55c666caa0c0000
-- 082:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa9bbbaaabbabbabba9a999fffffffffffffffffffffffffffffffffffffffffffffffffffffffff555fffffffccccccaaa0c000
-- 083:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9abbaaaaaabbbabbbacc99ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff66cbaac0000
-- 084:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaaaaaabbbabbaaabbaa99ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff65aaa0c000
-- 085:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaaa9aaabbabaabbaaaaa99ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5baac0000
-- 086:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaa9aaaaabaaaabbb9aaaa99ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaa0c000
-- 087:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff99aaaaaaaaaaaabbaccc999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba000000
-- 088:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff99aacaa999aaacaaac9aaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa000000
-- 089:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff999999ca9aa9aa9caaa9aaafffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa0c0000
-- 090:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9afffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff99999aa99aaa9999caa99aafffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba00c000
-- 091:ffffffffffffffffffffffcccccfffffffffffffffffffffffffffffffffffffffff9ff9aff9ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff99f99aaa99aa99aaccc999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba000000
-- 092:fffffffffffffffffffffc56666cffffffffffffffffffffffffffffffffffffffff99ffaf99ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9999aa9cc999aaacc99ccfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa00c000
-- 093:ffffffffffffffffffffc5656666cfffffffffffffffffffffffffffffffffffffff999ba999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff999f999ccc9959aa999cccfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba0c0000
-- 094:ffffffffffffffffffffc5588886cfffffffffffffffffffffffffffffffffffffff9a9ba999affffffffffffffffffffffffffffffffffffffffffffffffffffffffffff99ffff9cc5995f9999fccffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa00c000
-- 095:ffffffffffffffffffffc588888cffffffffffffffffffffffffffffffffffffffff9aabaa9aafffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6555ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffba000000
-- 096:ffffffffffffffffffffc5e8888cfffffffffffffffffffffffffffffffffffff9999aaaaaaaa99fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6766ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa000000
-- 097:fffffffffffffffffffceee8888ecfffffffffffffffffffffffffffffffffffff9999aabbaa99ffffff4fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7766ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa0c0000
-- 098:ffffffffffffffffffceeddeeedeecfffffffffffffffffffffffffffffffffffff99bbbb9a99ffffff323ffffffffffffffffffffffffffffffffffffffffffffbbffffffffffffff7776ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbfffffffaffffffffffffba000000
-- 099:ffffffffffffffffffc88ddeeed88c4ffffffffffffffffffffffffffffffffffffaaabba999aaafff24744ffffffffffffffffffffffffffffffffffffffffffafffbbfffffffffff7776fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffafffbbfffbfaffffffbffffba0c0000
-- 100:ffffffffffffffffffc87ddeeed78cfffffbfffffffbfffffffbfffffffbffff9999aaaba99aaafffff323fffffffffffffffffffffffffffffbfffffffffffffaffffafffffffffff7766fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaffffafffffafffffafffffaa000000
-- 101:fffffffffffffffffffccddddddccffffffbfffffffbfffffffbfffffffbfffff9999aaa99aaa999ffff1ffffffffffffffffffffffffffffffbfffffffffffffaffffaffffffffff777677ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaffffafffffafffffafffffba0c0000
-- 102:ffffffffffffffffffffcddccddcbffffbfbfbfffbfbfbfffbfbfbfffbfbfbffff999999a999999ffffabffffffffffffffffffffffffffffbfbfbfffffffffffafaffafffffffff77766777fffffffffffffffffffffffffffffffffffffffffffffffffffffffffafaffafffff9fffffafafffaa000000
-- 103:fffffffffffffffffffffccffccfaffffafafafffafafafffafafafffafafaffffffff99999999ffffffaffffffffffffffffffffffffffffafafafffffffffff9f9ff9fffffffff77666677fffffffffffffffffffffffffffffffffffffffffffffffffffffffff9f9ff9fffff9fffff9fafffba000000
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
-- 128:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003ffffff3
-- 129:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c0000000000000000000c000c00000c0c000c0c00000c000c000c0c0000000c0c000c0c00000c000c000c000c00000000000000000005550000f3ffff3f
-- 130:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c0c000000000000000000000c0c000c0c0c0000000000000c0c00000000000c0c0c0000000000000c0c00000c0c0000000000000000005550000ff3ff3ff
-- 131:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000c00000000000000000000000c000c000c000c00000000000c000c0000000c000c000c00000000000c0000000c00000000000000000005650000fff33fff
-- 132:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c0c00000000000000000000000c000c0c0c0000000c0000000c0000000c000c0c0c0000000c0000000c0000000c0000000000000000000000000fff33fff
-- 133:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c0c0000000000000000000c0000000c0c0c0000000c000c00000000000c000c0c0c0000000c000c0000000c000000000000000000000000000550ff3ff3ff
-- 134:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000c0000000000000000000c0000000c000c00000c0c000c000000000c0c000c000c00000c0c000c0000000c00000000000000000000000000550f3ffff3f
-- 135:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003ffffff3
-- </SCREEN7>

-- <PALETTE>
-- 000:0000009d9d9dffffffbe2633e06f8b493c2ba46422eb8931f7e26b2f484e44891aa3ce271b263200578431a2f2b2dcef
-- </PALETTE>

-- <PALETTE1>
-- 000:0000009d9d9dffffffbe2633e06f8b493c2ba46422eb8931f7e26b2f484e44891aa3ce271b263200578431a2f2b2dcef
-- </PALETTE1>

-- <PALETTE2>
-- 000:0000009d9d9dffffffbe2633e06f8b493c2ba46422eb8931f7e26b2f484e44891aa3ce271b263200578431a2f2b2dcef
-- </PALETTE2>

-- <PALETTE6>
-- 000:0000009d9d9dffffffbe2633e06f8b493c2ba46422eb8931f7e26b2f484e44891aa3ce271b263200578431a2f2b2dcef
-- </PALETTE6>

-- <PALETTE7>
-- 000:0000009d9d9dffffffbe2633e06f8b493c2ba46422eb8931f7e26b2f484e44891aa3ce271b263200578431a2f2b2dcef
-- </PALETTE7>

