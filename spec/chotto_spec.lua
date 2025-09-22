describe('chotto', function()
  local c = require('chotto')

  describe('integer()', function()
    it('should accept integers', function()
      local schema = c.integer()
      assert.are.equal(42, schema.parse(42))
      assert.are.equal(0, schema.parse(0))
      assert.are.equal(-10, schema.parse(-10))
    end)

    it('should reject non-integers', function()
      local schema = c.integer()
      assert.has_error(function()
        schema.parse(3.14)
      end)
      assert.has_error(function()
        schema.parse('42')
      end)
      assert.has_error(function()
        schema.parse(nil)
      end)
    end)
  end)

  describe('string()', function()
    it('should accept strings', function()
      local schema = c.string()
      assert.are.equal('hello', schema.parse('hello'))
      assert.are.equal('', schema.parse(''))
    end)

    it('should reject non-strings', function()
      local schema = c.string()
      assert.has_error(function()
        schema.parse(42)
      end)
      assert.has_error(function()
        schema.parse(nil)
      end)
    end)
  end)

  describe('number()', function()
    it('should accept numbers', function()
      local schema = c.number()
      assert.are.equal(42, schema.parse(42))
      assert.are.equal(3.14, schema.parse(3.14))
      assert.are.equal(-0.5, schema.parse(-0.5))
    end)
  end)

  describe('boolean()', function()
    it('should accept booleans', function()
      local schema = c.boolean()
      assert.are.equal(true, schema.parse(true))
      assert.are.equal(false, schema.parse(false))
    end)
  end)

  describe('null()', function()
    it('should accept nil', function()
      local schema = c.null()
      assert.are.equal(nil, schema.parse(nil))
    end)

    it('should reject non-nil values', function()
      local schema = c.null()
      assert.has_error(function()
        schema.parse('not nil')
      end)
      assert.has_error(function()
        schema.parse(42)
      end)
    end)
  end)

  describe('any()', function()
    it('should accept anything', function()
      local schema = c.any()
      assert.are.equal('hello', schema.parse('hello'))
      assert.are.equal(42, schema.parse(42))
      assert.are.equal(nil, schema.parse(nil))
      assert.are.same({}, schema.parse({}))
    end)
  end)

  describe('func()', function()
    it('should accept functions', function()
      local schema = c.func()
      local test_func = function() end
      assert.are.equal(test_func, schema.parse(test_func))
    end)

    it('should reject non-functions', function()
      local schema = c.func()
      assert.has_error(function()
        schema.parse('not a function')
      end)
    end)
  end)

  describe('object()', function()
    it('should validate object structure', function()
      local schema = c.object({
        name = c.string(),
        age = c.integer(),
      })

      local result = schema.parse({ name = 'Alice', age = 30 })
      assert.are.equal('Alice', result.name)
      assert.are.equal(30, result.age)
    end)

    it('should reject missing fields', function()
      local schema = c.object({
        name = c.string(),
        age = c.integer(),
      })

      assert.has_error(function()
        schema.parse({ name = 'Alice' })
      end)
      assert.has_error(function()
        schema.parse({ age = 30 })
      end)
    end)

    it('should allow and preserve unknown fields (zod-like behavior)', function()
      local schema = c.object({
        name = c.string(),
      })

      local result = schema.parse({ name = 'Alice', extra = 'field', another = 42 })
      assert.are.equal('Alice', result.name)
      assert.are.equal('field', result.extra)
      assert.are.equal(42, result.another)
    end)
  end)

  describe('array()', function()
    it('should validate array elements', function()
      local schema = c.array(c.string())

      local result = schema.parse({ 'a', 'b', 'c' })
      assert.are.equal('a', result[1])
      assert.are.equal('b', result[2])
      assert.are.equal('c', result[3])
    end)

    it('should reject invalid elements', function()
      local schema = c.array(c.string())
      assert.has_error(function()
        schema.parse({ 'a', 42, 'c' })
      end)
    end)
  end)

  describe('optional()', function()
    it('should accept nil', function()
      local schema = c.optional(c.string())
      assert.are.equal(nil, schema.parse(nil))
      assert.are.equal('hello', schema.parse('hello'))
    end)
  end)

  describe('union()', function()
    it('should accept any of the provided types', function()
      local schema = c.union({ c.string(), c.number() })
      assert.are.equal('hello', schema.parse('hello'))
      assert.are.equal(42, schema.parse(42))
    end)

    it('should reject types not in the union', function()
      local schema = c.union({ c.string(), c.number() })
      assert.has_error(function()
        schema.parse(true)
      end)
    end)
  end)

  describe('tuple()', function()
    it('should validate fixed-length arrays', function()
      local schema = c.tuple({ c.string(), c.number(), c.boolean() })

      local result = schema.parse({ 'hello', 42, true })
      assert.are.equal('hello', result[1])
      assert.are.equal(42, result[2])
      assert.are.equal(true, result[3])
    end)

    it('should reject wrong length', function()
      local schema = c.tuple({ c.string(), c.number() })
      assert.has_error(function()
        schema.parse({ 'hello' })
      end)
      assert.has_error(function()
        schema.parse({ 'hello', 42, 'extra' })
      end)
    end)
  end)

  describe('table()', function()
    it('should accept any table when no schemas provided', function()
      local schema = c.table()
      local input = { a = 1, b = 'hello' }
      assert.are.same(input, schema.parse(input))
    end)

    it('should validate key-value pairs', function()
      local schema = c.table(c.string(), c.number())

      local result = schema.parse({ hello = 1, world = 2 })
      assert.are.equal(1, result.hello)
      assert.are.equal(2, result.world)
    end)
  end)

  describe('literal()', function()
    it('should only accept the exact value', function()
      local schema = c.literal('success')
      assert.are.equal('success', schema.parse('success'))
      assert.has_error(function()
        schema.parse('failure')
      end)
      assert.has_error(function()
        schema.parse('Success')
      end)
    end)

    it('should work with numbers', function()
      local schema = c.literal(42)
      assert.are.equal(42, schema.parse(42))
      assert.has_error(function()
        schema.parse(41)
      end)
    end)
  end)

  describe('integration tests', function()
    it('should handle complex nested schemas', function()
      local schema = c.object({
        user = c.object({
          name = c.string(),
          age = c.integer(),
        }),
        status = c.union({ c.literal('active'), c.literal('inactive') }),
        tags = c.array(c.string()),
        metadata = c.optional(c.table()),
      })

      local valid_data = {
        user = { name = 'Alice', age = 25 },
        status = 'active',
        tags = { 'admin', 'user' },
        metadata = { created = '2023-01-01' },
      }

      local result = schema.parse(valid_data)
      assert.are.equal('Alice', result.user.name)
      assert.are.equal('active', result.status)
      assert.are.equal('admin', result.tags[1])
    end)
  end)

  describe('error handling with pcall', function()
    it('should throw errors that can be caught with pcall', function()
      local schema = c.string()

      -- Success case with pcall
      local ok, result = pcall(schema.parse, 'hello')
      assert.is_true(ok)
      assert.are.equal('hello', result)

      -- Error case with pcall
      local ok2, error_msg = pcall(schema.parse, 42)
      assert.is_false(ok2)
      assert.is_string(error_msg)
      assert.matches('Expected string', error_msg)
    end)

    it('should allow graceful error handling for validation', function()
      local user_schema = c.object({
        name = c.string(),
        age = c.integer(),
      })

      -- Function that safely validates and returns result or nil + error
      local function safe_validate(data)
        local ok, result = pcall(user_schema.parse, data)
        if ok then
          return result, nil
        else
          return nil, result -- result is the error message
        end
      end

      -- Valid data
      local user, err = safe_validate({ name = 'Bob', age = 30 })
      assert.is_nil(err)
      assert.are.equal('Bob', user.name)
      assert.are.equal(30, user.age)

      -- Invalid data
      local user2, err2 = safe_validate({ name = 'Alice' })
      assert.is_nil(user2)
      assert.is_string(err2)
      assert.matches('Missing required field', err2)
    end)

    it('should enable union-like validation with fallback', function()
      local string_schema = c.string()
      local number_schema = c.number()

      -- Manual union implementation using pcall
      local function parse_string_or_number(value)
        -- Try string first
        local ok, result = pcall(string_schema.parse, value)
        if ok then
          return result
        end

        -- Try number as fallback
        local ok2, result2 = pcall(number_schema.parse, value)
        if ok2 then
          return result2
        end

        -- Neither worked
        error('Expected string or number')
      end

      assert.are.equal('hello', parse_string_or_number('hello'))
      assert.are.equal(42, parse_string_or_number(42))

      local ok, err = pcall(parse_string_or_number, true)
      assert.is_false(ok)
      assert.matches('Expected string or number', err)
    end)
  end)
end)
