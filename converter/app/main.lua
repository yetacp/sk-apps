local form = startk.form('forms/main.frm')

local function convert(value, mode)
  if mode == 'c_f' then
    return value * 9 / 5 + 32, '°F'
  end
  if mode == 'f_c' then
    return (value - 32) * 5 / 9, '°C'
  end
  if mode == 'km_mi' then
    return value * 0.621371, 'mi'
  end
  return value / 0.621371, 'km'
end

local app =
  startk.application(
  {
    initial_state = {value = '', mode = 'c_f', result = 'Escolha uma conversão e informe um valor.'},
    view = function(state)
      return form:document(state)
    end
  }
)

app:on(
  'navigation.close',
  function(ctx)
    ctx:exit()
  end
)
app:on(
  'converter.convert',
  function(ctx, event)
    local values = form:values(event)
    local normalized = values.value:gsub(',', '.')
    local number = tonumber(normalized)
    if number then
      local converted, unit = convert(number, values.mode)
      values.result = string.format('Resultado: %.3f %s', converted, unit)
      ctx:log('info', 'converter completed mode=' .. values.mode)
    else
      values.result = 'Informe um número válido.'
      ctx:log('warn', 'converter rejected invalid value')
    end
    ctx:set(values)
  end
)
app:start()
