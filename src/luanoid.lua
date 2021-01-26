local curses = require "curses"
local sleep = require "sleep"

local luanoid = {}

local function current_date_time()
  return os.date("!%Y-%m-%dT%TZ")
end

debug_file = nil

local function log(msg, details)
  if debug_file == nil then
    debug_file = io.open("debug.log", "a")
    debug_file:write('\n=== new session ===\n')
  end

  log_text = "[" .. current_date_time() .. "] " .. msg .. "\n"

  for key, val in pairs(details or {}) do
    log_text = log_text .. '"' .. key .. '" = ' .. val .. "\n"
  end

  debug_file:write(log_text .. "\n")
  debug_file:flush()
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
  return string.char(screen:getch())
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

  log('is_pos', { diff_x1=diff_x1, diff_y1=diff_y1, diff_x2=diff_x2, diff_y2=diff_y2})

  return math.min(math.abs(diff_x1), math.abs(diff_x2)) <= 1 or math.min(math.abs(diff_y1), math.abs(diff_y2)) <= 1
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
    paddle_left_x=3,
  }
end

local function make_world_opts()
  return {
    brick_len=4,
    ball_char="o",
    paddle_len=6,
    paddle_y=10,
    paddle_char="=",
    board_size={ height=12, width=20 }
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
    if input_char == 'a' then
      world.paddle_left_x = world.paddle_left_x - 1
    elseif input_char == 'd' then
      world.paddle_left_x = world.paddle_left_x + 1
    end

    -- ball collisions
    if luanoid.point_rect_collision(
      snap_pos(world.ball_pos_frac),
      { x=1, y=1, width=world_opts.board_size.width, height=world_opts.board_size.height }
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
    log("read char", { input_char=input_char })

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
