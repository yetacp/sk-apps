local sqlite = startk.sqlite

local M = {}

function M.initialize(ctx)
  return ctx:await(sqlite.execute([[CREATE TABLE IF NOT EXISTS battery_samples (
    sampled_at INTEGER NOT NULL,
    percent INTEGER NOT NULL,
    status TEXT NOT NULL
  )]], {}))
end

function M.record(ctx, info)
  if type(info.battery_percent) ~= 'number' or type(info.sampled_at) ~= 'number' then
    return nil
  end
  local status = type(info.battery_status) == 'string' and info.battery_status or 'Unknown'
  local inserted = ctx:await(sqlite.execute(
    'INSERT INTO battery_samples(sampled_at,percent,status) VALUES(?,?,?)',
    {info.sampled_at, info.battery_percent, status}
  ))
  if not inserted.ok then return inserted end
  ctx:await(sqlite.execute([[DELETE FROM battery_samples
    WHERE rowid NOT IN (SELECT rowid FROM battery_samples ORDER BY sampled_at DESC LIMIT 512)]], {}))
  return nil
end

function M.summary(ctx)
  local result = ctx:await(sqlite.query(
    'SELECT sampled_at,percent,status FROM battery_samples ORDER BY sampled_at', {}
  ))
  if not result.ok then return nil, result.error.message end
  local rows = {}
  for _, row in ipairs(result.value.rows or {}) do
    if type(row) == 'table'
        and type(row[1]) == 'number'
        and type(row[2]) == 'number'
        and type(row[3]) == 'string' then
      rows[#rows + 1] = {
        sampled_at = row[1],
        percent = row[2],
        status = row[3]
      }
    end
  end
  if #rows < 2 then return 'Mais amostras são necessárias para estimar o consumo.' end

  local last = rows[#rows]
  local charging = tostring(last.status):lower() == 'charging'
  local segment_start = 1
  for index = 2, #rows do
    if tostring(rows[index].status):lower() ~= tostring(rows[index - 1].status):lower() then
      segment_start = index
    end
  end
  local first = rows[segment_start]
  local elapsed = math.max(0, tonumber(last.sampled_at) - tonumber(first.sampled_at))
  if elapsed == 0 then return 'As amostras ainda não cobrem um intervalo de tempo.' end

  local consumed, seconds = 0, 0
  for index = segment_start + 1, #rows do
    local previous, current = rows[index - 1], rows[index]
    if tostring(previous.status):lower() == tostring(current.status):lower() then
      local delta = math.max(0, tonumber(current.sampled_at) - tonumber(previous.sampled_at))
      consumed = consumed + math.abs(tonumber(current.percent) - tonumber(previous.percent))
      seconds = seconds + delta
    end
  end
  local rate = seconds > 0 and consumed * 3600 / seconds or 0
  local hours = rate > 0 and (charging and (100 - tonumber(last.percent)) or tonumber(last.percent)) / rate or nil
  local mode = charging and 'Carga' or 'Descarga'
  local estimate = hours and string.format('%.1f h', hours) or 'N/D'
  return string.format('%s observada: %.1f h\nTempo de amostragem: %.1f h\nVariação média: %.2f%%/h\nEstimativa %s: %s',
    mode, elapsed / 3600, seconds / 3600, rate, charging and 'até carga completa' or 'restante', estimate)
end

function M.clear(ctx)
  return ctx:await(sqlite.execute('DELETE FROM battery_samples', {}))
end

return M
