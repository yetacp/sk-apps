local form = startk.form('forms/main.frm')
local app =
  startk.application(
  {
    initial_state = {list = 'one', view = 'three', menu = 'open'},
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
app:start()
