local M = {}

-- Configuration
M.idle_threshold = 2  -- Seconds of inactivity before considering paused
M.data_path = vim.fn.stdpath('data') .. '/playtime.json'

-- Data storage
M.data = {
  total_playtime = 0,      -- Total active time in seconds
  total_lines = 0,         -- Total lines written
  days = {},               -- Daily statistics
}

-- Buffer tracking
M.buffers = {}         -- Track line counts per buffer
M.last_activity_time = os.time()
M.last_check_time = os.time()

-- Helper functions
function M.format_time(seconds)
  local hours = math.floor(seconds / 3600)
  local remainder = seconds % 3600
  local minutes = math.floor(remainder / 60)
  local seconds = remainder % 60
  return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

-- Data persistence
function M.load_data()
  local ok, contents = pcall(vim.fn.readfile, M.data_path)
  if ok and contents then
    local ok_parse, saved = pcall(vim.fn.json_decode, table.concat(contents, '\n'))
    if ok_parse and saved then
      M.data = vim.tbl_deep_extend('force', M.data, saved)
    end
  end
end

function M.save_data()
  local json = vim.fn.json_encode(M.data)
  vim.fn.mkdir(vim.fn.fnamemodify(M.data_path, ':h'), 'p')
  vim.fn.writefile({json}, M.data_path)
end

-- Line tracking
function M.setup_buffer(bufnr)
  if M.buffers[bufnr] then return end
  M.buffers[bufnr] = {
    last_line_count = vim.api.nvim_buf_line_count(bufnr),
  }
end

M.timer = vim.uv.new_timer()
M.timer:start(1000, 1000, function()
  local now = os.time()
  local time_since_last_activity = now - M.last_activity_time

  if time_since_last_activity <= M.idle_threshold then
    local elapsed = now - M.last_check_time
    M.data.total_playtime = M.data.total_playtime + elapsed

    local today = os.date('%Y-%m-%d')
    M.data.days[today] = M.data.days[today] or { playtime = 0, lines = 0 }
    M.data.days[today].playtime = M.data.days[today].playtime + elapsed
  end

  M.last_check_time = now
end)

-- Activity detection
function M.update_activity()
  M.last_activity_time = os.time()
end

-- Line counting
function M.update_line_count(bufnr)
  M.setup_buffer(bufnr)

  local current = vim.api.nvim_buf_line_count(bufnr)
  local last = M.buffers[bufnr].last_line_count

  if current > last then
    local delta = current - last
    M.data.total_lines = M.data.total_lines + delta

    local today = os.date('%Y-%m-%d')
    M.data.days[today] = M.data.days[today] or { playtime = 0, lines = 0 }
    M.data.days[today].lines = M.data.days[today].lines + delta
  end

  M.buffers[bufnr].last_line_count = current
end

-- Commands
function M.show_report(arg)
  if arg == 'report' then
    -- Generate report
    local report_lines = {
      'Playtime Report',
      string.format('Total playtime: %s', M.format_time(M.data.total_playtime)),
      string.format('Total lines written: %d', M.data.total_lines),
      '',
      'Daily breakdown:'
    }

    -- Collect and sort days
    local days = {}
    for date, day_data in pairs(M.data.days) do
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
        M.format_time(day.playtime),
        day.lines
      ))
    end

    -- Create buffer and set content
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, report_lines)
    vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
    vim.api.nvim_buf_set_name(buf, 'Playtime report')

    -- Calculate window dimensions
    local max_line_length = 0
    for _, line in ipairs(report_lines) do
      max_line_length = math.max(max_line_length, #line)
    end

    local ui = vim.api.nvim_list_uis()[1]
    local win_width = math.min(max_line_length + 2, ui.width - 4)
    local win_height = math.min(#report_lines + 2, ui.height - 4)

    -- Center the window
    local row = math.floor((ui.height - win_height) / 2)
    local col = math.floor((ui.width - win_width) / 2)

    -- Create floating window
    local win_opts = {
      relative = 'editor',
      width = win_width,
      height = win_height,
      row = row,
      col = col,
      style = 'minimal',
    }
    local win = vim.api.nvim_open_win(buf, true, win_opts)

    -- Set window options
    vim.api.nvim_set_option_value('wrap', false, { win = win })
    vim.api.nvim_set_option_value('number', false, { win = win })
    vim.api.nvim_set_option_value('relativenumber', false, { win = win })
  else
    -- Show summary
    local today = os.date('%Y-%m-%d')
    local today_data = M.data.days[today] or { playtime = 0, lines = 0 }

    vim.api.nvim_echo({
      { 'Playtime Summary:', 'Title' },
      { ' Total: '..M.format_time(M.data.total_playtime), 'Normal' },
      { ' Lines: '..tostring(M.data.total_lines), 'Normal' },
      { '\nToday:', 'Title' },
      { ' Time: '..M.format_time(today_data.playtime), 'Normal' },
      { ' Lines: '..tostring(today_data.lines), 'Normal' },
    }, true, {})
  end
end

-- Timer control
function M.stop_timer()
  M.timer:stop()
end

return M
