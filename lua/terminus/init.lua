local terminus = require("terminus.terminus").new()

return {
  terminus = terminus,
  setup = function(config)
    return terminus:setup(config)
  end,
}
