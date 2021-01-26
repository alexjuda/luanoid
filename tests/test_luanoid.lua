local luaunit = require('luaunit')

local luanoid = require('src.luanoid')

TestPointRectCollision = {}
  function TestPointRectCollision:test_left_edge()
    luaunit.assertTrue(
        luanoid.point_rect_collision(
        { x=1, y=2 },
        { x=1, y=1, width=6, height=1 }
        )
    )
  end

  function TestPointRectCollision:test_bottom_center()
    luaunit.assertTrue(
        luanoid.point_rect_collision(
        { x=10, y=10 },
        { x=1, y=1, width=20, height=10 }
        )
    )
  end

os.exit(luaunit.LuaUnit.run())
