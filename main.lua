function paddleLine(opts)
  return string.rep(" ", opts.pos) .. string.rep(opts.char, opts.length)
end

function printWorld(world, opts)
  print("paddle pos: " .. world.paddlePos)

  print(paddleLine{ pos=world.paddlePos, char=opts.paddleChar, length=opts.paddleLength })
end

function main()
  printWorld(
    {
      paddlePos=12
    },
    {
      paddleLength=6,
      paddleChar="="
    }
  )
end

main()
