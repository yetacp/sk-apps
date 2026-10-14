# Xadrez para StartK

`app/` ainda contém o protótipo Lua de apresentação usado pelo runtime atual.
O núcleo da migração Rust está no pacote Cargo deste diretório: ele reaproveita
e adapta regras, busca local limitada e validação de partidas do Cobalt, sem
dependência de `kobo-sdk`/`kobo-ui` nem acesso a I/O. `ChessApp` entrega um
estado imutável para a UI e recebe ações; o app chamador deverá persistir o
texto de `save()` pelo broker privado do `startkd`.
Os módulos adaptados permanecem sob AGPL-3.0-only; a licença está em
`LICENSE` e a origem é o projeto [Cobalt](https://github.com/BandarLabs/Cobalt).

O manifesto continua em `api = 2` e seleciona Lua porque o launcher StartK ainda
não aceita apps Rust. Este núcleo, portanto, ainda não é um executável que o
launcher possa iniciar. A próxima integração é o cliente Rust da API de sessão
comum, a apresentação por `chess_board` e a persistência mediada pelo daemon.

O tabuleiro usa `app/assets/chess.sprites.json`, que referencia o atlas
`app/assets/chess.png`. A app seleciona o catálogo por nome; o daemon lê PNG e
metadados do snapshot do pacote.
