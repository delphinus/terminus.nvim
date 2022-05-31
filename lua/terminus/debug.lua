local Debug = setmetatable({
  config = {
    enabled = false,
    level = vim.log.levels.DEBUG,
    prefix = "[Terminus]",
    printer = vim.notify,
  },
}, {
  __call = function(self, fmt, ...)
    if self.config.enabled then
      local f = self.config.prefix .. " " .. fmt
      local args = vim.F.pack_len(...)
      local msg = #args > 0 and f:format(vim.F.unpack_len(args)) or f
      self.config.printer(msg, self.config.level)
    end
  end,
})

Debug.setup = function(config)
  Debug.config = vim.tbl_extend("force", Debug.config, config or {})
end

return Debug
