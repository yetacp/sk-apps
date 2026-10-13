local form = startk.form('forms/main.frm')
local app =
  startk.application(
  {
    initial_state = {
      name = 'StartK',
      notes = 'Linha um\nLinha dois\nLinha três\nLinha quatro\nLinha cinco\nLinha seis\nLinha sete',
      source = 'local _ = startk\n_.log("info", "Olá")\n-- Edite este código'
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
