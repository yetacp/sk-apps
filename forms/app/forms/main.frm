version: 1
form:
  id: fields
  layout: vertical
  align: stretch
  children:
    - type: title_bar
      caption: Formulários
      left:
        {
          id: close,
          icon: arrow-left,
          caption: Voltar,
          action: "navigation.close",
        }
    - type: column
      padding: 32
      gap: 12
      align: stretch
      children:
        - { type: label, caption: Escolhas e campos }
        - type: row
          gap: 24
          align: stretch
          children:
            - type: expand
              child:
                type: column
                gap: 12
                align: stretch
                children:
                  - {
                      type: check_box,
                      id: checked,
                      field: checked,
                      caption: Selecionado,
                      action: "fields.checked",
                    }
                  - {
                      type: check_box,
                      id: disabled,
                      field: disabled,
                      caption: Desabilitado,
                      enabled: false,
                    }
                  - {
                      type: toggle,
                      id: night,
                      field: night,
                      caption: Modo noturno,
                      action: "fields.night",
                    }
                  - type: radio_group
                    id: theme
                    field: theme
                    action: "fields.theme"
                    options:
                      - value: light
                        caption: Claro
                      - value: dark
                        caption: Escuro
            - type: expand
              child:
                type: column
                gap: 12
                align: stretch
                children:
                  - {
                      type: edit,
                      id: name,
                      field: name,
                      placeholder: Nome,
                      max_length: 40,
                    }
                  - {
                      type: text_area,
                      id: notes,
                      field: notes,
                      placeholder: Notas,
                      rows: 2,
                    }
                  - {
                      type: text_box,
                      caption: "Texto somente leitura\nem mais de uma linha.",
                    }
