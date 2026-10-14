# Xadrez — primeiro corte

Este pacote exercita o componente `chess_board` no simulador: seleção de casa,
orientação, coordenadas e ações de toque. As peças são desenhadas a partir de
`app/assets/chess.png`, um atlas RGBA de 250×84 px com seis peças brancas na
primeira linha e seis pretas na segunda. `app/assets/chess.sprites.json`
declara os doze recortes e referencia `chess.png`. O runner envia apenas o nome
do catálogo ao `startkd`, que
resolve PNG e catálogo no snapshot validado antes da primeira tela; atualizações
enviam apenas o estado das casas. O componente
conserva um desenho de letras quando não há spritesheet.

Ainda não aplica regras de xadrez, não move peças, não tem adversário e não
salva partidas. Por isso não está no catálogo `apps.json`.

Execute a partir do StartK com:

```sh
rtk make current-app-check APP=chess
rtk make current-app-package APP=chess
rtk sh -c 'cd src && cargo build --workspace --locked --offline && target/debug/startkd --app ../../sk-apps/chess --sdl-input'
```
