local M = {}

function M.new(business)
  local forms = {
    list = startk.form('forms/list.frm'),
    empty = startk.form('forms/list-empty.frm'),
    edit = startk.form('forms/edit.frm'),
    edit_confirm = startk.form('forms/edit-confirm.frm'),
    detail = startk.form('forms/detail.frm'),
    detail_confirm = startk.form('forms/detail-confirm.frm')
  }

  local function list_model(state)
    local items = {}
    for _, contact in ipairs(state.contacts) do
      items[#items + 1] = {
        id = tostring(contact.id),
        caption = contact.name,
        secondary_caption = contact.email,
        enabled = contact.active
      }
    end
    return {
      notice = state.notice,
      empty_message = state.loading and 'Aguarde enquanto os cadastros são carregados.' or
        'Nenhum cadastro salvo. Crie o primeiro cadastro para começar.',
      selected_contact = state.selected and tostring(state.selected),
      contact_items = items
    }
  end

  local function edit_model(state)
    local model = business.copy(state.draft)
    model.message = state.edit_message or 'Preencha nome, telefone e e-mail.'
    model.categories = business.categories
    return model
  end

  local function detail_model(state)
    local contact = assert(business.find(state.contacts, state.selected), 'contact not found')
    local category = ''
    for _, item in ipairs(business.categories) do
      if item.value == contact.category then
        category = item.caption
      end
    end
    return {
      name = contact.name,
      contact = 'Telefone: ' .. contact.phone .. '\nE-mail: ' .. contact.email,
      notes = contact.notes,
      summary = 'Categoria: ' .. category .. ' | Prioridade: ' .. contact.priority,
      status = contact.active and 'Cadastro ativo' or 'Cadastro inativo'
    }
  end

  local function document(state)
    if state.page == 'list' then
      local template = #state.contacts == 0 and forms.empty or forms.list
      return template:document(list_model(state))
    end
    if state.page == 'edit' then
      local template = state.confirm_discard and forms.edit_confirm or forms.edit
      return template:document(edit_model(state))
    end
    local template = state.confirm_delete and forms.detail_confirm or forms.detail
    return template:document(detail_model(state))
  end

  return {forms = forms, document = document}
end

return M
