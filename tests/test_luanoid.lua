local luaunit = require('luaunit')

local luanoid = require('src.luanoid')

TestIsPosAdjacent = {}
  function TestIsPosAdjacent:test_left_edge()
    luaunit.assertTrue(
        luanoid.is_pos_adjacent_to_rect(
        { x=1, y=2 },
        { x=1, y=1, width=6, height=1 }
        )
    )
  end

  function TestIsPosAdjacent:test_bottom_center()
    luaunit.assertTrue(
        luanoid.is_pos_adjacent_to_rect(
        { x=10, y=10 },
        { x=1, y=1, width=20, height=10 }
        )
    )
  end

os.exit(luaunit.LuaUnit.run())
