# redbean-bits

Various independant modules for the Redbean web server.

Include any of the modules in the `.lua/` directory of your project/zip.

For each module, you can check the usage by reading the module's `test-*.lua` file.
You can run a test with for example `redbean.com -i test-redis.lua`

## [redis.lua](./redis.lua)

Simple [Redis](https://redis.io/) client.

The API is inspired by OpenResty's [lua-resty-redis](https://github.com/openresty/lua-resty-redis) module.

## [gwsocket.lua](./gwsocket.lua)

As of writing Redbean does not have native Websocket support, this module provides a simple API to 

Note: if you only need server-to-client messages, take a look at Fullmoon's [SSE](https://github.com/pkulchenko/fullmoon#htmx-sse-example) functionality.
