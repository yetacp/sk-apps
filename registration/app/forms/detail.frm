version: 1
form:
  id: registration-detail
  layout: vertical
  align: stretch
  children:
    - type: title_bar
      caption: Detalhe
      left:
        {
          id: back,
          icon: arrow-left,
          caption: Voltar,
          action: "registration.detail_back",
        }
    - type: column
      padding: 47
      gap: 24
      align: stretch
      children:
        - { type: label, id: nameLabel, field: name }
        - { type: text_box, id: contactText, field: contact }
        - { type: text_box, id: notesText, field: notes }
        - { type: text, id: summaryText, field: summary }
        - { type: text, id: statusText, field: status }
        - type: row
          gap: 16
          align: stretch
          children:
            - {
                type: expand,
                child:
                  {
                    type: icon_button,
                    id: edit,
                    icon: pencil-simple,
                    caption: Editar,
                    action: "registration.detail_edit",
                  },
              }
            - {
                type: expand,
                child:
                  {
                    type: button,
                    id: delete,
                    caption: Excluir,
                    action: "registration.delete",
                  },
              }
