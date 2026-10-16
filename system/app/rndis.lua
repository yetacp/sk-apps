local sqlite = startk.sqlite
local M = {
  defaults = {
    device_mac = '02:52:44:00:00:01', host_mac = '02:52:44:00:00:02',
    device_ip = '192.168.7.1', host_ip = '192.168.7.2', netmask = '255.255.255.0'
  }
}

local function ipv4(value)
  if type(value) ~= 'string' or not value:match('^%d+%.%d+%.%d+%.%d+$') then return nil end
  local out = {}
  for part in value:gmatch('%d+') do
    local n = tonumber(part)
    if not n or n > 255 then return nil end
    out[#out + 1] = n
  end
  if #out ~= 4 then return nil end
  return out
end

local function number(ip)
  return ((ip[1] * 256 + ip[2]) * 256 + ip[3]) * 256 + ip[4]
end

local function prefix(mask)
  local bits, ended = 0, false
  local partial = {[254]=7,[252]=6,[248]=5,[240]=4,[224]=3,[192]=2,[128]=1}
  for _, octet in ipairs(mask) do
    if ended and octet ~= 0 then return nil end
    if octet == 255 and not ended then bits = bits + 8
    elseif octet == 0 then ended = true
    elseif partial[octet] and not ended then bits, ended = bits + partial[octet], true
    else return nil end
  end
  if bits < 1 or bits > 30 then return nil end
  return bits
end

local function mac(value)
  if type(value) ~= 'string' or #value ~= 17 or not value:match('^%x%x:%x%x:%x%x:%x%x:%x%x:%x%x$') then return false end
  local first = tonumber(value:sub(1, 2), 16)
  return first and first % 2 == 0 and value:lower() ~= '00:00:00:00:00:00'
end

function M.validate(p)
  if type(p) ~= 'table' or not mac(p.device_mac) or not mac(p.host_mac)
      or p.device_mac:lower() == p.host_mac:lower() then
    return false, 'MACs devem ser unicast válidos e distintos'
  end
  local device, host, mask = ipv4(p.device_ip), ipv4(p.host_ip), ipv4(p.netmask)
  if not device or not host then return false, 'IP do Kobo ou host inválido' end
  local bits = mask and prefix(mask)
  if not bits then return false, 'máscara deve ser contígua entre /1 e /30' end
  local block = 2 ^ (32 - bits)
  local d, h = number(device), number(host)
  local network = math.floor(d / block) * block
  local broadcast = network + block - 1
  if math.floor(h / block) * block ~= network or d == h
      or d == network or h == network or d == broadcast or h == broadcast then
    return false, 'IPs devem ser distintos e utilizáveis na mesma sub-rede'
  end
  return true
end

function M.initialize(ctx)
  local created = ctx:await(sqlite.execute([[CREATE TABLE IF NOT EXISTS rndis_preferences (
    id INTEGER PRIMARY KEY CHECK (id=1), device_mac TEXT NOT NULL, host_mac TEXT NOT NULL,
    device_ip TEXT NOT NULL, host_ip TEXT NOT NULL, netmask TEXT NOT NULL
  )]], {}))
  if not created.ok then return created end
  return ctx:await(sqlite.execute([[INSERT OR IGNORE INTO rndis_preferences
    (id,device_mac,host_mac,device_ip,host_ip,netmask) VALUES (1,?,?,?,?,?)]], {
      M.defaults.device_mac, M.defaults.host_mac, M.defaults.device_ip,
      M.defaults.host_ip, M.defaults.netmask
    }))
end

function M.load(ctx)
  local result = ctx:await(sqlite.query([[SELECT device_mac,host_mac,device_ip,host_ip,netmask
    FROM rndis_preferences WHERE id=1]], {}))
  if not result.ok then return nil, result.error.message end
  local row = result.value.rows and result.value.rows[1]
  if not row then return nil, 'registro ausente' end
  local p = {device_mac=row[1],host_mac=row[2],device_ip=row[3],host_ip=row[4],netmask=row[5]}
  local valid, message = M.validate(p)
  if not valid then return nil, 'registro inválido: ' .. message end
  return p
end

function M.save(ctx, values)
  local p = {
    device_mac=values.rndis_device_mac, host_mac=values.rndis_host_mac,
    device_ip=values.rndis_device_ip, host_ip=values.rndis_host_ip,
    netmask=values.rndis_netmask
  }
  local valid, message = M.validate(p)
  if not valid then return nil, message end
  local result = ctx:await(sqlite.execute([[UPDATE rndis_preferences SET
    device_mac=?,host_mac=?,device_ip=?,host_ip=?,netmask=? WHERE id=1]], {
      p.device_mac,p.host_mac,p.device_ip,p.host_ip,p.netmask
    }))
  if not result.ok then return nil, result.error.message end
  return p
end

function M.refresh(ctx)
  local result = ctx:await(startk.system.rndis_status())
  if not result.ok then
    local message
    if result.error.code == 'device_unavailable' then
      message = 'RNDIS disponível apenas no Kobo Clara BW.'
    else
      message = 'Falha ao consultar RNDIS: '..(result.error.message or 'erro')
    end
    return {rndis_status=message,
      rndis_instructions='Neste simulador, os controles RNDIS não estão disponíveis.',
      rndis_available=false}
  end
  local s = result.value
  local state = type(s.state) == 'string' and s.state ~= '' and s.state or 'unknown'
  local status = state
  local function append_optional(value, prefix)
    if type(value) == 'string' and value ~= '' then
      status = status .. prefix .. value
    end
  end
  append_optional(s.interface, ' · ')
  append_optional(s.ip, ' · ')
  append_optional(s.udc, ' · UDC ')
  local instructions
  if state == 'enabled' then
    instructions = 'Configure o host manualmente: '..ctx.state.rndis_host_ip..' com máscara '..ctx.state.rndis_netmask..'.'
  elseif state == 'partial' then
    instructions = 'Estado parcial. Não repita a alteração; mantenha acesso independente. Desconecte/reconecte apenas para o handler stock tentar restaurar USB.'
  elseif state == 'unavailable' then
    instructions = 'Gadget ou configfs esperado ausente. Não altere; use conexão independente e confirme o USB stock.'
  else
    instructions = 'Estado consultado no dispositivo. Ejete o armazenamento no host antes de alterar o gadget.'
  end
  return {rndis_status=status,rndis_instructions=instructions,rndis_available=state ~= 'unavailable'}
end

return M
