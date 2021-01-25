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
end

local function render(screen)
  screen:refresh()
end

local function read_char(screen)
  return screen:getch()
end

local function move_cursor(screen, y, x)
  screen:move(y, x)
end

-- game rendering

function paddleLine(opts)
  return string.rep(" ", opts.pos) .. string.rep(opts.char, opts.length)
end

function brickFill(length)
  assert(2 <= length, "brick too short: " .. length)

  return "[" .. string.rep("=", length - 2) .. "]"
end

function brickPlaceholder(length)
  return string.rep(" ", length)
end

function brickLine(filledBrickIndices, brickLength)
  line = ""
  prevBrickI = 0

  for _, brickI in ipairs(filledBrickIndices) do
    for fillI = prevBrickI, brickI - 2 do
      line = line .. brickPlaceholder(brickLength)
    end

    line = line .. brickFill(brickLength)

    prevBrickI = brickI
  end

  return line
end


local function main()
  local screen = make_screen()

  print_text(screen, 5, 20, "hello!")
  print_text(screen, 2, 1, brickLine({ 1, 2, 4 }, 4))
  render(screen)

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
