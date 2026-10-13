local form = startk.form('forms/main.frm')
local app =
  startk.application(
  {
    initial_state = {status = 'Escolha uma ação'},
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
update('dialog.cancel', 'Diálogo cancelado')
update('dialog.accept', 'Diálogo aceito')
update('confirmation.accept', 'Confirmação aceita')
update('confirmation.reject', 'Confirmação recusada')
app:start()
