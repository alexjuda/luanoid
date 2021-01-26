local curses = require "curses"
local sleep = require "sleep"

local luanoid = {}

-- helpers

local function current_date_time()
  return os.date("!%Y-%m-%dT%TZ")
end

debug_file = nil

local function log(msg, details)
  if debug_file == nil then
    debug_file = io.open("debug.log", "w")
    debug_file:write('\n=== new session ===\n')
  end

  log_text = "[" .. current_date_time() .. "] " .. msg .. "\n"

  log_text = log_text .. table_to_str(details or {}) .. "\n"

  debug_file:write(log_text .. "\n")
  debug_file:flush()
end

function _deep_copy_table(o, tables)

  if type(o) ~= 'table' then
    return o
  end

  if tables[o] ~= nil then
    return tables[o]
  end

  local new_o = {}
  tables[o] = new_o

  for k, v in next, o, nil do
    local new_k = _deep_copy_table(k, tables)
    local new_v = _deep_copy_table(v, tables)
    new_o[new_k] = new_v
  end

  return new_o
end

function deep_copy_table(o)
  return _deep_copy_table(o, {})
end

function table_to_str(t)
  if type(t) == "table" then
    local str = "{ "
    for k, v in pairs(t) do
      str = str .. k .. "=" .. table_to_str(v) .. ", "
    end
    str = str .. " }"
    return str

  else
    return "" .. t

  end
end

-- translations

local function trans_coords(y, x, src2dst_trans)
  local trans = src2dst_trans or { dy=0, dx=0 }
  return y + trans.dy, x + trans.dx
end

local function inv_trans_coords(y, x, src2dst)
  return y - src2dst.dy, x - src2dst.dx
end

local function combine_trans(trans1, trans2)
  local trans1_ = trans1 or { dy=0, dx=0 }
  local trans2_ = trans2 or { dy=0, dx=0 }
  return { dy=trans1_.dy + trans2_.dy, dx=trans1_.dx + trans2_.dx }
end


-- curses wrappers

local function make_screen()
  local screen = curses.initscr()
  screen:clear()
  return screen
end

lua2curses_trans = { dy=-1, dx=-1 }

local function make_window(scr, height, width, y0, x0)
  local y_t, x_t = trans_coords(y0, x0, lua2curses_trans)

  log('make_window', { height=height, width=width, y_t=y_t, x_t=x_t })
  local win = curses.newwin(height, width, y_t, x_t)
  win:nodelay(true)

  return win
end

local function cleanup_screen()
  curses.endwin()
end

local function print_text(screen, y, x, text, trans)
  local y_t, x_t = trans_coords(y, x, combine_trans(trans, lua2curses_trans))
  screen:mvaddstr(y_t, x_t, text)
end

local function redraw(screen)
  -- screen:clearok()
  screen:refresh()
end

local function clear(screen)
  screen:erase()
end

local function read_char(screen)
  local char = screen:getch()
  if char == curses.err then
    return nil
  else
    return string.char(char)
  end
end

local function move_cursor(screen, y, x, trans)
  local y_t, x_t = trans_coords(y, x, combine_trans(trans, lua2curses_trans))
  screen:move(y_t, x_t)
end


-- game rendering

local render_interval = 0.01 -- [s]

local function time_since_start(frame_i)
  return render_interval * frame_i
end

local function snap_pos(pos)
  return { x=math.floor(pos.x), y=math.floor(pos.y) }
end

local function advance_pos(pos, velocity, time_delta)
  local x_new = pos.x + velocity.x * time_delta
  local y_new = pos.y + velocity.y * time_delta
  return { x=x_new, y=y_new }
end


-- collisions

function luanoid.point_rect_collision(pos, rect)
  rect_p2 = { x=rect.x + rect.width, y=rect.y + rect.height }

  diff_x1 = rect.x - pos.x
  diff_y1 = rect.y - pos.y
  diff_x2 = rect_p2.x - pos.x
  diff_y2 = rect_p2.y - pos.y

  return math.min(math.abs(diff_x1), math.abs(diff_x2)) <= 1 or math.min(math.abs(diff_y1), math.abs(diff_y2)) <= 1
end

function luanoid.rect_rect_collision(r1, r2)
  -- formula from http://www.jeffreythompson.org/collision-detection/rect-rect.php
  if (
    r1.x + r1.width >= r2.x and
    r1.x <= r2.x + r2.width and
    r1.y + r1.height >= r2.y and
    r1.y <= r2.y + r2.height
  ) then
    return true
  else
    return false
  end
end


-- render blocks

local function paddle(char, length)
  return string.rep(char, length)
end

local function brick_fill(length)
  assert(2 <= length, "brick too short: " .. length)

  return "[" .. string.rep("=", length - 2) .. "]"
end

local function brick_placeholder(length)
  return string.rep(" ", length)
end

local function paddle_rect(world, world_opts)
  return { x=world.paddle_left_x, y=world_opts.paddle_y, width=world_opts.paddle_len, height=1 }
end

local function board_rect(world_opts)
  return { x=1, y=1, width=world_opts.board_size.width, height=world_opts.board_size.height }
end

local function paddle_board_collision(world, world_opts)
  return world.paddle_left_x <= 1 or world_opts.board_size.width <= world.paddle_left_x + world_opts.paddle_len
end

local function render_world(scr, world, opts, trans)
  -- bricks
  for row_i, brick_row in ipairs(world.filled_brick_index_rows) do
    for _, filled_brick_index in ipairs(brick_row) do
      local brick_len = opts.brick_len
      print_text(
        scr,
        row_i,
        (filled_brick_index - 1) * brick_len + 1,
        brick_fill(brick_len),
        trans
      )
    end
  end

  -- ball
  local ball_pos = snap_pos(world.ball_pos_frac)
  print_text(
    scr,
    ball_pos.y,
    ball_pos.x,
    opts.ball_char,
    trans
  )


  -- paddle
  local paddle_r = paddle_rect(world, opts)
  print_text(
    scr,
    paddle_r.y,
    paddle_r.x,
    paddle(opts.paddle_char, paddle_r.width)
  )

end

local function starter_world()
  return {
    filled_brick_index_rows={
      {1, 2, 3, 4},
      {1,    3,  },
      {1, 2, 3, 4},
    },
    ball_pos_frac={ x=5.0, y=4.0 },
    ball_velocity={ x=1, y=1 },
    paddle_left_x=5,
  }
end

local function make_world_opts()
  return {
    brick_len=4,
    ball_char="o",
    paddle_len=6,
    paddle_y=10,
    paddle_char="=",
    board_size={ height=14, width=30 }
  }
end

local function run()
  local screen = make_screen()

  local world = starter_world()
  local world_opts = make_world_opts()
  local game_win = make_window(
    screen,
    world_opts.board_size.height,
    world_opts.board_size.width,
    1,
    1
  )
  -- window -> window content transformation caused by 1-width window borders
  local win_border_trans = { dy=1, dx=1 }

  local input_char = nil
  local frame_i = 0
  while input_char ~= 'q' do
    clear(game_win)
    game_win:border()

    -- paddle movement
    local world_candidate = deep_copy_table(world)
    if input_char == 'a' then
      world_candidate.paddle_left_x = world.paddle_left_x - 1
    elseif input_char == 'd' then
      world_candidate.paddle_left_x = world.paddle_left_x + 1
    end

    if paddle_board_collision(world_candidate, world_opts) then
      log("paddle-board collision detected")
    else
      world = world_candidate
    end

    -- ball collisions
    if luanoid.point_rect_collision(
      snap_pos(world.ball_pos_frac),
      board_rect(world_opts)
    ) then
      world.ball_velocity = { x=world.ball_velocity.x * -1, y=world.ball_velocity.y * -1 }
    end

    -- ball movement
    world.ball_pos_frac = advance_pos(world.ball_pos_frac, world.ball_velocity, render_interval)

    render_world(
        game_win,
        world,
        world_opts,
        win_border_trans
    )
    redraw(game_win)

    move_cursor(game_win, 0, 0)

    sleep(1000 * render_interval)
    input_char = read_char(game_win)
    if input_char ~= curses.err then
      log("read char", { input_char=input_char })
    end

    frame_i = frame_i + 1
  end

  cleanup_screen()
end


-- To display Lua errors, we must close curses to return to
-- normal terminal mode, and then write the error to stdout.
local function err (err)
  curses.endwin ()
  print "Caught an error:"
  print (debug.traceback (err, 2))
  os.exit (2)
end

function luanoid.main()
  xpcall (run, err)
end

return luanoid
