function paddleLine(opts)
  return string.rep(" ", opts.pos) .. string.rep(opts.char, opts.length)
end

function brickFill(length)
  assert(2 <= length, "brick too short: " .. length)

  return "[" .. string.rep("=", length - 2) .. "]"
end

function brickPlaceholder(length)
  return string.rep(".", length)
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

function printWorld(world, opts)
  print("paddle pos: " .. world.paddlePos)

  print(paddleLine{ pos=world.paddlePos, char=opts.paddleChar, length=opts.paddleLength })
end

function main()
  -- printWorld(
  --   {
  --     paddlePos=12
  --   },
  --   {
  --     paddleLength=6,
  --     paddleChar="="
  --   }
  -- )

  print(brickLine({1, 2, 3, 4}, 4))
  print(brickLine({   2,    4}, 4))
  print(brickLine({1, 2,     }, 4))
  print(brickLine({1, 2, 3, 4}, 4))
end

main()
