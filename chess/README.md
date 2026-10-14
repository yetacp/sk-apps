# Xadrez para StartK

`app/` ainda contém o protótipo Lua de apresentação usado pelo runtime atual.
O pacote Cargo deste diretório reaproveita e adapta regras, busca local
limitada e validação de partidas do Cobalt, sem dependência de `kobo-sdk`/
`kobo-ui` nem acesso direto a I/O. `ChessApp` entrega estado imutável, converte
ações em transições de domínio e produz documentos `startk-ui`. `run_session`
usa o cliente de sessão StartK para selecionar assets e ler/gravar o save pelo
broker privado do `startkd`.
Os módulos adaptados permanecem sob AGPL-3.0-only; a licença está em
`LICENSE` e a origem é o projeto [Cobalt](https://github.com/BandarLabs/Cobalt).

O manifesto continua em `api = 2` e seleciona Lua porque o launcher StartK ainda
não aceita apps Rust. O binário `chess` já espera as credenciais de sessão no
ambiente e o socket StartK conectado no descritor 3. Ainda falta o launcher
selecionar e iniciar esse binário para que o modo Rust possa ser executado.

O tabuleiro usa `app/assets/chess.sprites.json`, que referencia o atlas
`app/assets/chess.png`. A app seleciona o catálogo por nome; o daemon lê PNG e
metadados do snapshot do pacote.
