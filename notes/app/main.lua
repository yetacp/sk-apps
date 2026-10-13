local form = startk.form('forms/main.frm')
local app =
  startk.application(
  {
    initial_state = {body = '', message = 'Carregando nota privada…'},
    view = function(state)
      return form:document(state)
    end
  }
)

local function report(ctx, operation, result)
  if result.ok then
    ctx:patch({message = operation .. ' concluída.'})
    ctx:log('info', 'notes ' .. operation)
  else
    local message = result.error.message or 'erro desconhecido'
    ctx:patch({message = 'Falha ao ' .. operation .. ': ' .. message})
    ctx:log('error', 'notes ' .. operation .. ' failed: ' .. message)
  end
end

app:on(
  'navigation.close',
  function(ctx)
    ctx:exit()
  end
)
app:on(
  'notes.save',
  function(ctx, event)
    local values = form:values(event)
    ctx:patch({body = values.body, message = 'Salvando nota…'})
    report(ctx, 'Salvar', ctx:await(startk.file.write('note.txt', values.body)))
  end
)
app:on(
  'notes.clear',
  function(ctx)
    ctx:patch({body = '', message = 'Nota limpa; salve para persistir a alteração.'})
  end
)

app:on(
  'app.started',
  function(ctx)
    local result = ctx:await(startk.file.read('note.txt'))
    if result.ok then
      ctx:patch({body = result.value, message = 'Nota privada carregada.'})
    else
      ctx:patch({message = 'Nova nota privada; escreva e salve quando terminar.'})
    end
  end
)
app:start()
