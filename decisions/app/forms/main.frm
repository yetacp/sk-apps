version: 1
form:
  id: decisions
  layout: vertical
  align: stretch
  children:
    - type: title_bar
      caption: Diálogos
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
      align: center
      children:
        - { type: label, caption: Decisões }
        - { type: text, id: statusText, field: status }
        - type: dialog
          caption: Diálogo
          message: Ações declarativas.
          actions:
            - { id: cancel, caption: Cancelar, action: "dialog.cancel" }
            - { id: accept, caption: Aceitar, action: "dialog.accept" }
        - type: confirm_box
          caption: Confirmação
          message: Continuar?
          confirm:
            { id: confirm, caption: "Sim", action: "confirmation.accept" }
          cancel: { id: reject, caption: "Não", action: "confirmation.reject" }
