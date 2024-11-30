local c = require('litee.gh.config')

local M = {}

local level_to_hl = {
    error = 'ErrorMsg',
    info = 'Normal',
    warning = 'WarningMsg',
}

local debug_buffer = nil

function M.init()
    if not c.config['debug_logging'] then
        return
    end
    local buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_name(buf, 'gh-nvim://debug_buffer')
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)
    debug_buffer = buf
end

function M.open_debug_buffer()
    if not c.config.debug_logging then
        return
    end
    vim.cmd('tabnew')
    vim.api.nvim_win_set_buf(0, debug_buffer)
end

-- log will no-op if debug_logging is not set, or print a debug message to
-- the status line if it is.
function M.log(msg, level)
    vim.schedule(function()
        local msg_split = vim.fn.split(msg, '\n')
        if level_to_hl[level] == nil then
            return
        end
        msg_split[1] = '[' .. level .. '] ' .. msg_split[1]
        if c.config.debug_logging then
            local lc = vim.api.nvim_buf_line_count(debug_buffer)
            vim.api.nvim_buf_set_lines(debug_buffer, lc, (lc + #msg_split), false, msg_split)
        end
    end)
end

return M
