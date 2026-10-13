version: 1
form:
  id: registration-form
  layout: vertical
  align: stretch
  children:
    - type: title_bar
      caption: Cadastro
      left:
        {
          id: back,
          icon: arrow-left,
          caption: Voltar,
          action: "registration.back",
        }
    - type: column
      padding: 32
      gap: 16
      align: stretch
      children:
        - { type: text, caption: Dados de contato }
        - {
            type: edit,
            id: name,
            field: name,
            placeholder: Nome,
            required: true,
            max_length: 80,
          }
        - {
            type: edit,
            id: phone,
            field: phone,
            placeholder: Telefone,
            required: true,
            max_length: 40,
          }
        - {
            type: edit,
            id: email,
            field: email,
            placeholder: E-mail,
            required: true,
            max_length: 80,
            format: email,
          }
        - {
            type: check_box,
            id: active,
            field: active,
            caption: Cadastro ativo,
          }
        - { type: text, caption: Preferências }
        - {
            type: radio_group,
            id: category,
            field: category,
            options_field: categories,
          }
        - { type: number_picker, id: priority, field: priority, min: 1, max: 4 }
        - { type: text, caption: Observações }
        - {
            type: text_area,
            id: notes,
            field: notes,
            placeholder: Observações,
            rows: 1,
          }
        - { type: text_box, id: messageText, field: message }
        - type: row
          gap: 16
          align: stretch
          children:
            - {
                type: expand,
                child:
                  {
                    type: button,
                    id: save,
                    caption: Salvar cadastro,
                    action: "registration.save",
                  },
              }
            - {
                type: expand,
                child:
                  {
                    type: button,
                    id: discard,
                    caption: Descartar alterações,
                    action: "registration.discard",
                  },
              }
