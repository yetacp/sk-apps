version: 1
form:
  id: rndis-confirm
  layout: vertical
  align: stretch
  children:
    - type: title_bar
      caption: Confirmar alteração USB
      left: { id: cancelTop, icon: arrow-left, caption: Cancelar, action: "system.rndis.cancel" }
    - type: column
      padding: 32
      gap: 24
      align: stretch
      children:
        - { type: text, id: confirmMessage, field: confirm_message }
        - type: text_box
          caption: O dispositivo não detecta a ejeção. A operação pode interromper RNDIS e armazenamento USB.
        - type: confirm_box
          caption: Alterar RNDIS
          message: Você ejetou o armazenamento Kobo com segurança no host?
          confirm: { id: confirm, caption: "Sim, ejetei com segurança", action: "system.rndis.confirm" }
          cancel: { id: cancel, caption: Cancelar, action: "system.rndis.cancel" }
