local curses = require "curses"

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

  for key, val in pairs(details) do
    log_text = log_text .. '"' .. key .. '" = ' .. val .. "\n"
  end

  debug_file:write(log_text .. "\n")
  debug_file:flush()
end

-- curses wrappers

local function make_screen()
  local screen = curses.initscr()
  -- TODO: add screen configuration
  screen:clear()
  return screen
end

local function make_window(scr, height, width, y0, x0)
  return curses.newwin(height, width, y0, x0)
end

local function cleanup_screen()
  curses.endwin()
end

local function trans_coords(y, x, src2dst_trans)
  local trans = src2dst_trans or { dy=0, dx=0 }
  return y + trans.dy, x + trans.dx
end

local function inv_trans_coords(y, x, src2dst)
  return y - src2dst.dy, x - src2dst.dx
end

local function print_text(screen, y, x, text, trans)
  local trans_y, trans_x = trans_coords(y, x, trans)
  screen:mvaddstr(trans_y, trans_x, text)
  -- print("x = " .. x .. ", y = " .. y .. ", text = '" .. text .. "'\n")
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
  local trans_y, trans_x = trans_coords(y, x, trans)
  screen:move(trans_y, trans_x)
end

-- game rendering

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

local function render_world(scr, world, opts, trans)
  -- bricks
  for row_i, brick_row in ipairs(world.filled_brick_index_rows) do
    for _, filled_brick_index in ipairs(brick_row) do
      local brick_len = opts.brick_len
      print_text(
        scr,
        row_i - 1,
        (filled_brick_index - 1) * brick_len,
        brick_fill(brick_len),
        trans
      )
    end
  end

  -- ball
  print_text(
    scr,
    world.ball_pos.y - 1,
    world.ball_pos.x - 1,
    opts.ball_char
  )


  -- paddle
  paddle_y, paddle_x = trans_coords(opts.board_size.height - 1, world.paddle_left_x)
  print_text(
    scr,
    opts.board_size.height - 2,
    world.paddle_left_x - 1,
    paddle(opts.paddle_char, opts.paddle_len)
  )
end

local function starter_world()
  return {
    filled_brick_index_rows={
      {1, 2, 3, 4},
      {1,    3,  },
      {1, 2, 3, 4},
    },
    ball_pos={ x=5, y=4 },
    paddle_left_x=3,
  }
end

local function make_world_opts()
  return {
    brick_len=4,
    ball_char="o",
    paddle_len=6,
    paddle_char="=",
    board_size={ height=12, width=20 }
  }
end

local function main()
  local screen = make_screen()

  local world = starter_world()
  local world_opts = make_world_opts()
  local game_win = make_window(
    screen,
    world_opts.board_size.height,
    world_opts.board_size.width,
    0,
    0
  )
  -- window -> window content transformation caused by 1-width window borders
  local win_border_trans = { dy=1, dx=1 }

  local input_char = nil
  while input_char ~= 'q' do
    clear(game_win)
    game_win:border()

    if input_char == 'a' then
      world.paddle_left_x = world.paddle_left_x - 1
    elseif input_char == 'd' then
      world.paddle_left_x = world.paddle_left_x + 1
    end

    render_world(
        game_win,
        world,
        world_opts,
        win_border_trans
    )
    redraw(game_win)

    move_cursor(game_win, 0, 0)

    input_char = read_char(game_win)
    log("read char", { input_char=input_char })
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

xpcall (main, err)
