version: 1
form:
  id: registration-form-confirm
  layout: vertical
  align: stretch
  children:
    - type: title_bar
      caption: Descartar alterações
      left:
        {
          id: continueEditing,
          icon: arrow-left,
          caption: Continuar editando,
          action: "registration.discard_cancel",
        }
    - type: column
      padding: 32
      gap: 24
      align: stretch
      children:
        - {
            type: text_box,
            caption: As alterações ainda não salvas serão perdidas.
          }
        - type: confirm_box
          caption: Descartar
          message: Descartar as alterações deste cadastro?
          confirm:
            {
              id: discardConfirm,
              caption: Descartar,
              action: "registration.discard_confirm",
            }
          cancel:
            {
              id: discardCancel,
              caption: Continuar editando,
              action: "registration.discard_cancel",
            }
