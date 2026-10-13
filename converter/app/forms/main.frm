version: 1
form:
  id: converter
  layout: vertical
  align: stretch
  children:
    - type: title_bar
      caption: Conversor
      left: { id: close, icon: arrow-left, caption: Voltar, action: "navigation.close" }
    - type: column
      padding: 47
      gap: 24
      align: stretch
      children:
        - { type: edit, id: value, field: value, placeholder: Valor, max_length: 32 }
        - type: radio_group
          id: mode
          field: mode
          options:
            - { value: c_f, caption: "Celsius para Fahrenheit" }
            - { value: f_c, caption: "Fahrenheit para Celsius" }
            - { value: km_mi, caption: "Quilômetros para milhas" }
            - { value: mi_km, caption: "Milhas para quilômetros" }
        - { type: text_box, id: result, field: result }
        - { type: button, id: convert, caption: Converter, action: "converter.convert" }
