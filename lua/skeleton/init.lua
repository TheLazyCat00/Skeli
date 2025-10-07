local M = {}

-- Configuration
M.config = {
	template_dir = vim.fn.stdpath('config') .. '/skeleton',
	fallback_dirs = {
		vim.fn.stdpath('data') .. '/skeleton',
		vim.fn.expand('~/.local/nvim/skeleton'),
	}
}

-- Helper function to check if buffer is empty or whitespace only
local function is_empty_buffer()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	if #lines == 0 then
		return true
	end

	for _, line in ipairs(lines) do
		if line:match('%S') then	-- Contains non-whitespace
			return false
		end
	end
	return true
end

-- Get the skeleton directory path (check multiple locations)
local function get_skeleton_dir()
	-- Check primary template directory
	if vim.fn.isdirectory(M.config.template_dir) == 1 then
		return M.config.template_dir
	end

	-- Check fallback directories
	for _, dir in ipairs(M.config.fallback_dirs) do
		if vim.fn.isdirectory(dir) == 1 then
			return dir
		end
	end

	return nil
end

-- Convert template filename to pattern (- becomes *)
local function template_to_pattern(filename)
	return filename:gsub('%-', '*')
end

-- Find matching template for current buffer
local function find_template()
	local skeleton_dir = get_skeleton_dir()
	if not skeleton_dir then
		return nil
	end

	local current_file = vim.fn.expand('%:t')
	if current_file == '' then
		return nil
	end

	-- Get all files in skeleton directory
	local skeleton_files = vim.fn.glob(skeleton_dir .. '/*', false, true)

	local matches = {}

	for _, template_path in ipairs(skeleton_files) do
		local template_name = vim.fn.fnamemodify(template_path, ':t')
		local pattern = template_to_pattern(template_name)

		-- Check if current filename matches the pattern
		if current_file == template_name then
			-- Exact match (like main.js)
			table.insert(matches, { path = template_path, priority = 1, name = template_name })
		elseif pattern ~= template_name then
			-- Pattern match (like -.py -> *.py)
			local lua_pattern = pattern:gsub('%*', '.*')
			if current_file:match('^' .. lua_pattern .. '$') then
				table.insert(matches, { path = template_path, priority = 2, name = template_name })
			end
		end
	end

	-- Sort by priority (exact matches first)
	table.sort(matches, function(a, b) return a.priority < b.priority end)

	return matches[1] and matches[1].path or nil
end

-- Insert template content into current buffer
local function insert_template(template_path)
	local file = io.open(template_path, 'r')
	if not file then
		vim.notify('Failed to open template: ' .. template_path, vim.log.levels.ERROR)
		return false
	end

	local content = file:read('*all')
	file:close()

	if content then
		-- Split content into lines properly
		local lines = vim.split(content, '\n', { plain = true })

		-- Remove trailing empty lines if any
		while #lines > 0 and lines[#lines] == '' do
			table.remove(lines)
		end

		-- Clear current buffer and insert template
		vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

		-- Set cursor to beginning
		vim.api.nvim_win_set_cursor(0, {1, 0})

		vim.notify('Applied template: ' .. vim.fn.fnamemodify(template_path, ':t'), vim.log.levels.INFO)
		return true
	end

	return false
end

-- Main function to apply skeleton template
function M.apply_template()
	-- Only apply to empty buffers
	if not is_empty_buffer() then
		return
	end

	local template_path = find_template()
	if template_path then
		insert_template(template_path)
	end
end

-- Setup function to initialize autocommands
function M.setup(opts)
	-- Merge user config with defaults
	if opts then
		M.config = vim.tbl_extend('force', M.config, opts)
	end

	-- Create autocommand group
	local skeleton_group = vim.api.nvim_create_augroup('SkeletonPlugin', { clear = true })

	-- Apply template when opening a new file
	vim.api.nvim_create_autocmd({'BufNewFile'}, {
		group = skeleton_group,
		callback = function()
			-- Small delay to ensure buffer is properly initialized
			vim.defer_fn(function()
				M.apply_template()
			end, 10)
		end,
		desc = 'Apply skeleton template to new files'
	})

	-- Also check when entering a buffer (covers some edge cases)
	vim.api.nvim_create_autocmd({'BufEnter'}, {
		group = skeleton_group,
		callback = function()
			-- Only trigger for empty buffers with a filename
			if vim.fn.expand('%:t') ~= '' and is_empty_buffer() then
				vim.defer_fn(function()
					M.apply_template()
				end, 10)
			end
		end,
		desc = 'Apply skeleton template when entering empty buffer'
	})
end

-- Command to manually apply template
vim.api.nvim_create_user_command('SkeletonApply', function()
	M.apply_template()
end, { desc = 'Manually apply skeleton template' })

-- Command to list available templates
vim.api.nvim_create_user_command('SkeletonList', function()
	local skeleton_dir = get_skeleton_dir()
	if not skeleton_dir then
		vim.notify('No skeleton directory found', vim.log.levels.WARN)
		return
	end

	local skeleton_files = vim.fn.glob(skeleton_dir .. '/*', false, true)
	if #skeleton_files == 0 then
		vim.notify('No skeleton templates found in: ' .. skeleton_dir, vim.log.levels.INFO)
		return
	end

	vim.notify('Available skeleton templates:', vim.log.levels.INFO)
	for _, template_path in ipairs(skeleton_files) do
		local template_name = vim.fn.fnamemodify(template_path, ':t')
		local pattern = template_to_pattern(template_name)
		if pattern ~= template_name then
			vim.notify('	' .. template_name .. ' -> matches ' .. pattern, vim.log.levels.INFO)
		else
			vim.notify('	' .. template_name .. ' -> exact match', vim.log.levels.INFO)
		end
	end
end, { desc = 'List available skeleton templates' })

return M
