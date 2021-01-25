local curses = require "curses"

-- curses wrappers

local function make_screen()
  local screen = curses.initscr()
  -- TODO: add screen configuration
  screen:clear()
  return screen
end

local function cleanup_screen()
  curses.endwin()
end

local function print_text(screen, y, x, text)
  screen:mvaddstr(y, x, text)
  -- print("x = " .. x .. ", y = " .. y .. ", text = '" .. text .. "'\n")
end

local function redraw(screen)
  screen:refresh()
end

local function read_char(screen)
  return screen:getch()
end

local function move_cursor(screen, y, x)
  screen:move(y, x)
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

local function render_world(scr, world, opts)
  -- bricks
  for row_i, brick_row in ipairs(world.filled_brick_index_rows) do
    for _, filled_brick_index in ipairs(brick_row) do
      local brick_len = opts.brick_len
      print_text(
        scr,
        row_i - 1,
        (filled_brick_index - 1) * brick_len,
        brick_fill(brick_len)
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
  print_text(
    scr,
    opts.board_size.height - 2,
    world.paddle_left_x - 1,
    paddle(opts.paddle_char, opts.paddle_len)
  )
end

local function main()
  local screen = make_screen()

  render_world(
    screen,
    {
      filled_brick_index_rows={
        {1, 2, 3, 4},
        {1,    3,  },
        {1, 2, 3, 4},
      },
      ball_pos={ x=5, y=4 },
      paddle_left_x=3,
    },
    {
      brick_len=4,
      ball_char="o",
      paddle_len=6,
      paddle_char="=",
      board_size={ height=12 }
    }
  )
  redraw(screen)

  move_cursor(screen, 0, 0)
  read_char(screen)

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
