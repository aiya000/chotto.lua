# chotto.lua Examples

Practical usage examples for chotto.lua.

## Table of Contents

1. [Real-World Use Cases](#real-world-use-cases)
2. [Advanced Patterns](#advanced-patterns)
3. [Integration Examples](#integration-examples)

## Real-World Use Cases

### API Request/Response Validation

```lua
-- API request validation
---@type Schema<{method: 'GET' | 'POST', url: string, headers?: table<string, string>, body?: string}>
local api_request = c.object({
  method = c.union({
    c.literal('GET'),
    c.literal('POST')
  }),
  url = c.string(),
  headers = c.optional(c.table(c.string(), c.string())),
  body = c.optional(c.string())
})

-- API response validation
---@type Schema<{status: integer, data?: table, error?: string}>
local api_response = c.object({
  status = c.integer(),
  data = c.optional(c.table()),
  error = c.optional(c.string())
})

-- Usage function
local function make_api_call(request_data)
  -- Validate request
  local request, err = pcall(api_request.parse, request_data)
  if err then
    return nil, 'Invalid request: ' .. err
  end

  -- Make the actual call (pseudo-code)
  local raw_response = http.request(request)

  -- Validate response
  local response, err2 = pcall(api_response.parse, raw_response)
  if err2 then
    return nil, 'Invalid response: ' .. err2
  end

  return response, nil
end
```

### Configuration File Validation

```lua
-- Database configuration
---@type Schema<{host: string, port: integer, username: string, password: string, database: string}>
local db_config = c.object({
  host = c.string(),
  port = c.integer(),
  username = c.string(),
  password = c.string(),
  database = c.string()
})

-- Logging configuration
---@type Schema<{level: 'debug' | 'info' | 'warn' | 'error', file?: string, console: boolean}>
local log_config = c.object({
  level = c.union({
    c.literal('debug'),
    c.literal('info'),
    c.literal('warn'),
    c.literal('error')
  }),
  file = c.optional(c.string()),
  console = c.boolean()
})

-- Full application configuration
---@type Schema<{database: {host: string, port: integer, username: string, password: string, database: string}, logging: {level: 'debug' | 'info' | 'warn' | 'error', file?: string, console: boolean}, server: {port: integer, host?: string}}>
local app_config = c.object({
  database = db_config,
  logging = log_config,
  server = c.object({
    port = c.integer(),
    host = c.optional(c.string())
  })
})

-- Configuration loader
local function load_config(config_path)
  local config_data = dofile(config_path) -- or JSON.decode() etc.

  local config, err = pcall(app_config.parse, config_data)
  if err then
    error('Configuration validation failed: ' .. err)
  end

  return config
end
```

### User Input Validation

```lua
-- User registration form
---@alias Registration { username: string, email: string, password: string, age?: integer, terms_accepted: boolean }

--- Form validation helper
---@param form_data Registration
---@return Registration | nil, string | nil
local function validate_form(form_data)
  ---@type Schema<Registration>
  local registration_schema = c.object({
    username = c.string(),
    email = c.string(),
    password = c.string(),
    age = c.optional(c.integer()),
    terms_accepted = c.boolean()
  })

  local result, err = pcall(registration_schema.parse, form_data)
  if err then
    return nil, 'Validation failed: ' .. err
  end
  return result, nil
end

-- Usage
local user_data = {
  username = 'alice123',
  email = 'alice@example.com',
  password = 'securepassword',
  terms_accepted = true
}

---@type Registration, string | nil
local user, err = validate_form(user_data)
if err then
  print('Registration failed:', err)
else
  print('User registered:', user.username)
end
```

## Advanced Patterns

### Nesting Schemas

```lua
--- Game State Validation

-- Player data
---@alias Player {name: string, level: integer, health: number, inventory: string[], position: [number, number]}
---@type Schema<Player>
local player_schema = c.object({
  name = c.string(),
  level = c.integer(),
  health = c.number(),
  inventory = c.array(c.string()),
  position = c.tuple({
    c.number(),
    c.number()
  })
})

-- Game state
---@alias GameState {players: Player[], status: 'waiting' | 'playing' | 'finished', round: integer}

---**Nested Schema**
---@type Schema<GameState>
local game_state = c.object({
  players = c.array(player_schema), -- Reuse player_schema
  status = c.union({
    c.literal('waiting'),
    c.literal('playing'),
    c.literal('finished')
  }),
  round = c.integer()
})

-- Save/load game functions
---@param state GameState
---@return boolean, string | nil
local function save_game(state)
  local validated_state, err = pcall(game_state.parse, state)
  if err then
    return false, 'Invalid game state: ' .. err
  end

  -- Save to file
  local file = io.open('savegame.lua', 'w')
  file:write('return ' .. serialize(validated_state))
  file:close()

  return true, nil
end

---@return GameState | nil, string | nil
local function load_game()
  local raw_state = dofile('savegame.lua')

  local state, err = pcall(game_state.parse, raw_state)
  if err then
    return nil, 'Corrupted save file: ' .. err
  end

  return state, nil
end
```

### Recursive Validation

TODO

### Validation Utilities

```lua
-- Safe parsing utility
local function safe_parse(schema, data)
  local ok, result = pcall(schema.parse, data)
  return ok and result or nil, not ok and result or nil
end

-- Validation with default values
local function parse_with_defaults(schema, data, defaults)
  local result, err = safe_parse(schema, data)
  if err then
    return nil, err
  end

  -- Apply defaults for missing optional fields
  for key, default_value in pairs(defaults) do
    if result[key] == nil then
      result[key] = default_value
    end
  end

  return result, nil
end

-- Usage
local config_schema = c.object({
  port = c.optional(c.integer()),
  host = c.optional(c.string()),
  debug = c.optional(c.boolean())
})

local config, err = parse_with_defaults(
  config_schema,
  {port = 8080},
  {host = 'localhost', debug = false}
)
-- Result: {port = 8080, host = 'localhost', debug = false}
```

### Validation with ensure()

The `:ensure()` method is a chotto.lua-specific feature (not in Zod) that validates data without returning a value. It's useful when you only need to validate but don't need the validated result.

```lua
local c = require('chotto')
```

#### Basic usage

```lua
-- No error is thrown, handler is called instead
c.integer():ensure('not a number', function(err)
  print('Validation failed:', err)
end)

-- The handler is optional.
-- Without a handler, it behaves like :parse() but returns nothing.
c.string():ensure('hello') -- ✓ No error, no return value
c.string():ensure(123) -- ✗ Throws error
```

#### Real-world example

```lua
-- Contract Programming (Design by Contract pattern)

---@generic T
---@param schema chotto.Schema<T>
local function ensure_argument(schema, validatee)
  schema:ensure(validatee, function(e)
    vim.notify('Validation failed: ' .. e, vim.log.levels.ERROR) -- A Neovim API to notify messages
  end)
end

---@param num number
local function print_number(num)
  ensure_argument(c.number(), num)
  print(num)
end
```

```lua
-- Configuration validation
local function validate_config(config)
  local config_schema = c.object({
    port = c.integer(),
    host = c.string(),
    debug = c.boolean()
  })

  -- Ensure config is valid, throw error if not
  config_schema:ensure(config)

  -- If we reach here, config is valid
  print('Configuration is valid!')
end

-- With custom error handling
local function validate_config_safe(config)
  local config_schema = c.object({
    port = c.integer(),
    host = c.string(),
    debug = c.boolean()
  })

  local is_valid = true

  config_schema:ensure(config, function(err)
    print('Configuration error:', err)
    is_valid = false
  end)

  return is_valid
end

-- Usage
validate_config({port = 8080, host = 'localhost', debug = false})  -- ✓
validate_config_safe({port = 'invalid', host = 'localhost'})       -- ✗ Calls handler, returns false
```

## Integration Examples

### Web Framework Integration

```lua
-- Express.js-like framework integration
local function validate_middleware(schema)
  return function(req, res, next)
    local body, err = safe_parse(schema, req.body)
    if err then
      res:status(400):json({error = 'Validation failed: ' .. err})
      return
    end

    req.validated_body = body
    next()
  end
end

-- Route with validation
---@type Schema<{name: string, email: string}>
local create_user_schema = c.object({
  name = c.string(),
  email = c.string()
})

app:post('/users', validate_middleware(create_user_schema), function(req, res)
  local user_data = req.validated_body
  -- user_data is guaranteed to be valid
  local user = create_user(user_data)
  res:json(user)
end)
```

### CLI Argument Validation

```lua
-- Command line argument validation
---@type Schema<{command: 'start' | 'stop' | 'restart', port?: integer, config?: string}>
local cli_args = c.object({
  command = c.union({
    c.literal('start'),
    c.literal('stop'),
    c.literal('restart')
  }),
  port = c.optional(c.integer()),
  config = c.optional(c.string())
})

local function parse_cli_args(args)
  local parsed_args, err = safe_parse(cli_args, args)
  if err then
    print('Invalid arguments: ' .. err)
    print('Usage: program <start|stop|restart> [--port PORT] [--config CONFIG]')
    os.exit(1)
  end

  return parsed_args
end
```

For more detailed usage patterns and migration guides, see [Tutorial](tutorial.md) and [Zod Comparison](zod-comparison.md).
