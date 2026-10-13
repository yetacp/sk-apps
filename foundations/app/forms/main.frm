version: 1

form:
  id: foundations
  layout: vertical
  align: stretch

  children:
    - type: title_bar
      caption: Fundamentos
      left:
        id: close
        icon: arrow-left
        caption: Voltar
        action: navigation.close

    - type: column
      padding: 32
      gap: 16
      align: stretch
      children:
        - type: label
          caption: Estrutura e ações

        - type: row
          gap: 32
          children:
            - type: text
              caption: Esquerda
            - type: text
              caption: Direita

        - type: row
          gap: 20
          align: stretch
          children:
            - type: expand
              child:
                type: button
                id: primary
                caption: Primário
                action: foundations.primary
            - type: expand
              child:
                type: button
                id: secondary
                caption: Secundário
                action: foundations.secondary

        - type: icon_button
          id: library
          icon: books
          caption: Biblioteca
          action: foundations.library

        - type: text
          id: statusText
          field: status
