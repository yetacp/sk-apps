version: 1
form:
  id: checklist-list
  layout: vertical
  align: stretch
  children:
    - type: title_bar
      caption: Checklist
      left: { id: close, icon: arrow-left, caption: Voltar, action: "navigation.close" }
    - type: column
      padding: 47
      gap: 24
      align: stretch
      children:
        - { type: text, id: message, field: message }
        - { type: edit, id: task, field: task, placeholder: "Nova tarefa", max_length: 120 }
        - { type: list_view, id: selected, field: selected, items_field: items, visible_rows: 7, scroll_offset: 0 }
        - type: row
          gap: 24
          align: stretch
          children:
            - { type: expand, child: { type: button, id: add, caption: Adicionar, action: "checklist.add" } }
            - { type: expand, child: { type: button, id: toggle, caption: "Concluir / reabrir", action: "checklist.toggle" } }
            - { type: expand, child: { type: button, id: remove, caption: Excluir, action: "checklist.remove" } }
