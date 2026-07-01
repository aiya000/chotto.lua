# chotto.lua vs TypeScript Zod: Detailed Comparison

A comprehensive comparison between chotto.lua and TypeScript Zod, highlighting similarities, differences, and migration strategies.

## Table of Contents

1. [Philosophy & Goals](#philosophy--goals)
2. [Syntax Comparison](#syntax-comparison)
3. [Feature Comparison](#feature-comparison)
4. [Type System Differences](#type-system-differences)
5. [Error Handling](#error-handling)
6. [Migration Guide](#migration-guide)
7. [Performance Considerations](#performance-considerations)

## Philosophy & Goals

### Shared Philosophy

Both chotto.lua and TypeScript Zod share the same core philosophy:

- **Schema-first validation** - Define your data structure once, get validation and type safety
- **Runtime validation** - Validate data at runtime, not just compile time
- **Composable schemas** - Build complex types from simple primitives
- **Developer experience** - Clear, readable validation code

### Different Design Goals

**TypeScript Zod:**
- Automatic type inference from schemas
- Zero-runtime cost for TypeScript types
- Advanced TypeScript features (conditional types, template literals)
- Browser and Node.js runtime compatibility

**chotto.lua:**
- Lua ecosystem integration
- luaCATS type annotation support
- Pure Lua implementation (no dependencies)
- Lua conventions and idioms

### 🎯 The Big-Picture Vision

> **chotto.lua aims to be "Zod for Lua" — fully, not just partially.**

The main limitation today is that **luaCATS generics** are not yet powerful enough
to automatically infer result types from schema definitions the way TypeScript's
type system can.
As a result, users currently need to write explicit `---@type` annotations for
complex schemas.

This is a **temporary** constraint, not a design decision.
Once luaCATS generics evolve to support the necessary level of type propagation,
chotto.lua intends to provide exactly the same seamless, automatic type inference
that Zod provides in TypeScript — with no manual annotations required.

In short: **when LuaCATS generics become strong enough, chotto.lua aims to work
exactly like Zod.**

## Syntax Comparison

### Basic Types

| Type | TypeScript Zod | chotto.lua |
|------|----------------|------------|
| **String** | `z.string()` | `chotto.string()` |
| **Number** | `z.number()` | `chotto.number()` |
| **Integer** | `z.number().int()` | `chotto.integer()` |
| **Boolean** | `z.boolean()` | `chotto.boolean()` |
| **Null/Nil** | `z.null()` | `chotto.null()` |
| **Function** | `z.function()` | `chotto.func()` |
| **Any** | `z.any()` | `chotto.any()` |
| **Unknown** | `z.unknown()` | `chotto.unknown()` |

**Key Differences:**
- `chotto.func()` instead of `chotto.function()` (Lua reserved word)
- `chotto.null()` instead of `chotto.nil()` (Lua reserved word)
- `chotto.integer()` is a separate function, not a method chain

### Objects

**TypeScript Zod:**
```typescript
const UserSchema = z.object({
  name: z.string(),
  age: z.number(),
  email: z.string().email()
});

type User = z.infer<typeof UserSchema>; // Automatic type inference
```

**chotto.lua:**
```lua
---@type Schema<{name: string, age: number, email: string}>
local user_schema = chotto.object({
  name = chotto.string(),
  age = chotto.number(),
  email = chotto.string() -- No built-in email validation
})

-- Type annotation is manual and required
```

### Arrays

**TypeScript Zod:**
```typescript
const StringArraySchema = z.array(z.string());
type StringArray = z.infer<typeof StringArraySchema>; // string[]
```

**chotto.lua:**
```lua
---@type Schema<string[]>
local string_array_schema = chotto.array(chotto.string())
```

### Optional Fields

**TypeScript Zod:**
```typescript
const PersonSchema = z.object({
  name: z.string(),
  age: z.number().optional()
});
```

**chotto.lua:**
```lua
---@type Schema<{name: string, age?: number}>
local person_schema = chotto.object({
  name = chotto.string(),
  age = chotto.optional(chotto.number())
})
```

### Union Types

**TypeScript Zod:**
```typescript
const StringOrNumberSchema = z.union([z.string(), z.number()]);
// Or using z.string().or(z.number())
```

**chotto.lua:**
```lua
---@type Schema<string | number>
local string_or_number = chotto.union({
  chotto.string(),
  chotto.number()
})
```

### Literal Types

**TypeScript Zod:**
```typescript
const StatusSchema = z.enum(["pending", "success", "error"]);
// Or z.literal("success").or(z.literal("error"))...
```

**chotto.lua:**
```lua
---@type Schema<"pending" | "success" | "error">
local status_schema = chotto.union({
  chotto.literal("pending"),
  chotto.literal("success"),
  chotto.literal("error")
})
```

## Feature Comparison

### ✅ Features Available in Both

| Feature | Zod | chotto.lua | Notes |
|---------|-----|------------|-------|
| **Basic types** | ✅ | ✅ | Full coverage |
| **Objects** | ✅ | ✅ | Extra properties preserved |
| **Arrays** | ✅ | ✅ | Full support |
| **Nested validation** | ✅ | ✅ | Full support |
| **Union types** | ✅ | ✅ | OR logic |
| **Optional fields** | ✅ | ✅ | Different syntax |
| **Literal values** | ✅ | ✅ | Exact value matching |
| **Tuples** | ✅ | ✅ | Fixed-length arrays |
| **Error throwing** | ✅ | ✅ | Runtime validation errors |

### 🔄 Different Implementation

| Feature | Zod | chotto.lua | Difference |
|---------|-----|------------|------------|
| **Method chaining** | `z.string().optional()` | `chotto.optional(chotto.string())` | Function composition vs methods |
| **Type inference** | Automatic | Manual luaCATS annotations | Language limitation |
| **Error handling** | Try/catch or `.safeParse()` | `:safe_parse()` or `pcall()` | `:safe_parse()` is the recommended equivalent; `pcall()` available for finer control |
| **Reserved words** | `z.function()`, `z.null()` | `chotto.func()`, `chotto.null()` | Lua keyword conflicts |

### ❌ Zod Features Not Available in chotto.lua

| Feature | Why Not Available |
|---------|-------------------|
| **`.refine()`** | Not implemented yet |
| **`.transform()`** | Not implemented yet |
| **`.default()`** | Not implemented yet |
| **String validations** | `.email()`, `.url()`, etc. not implemented |
| **Number validations** | `.min()`, `.max()`, `.positive()` not implemented |
| **Date validation** | Lua doesn't have built-in Date type |
| **Async validation** | Not applicable to Lua |
| **Schema preprocessing** | Not implemented yet |

### ✨ chotto.lua Unique Features

| Feature | Description |
|---------|-------------|
| **Pure Lua** | No dependencies, works in any Lua environment |
| **luaCATS integration** | First-class support for Lua LSP type checking |
| **Lua conventions** | Uses `pcall()`, function composition, Lua idioms |

## Type System Differences

### Automatic vs Manual Type Annotations

**TypeScript Zod (Automatic):**
```typescript
const UserSchema = z.object({
  name: z.string(),
  age: z.number()
});

type User = z.infer<typeof UserSchema>; // Automatically: { name: string, age: number }

const user = UserSchema.parse(data); // user is typed as User
```

**chotto.lua (Manual):**
```lua
---@type Schema<{name: string, age: number}>  -- Manual annotation required
local user_schema = chotto.object({
  name = chotto.string(),
  age = chotto.number()
})

local user = user_schema:parse(data) -- user is typed based on annotation
```

### luaCATS Limitations

Due to luaCATS limitations, chotto.lua requires explicit type annotations:

**Why Manual Annotations Are Needed:**
```lua
-- Without annotation - type information is lost
local schema = chotto.object({
  name = chotto.string(),
  age = chotto.number()
})
-- Lua LSP doesn't know what type schema:parse() returns

-- With annotation - type information is preserved
---@type Schema<{name: string, age: number}>
local schema = chotto.object({
  name = chotto.string(),
  age = chotto.number()
})
-- Lua LSP knows schema:parse() returns {name: string, age: number}
```

## Error Handling

### TypeScript Zod

```typescript
// Method 1: Exception handling
try {
  const user = UserSchema.parse(data);
  console.log(user.name);
} catch (error) {
  console.error("Validation failed:", error.message);
}

// Method 2: Safe parsing
const result = UserSchema.safeParse(data);
if (result.success) {
  console.log(result.data.name);
} else {
  console.error("Validation failed:", result.error);
}
```

### chotto.lua

```lua
-- Method 1: Exception handling with pcall
local ok, user = pcall(function() return user_schema:parse(data) end)
if ok then
  print(user.name)
else
  print("Validation failed:", user) -- user contains error message
end

-- Method 2: Helper function (similar to safeParse)
local function safe_parse(schema, data)
  local ok, result = schema:safe_parse(data)
  if ok == true then
    return result, nil
  end
  return nil, result
end

local user, err = safe_parse(user_schema, data)
if err then
  print("Validation failed:", err)
else
  print(user.name)
end
```

## Migration Guide

### From Zod to chotto.lua

#### 1. Basic Schema Translation

**Before (Zod):**
```typescript
const UserSchema = z.object({
  name: z.string(),
  age: z.number().optional(),
  email: z.string().email()
});
```

**After (chotto.lua):**
```lua
---@type Schema<{name: string, age?: number, email: string}>
local user_schema = chotto.object({
  name = chotto.string(),
  age = chotto.optional(chotto.number()),
  email = chotto.string() -- Note: no .email() validation
})
```

#### 2. Method Chaining to Function Composition

**Before (Zod):**
```typescript
const schema = z.string().optional();
const arraySchema = z.array(z.string()).optional();
```

**After (chotto.lua):**
```lua
---@type Schema<string?>
local schema = chotto.optional(chotto.string())

---@type Schema<string[]?>
local array_schema = chotto.optional(chotto.array(chotto.string()))
```

#### 3. Error Handling Migration

**Before (Zod):**
```typescript
const result = UserSchema.safeParse(data);
if (result.success) {
  // Use result.data
} else {
  // Handle result.error
}
```

**After (chotto.lua):**
```lua
local ok, result = pcall(function() return user_schema:parse(data) end)
if ok then
  -- Use result
else
  -- Handle result (error message)
end

-- Or using helper function
local function safe_parse(schema, data)
  local ok, result = schema:safe_parse(data)
  if ok == true then
    return result, nil
  end
  return nil, result
end

local user, err = safe_parse(user_schema, data)
if err then
  -- Handle err
else
  -- Use user
end
```

#### 4. Type Inference Migration

**Before (Zod):**
```typescript
const UserSchema = z.object({
  name: z.string(),
  age: z.number()
});

type User = z.infer<typeof UserSchema>; // Automatic

function processUser(user: User) {
  // TypeScript knows user.name is string
}
```

**After (chotto.lua):**
```lua
---@type Schema<{name: string, age: number}>
local user_schema = chotto.object({
  name = chotto.string(),
  age = chotto.number()
})

---@param user {name: string, age: number}
local function process_user(user)
  -- Lua LSP knows user.name is string
end
```

### Migration Checklist

- [ ] Replace `z.` with `chotto.`
- [ ] Add manual type annotations with `---@type Schema<...>`
- [ ] Convert method chains to function composition
- [ ] Replace `.safeParse()` with `:safe_parse()` (or `pcall()` for lower-level control)
- [ ] Change `z.function()` to `chotto.func()`
- [ ] Change `z.null()` to `chotto.null()`
- [ ] Remove unsupported validations (`.email()`, `.min()`, etc.)
- [ ] Update error handling patterns

## Performance Considerations

### TypeScript Zod

- **Compile-time**: Type checking happens at TypeScript compile time
- **Runtime**: Minimal overhead for type-checked code
- **Bundle size**: Larger JavaScript bundle size
- **Validation speed**: Fast, optimized JavaScript execution

### chotto.lua

- **Compile-time**: luaCATS type checking (if using Lua LSP)
- **Runtime**: Pure Lua execution, no additional overhead
- **Memory usage**: Minimal memory footprint
- **Validation speed**: Good performance, depends on Lua implementation

### Performance Tips

**For chotto.lua:**
```lua
-- Cache schemas for better performance
local user_schema = chotto.object({...}) -- Create once, reuse many times

-- Use pcall efficiently
local function validate_many_users(users)
  for i, user_data in ipairs(users) do
    local ok, parsed_user = pcall(function() return user_schema:parse(user_data) end)
    if not ok then
      return nil, "User " .. i .. " invalid: " .. parsed_user
    end
    users[i] = parsed_user
  end
  return users
end
```

## Conclusion

chotto.lua brings the power and developer experience of TypeScript Zod to the Lua ecosystem, with adaptations for Lua's conventions and constraints. While some advanced features are not yet implemented, the core validation capabilities provide a solid foundation for type-safe Lua development.

**Choose chotto.lua when:**
- You're working in Lua and want Zod-like validation
- You need runtime validation with type safety
- You want to integrate with luaCATS for LSP support
- You prefer pure Lua solutions without dependencies

**Stick with Zod when:**
- You're working in TypeScript/JavaScript
- You need advanced features like `.transform()`, `.refine()`
- You require automatic type inference
- You need built-in string/number validations

For detailed usage examples, see [Examples](examples.md) and [Tutorial](tutorial.md).