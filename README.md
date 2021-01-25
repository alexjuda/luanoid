# luanoid

## Running

Dev setup:
```
$ docker build --target luanoid-dev -t luanoid-dev .
$ docker run -it --rm --mount type=bind,source="$(pwd)",target="/app/" luanoid-dev:latest /bin/bash
```


Inside docker container:
```
$ lua5.3 main.lua
```
