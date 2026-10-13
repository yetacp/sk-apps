version: 1
form:
  id: chess
  layout: vertical
  gap: 16
  align: center
  children:
    - type: title_bar
      caption: Xadrez
      left: { id: close, icon: arrow-left, caption: Voltar, action: navigation.close }
    - { type: text, id: status, field: status }
    - type: chess_board
      id: board
      board_field: board
      marks_field: marks
      selected_field: selected
      flipped_field: flipped
      action: chess.square
    - { type: button, id: flip, caption: Girar tabuleiro, action: chess.flip }
