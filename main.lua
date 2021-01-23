function printWorld(world, opts)
  print("paddle pos: " .. world.paddlePos)

  line = string.rep(" ", world.paddlePos) .. string.rep(opts.paddleChar, opts.paddleLength)
  print(line)
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
