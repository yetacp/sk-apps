version: 1
form:
  id: values
  layout: vertical
  align: stretch
  children:
    - type: title_bar
      caption: Valores
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
        - { type: label, caption: Ajustes e indicadores }
        - {
            type: progress,
            id: volumeProgress,
            field: volume,
            min: 0,
            max: 100,
            show_value: true,
          }
        - { type: slider, id: volume, field: volume, min: 0, max: 100, step: 5, action: "values.volume" }
        - { type: number_picker, id: page, field: page, min: 1, max: 20, action: "values.page" }
        - type: row
          children:
            - {
                type: scroll_bar,
                offset_field: offset,
                viewport: 5,
                content: 20,
              }
