local uv = vim.loop
local api = setmetatable({ _cache = {} }, {
  __index = function(self, name)
    if not self._cache[name] then
      local func = vim.api["nvim_" .. name]
      if func then
        self._cache[name] = func
      else
        error("Unknown api func: " .. name, 2)
      end
    end
    return self._cache[name]
  end,
})

local Process = require "terminus.process"
local debug = require "terminus.debug"
local Terminus = {}

Terminus.new = function()
  local self = setmetatable({}, { __index = Terminus })
  self.default_config = {
    executable = "tmux",
    mouse = true,
    focus_reporting = true,
    debug = false,
  }
  self.config = {}
  self.is_in_tmux = vim.env.TMUX ~= ""
  self.wait_ms = 50
  return self
end

function Terminus:setup(config)
  self.config = vim.tbl_extend("force", self.default_config, config or {})
  debug.setup { enabled = self.config.debug }
  debug("setup: %s", vim.inspect(self.config))
  if self.config.mouse then
    self:mouse()
  end
  if self.config.focus_reporting then
    self:focus_reporting()
  end
end

function Terminus:mouse()
  vim.opt.mouse = "a"
end

function Terminus:focus_reporting()
  local group = api.create_augroup("Terminus", {})
  api.create_autocmd("FocusGained", { group = group, command = "silent! checktime" })
  if self.is_in_tmux then
    api.create_autocmd("VimResized", {
      group = group,
      callback = function()
        if self.timer and uv.is_active(self.timer) then
          self.timer:stop()
          self.timer:close()
        end
        self.timer = vim.defer_fn(function()
          self:check_focus()
        end, self.wait_ms)
      end,
    })
  end
end

function Terminus:check_focus()
  debug "check_focus start"
  local current = vim.env.TMUX_PANE
  if not current then
    return
  end
  local p = Process.new(self.config.executable, { "list-panes", "-F", "#{pane_active} #{pane_id}" })
  p:run(function(result)
    debug("is_successful: %s", result.is_successful)
    if result.is_successful then
      for line in result.stdout:gmatch "[^\n]+" do
        local active = line:match "^1 (%%%d+)"
        if active then
          local event = active == current and "FocusGained" or "FocusLost"
          debug("active: %s, current: %s, event: %s", active, current, event)
          vim.schedule(function()
            api.exec_autocmds(event, { pattern = "%", modeline = false })
          end)
          break
        end
      end
    else
      debug("tmux failed: %s", result.stderr)
    end
  end)
end

return Terminus
