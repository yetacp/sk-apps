version: 1
form:
  id: collections
  layout: vertical
  align: stretch
  children:
    - type: title_bar
      caption: Coleções
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
        - { type: label, caption: Listas e menus }
        - { type: text, caption: "Listas, viewport e menu" }
        - type: row
          gap: 24
          align: stretch
          children:
            - type: expand
              child:
                type: column
                gap: 16
                align: stretch
                children:
                  - { type: label, caption: Lista 1 }
                  - type: list
                    id: list
                    field: list
                    items:
                      - { id: one, caption: Primeiro }
                      - { id: two, caption: Segundo }
                      - { id: three, caption: Terceiro }
                  - { type: label, caption: Lista 2 }
                  - type: list_view
                    id: view
                    field: view
                    scroll_offset: 1
                    visible_rows: 3
                    items:
                      - { id: one, caption: Primeiro }
                      - { id: two, caption: Segundo }
                      - { id: three, caption: Terceiro }
                      - { id: four, caption: Quarto }
            - type: expand
              child:
                type: column
                gap: 16
                align: stretch
                children:
                  - { type: label, caption: Lista 3 }
                  - type: menu
                    id: menu
                    field: menu
                    visible_rows: 3
                    scroll_offset: 0
                    items:
                      - { id: open, caption: Abrir }
                      - { id: remove, caption: Remover }
                      - { id: rename, caption: Renomear }
                      - { id: copy, caption: Copiar }
                      - { id: move, caption: Mover }
                      - { id: share, caption: Compartilhar }
