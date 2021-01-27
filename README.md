# luanoid

## Running

Dev setup:
```
$ docker build --target luanoid-dev -t luanoid-dev .
$ docker run -it --rm --mount type=bind,source="$(pwd)",target="/app/" luanoid-dev:latest /bin/bash
```


Inside the docker container:
```
$ lua5.3 src/main.lua
```

To run the tests:
```
$ tests/test_luanoid.lua
```


## Misc

- [Styleguide](https://github.com/luarocks/lua-style-guide)
