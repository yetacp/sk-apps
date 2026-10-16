local main_form = startk.form('forms/main.frm')
local stats_form = startk.form('forms/stats.frm')
local clear_form = startk.form('forms/clear.frm')
local rndis_form = startk.form('forms/rndis.frm')
local history = startk.require('history')
local rndis = startk.require('rndis')
local confirm_form = startk.form('forms/rndis-confirm.frm')

local function string_or(value, fallback)
  if type(value) == 'string' then return value end
  return fallback
end

local function number_or(value, fallback)
  if type(value) == 'number' then return value end
  return fallback
end

local function view(state)
  if state.page == 'rndis_confirm' then return confirm_form:document(state) end
  if state.page == 'rndis' then return rndis_form:document(state) end
  if state.page == 'clear' then return clear_form:document(state) end
  if state.page == 'stats' then return stats_form:document(state) end
  return main_form:document(state)
end

local app = startk.application({
  initial_state = {
    page = 'main',
    device = 'Consultando…',
    battery = '—',
    battery_status = '—',
    wifi_enabled = false,
    wifi_available = false,
    light_available = false,
    light_level = 0,
    warmth = 0,
    rndis_device_mac = rndis.defaults.device_mac,
    rndis_host_mac = rndis.defaults.host_mac,
    rndis_device_ip = rndis.defaults.device_ip,
    rndis_host_ip = rndis.defaults.host_ip,
    rndis_netmask = rndis.defaults.netmask,
    rndis_status = 'Consultando RNDIS…',
    rndis_instructions = 'Configuração do host manual.',
    notice = 'Lendo informações do dispositivo…',
    stats = 'Carregando estatísticas…'
  },
  view = view
})

local function refresh(ctx, notice)
  local network = rndis.refresh(ctx)
  local result = ctx:await(startk.system.info())
  if not result.ok then
    network.notice = 'Falha ao consultar o dispositivo: ' .. (result.error.message or 'erro')
    return ctx:patch(network)
  end
  local info = result.value
  local recorded = history.record(ctx, info)
  if recorded and not recorded.ok then
    startk.log('warn', 'Não foi possível registrar amostra da bateria.')
  end
  local summary = history.summary(ctx)
  network.device = info.device .. ' · ' .. info.platform
  network.battery = type(info.battery_percent) == 'number' and (tostring(info.battery_percent) .. '%') or 'Indisponível'
  network.battery_status = string_or(info.battery_status, 'Indisponível')
  network.wifi_enabled = info.wifi_enabled == true
  network.wifi_available = info.wifi_available == true
  network.light_available = info.light_available == true
  network.light_level = number_or(info.light_level, 0)
  network.warmth = number_or(info.warmth, 0)
  network.stats = summary or 'Não foi possível calcular estatísticas.'
  network.notice = notice or 'Informações atualizadas.'
  ctx:patch(network)
end

app:on('app.started', function(ctx)
  local initialized = history.initialize(ctx)
  if not initialized.ok then
    ctx:patch({notice = 'Falha ao preparar estatísticas da bateria.'})
    return
  end
  local prefs_initialized = rndis.initialize(ctx)
  if not prefs_initialized.ok then
    ctx:patch({notice = 'Falha ao preparar preferências RNDIS.'})
    return
  end
  local preferences, message = rndis.load(ctx)
  if not preferences then
    ctx:patch({notice = 'Falha ao carregar preferências RNDIS: ' .. message})
    return
  end
  ctx:patch({rndis_device_mac=preferences.device_mac,rndis_host_mac=preferences.host_mac,
    rndis_device_ip=preferences.device_ip,rndis_host_ip=preferences.host_ip,rndis_netmask=preferences.netmask})
  refresh(ctx)
end)

app:on('system.refresh', function(ctx)
  refresh(ctx, 'Informações atualizadas.')
end)

app:on('system.rndis.refresh', function(ctx)
  refresh(ctx, 'Estado RNDIS atualizado.')
end)

app:on('system.light', function(ctx, event)
  if not ctx.state.light_available then
    return ctx:patch({notice = 'Ajuste de iluminação disponível apenas no Kobo Clara BW.'})
  end
  local values = main_form:values(event)
  local level = math.floor(tonumber(values.light_level) or ctx.state.light_level)
  local result = ctx:await(startk.system.set_light(level))
  if not result.ok then
    return ctx:patch({notice = 'Não foi possível ajustar a iluminação: ' .. (result.error.message or 'erro')})
  end
  refresh(ctx, 'Iluminação ajustada.')
end)

app:on('system.warmth', function(ctx, event)
  if not ctx.state.light_available then
    return ctx:patch({notice = 'Luz natural disponível apenas no Kobo Clara BW.'})
  end
  local values = main_form:values(event)
  local warmth = math.floor(tonumber(values.warmth) or ctx.state.warmth)
  local result = ctx:await(startk.system.set_warmth(warmth))
  if not result.ok then
    return ctx:patch({notice = 'Não foi possível ajustar a temperatura da luz: ' .. (result.error.message or 'erro')})
  end
  refresh(ctx, 'Temperatura da luz ajustada.')
end)

app:on('system.wifi', function(ctx, event)
  if not ctx.state.wifi_available then
    return ctx:patch({notice = 'Controle de Wi-Fi disponível apenas no Kobo Clara BW.'})
  end
  local values = main_form:values(event)
  local enabled = values.wifi_enabled == true
  local result = ctx:await(startk.system.set_wifi(enabled))
  if not result.ok then
    return ctx:patch({notice = 'Não foi possível alterar o Wi-Fi: ' .. (result.error.message or 'erro')})
  end
  refresh(ctx, enabled and 'Wi-Fi ativado.' or 'Wi-Fi desativado.')
end)

app:on('system.rndis.save', function(ctx, event)
  local preferences, message = rndis.save(ctx, rndis_form:values(event))
  if not preferences then return ctx:patch({notice = 'Parâmetros inválidos: ' .. message}) end
  ctx:patch({rndis_device_mac=preferences.device_mac,rndis_host_mac=preferences.host_mac,
    rndis_device_ip=preferences.device_ip,rndis_host_ip=preferences.host_ip,rndis_netmask=preferences.netmask,
    notice='Preferências RNDIS salvas; estado ativo não é persistido.'})
end)

app:on('system.rndis.enable', function(ctx, event)
  local preferences, message = rndis.save(ctx, rndis_form:values(event))
  if not preferences then return ctx:patch({notice = 'Parâmetros inválidos: ' .. message}) end
  ctx:patch({rndis_device_mac=preferences.device_mac,rndis_host_mac=preferences.host_mac,
    rndis_device_ip=preferences.device_ip,rndis_host_ip=preferences.host_ip,rndis_netmask=preferences.netmask,
    page='rndis_confirm',pending_rndis='enable',
    confirm_message='Ativar RNDIS pode interromper USB e armazenamento. Confirme a ejeção segura no host.'})
end)

app:on('system.rndis.disable', function(ctx)
  ctx:patch({page='rndis_confirm',pending_rndis='disable',
    confirm_message='Desativar RNDIS derruba USB e deixa o gadget desassociado. Confirme a ejeção segura no host.'})
end)

app:on('system.rndis.confirm', function(ctx)
  local pending = ctx.state.pending_rndis
  local result
  if pending == 'enable' then
    result = ctx:await(startk.system.rndis_enable({
      device_mac=ctx.state.rndis_device_mac,host_mac=ctx.state.rndis_host_mac,
      device_ip=ctx.state.rndis_device_ip,host_ip=ctx.state.rndis_host_ip,
      netmask=ctx.state.rndis_netmask
    }, true))
  elseif pending == 'disable' then
    result = ctx:await(startk.system.rndis_disable(true))
  else
    ctx:patch({page='rndis',pending_rndis=false,notice='Confirmação expirada.'})
    return refresh(ctx)
  end
  ctx:patch({page='rndis',pending_rndis=false})
  if not result.ok then
    return refresh(ctx, 'Falha RNDIS: '..(result.error.message or 'erro')..'. Estado consultado; siga a recuperação se parcial.')
  end
  if pending == 'disable' then
    refresh(ctx, 'RNDIS removido. Desconecte e reconecte o cabo para restaurar o USB stock.')
  else
    refresh(ctx, 'RNDIS ativado. Configure o IP estático do host conforme indicado.')
  end
end)

app:on('system.rndis.cancel', function(ctx)
  ctx:patch({page='rndis',pending_rndis=false,notice='Operação RNDIS cancelada.'})
end)

app:on('system.stats', function(ctx)
  ctx:patch({page = 'stats'})
end)

app:on('system.stats.refresh', function(ctx)
  refresh(ctx)
end)

app:on('system.stats.clear', function(ctx)
  ctx:patch({page = 'clear'})
end)

app:on('system.stats.clear.confirm', function(ctx)
  local result = history.clear(ctx)
  if not result.ok then
    return ctx:patch({page = 'stats', notice = 'Não foi possível limpar as estatísticas.'})
  end
  refresh(ctx, 'Estatísticas da bateria reiniciadas.')
  ctx:patch({page = 'stats'})
end)

app:on('system.back', function(ctx)
  ctx:patch({page = 'main'})
end)

app:on('system.rndis.open', function(ctx)
  ctx:patch({page = 'rndis'})
end)

app:on('system.clear.cancel', function(ctx)
  ctx:patch({page = 'stats'})
end)

app:on('navigation.close', function(ctx)
  ctx:exit()
end)

app:start()
