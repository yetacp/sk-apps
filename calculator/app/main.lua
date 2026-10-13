local form = startk.form('forms/main.frm')

local state = {expression = '0', result = 'Digite um número.'}
local MAX_DIGITS = 12
local MAX_DECIMAL_PLACES = 6
local calculator = {
  accumulator = nil,
  pending_operator = nil,
  last_operator = nil,
  last_operand = nil,
  entering_new_value = true
}

local operator_symbols = {
  add = '+',
  subtract = '−',
  multiply = '×',
  divide = '÷'
}

local function reset(message)
  state.expression = '0'
  state.result = message or 'Digite um número.'
  calculator.accumulator = nil
  calculator.pending_operator = nil
  calculator.last_operator = nil
  calculator.last_operand = nil
  calculator.entering_new_value = true
end

local function number_from_display()
  local text = state.expression:match('^%s*(.-)%s*$')
  if not text:match('^%-?%d*[,%.]?%d+$') then
    return nil, 'Digite apenas um número.'
  end

  local digits = text:gsub('%D', '')
  if #digits > MAX_DIGITS then
    return nil, 'Limite: 12 dígitos.'
  end

  local decimals = text:match('[,.](%d*)$')
  if decimals and #decimals > MAX_DECIMAL_PLACES then
    return nil, 'Limite: 6 casas decimais.'
  end

  local normalized = text:gsub(',', '.')
  local value = tonumber(normalized)
  if not value then
    return nil, 'Número inválido.'
  end
  return value
end

local function display_number(value)
  if math.abs(value) < 0.000000000001 then
    value = 0
  end
  local text = ('%.6f'):format(value):gsub('(%..-)0+$', '%1'):gsub('%.$', '')
  if text == '-0' then
    text = '0'
  end

  local digits = text:gsub('%D', '')
  if #digits > MAX_DIGITS then
    return nil, 'Resultado excede 12 dígitos.'
  end
  return text:gsub('%.', ',')
end

local function apply_operator(left, operator, right)
  if operator == '+' then
    return left + right
  end
  if operator == '−' then
    return left - right
  end
  if operator == '×' then
    return left * right
  end
  if right == 0 then
    return nil, 'Não é possível dividir por zero.'
  end
  return left / right
end

local function fail(ctx, message)
  state.result = message
  calculator.pending_operator = nil
  calculator.last_operator = nil
  calculator.last_operand = nil
  calculator.entering_new_value = true
  ctx:log('warn', 'calculator: ' .. message)
end

local function apply_submitted_display(event)
  state = form:values(event)
  if
    calculator.entering_new_value and calculator.accumulator ~= nil and
      state.expression ~= display_number(calculator.accumulator)
   then
    calculator.entering_new_value = false
  end
end

local function enter_digit(digit)
  local digits = state.expression:gsub('%D', '')
  if #digits >= MAX_DIGITS and not calculator.entering_new_value then
    state.result = 'Limite: 12 dígitos.'
    return
  end

  local decimals = state.expression:match('[,.](%d*)$')
  if decimals and #decimals >= MAX_DECIMAL_PLACES and not calculator.entering_new_value then
    state.result = 'Limite: 6 casas decimais.'
    return
  end

  if calculator.entering_new_value then
    state.expression = digit
    calculator.entering_new_value = false
  elseif state.expression == '0' then
    state.expression = digit
  elseif state.expression == '-0' then
    state.expression = '-' .. digit
  else
    state.expression = state.expression .. digit
  end
  state.result = 'Entrada atual.'
end

local function enter_decimal()
  if calculator.entering_new_value then
    state.expression = '0,'
    calculator.entering_new_value = false
  elseif not state.expression:find('[,.]') then
    state.expression = state.expression .. ','
  end
  state.result = 'Entrada atual.'
end

local function choose_operator(ctx, operator)
  local current, error = number_from_display()
  if not current then
    return fail(ctx, error)
  end

  if calculator.accumulator == nil then
    calculator.accumulator = current
  elseif not calculator.entering_new_value then
    local value
    value, error = apply_operator(calculator.accumulator, calculator.pending_operator, current)
    if not value then
      return fail(ctx, error)
    end
    local display
    display, error = display_number(value)
    if not display then
      return fail(ctx, error)
    end
    calculator.accumulator = value
    state.expression = display
  end

  calculator.pending_operator = operator
  calculator.last_operator = nil
  calculator.last_operand = nil
  calculator.entering_new_value = true
  local display, error = display_number(calculator.accumulator)
  if not display then
    return fail(ctx, error)
  end
  state.result = display .. ' ' .. operator
end

local function calculate(ctx)
  local current, error = number_from_display()
  if not current then
    return fail(ctx, error)
  end

  if calculator.pending_operator then
    local value
    value, error = apply_operator(calculator.accumulator, calculator.pending_operator, current)
    if not value then
      return fail(ctx, error)
    end
    local display
    display, error = display_number(value)
    if not display then
      return fail(ctx, error)
    end
    calculator.last_operator = calculator.pending_operator
    calculator.last_operand = current
    calculator.accumulator = value
    calculator.pending_operator = nil
    state.expression = display
  elseif calculator.last_operator then
    local value
    value, error = apply_operator(calculator.accumulator or current, calculator.last_operator, calculator.last_operand)
    if not value then
      return fail(ctx, error)
    end
    local display
    display, error = display_number(value)
    if not display then
      return fail(ctx, error)
    end
    calculator.accumulator = value
    state.expression = display
  else
    calculator.accumulator = current
    local display
    display, error = display_number(current)
    if not display then
      return fail(ctx, error)
    end
    state.expression = display
  end

  state.result = 'Resultado: ' .. state.expression
  calculator.entering_new_value = true
  ctx:log('info', 'calculator calculated')
end

local app =
  startk.application(
  {
    initial_state = state,
    view = function(model)
      return form:document(model)
    end
  }
)

app:on(
  'navigation.close',
  function(ctx)
    ctx:exit()
  end
)

for digit = 0, 9 do
  app:on(
    'calculator.digit' .. digit,
    function(ctx, event)
      apply_submitted_display(event)
      enter_digit(tostring(digit))
      ctx:set(state)
    end
  )
end

app:on(
  'calculator.decimal',
  function(ctx, event)
    apply_submitted_display(event)
    enter_decimal()
    ctx:set(state)
  end
)

for name, symbol in pairs(operator_symbols) do
  app:on(
    'calculator.' .. name,
    function(ctx, event)
      apply_submitted_display(event)
      choose_operator(ctx, symbol)
      ctx:set(state)
    end
  )
end

app:on(
  'calculator.backspace',
  function(ctx, event)
    apply_submitted_display(event)
    if not calculator.entering_new_value then
      local start = utf8.offset(state.expression, -1)
      state.expression = start and state.expression:sub(1, start - 1) or ''
      if state.expression == '' or state.expression == '-' then
        state.expression = '0'
      end
    end
    state.result = 'Entrada atual.'
    ctx:set(state)
  end
)

app:on(
  'calculator.sign',
  function(ctx, event)
    apply_submitted_display(event)
    if calculator.entering_new_value then
      calculator.entering_new_value = false
    end
    if state.expression:sub(1, 1) == '-' then
      state.expression = state.expression:sub(2)
    elseif state.expression ~= '0' then
      state.expression = '-' .. state.expression
    end
    state.result = 'Entrada atual.'
    ctx:set(state)
  end
)

app:on(
  'calculator.percent',
  function(ctx, event)
    apply_submitted_display(event)
    local value, error = number_from_display()
    if value then
      local display
      display, error = display_number(value / 100)
      if display then
        state.expression = display
        calculator.entering_new_value = true
        state.result = 'Percentual convertido.'
      else
        fail(ctx, error)
      end
    else
      fail(ctx, error)
    end
    ctx:set(state)
  end
)

app:on(
  'calculator.clear',
  function(ctx)
    reset('Digite uma nova conta.')
    ctx:set(state)
  end
)

app:on(
  'calculator.calculate',
  function(ctx, event)
    apply_submitted_display(event)
    calculate(ctx)
    ctx:set(state)
  end
)

app:start()
