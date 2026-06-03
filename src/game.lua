local time = require("time")

local DIRECTIONS = {
    UP = { x = 0, y = -1 },
    DOWN = { x = 0, y = 1 },
    LEFT = { x = -1, y = 0 },
    RIGHT = { x = 1, y = 0 }
}

local Game = {}
Game.__index = Game

local function new(width, height)
    local self = setmetatable({
        width = width or 20,
        height = height or 15,
        snake = {},
        direction = DIRECTIONS.RIGHT,
        next_direction = DIRECTIONS.RIGHT,
        food = nil,
        score = 0,
        game_over = false,
        started_at = nil
    }, Game)
    self:reset()
    return self
end

function Game:reset()
    local cx = math.floor(self.width / 2)
    local cy = math.floor(self.height / 2)
    self.snake = {
        { x = cx, y = cy },
        { x = cx - 1, y = cy },
        { x = cx - 2, y = cy }
    }
    self.direction = DIRECTIONS.RIGHT
    self.next_direction = DIRECTIONS.RIGHT
    self.score = 0
    self.game_over = false
    self.started_at = time.now()
    self:spawn_food()
end

function Game:spawn_food()
    for _ = 1, self.width * self.height do
        local x = math.random(1, self.width)
        local y = math.random(1, self.height)
        local ok = true
        for _, s in ipairs(self.snake) do
            if s.x == x and s.y == y then ok = false break end
        end
        if ok then
            self.food = { x = x, y = y }
            return
        end
    end
end

function Game:set_direction(dir)
    if self.game_over then return false end
    local d = DIRECTIONS[dir]
    if not d then return false end
    if self.direction.x + d.x == 0 and self.direction.y + d.y == 0 then
        return false
    end
    self.next_direction = d
    return true
end

function Game:tick()
    if self.game_over then return false end
    self.direction = self.next_direction
    local head = self.snake[1]
    local nh = { x = head.x + self.direction.x, y = head.y + self.direction.y }

    if nh.x < 1 or nh.x > self.width or nh.y < 1 or nh.y > self.height then
        self.game_over = true
        return false
    end

    for i = 1, #self.snake - 1 do
        if self.snake[i].x == nh.x and self.snake[i].y == nh.y then
            self.game_over = true
            return false
        end
    end

    table.insert(self.snake, 1, nh)

    if self.food and nh.x == self.food.x and nh.y == self.food.y then
        self.score = self.score + 10
        self:spawn_food()
    else
        table.remove(self.snake)
    end
    return true
end

function Game:get_cell(x, y)
    if self.food and self.food.x == x and self.food.y == y then return "food" end
    for i, s in ipairs(self.snake) do
        if s.x == x and s.y == y then return i == 1 and "head" or "body" end
    end
    return "empty"
end

function Game:elapsed()
    if not self.started_at then return 0 end
    return time.now():sub(self.started_at):seconds()
end

return { new = new }
