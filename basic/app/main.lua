local form = startk.form('forms/main.frm')
local copy = startk.require('copy')

local app = startk.application({
  initial_state = {
    message = copy.initial,
    wifi = true,
    disabled = false,
    night = false,
    theme = 'light',
    name = '',
    notes = 'Linha um\nLinha dois',
    volume = 60,
    page = 7,
    offset = 4
  },
  view = function(state)
    return form:document(state)
  end
})

app:on('navigation.close', function(ctx)
  ctx:log('info', 'Botão Voltar acionado')
  ctx:exit()
end)

local function update(action)
  app:on(action, function(ctx, event)
    local values = form:values(event)
    if type(values.page) == 'number' then
      values.offset = math.floor((values.page - 1) * 15 / 19)
    end
    ctx:patch(values)
    ctx:log('info', 'Ação acionada: ' .. action)
  end)
end

update('controls.wifi')
update('controls.night')
update('controls.theme')
update('controls.volume')
update('controls.page')

app:start()
