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

function replaceChar(str, pos, r)
    res = ("%s%s%s"):format(str:sub(1,pos-1), r, str:sub(pos+1))
    return res
end

function rpad(str, maxLen, filler)
    if string.len(str) <= maxLen then
      return str
    end

    lenDiff = maxLen - string.len(str)

    return str .. string.rep(filler, lenDiff)
end

function printWorld(world, opts)
  lines = {}
  for _, indexRow in ipairs(world.brickIndexRows) do
    table.insert(lines, brickLine(indexRow, opts.brickLength))
  end

  for _ = 1, opts.clearance do
    table.insert(lines, opts.clearanceChar)
  end

  table.insert(lines, paddleLine{ pos=world.paddlePos, char=opts.paddleChar, length=opts.paddleLength })

  lines[world.ballPos.y] = rpad(
    replaceChar(lines[world.ballPos.y], world.ballPos.x, opts.ballChar),
    world.ballPos.x,
    opts.clearanceChar
  )

  for _, line in ipairs(lines) do
    print(line)
  end
end

function main()
  printWorld(
    {
      paddlePos=12,
      brickIndexRows={
        {1, 2, 3, 4},
        {   2,    4},
        {1, 2,     },
        {1, 2, 3, 4},
      },
      ballPos={ x=2, y=5 },
    },
    {
      paddleLength=6,
      paddleChar="=",
      brickLength=6,
      clearance=3,
      ballChar='o',
      clearanceChar=' ',
    }
  )

end

main()
