version: 1
form:
  id: system-rndis
  layout: vertical
  align: stretch
  children:
    - type: title_bar
      caption: USB via RNDIS
      left: { id: back, icon: arrow-left, caption: Sistema, action: "system.back" }
    - type: column
      padding: 24
      gap: 12
      align: stretch
      children:
        - { type: label, caption: Estado da conexão }
        - { type: text_box, id: rndisStatus, field: rndis_status, wrap: true }
        - { type: text_box, id: rndisInstructions, field: rndis_instructions, wrap: true }
        - { type: edit, id: deviceMac, field: rndis_device_mac, placeholder: MAC do Kobo, max_length: 17 }
        - { type: edit, id: hostMac, field: rndis_host_mac, placeholder: MAC do host, max_length: 17 }
        - { type: edit, id: deviceIp, field: rndis_device_ip, placeholder: IP do Kobo, max_length: 15 }
        - { type: edit, id: hostIp, field: rndis_host_ip, placeholder: IP estático do host, max_length: 15 }
        - { type: edit, id: netmask, field: rndis_netmask, placeholder: Máscara, max_length: 15 }
        - type: row
          gap: 12
          align: stretch
          children:
            - { type: button, id: saveRndis, caption: Salvar parâmetros, action: "system.rndis.save" }
            - { type: button, id: refreshRndis, caption: Atualizar estado, action: "system.rndis.refresh" }
        - type: row
          gap: 12
          align: stretch
          children:
            - { type: button, id: enableRndis, caption: Ativar RNDIS, action: "system.rndis.enable" }
            - { type: button, id: disableRndis, caption: Desativar RNDIS, action: "system.rndis.disable" }
        - { type: text_box, id: notice, field: notice, wrap: true }
