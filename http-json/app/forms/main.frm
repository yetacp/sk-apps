version: 1
form:
  id: http-json
  layout: vertical
  align: stretch
  children:
    - type: title_bar
      caption: HTTP JSON
      left:
        {
          id: close,
          icon: arrow-left,
          caption: Voltar,
          action: "navigation.close",
        }
    - type: column
      padding: 32
      gap: 20
      align: stretch
      children:
        - { type: text, id: status, field: message }
        - { type: text_box, id: postTitle, field: post_title }
        - {
            type: button,
            id: load,
            caption: Consultar post,
            action: "post.load",
          }
        - { type: button, id: send, caption: Enviar post, action: "post.send" }
