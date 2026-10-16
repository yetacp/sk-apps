local saved
local null_sentinel = {}
local reported_status = {
  state = 'enabled', interface = null_sentinel, ip = null_sentinel,
  udc = null_sentinel
}
startk = {
  msgpack = {null = null_sentinel},
  system = {
    rndis_status = function()
      return {result = {ok = true, value = reported_status}}
    end
  },
  sqlite = {
    execute = function(sql, parameters)
      if sql:find('INSERT OR IGNORE', 1, true) then
        if not saved then saved = {unpack(parameters)} end
      elseif sql:find('UPDATE rndis_preferences', 1, true) then
        saved = {unpack(parameters)}
      end
      return {ok = true}
    end,
    query = function()
      return {ok = true, value = {rows = saved and {{unpack(saved)}} or {}}}
    end
  }
}

local rndis = dofile('app/rndis.lua')
local function parameters(device_ip, host_ip, netmask)
  return {
    device_mac = '02:52:44:00:00:01',
    host_mac = '02:52:44:00:00:02',
    device_ip = device_ip or '192.168.7.1',
    host_ip = host_ip or '192.168.7.2',
    netmask = netmask or '255.255.255.0'
  }
end

assert(rndis.validate(parameters()))
assert(not rndis.validate(parameters('192.168.7.0')))
assert(not rndis.validate(parameters('192.168.7.1', '192.168.7.255')))
assert(not rndis.validate(parameters('192.168.7.1', '192.168.8.2')))
assert(not rndis.validate(parameters('192.168.7.1', '192.168.7.2', '255.0.255.0')))
local duplicate_mac = parameters()
duplicate_mac.host_mac = duplicate_mac.device_mac
assert(not rndis.validate(duplicate_mac))

local ctx = {await = function(_, result) return result end}
assert(rndis.initialize(ctx).ok)
assert(rndis.initialize(ctx).ok)
local defaults = assert(rndis.load(ctx))
assert(defaults.device_ip == '192.168.7.1' and defaults.host_ip == '192.168.7.2')
local edited = parameters('10.20.30.1', '10.20.30.2', '255.255.255.0')
local values = {
  rndis_device_mac=edited.device_mac, rndis_host_mac=edited.host_mac,
  rndis_device_ip=edited.device_ip, rndis_host_ip=edited.host_ip,
  rndis_netmask=edited.netmask
}
assert(rndis.save(ctx, values))
local loaded = assert(rndis.load(ctx))
assert(loaded.device_ip == edited.device_ip and loaded.host_ip == edited.host_ip)
local refresh_ctx = {
  state = {rndis_host_ip='192.168.7.2', rndis_netmask='255.255.255.0'},
  await = function(_, operation) return operation.result end
}
local status = rndis.refresh(refresh_ctx)
assert(status.rndis_status == 'enabled')
assert(status.rndis_available == true)
assert(status.rndis_instructions:find('192.168.7.2', 1, true))
reported_status.interface = 'rndis0'
reported_status.ip = '192.168.7.1'
reported_status.udc = '11211000.usb'
status = rndis.refresh(refresh_ctx)
assert(status.rndis_status == 'enabled · rndis0 · 192.168.7.1 · UDC 11211000.usb')
print('RNDIS app validation and preference tests passed')
