version: 1
form:
  id: registration-detail-confirm
  layout: vertical
  align: stretch
  children:
    - type: title_bar
      caption: Excluir cadastro
      left:
        {
          id: cancelDeleteTop,
          icon: arrow-left,
          caption: Cancelar,
          action: "registration.delete_cancel",
        }
    - type: column
      padding: 32
      gap: 24
      align: stretch
      children:
        - { type: label, id: nameLabel, field: name }
        - {
            type: text_box,
            caption: Esta operação remove o cadastro selecionado.
          }
        - type: confirm_box
          caption: Excluir
          message: Excluir este cadastro?
          confirm:
            {
              id: deleteConfirm,
              caption: Excluir,
              action: "registration.delete_confirm",
            }
          cancel:
            {
              id: deleteCancel,
              caption: Cancelar,
              action: "registration.delete_cancel",
            }
