local form = startk.form('forms/main.frm')
local app =
  startk.application(
  {
    initial_state = {
      checked = true,
      disabled = false,
      night = false,
      theme = 'light',
      name = 'Ada',
      notes = 'Linha um\nLinha dois'
    },
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
      ctx:set(form:values(event))
      ctx:log('info', 'Ação acionada: ' .. action)
    end
  )
end
update('fields.checked')
update('fields.night')
update('fields.theme')
app:start()
