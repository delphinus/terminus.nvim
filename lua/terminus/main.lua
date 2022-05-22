local M = {}

function M.new()
  return setmetatable({}, { __index = M })
end

function M.setup()
end

return M
