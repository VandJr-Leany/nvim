-- Colors
function Colors()
	themes = {
		"catppuccin",
		"catppuccin-frappe",
		"catppuccin-macchiato",
		"catppuccin-mocha",
		"kanagawa",
		"kanagawa-dragon",
		"kanagawa-wave",
		"tokyonight",
		"tokyonight-moon",
		"tokyonight-night",
		"tokyonight-storm",
	}

	local theme = themes[math.random(1, #themes)]

	print("Choosed theme: " .. theme)

	vim.cmd.colorscheme(theme)

	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

Colors()

-- Mason
require("mason").setup()
require("mason-lspconfig").setup()

-- Cmp
local cmp = require("cmp")

cmp.setup({
	mapping = cmp.mapping.preset.insert({
		["<Left>"] = cmp.mapping.confirm({ select = true }),
		["<Right>"] = cmp.mapping.abort(),
		["<Up>"] = cmp.mapping.select_prev_item({ behavior = "select" }),
		["<Down>"] = cmp.mapping.select_next_item({ behavior = "select" }),
	}),
	sources = cmp.config.sources({
		{ name = "render-markdown" },
	}),
})

require("render-markdown").setup({
	completions = { coq = { enabled = true } },
})

-- LSPs config
vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			completion = {
				callSnippet = "Both",
			},
			hint = {
				enable = true,
				arrayIndex = "Disable",
			},
			runtime = {
				version = "LuaJIT",
			},
			library = {
				vim.fn.expand("$VIMRUNTIME/lua"),
				vim.fn.stdpath("config") .. "/lua",
			},
		},
	},
})

vim.lsp.config("jsonls", {
	settings = {
		json = {
			schemas = require("schemastore").json.schemas(),
			validate = { enable = true },
		},
	},
})

vim.lsp.config("yamlls", {
	settings = {
		yaml = {
			schemaStore = {
				enable = false,
				url = "",
			},
			schemas = require("schemastore").yaml.schemas(),
		},
	},
})

vim.lsp.config("html", {
	filetypes = { "html", "heex", "astro" },
})

vim.lsp.config["astro"] = {}

-- Telescope
local telescope = require("telescope.builtin")

-- Treesitter
require("nvim-treesitter.configs").setup({
	ensure_installed = { "c", "lua", "javascript", "typescript", "rust", "dart", "go", "java" },

	sync_install = false,

	auto_install = true,

	highlight = {
		enable = true,
	},
})

-- nvim-colorizer
require("colorizer").setup()

-- Harpoon
local harpoon = require("harpoon")

harpoon:setup()

local conf = require("telescope.config").values
local function toggle_telescope(harpoon_files)
	local file_paths = {}
	for _, item in ipairs(harpoon_files.items) do
		table.insert(file_paths, item.value)
	end

	require("telescope.pickers")
		.new({}, {
			prompt_title = "Harpoon",
			finder = require("telescope.finders").new_table({
				results = file_paths,
			}),
			previewer = conf.file_previewer({}),
			sorter = conf.generic_sorter({}),
		})
		:find()
end

require("ufo").setup()

require("nvim-tree").setup({
	sort = {
		sorter = "case_sensitive",
	},
	view = {
		width = 30,
	},
	renderer = {
		group_empty = false,
	},
	filters = {
		dotfiles = true,
	},
})

local conform = require("conform")
conform.setup({
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "isort", "black" },
		rust = { "rustfmt", lsp_format = "fallback" },
		javascript = { "prettierd", "prettier", stop_after_first = true },
	},
	format_on_save = {
		lsp_format = "fallback",
		timeout_ms = 500,
	},
})

vim.api.nvim_create_user_command("Format", function(args)
	local range = nil
	if args.count ~= -1 then
		local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
		range = {
			start = { args.line1, 0 },
			["end"] = { args.line2, end_line:len() },
		}
	end
	require("conform").format({ async = true, lsp_format = "fallback", range = range })
end, { range = true })

require("Comment").setup()

local ufo = require("ufo")
ufo.setup()

local wk = require("which-key")
local isLow = false

require("codecompanion").setup({
  strategies = {
    chat = {
      adapter = "gemini",
    },
    inline = {
      adapter = "gemini",
    },
    cmd = {
      adapter = "gemini",
    }
  },
  opts = {
    log_level = "DEBUG"
  }
})

wk.add({
	{ "<leader>gs", vim.cmd.Git, desc = "Git" },

	{ "<leader>ff", telescope.find_files, desc = "Find files" },
	{ "<leader>fg", telescope.git_files, desc = "Git files" },
	{ "<leader>fl", telescope.live_grep, desc = "Live grep" },
	{ "<leader>fb", telescope.buffers, desc = "Buffers" },
	{ "<leader>fh", telescope.help_tags, desc = "Help tags" },

	{
		"<leader>ha",
		function()
			harpoon:list():add()
		end,
		desc = "Add",
	},
	{
		"<leader>hl",
		function()
			toggle_telescope(harpoon:list())
		end,
		desc = "List",
	},
	{
		"<leader>h1",
		function()
			harpoon:list():select(1)
		end,
		desc = "1",
	},
	{
		"<leader>h2",
		function()
			harpoon:list():select(2)
		end,
		desc = "2",
	},
	{
		"<leader>h3",
		function()
			harpoon:list():select(3)
		end,
		desc = "3",
	},
	{
		"<leader>h4",
		function()
			harpoon:list():select(4)
		end,
		desc = "4",
	},
	{
		"<leader>hp",
		function()
			harpoon:list():prev()
		end,
		desc = "Prev",
	},
	{
		"<leader>hn",
		function()
			harpoon:list():next()
		end,
		desc = "Next",
	},

	{ "<leader>lc", ":Lspsaga incoming_calls<CR>", desc = "Incoming calls" },
	{ "<leader>lC", ":Lspsaga outgoing_calls<CR>", desc = "Outgoing calls" },
	{ "<leader>la", ":Lspsaga code_action<CR>", desc = "Code adctions" },
	{ "<leader>lp", ":Lspsaga peek_definition<CR>", desc = "Peek definition" },
	{ "<leader>lP", ":Lspsaga peek_type_definition<CR>", desc = "Peek type definition" },
	{ "<leader>lf", ":Lspsaga finder<CR>", desc = "Finder" },
	{ "<leader>lt", ":Lspsaga term_toggle<CR>", desc = "Terminal toggle" },
	{ "<leader>lo", ":Lspsaga outline<CR>", desc = "Outline" },
	{ "<leader>lr", ":Lspsaga rename<CR>", desc = "Rename" },
	{ "<leader>lF", ":Format<CR>", desc = "Format" },

	{ "<leader>a", ":CodeCompanionActions<CR>", desc = "Apply" },
	{ "<leader>Ga", ":GeminiApply<CR>", desc = "Apply" },
	{ "<leader>Gc", ":GeminiChat ", desc = "Chat" },
	{ mode = { "v" }, "<leader>Ge", ":GeminiCodeExplain<CR>", desc = "Code explain" },
	{ mode = { "v" }, "<leader>Gr", ":GeminiCodeReview<CR>", desc = "Code review" },
	{ mode = { "v" }, "<leader>Gu", ":GeminiUnitTest<CR>", desc = "Unit tests" },
	{ "<leader>Gf", ":GeminiFunctionHint<CR>", desc = "Function hint" },

	{ "<leader>tv", vim.cmd.Ex, desc = "Explorer" },
	{ "<leader>tt", ":NvimTreeToggle<CR>", desc = "Toggle" },
	{ "<leader>tf", ":NvimTreeFocus<CR>", desc = "Focus" },
	{ "<leader>tF", ":NvimTreeFindFile<CR>", desc = "Find file" },
	{ "<leader>tr", ":NvimTreeRefresh<CR>", desc = "Refresh" },

	{ "<leader>zR", ufo.openAllFolds, desc = "Open all folds" },
	{ "<leader>zM", ufo.closeAllFolds, desc = "Close all folds" },

	{ mode = { "v" }, "<leader>J", ":m '>+1<CR>gv=gv", desc = "Line down" },
	{ mode = { "v" }, "<leader>K", ":m '<-2<CR>gv=gv", desc = "Line up" },
	{ mode = { "v" }, "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], desc = "Replace" },
	{ mode = { "x" }, "<leader>p", [["_dP]], desc = "Paste" },

	{ "<leader><Tab>", vim.cmd.tabnew, desc = "Tabnew" },
	{ "<S-Tab>", vim.cmd.tabclose, desc = "Tabclose" },
	{ "<Tab>", vim.cmd.tabnext, desc = "Next tab" },
	{ "<M-Tab>", vim.cmd.tabprev, desc = "Prev tab" },

	{
		"<leader>T",
		function()
			vim.cmd("belowright split")
			vim.cmd("resize10")
			vim.cmd("term")
		end,
		desc = "Terminal",
	},
	{
		"<C-t>",
		function()
			if isLow then
				vim.cmd("resize10")
			else
				vim.cmd("resize1")
			end
			isLow = not isLow
		end,
		desc = "Toggle terminal",
	},
})

require('lualine').setup {
  options = {
    icons_enabled = true,
    theme = 'auto',
    component_separators = { left = '', right = ''},
    section_separators = { left = '', right = ''},
    disabled_filetypes = {
      statusline = {},
      winbar = {},
    },
    ignore_focus = {},
    always_divide_middle = true,
    always_show_tabline = true,
    globalstatus = false,
    refresh = {
      statusline = 1000,
      tabline = 1000,
      winbar = 1000,
      refresh_time = 16, -- ~60fps
      events = {
        'WinEnter',
        'BufEnter',
        'BufWritePost',
        'SessionLoadPost',
        'FileChangedShellPost',
        'VimResized',
        'Filetype',
        'CursorMoved',
        'CursorMovedI',
        'ModeChanged',
      },
    }
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff', 'diagnostics'},
    lualine_c = {'filename'},
    lualine_x = {'encoding', 'fileformat', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filename'},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {}
}

