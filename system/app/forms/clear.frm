version: 1
form:
  id: clear_battery_stats
  layout: vertical
  align: stretch
  children:
    - type: title_bar
      caption: Limpar estatísticas
      left: { id: back, icon: arrow-left, caption: Voltar, action: "system.clear.cancel" }
    - type: column
      padding: 28
      gap: 16
      align: stretch
      children:
        - { type: text_box, caption: Apagar as amostras da bateria salvas por este app? }
        - type: row
          gap: 16
          align: stretch
          children:
            - { type: button, id: confirm, caption: Limpar, action: "system.stats.clear.confirm" }
            - { type: button, id: cancel, caption: Cancelar, action: "system.clear.cancel" }
