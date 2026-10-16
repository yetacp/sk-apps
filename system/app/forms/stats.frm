version: 1
form:
  id: battery_stats
  layout: vertical
  align: stretch
  children:
    - type: title_bar
      caption: Bateria
      left: { id: back, icon: arrow-left, caption: Voltar, action: "system.back" }
    - type: column
      padding: 28
      gap: 16
      align: stretch
      children:
        - { type: label, caption: Estatísticas desde as amostras registradas pelo StartK }
        - { type: text_box, id: stats, field: stats, wrap: true }
        - { type: text_box, id: notice, field: notice, wrap: true }
        - type: row
          gap: 16
          align: stretch
          children:
            - { type: button, id: refresh, caption: Atualizar, action: "system.stats.refresh" }
            - { type: button, id: clear, caption: Limpar dados, action: "system.stats.clear" }
