# redbean-bits

Various independent modules for the Redbean web server.

Include any of the modules in the `.lua/` directory of your project/zip.

For each module, you can learn the usage by reading the module's `test-*.lua` file.
You can run a test with for example `redbean.com -i test-redis.lua`

## [redis.lua](./redis.lua)

Simple [Redis](https://redis.io/) client.

The API is inspired by OpenResty's [lua-resty-redis](https://github.com/openresty/lua-resty-redis) module.

## [gwsocket.lua](./gwsocket.lua)

As of writing Redbean does not have native Websocket support, this module provides a simple API to [gwsocket](https://gwsocket.io/).

This module can spawn a gwsocket process by itself, but you can also run the process manually.

Note: if you only need server-to-client messages, take a look at Fullmoon's [SSE](https://github.com/pkulchenko/fullmoon#htmx-sse-example) functionality.

## [db.lua](./db.lua)

A small SQLite abstraction library.

## [htmlgen.lua](./htmlgen.lua)

A single generator function to procedurally generate HTML.

As opposed to templating (Lua in HTML or tables representing HTML), this method encourages generating HTML directly in the application logic.
