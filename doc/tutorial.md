# chotto.lua Tutorial

A comprehensive guide to using chotto.lua for data validation in Lua projects.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Basic Types](#basic-types)
3. [Type Annotations](#type-annotations)
4. [Error Handling](#error-handling)
5. [Complex Types](#complex-types)
6. [Advanced Patterns](#advanced-patterns)
7. [Best Practices](#best-practices)

## Getting Started

### Installation and Setup

```lua
-- Require the library
local chotto = require('chotto')

-- Create your first schema
local name_schema = chotto.string()

-- Validate data
local result = name_schema.parse("Alice") -- Returns "Alice"
```

## Basic Types

chotto.lua provides all fundamental Lua types:

### Primitive Types

```lua
-- Numbers
local int_schema = chotto.integer()    -- Only integers
local num_schema = chotto.number()     -- Any number (including floats)

-- Text
local str_schema = chotto.string()     -- String values

-- Boolean
local bool_schema = chotto.boolean()   -- true or false

-- Nil values
local nil_schema = chotto.null()       -- Only nil (note: null(), not nil())

-- Functions
local func_schema = chotto.func()      -- Function values

-- Any value
local any_schema = chotto.any()        -- Accepts anything
local unknown_schema = chotto.unknown() -- Same as any, but semantically "unknown"
```

### Usage Examples

```lua
-- Valid cases
print(int_schema.parse(42))        -- 42
print(str_schema.parse("hello"))   -- "hello"
print(bool_schema.parse(true))     -- true
print(nil_schema.parse(nil))       -- nil

-- Invalid cases (will throw errors)
-- int_schema.parse(3.14)          -- Error: Expected integer
-- str_schema.parse(42)            -- Error: Expected string
```

## Type Annotations

**Important**: Due to luaCATS limitations, you must provide explicit type annotations for complex schemas.

### Basic Annotation Pattern

```lua
-- ✅ Correct - with type annotation
---@type Schema<string>
local name_schema = chotto.string()

-- ✅ Also fine for simple types (annotation optional)
local simple_string = chotto.string()
```

### Complex Type Annotations

```lua
-- Object type annotation
---@type Schema<{name: string, age: integer}>
local user_schema = chotto.object({
  name = chotto.string(),
  age = chotto.integer(),
})

-- Array type annotation
---@type Schema<string[]>
local string_array = chotto.array(chotto.string())

-- Union type annotation
---@type Schema<string | number>
local string_or_number = chotto.union({
  chotto.string(),
  chotto.number()
})
```

## Error Handling

chotto.lua uses Lua's error throwing mechanism. Always use `pcall()` for safe validation.

### Basic Error Handling

```lua
local schema = chotto.integer()

-- Direct parsing (throws on error)
local result = schema.parse(42) -- Works fine

-- Safe parsing with pcall
local ok, result = pcall(schema.parse, "not a number")
if ok then
  print("Valid:", result)
else
  print("Error:", result) -- result contains error message
end
```

### Production-Ready Error Handling

```lua
---@type Schema<{email: string, age: integer}>
local user_schema = chotto.object({
  email = chotto.string(),
  age = chotto.integer(),
})

-- Safe validation function
local function validate_user(data)
  local ok, result = pcall(user_schema.parse, data)
  if ok then
    return result, nil
  else
    return nil, result -- return nil + error message
  end
end

-- Usage
local user_data = { email = "alice@example.com" } -- missing age

local user, err = validate_user(user_data)
if err then
  print("Validation failed:", err)
  -- Handle the error appropriately
else
  print("Welcome,", user.email)
end
```

## Complex Types

### Objects

Objects validate table structures with typed fields:

```lua
---@type Schema<{name: string, age: integer, active: boolean}>
local user_schema = chotto.object({
  name = chotto.string(),
  age = chotto.integer(),
  active = chotto.boolean(),
})

-- Valid object
local user = user_schema.parse({
  name = "Bob",
  age = 30,
  active = true,
  extra_field = "allowed" -- Extra fields are preserved (zod-like behavior)
})

print(user.name)        -- "Bob"
print(user.extra_field) -- "allowed"
```

### Arrays

Arrays validate sequences of the same type:

```lua
---@type Schema<integer[]>
local number_list = chotto.array(chotto.integer())

local numbers = number_list.parse({1, 2, 3, 4, 5})
print(numbers[1]) -- 1

-- Nested arrays
---@type Schema<string[][]>
local string_matrix = chotto.array(chotto.array(chotto.string()))

local matrix = string_matrix.parse({
  {"a", "b"},
  {"c", "d"}
})
```

### Optional Fields

Use `chotto.optional()` for fields that can be nil:

```lua
---@type Schema<{name: string, nickname?: string}>
local person_schema = chotto.object({
  name = chotto.string(),
  nickname = chotto.optional(chotto.string()),
})

-- Both are valid
local person1 = person_schema.parse({ name = "Alice" })
local person2 = person_schema.parse({ name = "Bob", nickname = "Bobby" })
```

### Union Types

Union types accept multiple possible types:

```lua
---@type Schema<string | number | boolean>
local flexible_schema = chotto.union({
  chotto.string(),
  chotto.number(),
  chotto.boolean()
})

-- All of these work
local val1 = flexible_schema.parse("hello")
local val2 = flexible_schema.parse(42)
local val3 = flexible_schema.parse(true)
```

### Tuples

Tuples validate fixed-length arrays with specific types at each position:

```lua
---@type Schema<[string, number, boolean]>
local tuple_schema = chotto.tuple({
  chotto.string(),
  chotto.number(),
  chotto.boolean()
})

local data = tuple_schema.parse({"hello", 42, true})
print(data[1]) -- "hello"
print(data[2]) -- 42
print(data[3]) -- true
```

### Literal Types

Literal types only accept specific values:

```lua
---@type Schema<"success">
local success_schema = chotto.literal("success")

---@type Schema<"pending" | "completed" | "failed">
local status_schema = chotto.union({
  chotto.literal("pending"),
  chotto.literal("completed"),
  chotto.literal("failed")
})

local status = status_schema.parse("completed") -- Works
-- status_schema.parse("invalid")               -- Error
```

### Table Types

For general key-value validation:

```lua
-- Any table
---@type Schema<table>
local any_table = chotto.table()

-- Typed key-value pairs
---@type Schema<table<string, number>>
local string_to_number = chotto.table(chotto.string(), chotto.number())

local scores = string_to_number.parse({
  alice = 95,
  bob = 87,
  charlie = 92
})
```

## Advanced Patterns

### Nested Objects

```lua
---@type Schema<{user: {name: string, email: string}, preferences: {theme: string, notifications: boolean}}>
local app_config = chotto.object({
  user = chotto.object({
    name = chotto.string(),
    email = chotto.string(),
  }),
  preferences = chotto.object({
    theme = chotto.string(),
    notifications = chotto.boolean(),
  })
})

local config = app_config.parse({
  user = {
    name = "Alice",
    email = "alice@example.com"
  },
  preferences = {
    theme = "dark",
    notifications = true
  }
})
```

### API Response Validation

```lua
---@type Schema<{status: "success" | "error", data?: table, message?: string}>
local api_response = chotto.object({
  status = chotto.union({
    chotto.literal("success"),
    chotto.literal("error")
  }),
  data = chotto.optional(chotto.table()),
  message = chotto.optional(chotto.string())
})

-- Validate API responses safely
local function handle_api_response(raw_response)
  local response, err = pcall(api_response.parse, raw_response)
  if err then
    print("Invalid API response:", err)
    return nil
  end

  if response.status == "success" then
    return response.data
  else
    print("API error:", response.message)
    return nil
  end
end
```

### Configuration Validation

```lua
---@type Schema<{database: {host: string, port: integer}, logging: {level: "debug" | "info" | "warn" | "error", file?: string}}>
local config_schema = chotto.object({
  database = chotto.object({
    host = chotto.string(),
    port = chotto.integer(),
  }),
  logging = chotto.object({
    level = chotto.union({
      chotto.literal("debug"),
      chotto.literal("info"),
      chotto.literal("warn"),
      chotto.literal("error")
    }),
    file = chotto.optional(chotto.string())
  })
})

-- Load and validate configuration
local function load_config(config_file)
  local raw_config = dofile(config_file) -- or JSON.decode(), etc.

  local config, err = pcall(config_schema.parse, raw_config)
  if err then
    error("Configuration validation failed: " .. err)
  end

  return config
end
```

## Best Practices

### 1. Always Use Type Annotations

```lua
-- ✅ Good
---@type Schema<{name: string, age: integer}>
local user_schema = chotto.object({
  name = chotto.string(),
  age = chotto.integer(),
})

-- ❌ Bad - loses type information
local user_schema = chotto.object({
  name = chotto.string(),
  age = chotto.integer(),
})
```

### 2. Use pcall() for All Validation

```lua
-- ✅ Good - safe validation
local ok, result = pcall(schema.parse, data)
if ok then
  -- use result
else
  -- handle error
end

-- ❌ Bad - can crash your program
local result = schema.parse(data) -- throws on invalid data
```

### 3. Create Reusable Schemas

```lua
-- Define common schemas once
---@type Schema<string>
local email_schema = chotto.string() -- Could add email validation

---@type Schema<{name: string, email: string}>
local user_schema = chotto.object({
  name = chotto.string(),
  email = email_schema, -- Reuse
})

---@type Schema<{users: {name: string, email: string}[]}>
local user_list_schema = chotto.object({
  users = chotto.array(user_schema) -- Reuse again
})
```

### 4. Validation Helper Functions

```lua
-- Create utility functions for common patterns
local function safe_parse(schema, data)
  local ok, result = pcall(schema.parse, data)
  return ok and result or nil, not ok and result or nil
end

-- Usage
local user, err = safe_parse(user_schema, user_data)
if err then
  print("Validation error:", err)
  return
end

print("Valid user:", user.name)
```

### 5. Error Context

```lua
-- Add context to your validation
local function validate_user_registration(data)
  local user, err = pcall(user_schema.parse, data)
  if err then
    return nil, "User registration validation failed: " .. err
  end
  return user, nil
end
```

## Migration from Other Libraries

If you're coming from TypeScript Zod, see [Zod Comparison](zod-comparison.md) for detailed differences and migration strategies.

For questions and examples, check out [Examples](examples.md) for a comprehensive API reference with practical use cases.