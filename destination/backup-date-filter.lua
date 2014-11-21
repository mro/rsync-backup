#!/usr/bin/env lua
--[[
  Implement a time-machine-like date filter.

  Read timestamps from stdin and write, prefixed with '+ ' and '- ' accordingly,
  to stdout.
]]

--[[
  No timezone, assumes local time!

  http://www.w3.org/TR/xmlschema-2/#isoformats
]]
function string:iso8601_to_time()
  local _,_,y,m,d,H,M,S = self:find('^(%d%d%d%d)-?(%d%d)-?(%d%d)[T -]?(%d%d):?(%d%d):?(%d%d)$')
  if not y then return nil,self end
  return os.time({year = y, month = m, day = d, hour = H, min = M, sec = S})
end


--[[
  Could be more standards compliant using LPEG, but I avoided the dependency so far.

  http://www.w3.org/TR/xmlschema-2/#isoformats
]]
function string:iso8601_duration_add(t0,factor)
  local fac = factor or 1
  local t = os.date('*t', t0 or os.time())
  local _,pos = self:find('P', 0)
  if not pos then return nil,'expect ISO8601 self to start with \'P\'' end
  local function evaluate(map)
    for c,key in pairs(map) do
      -- print(c, key, self:find('([+-]?%d+)' .. c, pos))
      local p0,p1,val = self:find('([+-]?%d+)' .. c, pos)
      if p1 then
        if p0 > pos + 1 then return nil,'non-ISO8601 garbage at \'' .. self .. '\'[' .. pos+1 .. ']' end
        pos = p1
        -- io.stderr:write(' ', 'key=', key, ' ', 'fac=', fac, ' ', 'val=', val, '\n')
        t[key] = t[key] + fac * tonumber(val)
      end
    end
    return true
  end
  local ok,err = evaluate{ Y = 'year', M = 'month', W = 'undefined', D = 'day' }
  if ok and 'T' == self:sub(pos+1,pos+1) then
    pos = pos + 1
    ok,err = evaluate{ H = 'hour', M = 'min', S = 'sec' }
  end
  if pos < self:len() then return nil,'non-ISO8601 garbage at \'' .. self .. '\'[' .. pos+1 .. ']' end
  if ok then return os.time(t) end
  return ok,err
end


-- http://nova-fusion.com/2011/06/30/lua-metatables-tutorial/
-- http://lua-users.org/wiki/LuaClassesWithMetatable
Filter = {} -- methods table
Filter_mt = { __index = Filter } -- metatable

function Filter:init(criteria, now)
  self.now_ = now or os.time()

  -- prepare the thresholds/intervals - an array of arrays
  self.thresholds_ = {}
  for thre,freq in pairs(assert(criteria)) do
    local a = assert(thre:iso8601_duration_add(self.now_, -1)) -- look into the past
    local b = assert(freq:iso8601_duration_add(self.now_))
    local t = { thre=a, freq=os.difftime(b, self.now_) }
    table.insert(self.thresholds_, t)
  end
  table.sort(self.thresholds_, function(a,b) return a.thre > b.thre end)
  assert(self.thresholds_[1].thre > self.thresholds_[2].thre) -- descending
end

-- Helper: figure out the bucket index of ts
function Filter:bucket_index(ts)
  for idx,t in ipairs(self.thresholds_) do
    local threshold = assert(t.thre)
    local frequency = assert(t.freq)
    -- io.stderr:write(' ts=', ts, ' th=', threshold, ' fr=', frequency, '\n')
    if threshold < assert(ts) then
      -- we're in!
      return 1 + math.floor(os.difftime(self.now_, ts) / frequency)
    end
  end
  return nil
end

function Filter:process(line)
  assert(self.now_)
  if not line then return nil end
  local ts = line:iso8601_to_time()
  if not ts then return nil,line end

  -- self.row_ = 1 + (self.row_ or 0)
  local bucket_index = self:bucket_index(ts)
  if self.prev_ then
    -- regular entry (n > 1)
    assert(ts >= assert(self.prev_.ts), 'input must be ascending')
    -- always keep the youngest entry (i.e. most recent read) per bucket index.
    self:callback(self.prev_.line, bucket_index ~= self.prev_.bucket_index)
  else
    -- first entry (n = 1)
    -- mark entry for callback. Clueless why - 1 doesn't do it.
    bucket_index = bucket_index - 2
  end
  self.prev_ = { line = line, ts = ts, bucket_index = bucket_index }
  return line
end

function Filter:finish()
  if self.prev_ then
    self:callback(self.prev_.line, true) -- always keep the last line
  end
  self.prev_ = nil
end

function Filter:callback(line, keep)
  local prefix = { [true] = '+', [false] = '-' }
  io.write(prefix[keep], ' ', line, '\n')
end


Filter:init{
  P1D   = 'PT1H', -- all younger 1 day: hourly
  P1M   = 'P1D',  -- all younger 1 month: daily
  P3M   = 'P3D',  -- all younger 3 months: 3-days
  P1Y   = 'P7D',
  P10Y  = 'P1M',
}
while Filter:process(io.read('*l')) do end
Filter:finish()
