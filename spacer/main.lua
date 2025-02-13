function _init()
    monster_count=7
    tick=0
    last_shot=0
    shot_delay=15
    min_x=0
    max_x=127-8
    bullet_speed=4
    bullet_color=8
    ship_gun_offset=3
    max_bullets = 2
    states={play="play",gameover_loser="gameover_loser",gameover_winner="gameover_winner",start="start"}
    star_count=200
    state=states.start
    reset()
end

function reset()
    ship={x=64,y=(127-16),xspeed=2, sprite=32, h=8, w=8}
    monsters={}
    stars={}
    bullets={}
    bombs={}
    ship_particles={}
    populate_monsters(4, 4, 8, 24, 12)
    populate_stars()
end

function populate_stars()
    for i=0,star_count do
        star = {x=flr(rnd(127)), y=flr(rnd(127)), yspeed=rnd(0.5)+0.5}
        add(stars, star)
    end
end

function _update()
    if state == states.play then
        tick += 1
        --left
        if btn(0) then
            if ship.x >= min_x+ship.xspeed then
                ship.x -= ship.xspeed
            end
        --right
        elseif btn(1) then
            if ship.x <= max_x+ship.xspeed then
                ship.x += ship.xspeed
            end
        end
        --allow for moving and firing at same time
        if btn(4) then
            add_bullet()
        end

        update_monsters()
        update_ship()
        update_bullets()
        update_bombs()
        update_stars()
        update_ship_particles()
        --check end state
        if #monsters == 0 then
            state = states.gameover_winner
        end
    elseif state == states.gameover_winner or state == states.gameover_loser then
        update_stars()
        if btn(5) then
            reset()
            state = states.play
            sfx(2)
        end

    elseif state == states.start then
        update_stars()
        if btn(5) then
            reset()
            state = states.play
            sfx(2)
        end
    end
end

function update_ship_particles()
    for p in all(ship_particles) do
        p.y+=p.yspeed
        p.x+=p.xspeed
        p.ttl-=1
        if p.ttl <= 0 then
            destroy_ship_particle(p)
        end
    end
end

function destroy_ship_particle(p)
    del(ship_particles, p)
end

function update_ship()
local x_offset, y_offset = ship.x+4, ship.y+6
particle={x=x_offset, y=y_offset, color=10, ttl=10, xspeed=rand_range(0.1), yspeed=rnd(1)}
add(ship_particles, particle)

end


function _draw()
    cls()
    draw_stars()
    if state == states.play then
        spr(ship.sprite,ship.x,ship.y)
        for m in all(monsters) do
                spr(m.sprite, m.x, m.y)
        end
        draw_bullets()
        draw_bombs()
        draw_ship_particles()

    elseif state == states.gameover_loser then
        print("a loser is you", 38, 64, 8)
        print("press x to restart", 34, 72, 8)

    elseif state == states.gameover_winner then
        print("a winner is you", 42, 64, 8)
        print("press x to restart", 34, 72, 8)

    elseif state == states.start then
        print("press x to start", 34, 64, 8)

    end
end

function draw_bullets()
        for b in all(bullets) do
            spr(16, b.x, b.y)
            if tick % 5 == 0 then
                --offset using the heigth and width to center
                circ(b.x+b.w/2, b.y+b.h/2, 4, 7)
            end
        end
end

function draw_ship_particles()
    for p in all(ship_particles) do
        if p.ttl >=2 then
            pset(p.x, p.y, p.color)
        else
            pset(p.x, p.y, p.color-1)
        end
    end
end

function draw_bombs()
    for b in all(bombs) do
            spr(17, b.x, b.y)
            if tick % 10 == 0 then
                --offset using the heigth and width to center
                circ(b.x+b.w/2, b.y+b.h/2, 2, 9)
            end
    end
end

function draw_stars()
    for s in all(stars) do
        if s.yspeed <0.7 then
            pset(s.x, s.y, 1)
        else
            pset(s.x, s.y, 6)
        end
    end
end

function add_bullet()
    if #bullets < max_bullets and tick-last_shot >= shot_delay then
        --y is the max minus sprite height
        local b={x=ship.x+ship_gun_offset, y=127-8, sprite=16, h=4, w=4}
        last_shot=tick
        add(bullets, b)
        sfx(1)
    end
end

function add_bomb(start_x, start_y)
    b={x=start_x, y=start_y, yspeed=1.5, h=3, w=3, sprite=17}
    add(bombs, b)
end

function update_bombs()
    for b in all(bombs) do
        b.y += b.yspeed
        if check_pixel_collision(b, ship) then
            hit_ship()
            destroy_bomb(b)
            break -- stop checking once we hit
        end

        if b.y > 127 then
            destroy_bomb(b)
        end
    end
end

function hit_ship()
    state = states.gameover_loser
end

function update_stars()
    for s in all(stars) do
        s.y += s.yspeed
        if s.y > 127 then
            s.y = 0
        end
    end
end

function update_monsters()

    local rows = {}

    for m in all(monsters) do
        if not rows[m.y] then
            rows[m.y] = {} -- Create a new row group if it doesn't exist
        end
        add(rows[m.y], m) -- Add monster to its respective row
    end

        -- Step 2: Process each row independently
        for y_value, row in pairs(rows) do
            local leftmost = 128
            local rightmost = 0
    
            -- Find leftmost and rightmost monster positions in the row
            for m in all(row) do
                leftmost = min(leftmost, m.x)
                rightmost = max(rightmost, m.x)
            end
    
            -- Reverse direction if the row reaches screen edges
            if rightmost >= 120 or leftmost <= 0 then
                for m in all(row) do
                    m.direction *= -1
                end
            end
    
            -- Move all monsters in the row
            for m in all(row) do
                m.x += m.xspeed * m.direction
            end
        end

    --shooting
    for m in all(monsters) do
        if tick % m.tts == 0 and abs(ship.x - m.x) <= 15 then
            add_bomb(m.x, m.y)
        end
    end
end


function destroy_monster(m)
    del(monsters, m)
    sfx(0)
end

function destroy_bullet(b)
   del(bullets, b) 
end

function destroy_bomb(b)
   del(bombs, b) 
end

function populate_monsters(n_rows, y_cols, start_y, spacing_x, spacing_y)
    -- Calculate centered starting X position
    local total_width = (y_cols - 1) * spacing_x
    local start_x = (128 - total_width) / 2

    for row=0, n_rows-1 do
        local row_direction = (row % 2 == 0) and 1 or -1
        for col=0, y_cols-1 do
            local x = start_x + col * spacing_x
            local y = start_y + row * spacing_y
            
            local time_to_shoot = flr(rnd(60)+30)
            add(monsters, {x=x, y=y, sprite=1, xspeed=1, yspeed=0, direction=row_direction, tts=time_to_shoot, h=8, w=8})
        end
    end
end

function update_bullets()
    for b in all(bullets) do
        b.y -= bullet_speed

        for m in all(monsters) do
            if check_pixel_collision(b, m) then
                                destroy_monster(m)
                                destroy_bullet(b)
                                goto next_bullet -- Exit both loops
            end
        end
        ::next_bullet::
        
        -- Remove bullets that go off-screen
        if b.y < 0 then
            del(bullets, b)
        end
    end
end


function check_pixel_collision(obj1, obj2)
    -- Fast rejection: Bounding box collision check
    if not aabb_collision(obj1.x, obj1.y, obj1.w, obj1.h, obj2.x, obj2.y, obj2.w, obj2.h) then
        return false
    end

    -- Get sprite positions in the spritesheet
    local obj1_sx, obj1_sy = (obj1.sprite % 16) * 8, flr(obj1.sprite / 16) * 8
    local obj2_sx, obj2_sy = (obj2.sprite % 16) * 8, flr(obj2.sprite / 16) * 8

    -- Determine overlapping region
    local x_start, x_end = max(obj1.x, obj2.x), min(obj1.x + obj1.w, obj2.x + obj2.w)
    local y_start, y_end = max(obj1.y, obj2.y), min(obj1.y + obj1.h, obj2.y + obj2.h)

    -- Loop through overlapping pixels
    for px = x_start, x_end - 1 do
        for py = y_start, y_end - 1 do
            -- Local pixel positions within each sprite
            local obj1_px, obj1_py = px - obj1.x, py - obj1.y
            local obj2_px, obj2_py = px - obj2.x, py - obj2.y

            -- Fetch pixel colors only if inside 8x8 sprite bounds
            if obj1_px < 8 and obj1_py < 8 and obj2_px < 8 and obj2_py < 8 then
                if sget(obj1_sx + obj1_px, obj1_sy + obj1_py) != 0 and
                   sget(obj2_sx + obj2_px, obj2_sy + obj2_py) != 0 then
                    return true -- Collision detected, exit early
                end
            end
        end
    end

    return false -- No pixel collision
end



function aabb_collision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
           x1 + w1 > x2 and
           y1 < y2 + h2 and
           y1 + h1 > y2
end

function rand_range(max)
    val = rnd()*max
    if rnd() >= 0.5 then return val else return -val end
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