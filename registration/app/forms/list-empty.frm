version: 1
form:
  id: registration-list-empty
  layout: vertical
  align: stretch
  children:
    - type: title_bar
      caption: Cadastro local
      left:
        {
          id: close,
          icon: arrow-left,
          caption: Voltar,
          action: "navigation.close",
        }
    - type: column
      padding: 47
      gap: 24
      align: stretch
      children:
        - { type: text, id: noticeText, field: notice }
        - { type: text_box, id: emptyMessage, field: empty_message }
        - {
            type: button,
            id: new,
            caption: Novo cadastro,
            action: "registration.new",
          }
