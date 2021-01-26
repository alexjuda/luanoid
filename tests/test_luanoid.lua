local luaunit = require('luaunit')

local luanoid = require('src.luanoid')

TestPointRectCollision = {}
  function TestPointRectCollision:test_inside_left_edge()
    luaunit.assertTrue(
        luanoid.point_rect_collision(
        { x=1, y=2 },
        { x=1, y=1, width=6, height=1 }
        )
    )
  end

  function TestPointRectCollision:test_inside_bottom_center()
    luaunit.assertTrue(
        luanoid.point_rect_collision(
        { x=10, y=10 },
        { x=1, y=1, width=20, height=10 }
        )
    )
  end

  function TestPointRectCollision:test_inside_almost_top_edge()
    luaunit.assertFalse(
        luanoid.point_rect_collision(
        { x=5, y=2 },
        { x=1, y=1, width=10, height=10 }
        )
    )
  end

  function TestPointRectCollision:test_inside_almost_bottom_edge()
    luaunit.assertFalse(
        luanoid.point_rect_collision(
        { x=5, y=9 },
        { x=1, y=1, width=10, height=10 }
        )
    )
  end

TestRectRectCollision = {}
  function TestRectRectCollision:test_disjoint()
    luaunit.assertFalse(
        luanoid.rect_rect_collision(
          { x=1, y=1, width=6, height=3 },
          { x=10, y=20, width=6, height=1 }
        )
    )
  end


  function TestRectRectCollision:test_intersection()
    luaunit.assertTrue(
        luanoid.rect_rect_collision(
          { x=1, y=1, width=6, height=6 },
          { x=5, y=5, width=2, height=2 }
        )
    )
  end

  function TestRectRectCollision:test_inclusion()
    luaunit.assertTrue(
        luanoid.rect_rect_collision(
          { x=1, y=1, width=10, height=10 },
          { x=5, y=5, width=2, height=2 }
        )
    )
  end

os.exit(luaunit.LuaUnit.run())
