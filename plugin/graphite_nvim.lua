local ok, graphite = pcall(require, 'graphite')
if not ok then
  return
end

local function create_commands()
  vim.api.nvim_create_user_command('GraphiteCreateStack', function()
    graphite.create_stack()
  end, { desc = 'Create a new Graphite change with: gt create -am "<message>"' })

  vim.api.nvim_create_user_command('GraphiteSubmitStack', function()
    graphite.submit_stack()
  end, { desc = 'Submit the current Graphite stack: gt submit --stack' })

  vim.api.nvim_create_user_command('GraphiteLog', function()
    graphite.log_stack()
  end, { desc = 'Show the current Graphite stack log: gt log' })
end

create_commands()


