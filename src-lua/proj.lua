--- Simple binding to proj.4: https://github.com/OSGeo/proj.4

-- (c) Copyright 2015-2016 Geoff Leyland.
-- See LICENSE for license information


local shortcuts = require"proj.shortcuts"

local ok, ffi = pcall(require, "ffi")
if not ok then ffi = nil end

local PJ, q, r

if ffi then
  -- Scratch space for passing numbers in and out
  q = ffi.new("double[1]", 0)
  r = ffi.new("double[1]", 0)

  ffi.cdef
  [[
  typedef void *projPJ;
  projPJ pj_init_plus(const char *);
  int pj_transform(projPJ, projPJ, long, int, double *, double *, double *);
  int pj_is_latlong(projPJ pj);
  void pj_free(projPJ *);
  int *pj_get_errno_ref();
  char *pj_strerrno(int);
  char *pj_get_def(projPJ, int);
  ]];
  PJ = ffi.load"proj"
else
  PJ = require"proj_core"
end

local TO_DEG = 180.0 / math.pi
local TO_RAD = math.pi / 180.0


------------------------------------------------------------------------------

local proj_error_string = (function()
  if ffi then
    return function(code)
      code = code or PJ.pj_get_errno_ref()[0]
      return ffi.string(PJ.pj_strerrno(code))
    end
  else
    return PJ.pj_error_string
  end
end)()


local function read_proj_string(s)
  if not s then return end
  if type(s) == "table" then return s end

  local degrees, reverse

  if s:match("%+degrees") then
    degrees = true
    s = s:gsub("%s*%+degrees%s*", "")
  end
  if s:match("%+order=") then
    reverse = s:match("%+order=latlong") ~= nil
    s = s:gsub("%s*%+order=%S*%s*", "")
  end

  local sh = shortcuts[s:lower()]
  if sh then
    s = sh

    if s:match("%+degrees") then
      degrees = true
      s = s:gsub("%s*%+degrees%s*", "")
    end
    if s:match("%+order=") then
      if reverse == nil then
        reverse = s:match("%+order=latlong") ~= nil
      end
      s = s:gsub("%s*%+order=%S*%s*", "")
    end
  end

  local P = PJ.pj_init_plus(s)
  if P == nil then
    error(("proj.read_proj_string: Error in projection '%s': %s"):format(s, proj_error_string()))
  end
  if ffi then
    P = ffi.gc(P, PJ.pj_free)
  end

  local is_latlong = PJ.pj_is_latlong(P)
  return { projection = P, degrees = is_latlong and degrees, reverse = is_latlong and reverse }
end


local transform = (function()
  if ffi then
    return function(input, output, x, y)
      q[0], r[0] =  x, y
      local code = PJ.pj_transform(input, output, 1, 1, q, r, nil)
      if code ~= 0 then
        return nil, code
      else
        return q[0], r[0]
      end
    end
  else
    return function(input, output, x, y)
      local code, x2, y2 = PJ.pj_transform(input, output, x, y)
      if code ~= 0 then
        return nil, code
      else
        return x2, y2
      end
    end
  end
end)()


local function convert(input, output, identity, ix, iy)
  assert(input, "Input projection not defined")
  assert(output, "Output projection not defined")

  local x, y = ix, iy
  if input.reverse then x, y = y, x end
  if input.degrees then
    x, y =   x * TO_RAD, y * TO_RAD
  end

  if not identity then
    x, y = transform(input.projection, output.projection, x, y)
    if not x then
      error(("proj.convert: Error converting %f, %f: %s"):format(
            ix, iy, proj_error_string(y)))
    end
  end

  if output.reverse then x, y = y, x end
  if output.degrees then
    return x * TO_DEG, y * TO_DEG
  else
    return x, y
  end
end


local function check_identity(input, output)
  if input == output then return true end
  if input and output then
    if ffi then
      return ffi.string(PJ.pj_get_def(input.projection, 0)) == ffi.string(PJ.pj_get_def(output.projection, 0))
    else
      return PJ.pj_get_def(input.projection, 0) == PJ.pj_get_def(output.projection, 0)
    end
  end
  return false
end


------------------------------------------------------------------------------

local proj = {}
proj.__index = proj


function proj:new(input, output)  -- luacheck: no self
  input = read_proj_string(input)
  output = read_proj_string(output)

  return setmetatable(
    {
      input = input,
      output = output,
      identity = check_identity(input, output)
    }, proj)
end


function proj:set_input(input)
  self.input = read_proj_string(input)
  self.identity = check_identity(self.input, self.output)
end


function proj:set_output(output)
  self.output = read_proj_string(output)
  self.identity = check_identity(self.input, self.output)
end


function proj:reverse()
  return self:new(self.output, self.input)
end


------------------------------------------------------------------------------


function proj:convert(x, y)
  return convert(self.input, self.output, self.identity, x, y)
end


function proj:__call(x, y)
  return convert(self.input, self.output, self.identity, x, y)
end


function proj:revert(x, y)
  return convert(self.output, self.input, self.identity, x, y)
end


------------------------------------------------------------------------------

local function identity_function(_, x, y)
  return x, y
end


local identity =
{
  convert = identity_function,
  __call = identity_function,
  revert = identity_function,
}
identity.__index = identity


function proj:identity()  -- luacheck: no self
  return setmetatable({}, identity)
end


------------------------------------------------------------------------------

return proj

------------------------------------------------------------------------------
