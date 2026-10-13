local form = startk.form('forms/main.frm')
local app =
  startk.application(
  {
    initial_state = {status = 'Use os controles; volte quando terminar.'},
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

local function update(action, message)
  app:on(
    action,
    function(ctx)
      ctx:log('info', 'Ação acionada: ' .. action)
      ctx:patch({status = message})
    end
  )
end

update('foundations.primary', 'Ação primária selecionada.')
update('foundations.secondary', 'Ação secundária selecionada.')
update('foundations.library', 'Biblioteca selecionada.')
app:start()
