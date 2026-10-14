# Xadrez para StartK

Chess é uma app Rust nativa. O pacote Cargo deste diretório reaproveita e adapta
regras, busca local limitada e validação de partidas do Cobalt, sem dependência
de `kobo-sdk`/`kobo-ui` nem acesso direto a I/O. `ChessApp` entrega estado
imutável, converte ações em transições de domínio e produz documentos
`startk-ui`. `run_session` usa o cliente de sessão StartK para selecionar
assets e ler/gravar o save pelo broker privado do `startkd`.
Os módulos adaptados permanecem sob AGPL-3.0-only; a licença está em
`LICENSE` e a origem é o projeto [Cobalt](https://github.com/BandarLabs/Cobalt).

O manifesto API 3 seleciona o runtime Rust e declara executáveis estáticos para
Linux x86_64 e Kobo ARMv7/musl. `rtk make -C ../startk app-release APP=chess` gera as duas
variantes, valida o pacote SKB4 e prepara os artefatos de release. O launcher
StartK já identifica o runtime no manifesto; o início permanece condicionado à
política de isolamento nativo descrita no repositório StartK. O binário recebe
as credenciais de sessão no ambiente e o socket conectado no descritor 3.

O tabuleiro usa `app/assets/chess.sprites.json`, que referencia o atlas
`app/assets/chess.png`. A app seleciona o catálogo por nome; o daemon lê PNG e
metadados do snapshot do pacote.
