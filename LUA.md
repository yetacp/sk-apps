# Programação Lua no StartK

Um aplicativo é um pacote com `manifest.stk`, `app/main.lua` e seus recursos. O manifesto declara a identidade, a versão, a API, o ponto de entrada, as capacidades e os limites. Use um dos pacotes deste repositório como modelo.

O runtime carrega o SDK Lua como `startk` antes de executar `app/main.lua`. Declare o estado inicial, uma função `view` que produz o documento da tela e handlers para as ações da interface:

```lua
local form = startk.form('forms/main.frm')
local app = startk.application({
  initial_state = {message = 'Pronto'},
  view = function(state)
    return form:document(state)
  end,
})

app:on('example.activate', function(ctx, event)
  ctx:patch({message = 'Ativado'})
end)

app:start()
```

O arquivo `.frm` descreve os componentes e as ações sem fazer I/O. Uma ação declarada no formulário é entregue ao handler com o mesmo nome. O estado alterado por `ctx:patch` faz a tela ser publicada novamente. Veja `basic/` para um exemplo pequeno e `registration/` para a separação entre apresentação, regras e persistência.

Para carregar outro módulo Lua do pacote, use `startk.require('nome.do.modulo')`; o nome corresponde a `app/nome/do/modulo.lua`. O `require` global e os módulos de sistema não estão disponíveis.

Arquivos privados e SQLite são serviços assíncronos do SDK. Declare `storage_private = true` em `[capabilities]` antes de usá-los e aguarde o resultado com `ctx:await(...)`. Veja `ipc-storage/`, `checklist/` e `registration/` para exemplos executáveis. O aplicativo não acessa diretamente arquivos, sockets, display ou processos do sistema.

Para consultar uma API JSON, declare os hosts exatos em `network = ["api.exemplo.com"]` no manifesto. `startk.http.get_json(url)` e `startk.http.post_json(url, tabela)` retornam operações aguardadas com `ctx:await`. A resposta bem-sucedida tem `result.value.status` e `result.value.body`. O daemon aceita HTTPS na porta 443, sem redirecionamentos, e limita a resposta a 240 KiB. Para enviar JSON `null`, use `startk.json.null`.

Para registrar diagnósticos, use `startk.log('info', 'Mensagem')`. Os níveis aceitos são `debug`, `info`, `warn` e `error`.

Os contratos completos do pacote, do formulário e da sessão estão na [documentação do StartK](../startk/docs/README.md). Na raiz de `startk/`, verifique um pacote com `rtk make current-app-check APP=basic` e gere o pacote com `rtk make current-app-package APP=basic`.
