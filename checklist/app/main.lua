local sqlite = startk.sqlite
local forms = {empty = startk.form('forms/empty.frm'), list = startk.form('forms/list.frm')}
local function active_form(state)
  return #state.items == 0 and forms.empty or forms.list
end
local app =
  startk.application(
  {
    initial_state = {task = '', selected = nil, items = {}, message = 'Carregando tarefas…'},
    view = function(state)
      return active_form(state):document(state)
    end
  }
)

local function load(ctx, message)
  local result = ctx:await(sqlite.query('SELECT id,label,done FROM tasks ORDER BY done,id', {}))
  if not result.ok then
    return ctx:patch({message = 'Falha ao carregar: ' .. result.error.message})
  end
  local items = {}
  for _, row in ipairs(result.value.rows) do
    items[#items + 1] = {
      id = tostring(row[1]),
      caption = row[2],
      secondary_caption = row[3] == 0 and 'Pendente' or 'Concluída',
      enabled = true
    }
  end
  local current = ctx.state.selected
  local selected = false
  for _, item in ipairs(items) do
    if item.id == current then
      selected = true
    end
  end
  if not selected then
    current = items[1] and items[1].id
  end
  ctx:patch(
    {
      items = items,
      selected = current,
      message = message or
        (#items == 0 and 'Nenhuma tarefa. Adicione a primeira.' or 'Seleção e estado ficam salvos localmente.')
    }
  )
end

local function add(ctx, event)
  local values = active_form(ctx.state):values(event)
  if values.task == '' then
    return ctx:patch({message = 'Informe uma tarefa.'})
  end
  ctx:patch({task = '', message = 'Adicionando tarefa…'})
  local result = ctx:await(sqlite.execute('INSERT INTO tasks(label,done) VALUES(?,0)', {values.task}))
  if not result.ok then
    return ctx:patch({message = 'Falha ao adicionar: ' .. result.error.message})
  end
  ctx:log('info', 'checklist task added')
  load(ctx, 'Tarefa adicionada.')
end

app:on(
  'navigation.close',
  function(ctx)
    ctx:exit()
  end
)
app:on('checklist.add', add)
app:on(
  'checklist.toggle',
  function(ctx, event)
    local values = forms.list:values(event)
    if not values.selected then
      return ctx:patch({message = 'Selecione uma tarefa.'})
    end
    ctx:patch({selected = values.selected, message = 'Atualizando tarefa…'})
    local result = ctx:await(sqlite.execute('UPDATE tasks SET done=1-done WHERE id=?', {tonumber(values.selected)}))
    if not result.ok then
      return ctx:patch({message = 'Falha ao atualizar: ' .. result.error.message})
    end
    ctx:log('info', 'checklist task toggled')
    load(ctx, 'Tarefa atualizada.')
  end
)
app:on(
  'checklist.remove',
  function(ctx, event)
    local values = forms.list:values(event)
    if not values.selected then
      return ctx:patch({message = 'Selecione uma tarefa.'})
    end
    ctx:patch({selected = nil, message = 'Excluindo tarefa…'})
    local result = ctx:await(sqlite.execute('DELETE FROM tasks WHERE id=?', {tonumber(values.selected)}))
    if not result.ok then
      return ctx:patch({message = 'Falha ao excluir: ' .. result.error.message})
    end
    ctx:log('info', 'checklist task removed')
    load(ctx, 'Tarefa excluída.')
  end
)

app:on(
  'app.started',
  function(ctx)
    local result =
      ctx:await(
      sqlite.execute(
        'CREATE TABLE IF NOT EXISTS tasks(id INTEGER PRIMARY KEY,label TEXT NOT NULL,done INTEGER NOT NULL DEFAULT 0)',
        {}
      )
    )
    if result.ok then
      load(ctx)
    else
      ctx:patch({message = 'Falha ao preparar: ' .. result.error.message})
    end
  end
)
app:start()
