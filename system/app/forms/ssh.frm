version: 1
form:
  id: system-ssh
  layout: vertical
  align: stretch
  children:
    - type: title_bar
      caption: SSH
      left: { id: back, icon: arrow-left, caption: Sistema, action: "system.back" }
    - type: column
      padding: 24
      gap: 12
      align: stretch
      children:
        - { type: label, caption: Estado do servidor }
        - { type: text, id: sshStatus, field: ssh_status }
        - { type: text_box, id: sshInstructions, field: ssh_instructions, wrap: true }
        - type: row
          gap: 12
          align: stretch
          children:
            - { type: button, id: refreshSsh, caption: Atualizar estado, action: "system.ssh.refresh" }
            - { type: button, id: startSsh, caption: Iniciar SSH, action: "system.ssh.start" }
            - { type: button, id: stopSsh, caption: Parar SSH, action: "system.ssh.stop" }
        - { type: text_box, id: notice, field: notice, wrap: true }
