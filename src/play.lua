local game = require("game")
local time = require("time")
local channel = require("channel")
local io = require("io")

local ESC = "\027["
local CLEAR = ESC .. "2J"
local HOME = ESC .. "H"
local HIDE_CURSOR = ESC .. "?25l"
local SHOW_CURSOR = ESC .. "?25h"

local function color(fg, bg)
    local s = ""
    if fg then s = s .. ESC .. "38;2;" .. fg .. "m" end
    if bg then s = s .. ESC .. "48;2;" .. bg .. "m" end
    return s
end
local RESET = ESC .. "0m"
local DIM = ESC .. "2m"
local BOLD = ESC .. "1m"

local HEAD = color("0;0;0", "50;255;50") .. "@@" .. RESET
local BODY = color("0;0;0", "0;200;0") .. "()" .. RESET
local FOOD = color("255;255;255", "255;50;50") .. BOLD .. "<>" .. RESET
local EMPTY = DIM .. color("40;40;50") .. ". " .. RESET
local BORDER_COLOR = color("100;255;100")

local function goto_xy(x, y) return ESC .. y .. ";" .. x .. "H" end

local function render(g, w, h)
    local bx, by = 3, 2

    io.write(goto_xy(bx - 1, by - 1) .. BORDER_COLOR .. "+" .. string.rep("--", w) .. "+" .. RESET)

    for y = 1, h do
        io.write(goto_xy(bx - 1, by + y - 1) .. BORDER_COLOR .. "|" .. RESET)
        for x = 1, w do
            local c = g:get_cell(x, y)
            if c == "head" then io.write(HEAD)
            elseif c == "body" then io.write(BODY)
            elseif c == "food" then io.write(FOOD)
            else io.write(EMPTY) end
        end
        io.write(BORDER_COLOR .. "|" .. RESET)
    end

    io.write(goto_xy(bx - 1, by + h) .. BORDER_COLOR .. "+" .. string.rep("--", w) .. "+" .. RESET)

    local ix = bx + w * 2 + 3
    io.write(goto_xy(ix, by) .. color("100;255;100") .. BOLD .. "SNAKE" .. RESET)
    io.write(goto_xy(ix, by + 2) .. "Score: " .. BOLD .. g.score .. RESET)
    io.write(goto_xy(ix, by + 3) .. "Length: " .. #g.snake)
    local el = math.floor(g:elapsed())
    io.write(goto_xy(ix, by + 4) .. string.format("Time: %02d:%02d", math.floor(el/60), el%60))
    io.write(goto_xy(bx, by + h + 2) .. DIM .. "WASD/Arrows: Move  Q: Quit  R: Restart" .. RESET)
end

local function read_key()
    local ch = io.read(1)
    if not ch then return nil end
    if ch == "\027" then
        local b1 = io.read(1)
        if b1 == "[" then
            local b2 = io.read(1)
            if b2 == "A" then return "up" end
            if b2 == "B" then return "down" end
            if b2 == "C" then return "right" end
            if b2 == "D" then return "left" end
        end
        return nil
    end
    if ch == "\r" or ch == "\n" then return nil end
    return ch
end

local function main()
    math.randomseed(time.now():unix_nano())
    local args = io.args()
    local w = tonumber(args[1]) or 40
    local h = tonumber(args[2]) or 20
    local g = game.new(w, h)

    io.raw(true)
    io.write(HIDE_CURSOR .. CLEAR .. HOME)
    io.flush()

    local input_ch = channel.new(1)
    coroutine.spawn(function()
        while true do
            local k = read_key()
            if k then input_ch:send({ key = k }) end
        end
    end)

    local running = true
    while running do
        render(g, w, h)
        io.flush()

        if g.game_over then
            local cy = 2 + math.floor(h / 2)
            io.write(goto_xy(3 + w - 6, cy) .. color("255;255;255", "200;0;0") .. BOLD .. "  GAME OVER  " .. RESET)
            io.write(goto_xy(3 + w - 6, cy + 1) .. color("255;255;255", "80;80;80") .. " R:Restart Q:Quit " .. RESET)
            io.flush()
            while running and g.game_over do
                local msg = input_ch:receive()
                local k = msg and msg.key
                if k == "q" then running = false
                elseif k == "r" then g:reset() io.write(CLEAR .. HOME) end
            end
        else
            local tick = time.after("120ms")
            local res = channel.select { input_ch:case_receive(), tick:case_receive() }
            if res.channel == tick then
                g:tick()
            else
                local k = res.value and res.value.key
                if k then k = k:lower() end
                if k == "q" then running = false
                elseif k == "up" or k == "w" then if g:set_direction("UP") then g:tick() end
                elseif k == "down" or k == "s" then if g:set_direction("DOWN") then g:tick() end
                elseif k == "left" or k == "a" then if g:set_direction("LEFT") then g:tick() end
                elseif k == "right" or k == "d" then if g:set_direction("RIGHT") then g:tick() end
                elseif k == "r" then g:reset() io.write(CLEAR .. HOME) end
            end
        end
    end

    io.raw(false)
    io.write(SHOW_CURSOR .. CLEAR .. HOME)
    io.flush()
end

return { main = main }
