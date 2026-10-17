local M = {}

function M.refresh(ctx)
  local result = ctx:await(startk.system.ssh_status())
  if not result.ok then
    local message = result.error.code == 'device_unavailable'
      and 'Controle SSH disponível apenas no Kobo Clara BW.'
      or ('Falha ao consultar SSH: ' .. (result.error.message or 'erro'))
    return {ssh_status='Indisponível',ssh_instructions=message,ssh_running=false}
  end
  local state = result.value.state == 'running'
  return {
    ssh_status=state and ('Ativo · porta ' .. tostring(result.value.port)) or 'Inativo',
    ssh_instructions='Conecte com ssh -p 2222 root@<IP-do-Kobo>. O IP depende da rede '
      .. '(RNDIS padrão: 192.168.7.1). Acesso somente por chave pública; cadastre-a em '
      .. tostring(result.value.authorized_keys)
      .. ' e confira a impressão digital do servidor no primeiro acesso.',
    ssh_running=state
  }
end

return M
