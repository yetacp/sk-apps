version: 1
form:
  id: checklist-empty
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
        - { type: button, id: add, caption: Adicionar, action: "checklist.add" }
