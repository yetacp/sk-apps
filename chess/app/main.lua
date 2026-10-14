local form = startk.form('forms/main.frm')
startk.sprite_sheet('chess.sprites.json')
local board = 'rnbqkbnrpppppppp................................PPPPPPPPRNBQKBNR'

local app = startk.application({
  initial_state = {
    board = board,
    marks = string.rep('0', 64),
    selected = 255,
    flipped = false,
    status = 'Toque uma casa para inspecionar o tabuleiro.'
  },
  view = function(state)
    return form:document(state)
  end
})

app:on('chess.square', function(ctx, event)
  local square = event.payload.source:match('^board%.([a-h][1-8])$')
  if square == nil then return end
  local index = (8 - tonumber(square:sub(2))) * 8 + square:byte(1) - 97
  ctx:patch({selected = index, status = 'Casa selecionada: ' .. square})
end)

app:on('chess.flip', function(ctx)
  ctx:patch({flipped = not ctx.state.flipped})
end)

app:on('navigation.close', function(ctx)
  ctx:exit()
end)

app:start()
