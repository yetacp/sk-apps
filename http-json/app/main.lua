local form = startk.form('forms/main.frm')
local base_url = 'https://jsonplaceholder.typicode.com/posts'

local app = startk.application({
  initial_state = {
    message = 'Escolha uma operação.',
    post_title = 'Nenhum post carregado.'
  },
  view = function(state)
    return form:document(state)
  end
})

app:on('post.load', function(ctx)
  ctx:patch({message = 'Consultando…'})
  local result = ctx:await(startk.http.get_json(base_url .. '/1'))
  if not result.ok then
    return ctx:patch({message = result.error.message})
  end
  if result.value.status ~= 200 or type(result.value.body) ~= 'table' then
    return ctx:patch({message = 'GET: HTTP ' .. result.value.status})
  end

  local title = result.value.body.title
  if type(title) ~= 'string' then
    return ctx:patch({message = 'Resposta sem título.'})
  end
  ctx:patch({message = 'GET: HTTP 200', post_title = title})
end)

app:on('post.send', function(ctx)
  ctx:patch({message = 'Enviando…'})
  local result = ctx:await(startk.http.post_json(base_url, {
    title = 'Exemplo StartK',
    body = 'Enviado como JSON pelo SDK.',
    userId = 1
  }))
  if not result.ok then
    return ctx:patch({message = result.error.message})
  end
  if result.value.status ~= 201 or type(result.value.body) ~= 'table' then
    return ctx:patch({message = 'POST: HTTP ' .. result.value.status})
  end

  local id = result.value.body.id
  ctx:patch({message = 'POST: HTTP 201, id ' .. tostring(id)})
end)

app:on('navigation.close', function(ctx)
  ctx:exit()
end)

app:start()
