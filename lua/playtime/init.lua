local M = {}

function M.setup()
  -- Load the main module
  local playtime = require('playtime.playtime')

  -- Initialize data
  playtime.load_data()

  -- Register autocmds
  vim.api.nvim_create_autocmd({'CursorMoved', 'CursorMovedI', 'InsertEnter', 'TextChanged', 'TextChangedI'}, {
    callback = function()
      playtime.update_activity()
    end
  })

  vim.api.nvim_create_autocmd({'BufRead', 'BufNewFile'}, {
    callback = function(args)
      playtime.setup_buffer(args.buf)
    end
  })

  vim.api.nvim_create_autocmd({'TextChanged', 'TextChangedI'}, {
    callback = function(args)
      playtime.update_line_count(args.buf)
    end
  })

  -- Register command
  vim.api.nvim_create_user_command('Playtime', function(opts)
    playtime.show_report(opts.args)
  end, {
    nargs = '?',
    complete = function()
      return { 'report' }
    end
  })

  -- Save data on exit
  vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function()
      playtime.save_data()
      playtime.stop_timer()
    end
  })
end

return M
