local M = {}

---@generic T
---@alias Validator<T> fun(x: unknown): T

---A schema for validating data.
---`.parse()` throws an error if `validatee` is not valid `T`.
---@generic T
---@alias Schema<T> { parse: fun(validatee: unknown): T }

---@type Validator<integer>
local function is_integer(x)
  if type(x) == 'number' and math.floor(x) == x then
    return x
  end
  error('Expected integer, got: ' .. tostring(x))
end

---@return Schema<integer>
function M.integer()
  return { parse = is_integer }
end

---@type Validator<number>
local function is_number(x)
  if type(x) == 'number' then
    return x
  end
  error('Expected number, got: ' .. tostring(x))
end

---@return Schema<number>
function M.number()
  return { parse = is_number }
end

---@type Validator<string>
local function is_string(x)
  if type(x) == 'string' then
    return x
  end
  error('Expected string, got: ' .. tostring(x))
end

---@return Schema<string>
function M.string()
  return { parse = is_string }
end

---@type Validator<boolean>
local function is_boolean(x)
  if type(x) == 'boolean' then
    return x
  end
  error('Expected boolean, got: ' .. tostring(x))
end

---@return Schema<boolean>
function M.boolean()
  return { parse = is_boolean }
end

---@type Validator<nil>
local function is_nil(x)
  if x == nil then
    return nil
  end
  error('Expected nil, got: ' .. tostring(x))
end

---@return Schema<nil>
function M.null()
  return { parse = is_nil }
end

---@type Validator<any>
local function is_any(x)
  return x
end

---@return Schema<any>
function M.any()
  return { parse = is_any }
end

---@type Validator<unknown>
local function is_unknown(x)
  return x
end

---@return Schema<unknown>
function M.unknown()
  return { parse = is_unknown }
end

---@type Validator<function>
local function is_func(x)
  if type(x) == 'function' then
    return x
  end
  error('Expected function, got: ' .. type(x))
end

---@return Schema<function>
function M.func()
  return { parse = is_func }
end

---Creates an object schema. The return type should be explicitly annotated.
---```lua
------@type Schema<{a: integer, b: string}>
---local schema = M.object({
---  a = M.integer(),
---  b = M.string(),
---})
---```
---@param raw_schema table<string, Schema<unknown>>
---@return Schema<unknown>
function M.object(raw_schema)
  ---@param obj unknown
  ---@return unknown
  local function is_that_object(obj)
    if type(obj) ~= 'table' then
      error('Expected object, got: ' .. type(obj))
    end

    local validated = {}

    -- Validate all required fields
    for key, schema in pairs(raw_schema) do
      local field_value = obj[key]
      if field_value == nil then
        error('Missing required field: ' .. tostring(key))
      end
      validated[key] = schema.parse(field_value)
    end

    -- Copy over any extra fields (zod-like behavior: allow unknown properties)
    for key, value in pairs(obj) do
      if raw_schema[key] == nil then
        validated[key] = value
      end
    end

    return validated
  end

  return { parse = is_that_object }
end

---Creates an array schema. The return type should be explicitly annotated.
---```lua
------@type Schema<integer[]>
---local schema = M.array(M.integer())
---```
---@param item_schema Schema<unknown>
---@return Schema<unknown>
function M.array(item_schema)
  ---@param arr unknown
  ---@return unknown
  local function is_that_array(arr)
    if type(arr) ~= 'table' then
      error('Expected array, got: ' .. type(arr))
    end

    local validated = {}

    for i, item in ipairs(arr) do
      validated[i] = item_schema.parse(item)
    end

    return validated
  end

  return { parse = is_that_array }
end

---Creates an optional schema that accepts nil.
---```lua
------@type Schema<integer?>
---local schema = M.optional(M.integer())
---```
---@param schema Schema<unknown>
---@return Schema<unknown>
function M.optional(schema)
  ---@param x unknown
  ---@return unknown
  local function is_optional(x)
    if x == nil then
      return nil
    end
    return schema.parse(x)
  end

  return { parse = is_optional }
end

---Creates a union schema that accepts multiple types. Type annotation required.
---```lua
------@type Schema<string | number>
---local schema = M.union({ M.string(), M.number() })
---```
---@param schemas Schema<unknown>[]
---@return Schema<unknown>
function M.union(schemas)
  ---@param x unknown
  ---@return unknown
  local function is_union(x)
    local errors = {}

    for i, schema in ipairs(schemas) do
      local ok, result = pcall(schema.parse, x)
      if ok then
        return result
      else
        table.insert(errors, 'Option ' .. i .. ': ' .. result)
      end
    end

    error('Union validation failed. Errors: ' .. table.concat(errors, '; '))
  end

  return { parse = is_union }
end

---Creates a tuple schema for fixed-length arrays. Type annotation required.
---```lua
------@type Schema<[string, number, boolean]>
---local schema = M.tuple({ M.string(), M.number(), M.boolean() })
---```
---@param schemas Schema<unknown>[]
---@return Schema<unknown>
function M.tuple(schemas)
  ---@param x unknown
  ---@return unknown
  local function is_tuple(x)
    if type(x) ~= 'table' then
      error('Expected tuple (table), got: ' .. type(x))
    end

    local validated = {}

    for i, schema in ipairs(schemas) do
      local value = x[i]
      if value == nil then
        error('Missing tuple element at index ' .. i)
      end
      validated[i] = schema.parse(value)
    end

    -- Check for extra elements
    for i = #schemas + 1, #x do
      if x[i] ~= nil then
        error('Unexpected extra element at index ' .. i)
      end
    end

    return validated
  end

  return { parse = is_tuple }
end

---Creates a table schema. Can be used for general tables or typed key-value pairs.
---
---Examples:
---```lua
------@type Schema<table>
---local any_table = M.table()
---
------@type Schema<table<string, number>>
---local string_to_number = M.table(M.string(), M.number())
---```
---@param key_schema? Schema<unknown>
---@param value_schema? Schema<unknown>
---@return Schema<unknown>
function M.table(key_schema, value_schema)
  ---@param x unknown
  ---@return unknown
  local function is_table(x)
    if type(x) ~= 'table' then
      error('Expected table, got: ' .. type(x))
    end

    -- If no schemas provided, accept any table
    if not key_schema and not value_schema then
      return x
    end

    local validated = {}

    for k, v in pairs(x) do
      local validated_key = key_schema and key_schema.parse(k) or k
      local validated_value = value_schema and value_schema.parse(v) or v
      validated[validated_key] = validated_value
    end

    return validated
  end

  return { parse = is_table }
end

---Creates a literal schema that only accepts a specific value.
---```lua
------@type Schema<"success">
---local success_schema = M.literal("success")
---```
---@param expected_value unknown
---@return Schema<unknown>
function M.literal(expected_value)
  ---@param x unknown
  ---@return unknown
  local function is_literal(x)
    if x == expected_value then
      return x
    end
    error('Expected literal value ' .. tostring(expected_value) .. ', got: ' .. tostring(x))
  end

  return { parse = is_literal }
end

return M
