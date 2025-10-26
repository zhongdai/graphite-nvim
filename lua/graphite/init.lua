local runner = require('graphite.runner')

local M = {}

local DEFAULTS = {
  gt_cmd = 'gt',
}

M._config = vim.deepcopy(DEFAULTS)

local function executable_or_error(cmd)
  if vim.fn.executable(cmd) == 1 then
    return true
  end
  vim.notify(string.format('Graphite CLI not found: %s. Install via: brew install withgraphite/tap/graphite', cmd), vim.log.levels.ERROR)
  return false
end

local function ensure_config()
  M._config = M._config or vim.deepcopy(DEFAULTS)
  return M._config
end

local function current_cwd()
  return vim.loop.cwd() or vim.fn.getcwd()
end

function M.setup(opts)
  M._config = vim.tbl_deep_extend('force', vim.deepcopy(DEFAULTS), opts or {})
end

local function run_gt_background(title, args)
  local cfg = ensure_config()
  local cmdlist = { cfg.gt_cmd }
  for _, a in ipairs(args) do
    table.insert(cmdlist, a)
  end
  return runner.run_in_background(title, cmdlist, { cwd = current_cwd() })
end

function M.create_stack()
  local cfg = ensure_config()
  if not executable_or_error(cfg.gt_cmd) then
    return
  end
  vim.ui.input({ prompt = 'Graphite create message: ' }, function(input)
    if not input or input == '' then
      vim.notify('Graphite create aborted (empty message).', vim.log.levels.WARN)
      return
    end
    run_gt_background('gt create', { 'create', '-am', input })
  end)
end

function M.submit_stack()
  local cfg = ensure_config()
  if not executable_or_error(cfg.gt_cmd) then
    return
  end
  run_gt_background('gt submit --stack', { 'submit', '--stack' })
end

function M.log_stack()
  local cfg = ensure_config()
  if not executable_or_error(cfg.gt_cmd) then
    return
  end
  run_gt_background('gt log', { 'log' })
end

return M


