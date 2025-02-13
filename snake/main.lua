function _init() 
snake = {{x=64,y=64}}
powerup = spawn_powerup()
lastdir={x=0,y=0}
step=0
speed=5
snake_length=1
pending_growth=0
anim_timer = 0       -- counts frames for timing the animation
anim_frame = 0       -- 0 or 1, used to choose sprite 44 or 45
state="play"
sfx(3)
end

function spawn_powerup()
  -- there are 16 grid cells (0 to 15) along each axis, we'll add one
  local grid_cells = 14
  
  -- generate a random grid coordinate (0 through 15)
  local tile_x = flr(rnd(grid_cells))
  local tile_y = flr(rnd(grid_cells))
  
  -- convert the grid coordinates to pixel coordinates by multiplying by 8
  local x = (tile_x+1) * 8
  local y = (tile_y+1) * 8

  --don't spawn on the snake body
  for i, p in ipairs(snake) do
	if p.x/8 == tile_x+1 and p.y/8 == tile_y+1 then
		return spawn_powerup()
	end
  end
  
  return { x = x, y = y }
end

function update_fire()
 -- Update the fire animation timer:
 anim_timer += 1
 -- Toggle every X frames (adjust as needed for your desired speed)
 if anim_timer >= 10 then
   anim_timer = 0
   anim_frame = (anim_frame + 1) % 2  -- toggles between 0 and 1
 end
end

function update_snake()
	local head = snake[#snake]
	local new_head = { x = head.x + lastdir.x, y = head.y + lastdir.y }
	--dot check
	if new_head.x == powerup.x and new_head.y == powerup.y then
		pending_growth+=3
		sfx(1)
		powerup = spawn_powerup()
	--check collision with border
	elseif fget(mget(new_head.x/8, new_head.y/8), 0) then
		state="gameover"
		sfx(2)
		return
	--check collision with self
	elseif lastdir.x != 0 or lastdir.y != 0 then
		for i, p in ipairs(snake) do
			if p.x == new_head.x and p.y == new_head.y then
				state="gameover"
				sfx(2)
				return
			end
		end
	end
	

	add(snake, new_head)
	if pending_growth >1 then
		pending_growth -= 1
	else
		del(snake, snake[1])
	end
end

function _update()
	if state == "play" then
	step+=1
	--movement
	if btn(⬅️) and (#snake == 1 or lastdir.x ~= 8) then
		lastdir={x=-8,y=0}
	elseif btn(➡️) and (#snake == 1 or lastdir.x ~= -8) then
		lastdir={x=8,y=0}
	elseif btn(⬆️) and (#snake == 1 or lastdir.y ~= 8) then 
		lastdir={x=0,y=-8}
	elseif btn(⬇️) and (#snake == 1 or lastdir.y ~= -8) then 
		lastdir={x=0,y=8}
	end

	
	if step%speed == 0 then
	update_snake()
	update_fire()
	end
	elseif state == "gameover" then
		if btn(4) then
			_init()
		end
	end
end


function _draw()
	cls()
	if state == "gameover" then
		--print("fire bad", 52,50)
		spr(4,64,55)	
		print("game over", 50,64)
		print("score: "..#snake, 50, 72)
		print("press button O to restart", 20, 80)
	elseif state == "play" then
	map()
	for i, segment in ipairs(snake) do
		spr(1,segment.x,segment.y)
	end
	spr(3,powerup.x,powerup.y)
	local fire_sprite = 48 + anim_frame  -- 44 or 45 depending on anim_frame

	-- Top border (row 0) and bottom border (row 15)
	for tile_x=0,15 do
	  local x = tile_x * 8
	  spr(fire_sprite, x, 0)      -- top row
	  spr(fire_sprite, x, 120)    -- bottom row (15*8 = 120)
	end
  
	-- Left border (column 0) and right border (column 15)
	-- Avoid redrawing the corners since they're already drawn above.
	for tile_y=1,14 do
	  local y = tile_y * 8
	  spr(fire_sprite, 0, y)      -- left column
	  spr(fire_sprite, 120, y)    -- right column (15*8 = 120)
	end
	end
end
-->8
-- pq-debugging, by pancelor

-- quotes all args and prints to host console
-- usage:
--   pq("handles nils", many_vars, {tables=1, work=11, too=111})
function pq(...)
  printh(qq(...))
  return ...
end

-- quotes all arguments into a string
-- usage:
--   ?qq("p.x=",x,"p.y=",y)
function qq(...)
  local args=pack(...)
  local s=""
  for i=1,args.n do
    s..=quote(args[i]).." "
  end
  return s
end

-- quote a single thing
-- like tostr() but for tables
-- don't call this directly; call pq or qq instead
function quote(t, depth)
  depth=depth or 4 --avoid inf loop
  if type(t)~="table" or depth<=0 then return tostr(t) end

  local s="{"
  for k,v in pairs(t) do
    s..=tostr(k).."="..quote(v,depth-1)..","
  end
  return s.."}"
end

-- like sprintf (from c)
-- usage:
--   ?qf("%/% is %%",3,8,3/8*100,"%")
function qf(fmt,...)
  local parts,args=split(fmt,"%"),pack(...)
  local str=deli(parts,1)
  for ix,pt in ipairs(parts) do
    str..=quote(args[ix])..pt
  end
  if args.n~=#parts then
    -- uh oh! mismatched arg count
    str..="(extraqf:"..(args.n-#parts)..")"
  end
  return str
end
function pqf(...) printh(qf(...)) end
