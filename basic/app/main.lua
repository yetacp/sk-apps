local form = startk.form('forms/main.frm')
local copy = startk.require('copy')
local app =
  startk.application(
  {
    initial_state = {
      message = copy.initial,
      wifi = true,
      night = false,
      theme = 'light',
      name = '',
      notes = 'Linha um\nLinha dois',
      volume = 60,
      page = 7
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
app:start()
