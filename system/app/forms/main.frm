version: 1
form:
  id: system
  layout: vertical
  align: stretch
  children:
    - type: title_bar
      caption: Sistema
      left: { id: close, icon: arrow-left, caption: Voltar, action: "navigation.close" }
    - type: column
      padding: 24
      gap: 12
      align: stretch
      children:
        - { type: text, id: device, field: device }
        - type: row
          gap: 20
          align: stretch
          children:
            - type: expand
              child:
                type: column
                gap: 8
                align: stretch
                children:
                  - { type: label, caption: Bateria }
                  - { type: text, id: battery, field: battery }
                  - { type: text, id: batteryStatus, field: battery_status }
            - type: expand
              child:
                type: column
                gap: 8
                align: stretch
                children:
                  - { type: label, caption: Conectividade }
                  - { type: toggle, id: wifi, field: wifi_enabled, caption: Wi-Fi, action: "system.wifi" }
        - { type: label, caption: Iluminação frontal (0–100) }
        - { type: slider, id: lightLevel, field: light_level, min: 0, max: 100, step: 4, action: "system.light" }
        - { type: label, caption: Luz natural (fria–quente) }
        - { type: slider, id: warmth, field: warmth, min: 0, max: 100, step: 10, action: "system.warmth" }
        - { type: text, id: notice, field: notice }
        - type: row
          gap: 16
          align: stretch
          children:
            - { type: button, id: refresh, caption: Atualizar, action: "system.refresh" }
            - { type: button, id: rndis, caption: USB via RNDIS, action: "system.rndis.open" }
            - { type: button, id: stats, caption: Estatísticas da bateria, action: "system.stats" }
