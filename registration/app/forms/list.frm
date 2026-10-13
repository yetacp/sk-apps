version: 1
form:
  id: registration-list
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
        - {
            type: list_view,
            id: contacts,
            field: selected_contact,
            items_field: contact_items,
            visible_rows: 8,
            scroll_offset: 0,
          }
        - type: row
          gap: 16
          align: stretch
          children:
            - {
                type: expand,
                child:
                  {
                    type: button,
                    id: new,
                    caption: Novo cadastro,
                    action: "registration.new",
                  },
              }
            - {
                type: expand,
                child:
                  {
                    type: button,
                    id: openSelected,
                    caption: Abrir cadastro,
                    action: "registration.open",
                  },
              }
