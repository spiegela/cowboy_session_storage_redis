## Cowboy Session Storage Redis

# Description

Adds [Redis](http://redis.io) storage option to
[Cowboy Session](https://github.com/chvanikoff/cowboy_session). This can be
useful for when you want to share state between multiple Erlang VMs that may
not have access to the same ETS tables.  You can also use this to share session
storage between webapps of different languages.
[#Polyglot](http://twitter.com/search?q=%23polyglot)

# Configuration

To keep things as simple as possible, configuration is done via environment
variables:

```shell
# Set the Redis connection information
# Default is: "redis://127.0.0.1:6379/0"
REDIS_URL=redis://[pass@]<hostname>:<port>/<db-index>

# Set the prefix used to prepend sessions in Redis key
# Default is: "cowboy_session"
REDIS_PREFIX=<prefixname>
```

# Installation

Easy to add via rebar, or just copy `cowboy_session_storage_redis.erl` to your
source-dir.  Configure via cowboy_session:

```erlang
% Make sure you start cowboy_session first
cowboy_session:start(),

% Then add a storage option
cowboy_session_config:update_storage(cowboy_session_storage_redis).
```

# TODO

 * I tried to use with [eredis_pool](https://github.com/hiroeorz/eredis_pool),
   but using "app.src"-based configuration was onerous, so I punted.  I'd like
   to use a connection pool, so I'll circle back on that.

 * Improvements on configuration:  I'm open for suggestions on this

 * Testing:  Since cowboy_session is test-less, I didn't spend enough time
   contemplating how to test session storage...  So I should do that.

 * Suggestions?


