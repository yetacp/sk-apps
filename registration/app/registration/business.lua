local M = {}

M.categories = {
  {value = 'cliente', caption = 'Cliente'},
  {value = 'fornecedor', caption = 'Fornecedor'},
  {value = 'parceiro', caption = 'Parceiro'}
}

function M.copy(contact)
  return {
    id = contact.id,
    name = contact.name,
    phone = contact.phone,
    email = contact.email,
    notes = contact.notes,
    active = contact.active,
    category = contact.category,
    priority = contact.priority
  }
end

function M.empty()
  return {name = '', phone = '', email = '', notes = '', active = true, category = 'cliente', priority = 1}
end

function M.find(contacts, id)
  for _, contact in ipairs(contacts) do
    if contact.id == id then
      return contact
    end
  end
end

function M.validate(draft)
  if draft.name == '' then
    return 'Informe o nome.'
  end
  if #draft.name > 80 then
    return 'Nome excede 80 bytes.'
  end
  if #draft.phone > 40 then
    return 'Telefone excede 40 bytes.'
  end
  if #draft.email > 80 then
    return 'E-mail excede 80 bytes.'
  end
  if #draft.notes > 4096 then
    return 'Observações excedem 4096 bytes.'
  end
  if not draft.email:find('@', 1, true) then
    return 'Informe um e-mail com @.'
  end
  if draft.phone == '' then
    return 'Informe o telefone.'
  end
end

function M.from_row(row)
  return {
    id = row[1],
    name = row[2],
    phone = row[3],
    email = row[4],
    notes = row[5],
    active = row[6] ~= 0,
    category = row[7],
    priority = row[8]
  }
end

function M.changed(draft, original)
  if not draft or not original then
    return false
  end
  return draft.name ~= original.name or draft.phone ~= original.phone or draft.email ~= original.email or
    draft.notes ~= original.notes or
    draft.active ~= original.active or
    draft.category ~= original.category or
    draft.priority ~= original.priority
end

function M.list_model(state, contacts)
  local items = {}
  for _, contact in ipairs(contacts) do
    items[#items + 1] = {
      id = tostring(contact.id),
      caption = contact.name,
      secondary_caption = contact.email,
      enabled = contact.active
    }
  end
  if not M.find(contacts, state.selected) then
    state.selected = contacts[1] and contacts[1].id
  end
  return {
    notice = state.notice,
    empty_message = state.loading and 'Aguarde enquanto os cadastros são carregados.' or
      'Nenhum cadastro salvo. Crie o primeiro cadastro para começar.',
    selected_contact = state.selected and tostring(state.selected),
    contact_items = items
  }
end

return M
