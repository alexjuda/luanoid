local curses = require "curses"

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


local function main()
  local screen = make_screen()

  print_text(screen, 5, 20, "hello!")
  render(screen)

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
