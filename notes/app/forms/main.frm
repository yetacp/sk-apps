version: 1
form:
  id: notes
  layout: vertical
  align: stretch
  children:
    - type: title_bar
      caption: Notas locais
      left: { id: close, icon: arrow-left, caption: Voltar, action: "navigation.close" }
    - type: column
      padding: 47
      gap: 24
      align: stretch
      children:
        - { type: text_box, id: message, field: message }
        - { type: text_area, id: body, field: body, placeholder: "Escreva uma nota…", rows: 12 }
        - type: row
          gap: 24
          align: stretch
          children:
            - { type: expand, child: { type: button, id: save, caption: "Salvar nota", action: "notes.save" } }
            - { type: expand, child: { type: button, id: clear, caption: Limpar, action: "notes.clear" } }
