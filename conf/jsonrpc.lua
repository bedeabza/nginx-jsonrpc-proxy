local cjson = require('cjson')

local function empty(s)
  return s == nil or s == ''
end

local function split(s, reg)
  local res = {}
  local i = 1
  for v in string.gmatch(s, reg) do
    res[i] = v
    i = i + 1
  end
  return res
end

local function contains(arr, val)
  for i, v in ipairs (arr) do
    if v == val then
      return true
    end
  end
  return false
end

local function slice(tbl, first, last, step)
  local sliced = {}

  for i = first or 1, last or #tbl, step or 1 do
    sliced[#sliced+1] = tbl[i]
  end

  return sliced
end

local function convert_to_numbers(tbl)
  local newtbl = {}

  for i = 1, #tbl, 1 do
    if tonumber(tbl[i]) ~= nil then
      newtbl[i] = tonumber(tbl[i])
    else
      newtbl[i] = tbl[i]
    end
  end

  return newtbl
end

-- parse conf
local blacklist, whitelist = nil
if not empty(ngx.var.jsonrpc_blacklist) then
  blacklist = split(ngx.var.jsonrpc_blacklist, "([^,]+)")
end
if not empty(ngx.var.jsonrpc_whitelist) then
  whitelist = split(ngx.var.jsonrpc_whitelist, "([^,]+)")
end

-- check conf
if blacklist ~= nil and whitelist ~= nil then
  ngx.log(ngx.ERR, 'invalid conf: jsonrpc_blacklist and jsonrpc_whitelist are both set')
  ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
  return
end

-- parse URI
if not empty(ngx.var.original_uri) then
  arr = split(ngx.var.original_uri, "([^/]+)")
  if not empty(arr[1]) then
    ngx.var.rpc_method = arr[1]
  end
  params = convert_to_numbers(slice(arr, 2))
  if #params > 0 then
    ngx.var.rpc_params = cjson.encode(params)
  end
end

-- if whitelist is configured, check that the method is whitelisted
if whitelist ~= nil then
  if not contains(whitelist, ngx.var.rpc_method) then
    ngx.log(ngx.ERR, 'jsonrpc method is not whitelisted: ' .. ngx.var.rpc_method)
    ngx.exit(ngx.HTTP_FORBIDDEN)
    return
  end
end

-- if blacklist is configured, check that the method is not blacklisted
if blacklist ~= nil then
  if contains(blacklist, ngx.var.rpc_method) then
    ngx.log(ngx.ERR, 'jsonrpc method is blacklisted: ' .. ngx.var.rpc_method)
    ngx.exit(ngx.HTTP_FORBIDDEN)
    return
  end
end

return
