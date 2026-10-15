local main_form = startk.form('forms/main.frm')
local stats_form = startk.form('forms/stats.frm')
local clear_form = startk.form('forms/clear.frm')
local history = startk.require('history')

local function string_or(value, fallback)
  if type(value) == 'string' then return value end
  return fallback
end

local function number_or(value, fallback)
  if type(value) == 'number' then return value end
  return fallback
end

local function view(state)
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
    notice = 'Lendo informações do dispositivo…',
    stats = 'Carregando estatísticas…'
  },
  view = view
})

local function refresh(ctx, notice)
  local result = ctx:await(startk.system.info())
  if not result.ok then
    return ctx:patch({notice = 'Falha ao consultar o dispositivo: ' .. (result.error.message or 'erro')})
  end
  local info = result.value
  local recorded = history.record(ctx, info)
  if recorded and not recorded.ok then
    startk.log('warn', 'Não foi possível registrar amostra da bateria.')
  end
  local summary = history.summary(ctx)
  ctx:patch({
    device = info.device .. ' · ' .. info.platform,
    battery = type(info.battery_percent) == 'number' and (tostring(info.battery_percent) .. '%') or 'Indisponível',
    battery_status = string_or(info.battery_status, 'Indisponível'),
    wifi_enabled = info.wifi_enabled == true,
    wifi_available = info.wifi_available == true,
    light_available = info.light_available == true,
    light_level = number_or(info.light_level, 0),
    warmth = number_or(info.warmth, 0),
    stats = summary or 'Não foi possível calcular estatísticas.',
    notice = notice or 'Informações atualizadas.'
  })
end

app:on('app.started', function(ctx)
  local initialized = history.initialize(ctx)
  if not initialized.ok then
    ctx:patch({notice = 'Falha ao preparar estatísticas da bateria.'})
    return
  end
  refresh(ctx)
end)

app:on('system.refresh', function(ctx)
  refresh(ctx, 'Informações atualizadas.')
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

app:on('system.clear.cancel', function(ctx)
  ctx:patch({page = 'stats'})
end)

app:on('navigation.close', function(ctx)
  ctx:exit()
end)

app:start()
