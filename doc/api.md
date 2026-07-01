# chotto.lua API Reference

Comprehensive API documentation for chotto.lua.

## Table of Contents

1. [Complete API Reference](#complete-api-reference)
2. [Examples](#examples)

## Complete API Reference

### Basic Types

```lua
local c = require('chotto')

-- Primitive types
c.string()     -- String validation
c.number()     -- Number validation (integers and floats)
c.integer()    -- Integer-only validation
c.boolean()    -- Boolean validation
c.null()       -- nil validation (note: null, not nil)
c.func()       -- Function validation (note: func, not function)
c.any()        -- Accept any value
c.unknown()    -- Same as any, semantically different
```

### Complex Types

```lua
-- Object validation
c.object(schema_table)

-- Array validation
c.array(item_schema)

-- Optional validation (allows nil)
c.optional(schema)

-- Union validation (OR logic)
c.union(schema_array)

-- Tuple validation (fixed-length array)
c.tuple(schema_array)

-- Table validation (key-value pairs)
c.table()                           -- Any table (`table` type)
c.table(key_schema, value_schema)   -- Typed key-value pairs (`table<K, V>` type)

-- Literal validation (exact value match)
c.literal(value)
```

### Schema Methods

Every schema has two main methods:

```lua
schema:parse(data)              -- Validates and returns data, throws error on failure
schema:safe_parse(data)         -- Returns (true, data) on success or (false, error_msg) on failure
```

There is also an additional method `:ensure()` for validation without return values. See [Validation with ensure()](examples.md#validation-with-ensure) for details.

### Primitive Types

```lua
local c = require('chotto')

-- String validation
local name_schema = c.string()
local name = name_schema:parse('Alice')           -- ✓ 'Alice'
-- name_schema:parse(123)                         -- ✗ Error

-- Number validation
local age_schema = c.number()
local age = age_schema:parse(25)                  -- ✓ 25
local height = age_schema:parse(5.9)              -- ✓ 5.9 (floats OK)

-- Integer-only validation
local count_schema = c.integer()
local count = count_schema:parse(42)              -- ✓ 42
-- count_schema:parse(3.14)                       -- ✗ Error (no floats)

-- Boolean validation
local active_schema = c.boolean()
local is_active = active_schema:parse(true)       -- ✓ true

-- Nil validation
local empty_schema = c.null()
local empty = empty_schema:parse(nil)             -- ✓ nil

-- Function validation
local callback_schema = c.func()
local fn = callback_schema:parse(function() end)  -- ✓ function

-- Any value validation
local flexible_schema = c.any()
local anything = flexible_schema:parse('anything') -- ✓ 'anything'
local number = flexible_schema:parse(42)           -- ✓ 42
local table = flexible_schema:parse({})            -- ✓ {}
```

### Object Validation

```lua
-- Basic object
---@type Schema<{name: string, age: integer}>
local person_schema = c.object({
  name = c.string(),
  age = c.integer(),
})

local person = person_schema:parse({
  name = 'Bob',
  age = 30,
  extra = 'field'  -- Extra fields are preserved (zod-like behavior)
})

print(person.name)  -- 'Bob'
print(person.extra) -- 'field'

-- Nested objects
---@type Schema<{user: {name: string, email: string}, settings: {theme: string}}>
local profile_schema = c.object({
  user = c.object({
    name = c.string(),
    email = c.string(),
  }),
  settings = c.object({
    theme = c.string(),
  })
})

local profile = profile_schema:parse({
  user = {
    name = 'Alice',
    email = 'alice@example.com'
  },
  settings = {
    theme = 'dark'
  }
})
```

### Array Validation

```lua
-- String array
---@type Schema<string[]>
local tags_schema = c.array(c.string())
local tags = tags_schema:parse({'lua', 'validation', 'library'})

-- Number array
---@type Schema<number[]>
local scores_schema = c.array(c.number())
local scores = scores_schema:parse({95.5, 87, 92.3})

-- Object array
---@type Schema<{name: string, age: integer}[]>
local users_schema = c.array(c.object({
  name = c.string(),
  age = c.integer(),
}))

local users = users_schema:parse({
  {name = 'Alice', age = 25},
  {name = 'Bob', age = 30}
})

-- Nested arrays
---@type Schema<string[][]>
local matrix_schema = c.array(c.array(c.string()))
local matrix = matrix_schema:parse({
  {'a', 'b', 'c'},
  {'d', 'e', 'f'}
})
```

### Union Types

```lua
-- String or number
---@type Schema<string | number>
local id_schema = c.union({
  c.string(),
  c.number()
})

local id1 = id_schema:parse('user123')  -- ✓ string
local id2 = id_schema:parse(42)         -- ✓ number

-- Status enum
---@type Schema<'pending' | 'success' | 'error'>
local status_schema = c.union({
  c.literal('pending'),
  c.literal('success'),
  c.literal('error')
})

local status = status_schema:parse('success') -- ✓

-- Complex union
---@type Schema<string | {type: 'object', data: table}>
local flexible_data = c.union({
  c.string(),
  c.object({
    type = c.literal('object'),
    data = c.table()
  })
})

local data1 = flexible_data:parse('simple string')
local data2 = flexible_data:parse({
  type = 'object',
  data = {key = 'value'}
})
```

### Optional Fields

```lua
-- Optional string
---@type Schema<string?>
local optional_name = c.optional(c.string())
local name1 = optional_name:parse('Alice')  -- ✓ 'Alice'
local name2 = optional_name:parse(nil)      -- ✓ nil

-- Object with optional fields
---@type Schema<{name: string, nickname?: string, age?: integer}>
local user_schema = c.object({
  name = c.string(),
  nickname = c.optional(c.string()),
  age = c.optional(c.integer())
})

local user1 = user_schema:parse({name = 'Alice'})  -- ✓
local user2 = user_schema:parse({name = 'Bob', nickname = 'Bobby'})  -- ✓
local user3 = user_schema:parse({name = 'Charlie', age = 25})        -- ✓
```

### Tuple Validation

```lua
-- Fixed-length array with different types
---@type Schema<[string, number, boolean]>
local response_tuple = c.tuple({
  c.string(),
  c.number(),
  c.boolean()
})

local response = response_tuple:parse({'success', 200, true})
print(response[1]) -- 'success'
print(response[2]) -- 200
print(response[3]) -- true

-- Coordinate tuple
---@type Schema<[number, number]>
local coordinate = c.tuple({
  c.number(),
  c.number()
})

local point = coordinate:parse({10.5, 20.3})
local x, y = point[1], point[2]
```

### Table Validation

```lua
-- Any table
---@type Schema<table>
local any_table = c.table()
local data = any_table:parse({anything = 'goes', here = 123})

-- String to number mapping
---@type Schema<table<string, number>>
local scores = c.table(c.string(), c.number())
local student_scores = scores:parse({
  alice = 95,
  bob = 87,
  charlie = 92
})

-- String to string mapping
---@type Schema<table<string, string>>
local config = c.table(c.string(), c.string())
local settings = config:parse({
  theme = 'dark',
  language = 'en',
  timezone = 'UTC'
})
```

### Literal Types

```lua
-- Single literal
---@type Schema<'production'>
local env_schema = c.literal('production')
local env = env_schema:parse('production')  -- ✓
-- env_schema:parse('development')          -- ✗ Error

-- Multiple literals via union
---@alias HttpMethod 'GET' | 'POST' | 'PUT' | 'DELETE'

---@type Schema<HttpMethod>
local method_schema = c.union({
  c.literal('GET'),
  c.literal('POST'),
  c.literal('PUT'),
  c.literal('DELETE')
})

---@type HttpMethod
local method = method_schema:parse('POST')

-- Number literals
---@alias HttpStatusCode 200 | 404 | 500

---@type Schema<HttpStatusCode>
local status_code = c.union({
  c.literal(200),
  c.literal(404),
  c.literal(500)
})

---@type HttpStatusCode
local code = status_code:parse(404)
```

## Examples

Examples have been moved to **[Examples](examples.md)**.
