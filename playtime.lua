local M = {}

-- Configuration
local idle_threshold = 2  -- Seconds of inactivity before considering paused
local data_path = vim.fn.stdpath('data') .. '/playtime.json'

-- Data storage
local data = {
  total_playtime = 0,      -- Total active time in seconds
  total_lines = 0,         -- Total lines written
  days = {},               -- Daily statistics
}

-- Buffer tracking
local buffers = {}         -- Track line counts per buffer
local last_activity_time = os.time()
local last_check_time = os.time()

-- Helper functions
local function format_time(seconds)
  local hours = math.floor(seconds / 3600)
  local remainder = seconds % 3600
  local minutes = math.floor(remainder / 60)
  local seconds = remainder % 60
  return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

-- Data persistence
local function load_data()
  local ok, contents = pcall(vim.fn.readfile, data_path)
  if ok and contents then
    local ok_parse, saved = pcall(vim.fn.json_decode, table.concat(contents, '\n'))
    if ok_parse and saved then
      data = vim.tbl_deep_extend('force', data, saved)
    end
  end
end

local function save_data()
  local json = vim.fn.json_encode(data)
  vim.fn.mkdir(vim.fn.fnamemodify(data_path, ':h'), 'p')
  vim.fn.writefile({json}, data_path)
end

-- Line tracking
local function setup_buffer(bufnr)
  if buffers[bufnr] then return end
  buffers[bufnr] = {
    last_line_count = vim.api.nvim_buf_line_count(bufnr),
  }
end

-- Time tracking
local timer = vim.loop.new_timer()
timer:start(1000, 1000, vim.schedule_wrap(function()
  local now = os.time()
  local time_since_last_activity = now - last_activity_time
  
  if time_since_last_activity <= idle_threshold then
    local elapsed = now - last_check_time
    data.total_playtime = data.total_playtime + elapsed
    
    local today = os.date('%Y-%m-%d')
    data.days[today] = data.days[today] or { playtime = 0, lines = 0 }
    data.days[today].playtime = data.days[today].playtime + elapsed
  end
  
  last_check_time = now
end))

-- Activity detection
vim.api.nvim_create_autocmd({'CursorMoved', 'CursorMovedI', 'InsertEnter', 'TextChanged', 'TextChangedI'}, {
  callback = function()
    last_activity_time = os.time()
  end
})

-- Line counting
vim.api.nvim_create_autocmd({'BufRead', 'BufNewFile'}, {
  callback = function(args)
    setup_buffer(args.buf)
  end
})

vim.api.nvim_create_autocmd({'TextChanged', 'TextChangedI'}, {
  callback = function(args)
    local bufnr = args.buf
    setup_buffer(bufnr)
    
    local current = vim.api.nvim_buf_line_count(bufnr)
    local last = buffers[bufnr].last_line_count
    
    if current > last then
      local delta = current - last
      data.total_lines = data.total_lines + delta
      
      local today = os.date('%Y-%m-%d')
      data.days[today] = data.days[today] or { playtime = 0, lines = 0 }
      data.days[today].lines = data.days[today].lines + delta
    end
    
    buffers[bufnr].last_line_count = current
  end
})

-- Commands
vim.api.nvim_create_user_command('Playtime', function(opts)
  if opts.args == 'report' then
    -- Generate report
    local report_lines = {
      'Playtime Report',
      string.format('Total Playtime: %s', format_time(data.total_playtime)),
      string.format('Total Lines Written: %d', data.total_lines),
      '',
      'Daily Breakdown:'
    }
    
    -- Collect and sort days
    local days = {}
    for date, day_data in pairs(data.days) do
      table.insert(days, {
        date = date,
        playtime = day_data.playtime,
        lines = day_data.lines
      })
    end
    
    table.sort(days, function(a, b) return a.date < b.date end)
    
    -- Add daily stats
    for _, day in ipairs(days) do
      table.insert(report_lines, string.format(
        '• %s: %s | %d lines',
        day.date,
        format_time(day.playtime),
        day.lines
      ))
    end
    
    -- Display in split window
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, report_lines)
    vim.cmd('vsplit')
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.api.nvim_buf_set_name(buf, 'Playtime Report')
  else
    -- Show summary
    local today = os.date('%Y-%m-%d')
    local today_data = data.days[today] or { playtime = 0, lines = 0 }
    
    vim.api.nvim_echo({
      { 'Playtime Summary:', 'Title' },
      { 'Total: '..format_time(data.total_playtime), 'Normal' },
      { 'Lines: '..tostring(data.total_lines), 'Normal' },
      { '\nToday:', 'Title' },
      { 'Time: '..format_time(today_data.playtime), 'Normal' },
      { 'Lines: '..tostring(today_data.lines), 'Normal' },
    }, true, {})
  end
end, {
  nargs = '?',
  complete = function()
    return { 'report' }
  end
})

-- Initialize
load_data()
vim.api.nvim_create_autocmd('VimLeavePre', {
  callback = save_data
})

return M