version: 1
form:
  id: controls
  layout: vertical
  align: stretch
  children:
    - type: title_bar
      caption: Controles fundamentais
      left:
        {
          id: close,
          icon: arrow-left,
          caption: Voltar,
          action: "navigation.close",
        }
    - type: column
      padding: 32
      gap: 20
      align: stretch
      children:
        - { type: text, id: messageText, field: message }
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
                  - { type: label, caption: Seleção }
                  - { type: check_box, id: wifi, field: wifi, caption: Wi-Fi }
                  - {
                      type: toggle,
                      id: night,
                      field: night,
                      caption: Modo noturno,
                    }
                  - type: radio_group
                    id: theme
                    field: theme
                    options:
                      - { value: light, caption: Tema claro }
                      - { value: dark, caption: Tema escuro }
            - type: expand
              child:
                type: column
                gap: 12
                align: stretch
                children:
                  - { type: label, caption: Campos e valores }
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
                  - { type: text_box, caption: Somente leitura }
                  - {
                      type: progress,
                      id: volumeProgress,
                      field: volume,
                      min: 0,
                      max: 100,
                      show_value: true,
                    }
                  - {
                      type: slider,
                      id: volume,
                      field: volume,
                      min: 0,
                      max: 100,
                      step: 5,
                    }
                  - {
                      type: number_picker,
                      id: page,
                      field: page,
                      min: 1,
                      max: 20,
                    }
