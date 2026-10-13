version: 1
form:
  id: editor
  layout: vertical
  align: stretch
  children:
    - type: title_bar
      caption: Editor e teclado
      left:
        {
          id: close,
          icon: arrow-left,
          caption: Voltar,
          action: "navigation.close",
        }
    - type: column
      padding: 32
      gap: 16
      align: stretch
      children:
        - { type: label, caption: Edição de texto }
        - { type: text, caption: Toque em um campo para abrir o teclado }
        - {
            type: edit,
            id: name,
            field: name,
            placeholder: Nome,
            max_length: 80,
          }
        - {
            type: text_area,
            id: notes,
            field: notes,
            placeholder: Notas,
            rows: 5,
          }
        - { type: label, caption: Código Lua }
        - {
            type: code_editor,
            id: source,
            field: source,
            rows: 5,
            line_numbers: true,
            tab_width: 4,
          }
