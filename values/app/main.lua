local form = startk.form('forms/main.frm')
local app =
  startk.application(
  {
    initial_state = {volume = 60, page = 7, offset = 4},
    view = function(state)
      return form:document(state)
    end
  }
)
app:on(
  'navigation.close',
  function(ctx)
    ctx:log('info', 'Botão Voltar acionado')
    ctx:exit()
  end
)
local function update(action)
  app:on(
    action,
    function(ctx, event)
      local values = form:values(event)
      values.offset = math.floor((values.page - 1) * 15 / 19)
      ctx:set(values)
      ctx:log('info', 'Ação acionada: ' .. action)
    end
  )
end
update('values.volume')
update('values.page')
app:start()
