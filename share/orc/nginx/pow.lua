local host_mapping = ngx.shared.host_mapping
local host = ngx.var.host
local default_host = '127.0.0.1'
local default_domain = 'test'
local mapping_size = 0
local pow_path = "/pow"
local restart_file = pow_path.."/restart.txt"

host = string.lower(host)

function basename(str)
	local name = string.gsub(str, "(.*/)(.*)", "%2")
	return name
end

function read_file(filename)
  local contents = ""
  local file = io.open( filename, "r" )
  if (file) then
    -- read all contents of file into a string
    contents = file:read()
    file:close()
  end
  return contents
end

function read_dir(dir)
  local t = {}
  local p = io.popen('find "'..dir..'" -type f' )
  for file in p:lines() do
    local target = basename(file).."."..default_domain
    local dest = read_file(file)

    if string.find(dest, ':') then
      t[target] = dest
    else
      t[target] = default_host..":"..dest
    end
    mapping_size = mapping_size + 1
  end
  return t
end

function load_hosts()
  local maps = read_dir(pow_path)
  for target,dest in pairs(maps) do
    ngx.log(ngx.INFO, "Mapping "..target.." to "..dest)
    host_mapping:add(target, dest)
  end
  host_mapping:add("is_loaded",mapping_size)
end

-- Look for a backend; either a direct match, or a parent domain
function find_backend(host)
  local host_parts = {}
  local host_trimmed = host
  for token in string.gmatch(host, '([^.]+)') do
      table.insert(host_parts, token)
  end
  if #host_parts > 2 then
    table.remove(host_parts, 1)
    host_trimmed = table.concat(host_parts, '.')
  end
  return host_mapping:get(host_trimmed)
end

-- Check if we're supposed to 'restart'
if host_mapping:get("restart") then
  ngx.log(ngx.INFO, "Reloading Hosts at user request!")
  host_mapping:flush_all()
end

-- Load host mappings if we're empty.
if host_mapping:get("is_loaded") == nil then
  load_hosts()
end

backend = find_backend(host)

if backend ~= nil then
  ngx.var.proxy_to = backend
  ngx.var.proxy_host = ngx.var.http_host
else
  ngx.exit(404)
end