local business = startk.require('registration.business')
local persistence = startk.require('registration.persistence')
local presentation = startk.require('registration.presentation').new(business)
local forms = presentation.forms

local app =
  startk.application(
  {
    initial_state = {
      page = 'list',
      contacts = {},
      selected = nil,
      loading = true,
      notice = 'Carregando cadastros…',
      draft = nil,
      original = nil,
      edit_message = nil,
      confirm_discard = false,
      confirm_delete = false
    },
    view = presentation.document
  }
)

local function fail(ctx, label, result)
  local message = label .. ': ' .. (result.error.message or 'erro desconhecido')
  if ctx.state.page == 'edit' then
    ctx:patch({edit_message = message, loading = false})
  else
    ctx:patch({notice = message, loading = false})
  end
  ctx:log('error', message)
end

local function load(ctx, notice)
  ctx:patch({loading = true, notice = notice or 'Carregando cadastros…'})
  local result = ctx:await(persistence.list())
  if not result.ok then
    fail(ctx, 'Falha ao carregar cadastros', result)
    return false
  end
  local contacts = {}
  for _, row in ipairs(result.value.rows) do
    contacts[#contacts + 1] = business.from_row(row)
  end
  local selected = ctx.state.selected
  if not business.find(contacts, selected) then
    selected = contacts[1] and contacts[1].id
  end
  ctx:patch(
    {
      contacts = contacts,
      selected = selected,
      loading = false,
      notice = notice or
        (#contacts == 0 and 'Nenhum cadastro salvo.' or tostring(#contacts) .. ' cadastro(s). Toque para selecionar.')
    }
  )
  return true
end

local function edit_values(event)
  local values, errors = forms.edit:values(event)
  return business.copy(values), errors
end

app:on(
  'app.started',
  function(ctx)
    local result = ctx:await(persistence.initialize())
    if not result.ok then
      return fail(ctx, 'Falha ao preparar o banco', result)
    end
    load(ctx)
  end
)

app:on(
  'navigation.close',
  function(ctx)
    ctx:exit()
  end
)

app:on(
  'registration.new',
  function(ctx)
    local draft = business.empty()
    ctx:patch(
      {
        page = 'edit',
        draft = draft,
        original = business.copy(draft),
        edit_message = 'Preencha nome, telefone e e-mail.',
        confirm_discard = false
      }
    )
  end
)

app:on(
  'registration.open',
  function(ctx, event)
    local values = forms.list:values(event)
    local id = tonumber(values.selected_contact)
    local contact = business.find(ctx.state.contacts, id)
    if not contact then
      return ctx:patch({notice = 'Selecione um cadastro válido.'})
    end
    ctx:patch({page = 'detail', selected = id, confirm_delete = false})
  end
)

app:on(
  'registration.detail_back',
  function(ctx)
    ctx:patch({page = 'list', confirm_delete = false})
  end
)

app:on(
  'registration.detail_edit',
  function(ctx)
    local contact = business.find(ctx.state.contacts, ctx.state.selected)
    if not contact then
      return ctx:patch({page = 'list', notice = 'Cadastro não encontrado.'})
    end
    ctx:patch(
      {
        page = 'edit',
        draft = business.copy(contact),
        original = business.copy(contact),
        edit_message = 'Revise os dados e salve quando terminar.',
        confirm_discard = false
      }
    )
  end
)

app:on(
  'registration.back',
  function(ctx, event)
    local draft = edit_values(event)
    if business.changed(draft, ctx.state.original) then
      ctx:patch({draft = draft, confirm_discard = true})
    else
      ctx:patch(
        {
          page = 'list',
          draft = nil,
          original = nil,
          notice = 'Nenhuma alteração para descartar.'
        }
      )
    end
  end
)

app:on(
  'registration.discard',
  function(ctx, event)
    ctx:patch({draft = edit_values(event), confirm_discard = true})
  end
)

app:on(
  'registration.discard_cancel',
  function(ctx)
    ctx:patch({confirm_discard = false})
  end
)

app:on(
  'registration.discard_confirm',
  function(ctx)
    ctx:patch(
      {
        page = 'list',
        draft = nil,
        original = nil,
        confirm_discard = false,
        notice = 'Alterações descartadas.'
      }
    )
  end
)

app:on(
  'registration.save',
  function(ctx, event)
    local draft, errors = edit_values(event)
    if errors then
      return ctx:patch({draft = draft, edit_message = 'Revise os campos.'})
    end
    local validation = business.validate(draft)
    if validation then
      return ctx:patch({draft = draft, edit_message = validation})
    end
    ctx:patch({draft = draft, edit_message = 'Salvando cadastro…'})
    local id = ctx.state.original and ctx.state.original.id or nil
    local result = ctx:await(persistence.save(draft, id))
    if not result.ok then
      return fail(ctx, 'Falha ao salvar cadastro', result)
    end
    ctx:patch({page = 'list', draft = nil, original = nil})
    load(ctx, 'Cadastro salvo.')
  end
)

app:on(
  'registration.delete',
  function(ctx)
    ctx:patch({confirm_delete = true})
  end
)

app:on(
  'registration.delete_cancel',
  function(ctx)
    ctx:patch({confirm_delete = false})
  end
)

app:on(
  'registration.delete_confirm',
  function(ctx)
    local id = ctx.state.selected
    ctx:patch(
      {
        page = 'list',
        selected = nil,
        confirm_delete = false,
        notice = 'Excluindo cadastro…'
      }
    )
    local result = ctx:await(persistence.remove(id))
    if not result.ok then
      return fail(ctx, 'Falha ao excluir cadastro', result)
    end
    load(ctx, 'Cadastro excluído.')
  end
)

app:start()
