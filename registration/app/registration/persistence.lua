local sqlite = startk.sqlite
local M = {}

local SELECT = 'SELECT id,name,phone,email,notes,active,category,priority FROM contacts ORDER BY name,id'
local SCHEMA =
  [[CREATE TABLE IF NOT EXISTS contacts(
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 name TEXT NOT NULL CHECK(length(name) BETWEEN 1 AND 80),
 phone TEXT NOT NULL CHECK(length(phone)<=40),
 email TEXT NOT NULL CHECK(length(email)<=80),
 notes TEXT NOT NULL DEFAULT '' CHECK(length(notes)<=4096),
 active INTEGER NOT NULL DEFAULT 1 CHECK(active IN(0,1)),
 category TEXT NOT NULL DEFAULT 'cliente' CHECK(category IN('cliente','fornecedor','parceiro')),
 priority INTEGER NOT NULL DEFAULT 1 CHECK(priority BETWEEN 1 AND 4)
)]]

function M.list()
  return sqlite.query(SELECT, {})
end

function M.initialize()
  return sqlite.execute(SCHEMA, {})
end

function M.save(draft, id)
  local sql, params
  if id then
    sql = 'UPDATE contacts SET name=?,phone=?,email=?,notes=?,active=?,category=?,priority=? WHERE id=?'
    params = {
      draft.name,
      draft.phone,
      draft.email,
      draft.notes,
      draft.active and 1 or 0,
      draft.category,
      draft.priority,
      id
    }
  else
    sql = 'INSERT INTO contacts(name,phone,email,notes,active,category,priority) VALUES(?,?,?,?,?,?,?)'
    params = {
      draft.name,
      draft.phone,
      draft.email,
      draft.notes,
      draft.active and 1 or 0,
      draft.category,
      draft.priority
    }
  end
  return sqlite.execute(sql, params)
end

function M.remove(id)
  return sqlite.execute('DELETE FROM contacts WHERE id=?', {id})
end

return M
