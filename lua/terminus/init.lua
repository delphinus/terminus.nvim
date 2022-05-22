local main = require("terminus.main").new()

return {
  setup = function()
    return main:setup()
  end,
}
