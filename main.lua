local sw, sh = love.graphics.getDimensions()

local function mouse_get_position_flipped()
    local mx, my = love.mouse.getPosition()
    return mx, sh - my
end

local function graphics_print_flipped(text, x, y)
    love.graphics.print(text, x, y, 0, 1, -1)
end

local function graphics_draw_flipped(drawable, x, y)
    love.graphics.draw(drawable, x, y, 0, 1, -1)
end

local function graphics_rectangle(mode, x, y, w, h, rx)
    love.graphics.rectangle(mode, x, y-h, w, h, rx)
end

love.graphics.setDefaultFilter("nearest", "nearest")

local point_size = 30
local camera_x = -10
local camera_y = -10

local function coord_to_screen(cx, cy)
    local sx = (cx - camera_x) * point_size
    local sy = (cy - camera_y) * point_size
    return sx, sy
end

local function screen_to_coord(sx, sy)
    local cx = sx / point_size + camera_x
    local cy = sy / point_size + camera_y
    return cx, cy
end

local function screen_to_coord_int(sx, sy)
    local cx, cy = screen_to_coord(sx, sy)
    return math.floor(cx), math.floor(cy)
end

local function coord_to_screen_point(cx, cy)
    local sx, sy = coord_to_screen(cx, cy)
    return sx + point_size / 2, sy + point_size / 2
end

local primes = {}
local squares = {}
for i = 2, 10000 do
    for j = 1, #primes do
        if i % primes[j] == 0 then goto not_prime end
    end
    table.insert(primes, i)
    local sq = {}
    for j = 0, i-1 do
        table.insert(sq, false)
    end
    for j = 0, i-1 do
        sq[j*j % i] = true
    end
    table.insert(squares, sq)
    ::not_prime::
end

local function factor(n)
    if n == 0 then error() end
    if n == 1 then return {} end
    local negative = (n < 0)
    if negative then n = -n end
    local factors = {0}
    local i = 1
    local p = primes[i]
    while n > 1 do
        if n % p == 0 then
            n = n / p
            factors[i] = factors[i] + 1
        else
            i = i + 1
            p = primes[i]
            factors[i] = 0
        end
    end
    return factors
end

local function remove_square(n)
    if n == 0 then return 0 end
    local negative = (n < 0)
    if negative then n = -n end
    local i = 1
    local p = primes[i]
    local e = 0
    local m = n
    while m > 1 do
        if m % p == 0 then
            m = m / p
            e = e + 1
            if e == 2 then
                n = n / (p*p)
                e = e - 2
            end
        else
            i = i + 1
            p = primes[i]
            e = 0
        end
    end
    if negative then n = -n end
    return n
end

local function valuation_residue(n, i)
    local p = primes[i]
    local v = 0
    local negative = (n < 0)
    if negative then n = -n end
    while n % p == 0 do
        v = v + 1
        n = n / p
    end
    n = n % p
    if negative then n = p - n end
    return v, n
end

local function splits(a, b, i)
    local p = primes[i]
    local va, ra = valuation_residue(a, i)
    local vb, rb = valuation_residue(b, i)
    if va == 0 and vb == 0 then return false
    elseif va == vb then return not squares[i][p - ((ra * rb) % p)]
    elseif va < vb then return not squares[i][ra]
    elseif va > vb then return not squares[i][rb] end
end

local data = {}

local function get_data(a, b)
    if data[a] == nil then data[a] = {} end
    if data[a][b] ~= nil then return data[a][b]
    else data[a][b] = {} end
    
    if a == 0 or b == 0 then
        table.insert(data[a][b], -1)
        return data[a][b]
    end
    if b > a then
        data[a][b] = get_data(b, a)
        return data[a][b]
    end
    local a2, b2 = remove_square(a), remove_square(b)
    if a2 ~= a or b2 ~= b then
        data[a][b] = get_data(a2, b2)
        return data[a][b]
    end

    if a < 0 and b < 0 then table.insert(data[a][b], 0) end

    local i = 2
    while primes[i] <= math.abs(a) or primes[i] <= math.abs(b) do
        if splits(a, b, i) then table.insert(data[a][b], i) end
        i = i + 1
    end

    if #data[a][b] % 2 == 1 then
        table.insert(data[a][b], 1)
        table.sort(data[a][b])
    end

    return data[a][b]
end

local function data_has(a, b, j)
    local d = get_data(a, b)
    for i = 1, #d do
        if j == d[i] then return true end
        if j < d[i] then return false end
    end
end

local function data_to_string(d)
    if #d == 0 then return "" end
    local str = ""
    local m = d[#d]
    local j = 1
    for i = -1, m do
        if i < d[j] then
            str = str .. "0"
        else
            str = str .. "1"
            j = j + 1
        end
    end
    return str
end

local colors = require "color"

local data_color = {}
local str_color = {
    [""] = {0, 0, 0},
    ["1"] = {1, 1, 1},
}

local function get_color(a, b)
    if b > a then a, b = b, a end
    if data_color[a] == nil then data_color[a] = {} end
    if data_color[a][b] ~= nil then return data_color[a][b] end

    local str = data_to_string(get_data(a, b))
    if str_color[str] == nil then
        if #colors > 0 then
            str_color[str] = colors[1]
            table.remove(colors, 1)
        else
            str_color[str] = {love.math.random(), love.math.random(), love.math.random()}
        end
    end
    data_color[a][b] = str_color[str]
    return data_color[a][b]
end

-- https://stackoverflow.com/questions/3407942/rgb-values-of-visible-spectrum
local function spectral_color(l)
    local t
    local r, g, b = 0, 0, 0
        if ((l>=400.0)and(l<410.0)) then t=(l-400.0)/(410.0-400.0); r=     (0.33*t)-(0.20*t*t)
    elseif ((l>=410.0)and(l<475.0)) then t=(l-410.0)/(475.0-410.0); r=0.14         -(0.13*t*t)
    elseif ((l>=545.0)and(l<595.0)) then t=(l-545.0)/(595.0-545.0); r=     (1.98*t)-(     t*t)
    elseif ((l>=595.0)and(l<650.0)) then t=(l-595.0)/(650.0-595.0); r=0.98+(0.06*t)-(0.40*t*t)
    elseif ((l>=650.0)and(l<700.0)) then t=(l-650.0)/(700.0-650.0); r=0.65-(0.84*t)+(0.20*t*t) end
        if ((l>=415.0)and(l<475.0)) then t=(l-415.0)/(475.0-415.0); g=              (0.80*t*t)
    elseif ((l>=475.0)and(l<590.0)) then t=(l-475.0)/(590.0-475.0); g=0.8 +(0.76*t)-(0.80*t*t)
    elseif ((l>=585.0)and(l<639.0)) then t=(l-585.0)/(639.0-585.0); g=0.84-(0.84*t)            end
        if ((l>=400.0)and(l<475.0)) then t=(l-400.0)/(475.0-400.0); b=     (2.20*t)-(1.50*t*t)
    elseif ((l>=475.0)and(l<560.0)) then t=(l-475.0)/(560.0-475.0); b=0.7 -(     t)+(0.30*t*t) end
    local n = math.sqrt(r^2 + g^2 + b^2)
    -- local n = 1
    return {r/n, g/n, b/n}
end

local function prime_color(i)
    if i == - 1 then return {1, 1, 1}
    elseif i == 0 then return {0, 0, 0}
    else
        local a = 660
        local b = 2000
        local c = 7
        return spectral_color(a - b/(i+c))
        -- return spectral_color(700 - 500/(i+2))
    end
end

local function color2(a, b)
    local d = get_data(a, b)
    local cs = {}
    for i = 1, #d do
        table.insert(cs, prime_color(d[i]))
    end
    local r, g, b = 0, 0, 0
    for i = 1, #cs do
        r = r + cs[i][1]^2
        g = g + cs[i][2]^2
        b = b + cs[i][3]^2
    end
    r = math.sqrt(r)-- / #cs)
    g = math.sqrt(g)-- / #cs)
    b = math.sqrt(b)-- / #cs)
    return {r, g, b}
end

local function data_print(a, b)
    local d = get_data(a, b)
    if #d == 0 then return "trivial" end
    local str = ""
    for _, v in ipairs(d) do
        local word
        if v == -1 then word = "degenerate"
        elseif v == 0 then word = "imaginary"
        else word = primes[v] end
        str = str .. word .. ", "
    end
    return str:sub(1, -3)
end

local dt
function love.update(_dt)
    dt = _dt
    if love.keyboard.isDown("escape") then
        love.event.quit()
    end
end

local show_mode = 1
local first_mode = 1
function love.keypressed(key, scancode, isrepeat)
    if key == "1" then
        show_mode = 1
    elseif key == "2" then
        show_mode = 2
    elseif key == "3" then
        show_mode = 3
    elseif key == "4" then
        show_mode = 4
    elseif key == "q" then
        first_mode = first_mode - 1
    elseif key == "w" then
        first_mode = first_mode + 1
    end
end

function love.wheelmoved(x, y)
    local mx, my = mouse_get_position_flipped()
    
    camera_x = camera_x + mx / point_size
    camera_y = camera_y + my / point_size

    point_size = point_size + y
    if point_size < 3 then point_size = 3 end

    local cx, cy = screen_to_coord(mx, my)
    camera_x = camera_x - mx / point_size
    camera_y = camera_y - my / point_size
end

function love.mousemoved(x, y, dx, dy, istouch)
    if love.mouse.isDown(1) then
        camera_x = camera_x - dx / point_size
        camera_y = camera_y + dy / point_size
    end
end

local font = love.graphics.newFont(20)
love.graphics.setFont(font)

local flipped = love.graphics.newCanvas(sw, sh)
local text = love.graphics.newText(font)

local transform = love.math.newTransform()

function love.draw()
    love.graphics.setCanvas(flipped)
    love.graphics.clear()

    transform:setTransformation(
        -camera_x*point_size + point_size / 2,
        -camera_y*point_size + point_size / 2,
        0,
        point_size,
        point_size
    )
    love.graphics.replaceTransform(transform)

    do
        local mx, my = mouse_get_position_flipped()
        local cx, cy = screen_to_coord_int(mx, my)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setPointSize(point_size+1)
        love.graphics.points(cx, cy)
    end

    do
        local points = {}
        local x0, y0 = screen_to_coord_int(0, 0)
        local x1, y1 = screen_to_coord_int(sw, sh)
        for x = x0, x1 do
            for y = y0, y1 do

                local black = {0, 0, 0, 1}
                local white = {1, 1, 1, 1}
                local c = black
                if show_mode == 2 then
                    if data_has(x, y, first_mode) then
                        -- c = white
                        c = prime_color(first_mode)
                    end
                elseif show_mode == 1 then
                    c = get_color(x, y)
                elseif show_mode == 4 then
                    local n = #get_data(x, y)
                    c = {n / 8, n / 8, n / 8}
                elseif show_mode == 3 then
                    c = color2(x, y)
                end

                table.insert(points, {
                    x,
                    y,
                    c[1],
                    c[2],
                    c[3],
                    1
                })
            end
        end
        love.graphics.setPointSize(point_size-1)
        love.graphics.points(points)
    end

    love.graphics.origin()

    do
        local mx, my = mouse_get_position_flipped()

        local cx, cy = screen_to_coord_int(mx, my)
        text:setf(cx .. ", " .. cy, 1000, "left")
        local width = text:getWidth()
        local height = text:getHeight()
        local x = mx+10
        local y = my-10
        love.graphics.setColor(0, 0, 0, 0.8)
        graphics_rectangle("fill", x, y, width, height, 2)
        love.graphics.setColor(1, 1, 1)
        graphics_draw_flipped(text, x, y)

        local cx, cy = screen_to_coord_int(mx, my)
        text:setf(data_print(cx, cy), 1000, "left")
        local width = text:getWidth()
        local height = text:getHeight()
        local x = mx+10
        local y = my-35
        love.graphics.setColor(0, 0, 0, 0.8)
        graphics_rectangle("fill", x, y, width, height, 2)
        love.graphics.setColor(1, 1, 1)
        graphics_draw_flipped(text, x, y)
    end

    love.graphics.setCanvas()
    love.graphics.draw(flipped, 0, sh, 0, 1, -1)
end