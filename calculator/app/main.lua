local form = startk.form('forms/main.frm')

local state = {expression = '0', result = 'Digite uma expressão.'}
local MAX_EXPRESSION_LENGTH = 64
local MAX_NUMBER_DIGITS = 12
local MAX_DECIMAL_PLACES = 6
local after_result = false

local function display_number(value)
  if value ~= value or value == math.huge or value == -math.huge then
    return nil, 'Resultado fora do limite.'
  end
  if math.abs(value) < 0.000000000001 then
    value = 0
  end
  local text = ('%.6f'):format(value):gsub('(%..-)0+$', '%1'):gsub('%.$', '')
  if text == '-0' then
    text = '0'
  end
  if #text:gsub('%D', '') > MAX_NUMBER_DIGITS then
    return nil, 'Resultado excede 12 dígitos.'
  end
  return text:gsub('%.', ',')
end

local function evaluate(expression)
  if #expression > MAX_EXPRESSION_LENGTH then
    return nil, 'Limite: expressão muito longa.'
  end
  local text = expression:gsub('−', '-'):gsub('×', '*'):gsub('÷', '/')
  text = text:gsub(',', '.')
  local position = 1
  local parse_sum

  local function skip_spaces()
    while text:sub(position, position):match('%s') do
      position = position + 1
    end
  end

  local function parse_primary()
    skip_spaces()
    local value
    local is_percent = false
    if text:sub(position, position) == '(' then
      position = position + 1
      local err
      value, is_percent, err = parse_sum()
      if value == nil then
        return nil, false, err
      end
      skip_spaces()
      if text:sub(position, position) ~= ')' then
        return nil, false, 'Falta fechar um parêntese.'
      end
      position = position + 1
    else
      local remaining = text:sub(position)
      local literal = remaining:match('^(%d+%.?%d*)') or remaining:match('^(%.%d+)')
      if not literal then
        return nil, false, 'Expressão incompleta ou inválida.'
      end
      local digits = literal:gsub('%D', '')
      if #digits > MAX_NUMBER_DIGITS then
        return nil, false, 'Limite: 12 dígitos por número.'
      end
      local decimals = literal:match('%.(%d*)$')
      if decimals and #decimals > MAX_DECIMAL_PLACES then
        return nil, false, 'Limite: 6 casas decimais.'
      end
      value = tonumber(literal)
      position = position + #literal
    end

    skip_spaces()
    local has_percent_suffix = text:sub(position, position) == '%'
    if has_percent_suffix then
      value = value / 100
      is_percent = true
      position = position + 1
    end
    return value, is_percent
  end

  local function parse_unary()
    skip_spaces()
    local sign = text:sub(position, position)
    if sign == '+' or sign == '-' then
      position = position + 1
      local value, is_percent, err = parse_unary()
      if value == nil then
        return nil, false, err
      end
      return sign == '-' and -value or value, is_percent
    end
    return parse_primary()
  end

  local function parse_product()
    local value, is_percent, err = parse_unary()
    if value == nil then
      return nil, false, err
    end
    while true do
      skip_spaces()
      local operator = text:sub(position, position)
      if operator ~= '*' and operator ~= '/' then
        return value, is_percent
      end
      position = position + 1
      local right, _, right_error = parse_unary()
      if right == nil then
        return nil, false, right_error
      end
      if operator == '/' and right == 0 then
        return nil, false, 'Não é possível dividir por zero.'
      end
      value = operator == '*' and value * right or value / right
      is_percent = false
    end
  end

  parse_sum = function()
    local value, is_percent, err = parse_product()
    if value == nil then
      return nil, false, err
    end
    while true do
      skip_spaces()
      local operator = text:sub(position, position)
      if operator ~= '+' and operator ~= '-' then
        return value, is_percent
      end
      position = position + 1
      local right, right_is_percent, right_error = parse_product()
      if right == nil then
        return nil, false, right_error
      end
      local amount = right_is_percent and value * right or right
      value = operator == '+' and value + amount or value - amount
      is_percent = false
    end
  end

  local value, _, err = parse_sum()
  if value == nil then
    return nil, err
  end
  skip_spaces()
  if position <= #text then
    if text:sub(position, position) == ')' then
      return nil, 'Parêntese sem abertura correspondente.'
    end
    return nil, 'Expressão inválida.'
  end
  return value
end

local function set_status(ctx, message)
  state.result = message
  ctx:set(state)
end

local function append_digit(ctx, digit)
  if after_result then
    state.expression = digit
    after_result = false
  elseif state.expression == '0' then
    state.expression = digit
  else
    local last = state.expression:sub(-1)
    if last == ')' or last == '%' then
      state.expression = state.expression .. '*'
    end
    state.expression = state.expression .. digit
  end
  if #state.expression > MAX_EXPRESSION_LENGTH then
    state.expression = state.expression:sub(1, MAX_EXPRESSION_LENGTH)
    return set_status(ctx, 'Limite: expressão muito longa.')
  end
  set_status(ctx, 'Entrada atual.')
end

local function append_operator(ctx, operator)
  after_result = false
  local last = state.expression:sub(-1)
  if state.expression == '0' and operator == '-' then
    state.expression = '-'
  elseif last == '(' and operator == '-' then
    state.expression = state.expression .. '-'
  elseif last:match('[+%-%*/]') then
    if operator == '-' then
      state.expression = state.expression .. '-'
    else
      state.expression = state.expression:gsub('[+%-%*/]+$', '') .. operator
    end
  elseif last ~= '' and last ~= '(' then
    state.expression = state.expression .. operator
  end
  set_status(ctx, 'Entrada atual.')
end

local function open_parenthesis(ctx)
  if after_result or state.expression == '0' then
    state.expression = '('
    after_result = false
  else
    local last = state.expression:sub(-1)
    if last:match('[%d%)%%]') then
      state.expression = state.expression .. '*('
    elseif last:match('[+%-%*/%(]') then
      state.expression = state.expression .. '('
    end
  end
  set_status(ctx, 'Entrada atual.')
end

local function close_parenthesis(ctx)
  local opens = select(2, state.expression:gsub('%(', ''))
  local closes = select(2, state.expression:gsub('%)', ''))
  local last = state.expression:sub(-1)
  if opens > closes and last:match('[%d%)%%]') then
    state.expression = state.expression .. ')'
    after_result = false
    set_status(ctx, 'Entrada atual.')
  end
end

local function enter_decimal(ctx)
  if after_result then
    state.expression = '0,'
    after_result = false
  else
    local last = state.expression:sub(-1)
    if last == ')' or last == '%' then
      state.expression = state.expression .. '*0,'
    elseif last:match('[+%-%*/%(]') then
      state.expression = state.expression .. '0,'
    else
      local current_number = state.expression:match('([%d,%.]+)$') or ''
      if not current_number:find('[,.]') then
        state.expression = state.expression .. ','
      end
    end
  end
  set_status(ctx, 'Entrada atual.')
end

local function enter_percent(ctx)
  local last = state.expression:sub(-1)
  if last:match('[%d%)%%]') and last ~= '%' then
    state.expression = state.expression .. '%'
    after_result = false
    set_status(ctx, 'Percentual aplicado à expressão.')
  end
end

local function backspace(ctx)
  if after_result then
    after_result = false
  end
  state.expression = state.expression:sub(1, -2)
  if state.expression == '' or state.expression == '-' then
    state.expression = '0'
  end
  set_status(ctx, 'Entrada atual.')
end

local function toggle_sign(ctx)
  after_result = false
  local prefix, number = state.expression:match('^(.-)(%d+[,%.]?%d*)$')
  if not number then
    if state.expression:sub(1, 2) == '-(' and state.expression:sub(-1) == ')' then
      state.expression = state.expression:sub(3, -2)
    else
      state.expression = '-(' .. state.expression .. ')'
    end
  elseif prefix:sub(-1) == '-' then
    local before_sign = prefix:sub(1, -2)
    if before_sign == '' or before_sign:match('[+%-%*/%(]$') then
      prefix = before_sign
    else
      number = '-' .. number
    end
    state.expression = prefix .. number
  else
    state.expression = prefix .. '-' .. number
  end
  set_status(ctx, 'Entrada atual.')
end

local app =
  startk.application(
  {
    initial_state = state,
    view = function(model)
      local visible = {
        expression = model.expression:gsub('%*', '×'):gsub('/', '÷'):gsub('%-', '−'),
        result = model.result
      }
      return form:document(visible)
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
    function(ctx)
      append_digit(ctx, tostring(digit))
    end
  )
end

local operators = {
  add = '+',
  subtract = '-',
  multiply = '*',
  divide = '/'
}

for name, operator in pairs(operators) do
  app:on(
    'calculator.' .. name,
    function(ctx)
      append_operator(ctx, operator)
    end
  )
end

app:on('calculator.decimal', enter_decimal)
app:on('calculator.open_parenthesis', open_parenthesis)
app:on('calculator.close_parenthesis', close_parenthesis)
app:on('calculator.percent', enter_percent)
app:on('calculator.backspace', backspace)
app:on('calculator.sign', toggle_sign)

app:on(
  'calculator.clear',
  function(ctx)
    state.expression = '0'
    after_result = false
    set_status(ctx, 'Digite uma nova expressão.')
  end
)

app:on(
  'calculator.calculate',
  function(ctx)
    local value, error = evaluate(state.expression)
    if value == nil then
      set_status(ctx, error)
      return
    end
    local display
    display, error = display_number(value)
    if not display then
      set_status(ctx, error)
      return
    end
    state.expression = display
    after_result = true
    set_status(ctx, 'Resultado.')
    ctx:log('info', 'calculator calculated')
  end
)

app:start()
