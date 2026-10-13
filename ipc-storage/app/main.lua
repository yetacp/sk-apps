local form = startk.form('forms/main.frm')
local file = startk.file
local sqlite = startk.sqlite
local file_path = 'storage-demo.txt'

local function summary(value)
  if type(value) == 'number' then
    return ' linhas=' .. value
  end
  if type(value) == 'string' then
    return ' bytes=' .. #value
  end
  if type(value) == 'table' then
    if value.rows then
      return ' linhas=' .. #value.rows
    end
    return ' itens=' .. #value
  end
  return ''
end

local operations = {
  {
    'file.write',
    function()
      return file.write(file_path, 'StartK file storage via IPC\n')
    end
  },
  {
    'file.list',
    function()
      return file.list('.')
    end
  },
  {
    'file.read',
    function()
      return file.read(file_path)
    end
  },
  {
    'file.remove',
    function()
      return file.remove(file_path)
    end
  },
  {
    'file.list after remove',
    function()
      return file.list('.')
    end
  },
  {
    'sql.create',
    function()
      return sqlite.execute(
        [[CREATE TABLE IF NOT EXISTS storage_demo
      (id INTEGER PRIMARY KEY, label TEXT NOT NULL, state TEXT NOT NULL)]],
        {}
      )
    end
  },
  {
    'sql.reset',
    function()
      return sqlite.execute('DELETE FROM storage_demo', {})
    end
  },
  {
    'sql.insert',
    function()
      return sqlite.execute('INSERT INTO storage_demo (label,state) VALUES (?,?)', {'IPC storage', 'created'})
    end
  },
  {
    'sql.query created',
    function()
      return sqlite.query('SELECT id,label,state FROM storage_demo ORDER BY id', {})
    end
  },
  {
    'sql.update',
    function()
      return sqlite.execute('UPDATE storage_demo SET state=? WHERE label=?', {'updated', 'IPC storage'})
    end
  },
  {
    'sql.query updated',
    function()
      return sqlite.query('SELECT id,label,state FROM storage_demo ORDER BY id', {})
    end
  },
  {
    'sql.delete',
    function()
      return sqlite.execute('DELETE FROM storage_demo WHERE label=?', {'IPC storage'})
    end
  }
}

local app =
  startk.application(
  {
    initial_state = {status = 'Executando operações de armazenamento…'},
    view = function(state)
      return form:document(state)
    end
  }
)

app:on(
  'navigation.close',
  function(ctx)
    ctx:exit()
  end
)
app:on(
  'app.started',
  function(ctx)
    local completed = 0
    for _, operation in ipairs(operations) do
      local name, request = operation[1], operation[2]
      ctx:patch({status = 'Executando ' .. name .. '…'})
      ctx:log('info', 'storage begin ' .. name)
      local result = ctx:await(request())
      completed = completed + 1
      if result.ok then
        ctx:log('info', 'storage ok ' .. name .. summary(result.value))
      else
        ctx:log('error', 'storage failed ' .. name .. ': ' .. result.error.message)
      end
    end
    ctx:patch({status = 'Concluído: ' .. completed .. ' operações; veja o log'})
    ctx:log('info', 'storage demo complete operations=' .. completed)
  end
)
app:start()
