version: 1
form:
  id: calculator
  layout: vertical
  align: stretch
  children:
    - type: title_bar
      caption: Calculadora
      left: { id: close, icon: arrow-left, caption: Voltar, action: "navigation.close" }
    - type: column
      padding: 47
      gap: 16
      align: stretch
      children:
        - type: row
          gap: 0
          align: center
          children:
            - type: expand
              weight: 1
              child: { type: space, width: 0, height: 0 }
            - { type: label, id: display, field: expression }
        - type: row
          gap: 16
          align: stretch
          children:
            - { type: expand, child: { type: button, id: clear, caption: "C", action: "calculator.clear" } }
            - { type: expand, child: { type: button, id: backspace, caption: "Apagar", action: "calculator.backspace" } }
            - { type: expand, child: { type: button, id: openParen, caption: "(", action: "calculator.open_parenthesis" } }
            - { type: expand, child: { type: button, id: closeParen, caption: ")", action: "calculator.close_parenthesis" } }
            - { type: expand, child: { type: button, id: percent, caption: "%", action: "calculator.percent" } }
            - { type: expand, child: { type: button, id: divide, caption: "÷", action: "calculator.divide" } }
        - type: row
          gap: 16
          align: stretch
          children:
            - { type: expand, child: { type: button, id: digit7, caption: "7", action: "calculator.digit7" } }
            - { type: expand, child: { type: button, id: digit8, caption: "8", action: "calculator.digit8" } }
            - { type: expand, child: { type: button, id: digit9, caption: "9", action: "calculator.digit9" } }
            - { type: expand, child: { type: button, id: multiply, caption: "×", action: "calculator.multiply" } }
        - type: row
          gap: 16
          align: stretch
          children:
            - { type: expand, child: { type: button, id: digit4, caption: "4", action: "calculator.digit4" } }
            - { type: expand, child: { type: button, id: digit5, caption: "5", action: "calculator.digit5" } }
            - { type: expand, child: { type: button, id: digit6, caption: "6", action: "calculator.digit6" } }
            - { type: expand, child: { type: button, id: subtract, caption: "−", action: "calculator.subtract" } }
        - type: row
          gap: 16
          align: stretch
          children:
            - { type: expand, child: { type: button, id: digit1, caption: "1", action: "calculator.digit1" } }
            - { type: expand, child: { type: button, id: digit2, caption: "2", action: "calculator.digit2" } }
            - { type: expand, child: { type: button, id: digit3, caption: "3", action: "calculator.digit3" } }
            - { type: expand, child: { type: button, id: add, caption: "+", action: "calculator.add" } }
        - type: row
          gap: 16
          align: stretch
          children:
            - { type: expand, child: { type: button, id: sign, caption: "±", action: "calculator.sign" } }
            - { type: expand, child: { type: button, id: digit0, caption: "0", action: "calculator.digit0" } }
            - { type: expand, child: { type: button, id: decimal, caption: ",", action: "calculator.decimal" } }
            - { type: expand, child: { type: button, id: calculate, caption: "=", action: "calculator.calculate" } }
        - { type: text_box, id: result, field: result, wrap: false, align: right }
