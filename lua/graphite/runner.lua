local M = {}

local function join_cmd(cmdlist)
  local parts = {}
  for _, p in ipairs(cmdlist) do
    if p:find('%s') then
      table.insert(parts, string.format('"%s"', p))
    else
      table.insert(parts, p)
    end
  end
  return table.concat(parts, ' ')
end

local function create_float_window(title, opts)
  local columns = vim.o.columns
  local lines = vim.o.lines - vim.o.cmdheight

  local width = math.floor(columns * (opts.width or 0.9))
  local height = math.floor(lines * (opts.height or 0.8))
  local col = math.floor((columns - width) / 2)
  local row = math.floor((lines - height) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'graphite')

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    row = row,
    col = col,
    width = width,
    height = height,
    style = 'minimal',
    border = opts.border or 'rounded',
    title = title or 'Graphite',
    title_pos = 'center',
  })

  vim.api.nvim_win_set_option(win, 'wrap', false)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.keymap.set('n', 'q', function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, nowait = true, silent = true })
  vim.keymap.set('n', '<Esc>', function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, nowait = true, silent = true })

  return buf, win
end

local function append_lines(buf, lines)
  if not lines or #lines == 0 then
    return
  end
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  local current_line_count = vim.api.nvim_buf_line_count(buf)
  -- Trim trailing empty line that many job callbacks include
  if lines[#lines] == '' then
    table.remove(lines, #lines)
  end
  if #lines > 0 then
    vim.api.nvim_buf_set_lines(buf, current_line_count, current_line_count, false, lines)
    vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(buf), 0 })
  end
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

--- Run a command as a job and stream output to the provided buffer.
-- @param cmdlist string[] full argv, e.g. { 'gt', 'log' }
-- @param job_opts table|nil supports { cwd = 'path' }
-- @param handlers table|nil supports { on_exit = function(code) end }
function M.run_job(cmdlist, job_opts, handlers)
  local argv = vim.deepcopy(cmdlist)
  local stdout_acc = {}
  local stderr_acc = {}

  local job_id = vim.fn.jobstart(argv, {
    cwd = job_opts and job_opts.cwd or nil,
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data, _)
      if handlers and handlers.on_stdout then
        handlers.on_stdout(data)
      end
    end,
    on_stderr = function(_, data, _)
      if handlers and handlers.on_stderr then
        handlers.on_stderr(data)
      end
    end,
    on_exit = function(_, code, _)
      if handlers and handlers.on_exit then
        handlers.on_exit(code)
      end
    end,
  })

  return job_id
end

--- Create a floating output window and run the job inside, streaming stdout/stderr.
-- Returns { bufnr = number, winid = number, job_id = number }
function M.run_in_float(title, cmdlist, ui_opts, job_opts)
  local buf, win = create_float_window(title, ui_opts or {})

  local function write_prefixed(prefix, lines)
    if not lines then
      return
    end
    local out = {}
    for _, l in ipairs(lines) do
      table.insert(out, prefix .. l)
    end
    append_lines(buf, out)
  end

  local job_id = M.run_job(cmdlist, job_opts or {}, {
    on_stdout = function(lines)
      write_prefixed('', lines)
    end,
    on_stderr = function(lines)
      write_prefixed('[stderr] ', lines)
    end,
    on_exit = function(code)
      append_lines(buf, { '', string.format('Process exited with code %d', code) })
    end,
  })

  return { bufnr = buf, winid = win, job_id = job_id }
end

-- Run a command in the background and notify on finish.
-- job_opts: { cwd?: string, on_exit?: fun(code, stdout, stderr) }
function M.run_in_background(title, cmdlist, job_opts)
  local stdout_acc = {}
  local stderr_acc = {}
  local job_id = vim.fn.jobstart(cmdlist, {
    cwd = job_opts and job_opts.cwd or nil,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data, _)
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line ~= '' then table.insert(stdout_acc, line) end
        end
      end
    end,
    on_stderr = function(_, data, _)
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line ~= '' then table.insert(stderr_acc, line) end
        end
      end
    end,
    on_exit = function(_, code, _)
      local cmd_str = join_cmd(cmdlist)
      if code == 0 then
        vim.notify(string.format('[Graphite] %s succeeded: %s', title or 'Command', cmd_str), vim.log.levels.INFO)
      else
        local function tail(tbl, n)
          local len = #tbl
          local start = math.max(1, len - n + 1)
          local res = {}
          for i = start, len do
            table.insert(res, tbl[i])
          end
          return res
        end
        local err_tail = tail(stderr_acc, 10)
        if #err_tail == 0 then
          err_tail = tail(stdout_acc, 10)
        end
        local detail = (#err_tail > 0) and ('\n' .. table.concat(err_tail, '\n')) or ''
        vim.notify(string.format('[Graphite] %s failed (exit %d): %s%s', title or 'Command', code, cmd_str, detail), vim.log.levels.ERROR)
      end
      if job_opts and job_opts.on_exit then
        job_opts.on_exit(code, stdout_acc, stderr_acc)
      end
    end,
  })
  return job_id
end

return M


