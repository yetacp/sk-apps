version: 1
form:
  id: storage
  layout: vertical
  align: stretch
  children:
    - type: title_bar
      caption: Armazenamento
      left: { id: close, icon: arrow-left, caption: Voltar, action: "navigation.close" }
    - type: column
      padding: 47
      gap: 24
      align: stretch
      children:
        - { type: text_box, id: status, field: status }
