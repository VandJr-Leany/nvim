-- Colors
function Colors()
  local themes = {
    "catppuccin", "catppuccin-frappe", "catppuccin-macchiato", "catppuccin-mocha",
    "kanagawa", "kanagawa-dragon", "kanagawa-wave",
    "tokyonight", "tokyonight-moon", "tokyonight-night", "tokyonight-storm",
  }
  local theme = themes[math.random(1, #themes)]
  print("Choosed theme: " .. theme)
  vim.cmd.colorscheme(theme)

  vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

Colors()

-- ==========================================
-- FUNÇÕES DE TOGGLE (Autosave & Autoformat)
-- ==========================================

-- Toggle Autoformat
vim.g.disable_autoformat = false
local function toggle_autoformat()
  vim.g.disable_autoformat = not vim.g.disable_autoformat
  if vim.g.disable_autoformat then
    print("Autoformat on save: Disabled")
  else
    print("Autoformat on save: Enabled")
  end
end

-- Toggle Autosave
local autosave_group = vim.api.nvim_create_augroup("AutosaveGroup", { clear = true })
local autosave_enabled = false
local function toggle_autosave()
  autosave_enabled = not autosave_enabled
  if autosave_enabled then
    vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
      group = autosave_group,
      pattern = "*",
      command = "silent! update",
    })
    print("Autosave: Enabled")
  else
    vim.api.nvim_clear_autocmds({ group = autosave_group })
    print("Autosave: Disabled")
  end
end

-- ==========================================
-- SETUP BÁSICO MASON
-- ==========================================
require("mason").setup()

-- Integração Mason com LSP
require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "jsonls", "yamlls", "html", "sqlls" },
})

-- ==========================================
-- DEBUGGING (DAP) SETUP
-- ==========================================
local dap = require("dap")

-- Carrega o launch.json automaticamente se existir na raiz do projeto
require('dap.ext.vscode').load_launchjs(nil, {
  ['pwa-node'] = { 'javascript', 'typescript' },
  ['python'] = { 'python' }
})

require("mason-nvim-dap").setup({
  ensure_installed = { "python", "js-debug-adapter" },
  automatic_installation = true,
  handlers = {
    -- Padrão: Deixa o Mason configurar os adaptadores (incluindo Python) automaticamente.
    -- O Mason usa seu próprio venv interno para o 'debugpy-adapter', o que é mais estável.
    function(config)
      require('mason-nvim-dap').default_setup(config)
    end,
  },
})

-- >>>> CONFIGURAÇÃO JS/TS (PWA-NODE) <<<<
-- Necessário manual pois o pwa-node tem estrutura complexa
local mason_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter"
local js_debug_path = mason_path .. "/js-debug/src/dapDebugServer.js"

if not vim.loop.fs_stat(js_debug_path) then
  js_debug_path = mason_path .. "/out/src/dapDebugServer.js"
end

dap.adapters["pwa-node"] = {
  type = "server",
  host = "localhost",
  port = "${port}",
  executable = {
    command = "node",
    args = { js_debug_path, "${port}" },
  }
}

for _, language in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
  if not dap.configurations[language] then
    dap.configurations[language] = {
      {
        type = "pwa-node",
        request = "launch",
        name = "Launch file",
        program = "${file}",
        cwd = "${workspaceFolder}",
      },
      {
        type = "pwa-node",
        request = "attach",
        name = "Attach",
        processId = require("dap.utils").pick_process,
        cwd = "${workspaceFolder}",
      }
    }
  end
end

-- ==========================================
-- SETUP DE AUTOCOMPLETAR (NVIM-CMP)
-- ==========================================
local cmp = require("cmp")
local luasnip = require("luasnip")
local lspkind = require("lspkind")

require("luasnip.loaders.from_vscode").lazy_load()

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "render-markdown" },
    { name = "path" },
    { name = "vim-dadbod-completion" },
    per_filetype = {
      codecompanion = { "codecompanion" },
    }
  }, {
    { name = "buffer" },
  }),
  formatting = {
    format = lspkind.cmp_format({
      mode = 'symbol_text',
      maxwidth = 50,
      ellipsis_char = '...',
    })
  }
})

-- ==========================================
-- DEBUGGING UI & TESTING
-- ==========================================
local dapui = require("dapui")

dapui.setup()

dap.listeners.before.attach.dapui_config = function() dapui.open() end
dap.listeners.before.launch.dapui_config = function() dapui.open() end
dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

require("neotest").setup({
  adapters = {
    require("neotest-python")({
      dap = { justMyCode = false },
    }),
    require("neotest-jest")({
      jestCommand = "npm test --",
      jestConfigFile = "custom.jest.config.ts",
      env = { CI = true },
      cwd = function(path)
        return vim.fn.getcwd()
      end,
    }),
  },
})

-- ==========================================
-- GIT (Gitsigns)
-- ==========================================
require('gitsigns').setup()

-- ==========================================
-- OUTRAS FERRAMENTAS
-- ==========================================

require("render-markdown").setup({})

local telescope = require("telescope.builtin")

require("nvim-treesitter.configs").setup({
  ensure_installed = { "lua", "javascript", "typescript", "python", "sql" },
  sync_install = false,
  auto_install = true,
  highlight = { enable = true },
})

require("colorizer").setup()
local harpoon = require("harpoon")
harpoon:setup()

local conf = require("telescope.config").values
local function toggle_telescope(harpoon_files)
  local file_paths = {}
  for _, item in ipairs(harpoon_files.items) do
    table.insert(file_paths, item.value)
  end
  require("telescope.pickers").new({}, {
    prompt_title = "Harpoon",
    finder = require("telescope.finders").new_table({ results = file_paths }),
    previewer = conf.file_previewer({}),
    sorter = conf.generic_sorter({}),
  }):find()
end

require("ufo").setup()

-- ==========================================
-- NVIM TREE
-- ==========================================
require("nvim-tree").setup({
  sort = { sorter = "case_sensitive" },
  view = { width = 30 },
  renderer = { group_empty = false },
  filters = {
    dotfiles = false,
    git_ignored = false,
  },
  git = {
    enable = true,
    ignore = false,
  }
})

-- Conform Formatter
require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "isort", "black" },
    javascript = { "prettierd", "prettier", stop_after_first = true },
    typescript = { "prettierd", "prettier", stop_after_first = true },
    sql = { "sql_formatter" },
  },
  format_on_save = function(bufnr)
    if vim.g.disable_autoformat then
      return
    end
    return { timeout_ms = 500, lsp_format = "fallback" }
  end,
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
require("which-key").setup()

require("codecompanion").setup({
  strategies = {
    chat = { adapter = "gemini_cli" },
    inline = { adapter = "gemini_cli" },
    cmd = { adapter = "gemini_cli" }
  },
  opts = { log_level = "DEBUG" },
  extensions = {
    mcphub = {
      callback = "mcphub.extensions.codecompanion",
      opts = {
        make_tools = true,                    -- Make individual tools (@server__tool) and server groups (@server) from MCP servers
        show_server_tools_in_chat = true,     -- Show individual tools in chat completion (when make_tools=true)
        add_mcp_prefix_to_tool_names = false, -- Add mcp__ prefix (e.g `@mcp__github`, `@mcp__neovim__list_issues`)
        show_result_in_chat = true,           -- Show tool results directly in chat buffer
        format_tool = nil,                    -- function(tool_name:string, tool: CodeCompanion.Agent.Tool) : string Function to format tool names to show in the chat buffer
        -- MCP Resources
        make_vars = true,                     -- Convert MCP resources to #variables for prompts
        -- MCP Prompts
        make_slash_commands = true,           -- Add MCP prompts as /slash commands
      }
    }
  }
})

-- ==========================================
-- CUSTOM FUNCTIONS
-- ==========================================

local function open_multi_term()
  vim.cmd("tabnew")
  vim.cmd("term")
  vim.cmd("vsplit")
  vim.cmd("term")
  vim.cmd("split")
  vim.cmd("term")
end

-- ==========================================
-- KEYMAPS (WHICH-KEY)
-- ==========================================
local wk = require("which-key")
local isLow = false
local nvim_tree_api = require("nvim-tree.api")
local neotest = require("neotest")

wk.add({
  -- Groups Definition
  { "<leader>c",         group = "Misc" },
  { "<leader>d",         group = "Debug/Test" },
  { "<leader>f",         group = "Find" },
  { "<leader>g",         group = "Git" },
  { "<leader>h",         group = "Harpoon" },
  { "<leader>l",         group = "LSP" },
  { "<leader>t",         group = "Tree" },
  { "<leader>z",         group = "Fold" },
  { "<leader>D",         group = "Database" },

  -- Database (Dadbod)
  { "<leader>Du",        ":DBUIToggle<CR>",                                       desc = "Toggle DB UI" },
  { "<leader>Df",        ":DBUIFindBuffer<CR>",                                   desc = "Find DB Buffer" },
  { "<leader>Dr",        ":DBUIRenameBuffer<CR>",                                 desc = "Rename DB Buffer" },
  { "<leader>Dl",        ":DBUILastQueryInfo<CR>",                                desc = "Last Query Info" },

  -- Docker (Lazydocker)
  { "<leader>ld",        ":LazyDocker<CR>",                                       desc = "LazyDocker" },

  -- Git Group
  { "<leader>gs",        vim.cmd.Git,                                             desc = "Git Status" },
  { "<leader>ga",        ":Git add %<CR>",                                        desc = "Git Add (Current File)" },
  { "<leader>gc",        ":Git commit<CR>",                                       desc = "Git Commit" },
  { "<leader>gp",        ":Git push<CR>",                                         desc = "Git Push" },
  { "<leader>gl",        ":Git pull<CR>",                                         desc = "Git Pull" },
  { "<leader>gd",        ":Gdiffsplit<CR>",                                       desc = "Git Diff" },
  { "<leader>gb",        ":Gitsigns toggle_current_line_blame<CR>",               desc = "Toggle Blame Line" },
  { "<leader>gh",        ":Gitsigns preview_hunk<CR>",                            desc = "Preview Hunk" },

  -- Misc Group (<leader>c)
  { "<leader>ca",        ":CodeCompanionActions<CR>",                             desc = "Apply AI" },
  { "<leader>cx",        function() Colors() end,                                 desc = "Change Colors" },
  { "<leader>cw",        function() toggle_autosave() end,                        desc = "Toggle Autosave" },
  { "<leader>cf",        function() toggle_autoformat() end,                      desc = "Toggle Autoformat" },

  -- Telescope
  { "<leader>ff",        telescope.find_files,                                    desc = "Find files" },
  { "<leader>fg",        telescope.git_files,                                     desc = "Git files" },
  { "<leader>fl",        telescope.live_grep,                                     desc = "Live grep" },
  { "<leader>fb",        telescope.buffers,                                       desc = "Buffers" },
  { "<leader>fh",        telescope.help_tags,                                     desc = "Help tags" },

  -- Harpoon
  { "<leader>ha",        function() harpoon:list():add() end,                     desc = "Add" },
  { "<leader>hr",        function() harpoon:list():remove() end,                  desc = "Remove" },
  { "<leader>hl",        function() toggle_telescope(harpoon:list()) end,         desc = "List" },
  { "<leader>h1",        function() harpoon:list():select(1) end,                 desc = "1" },
  { "<leader>h2",        function() harpoon:list():select(2) end,                 desc = "2" },
  { "<leader>h3",        function() harpoon:list():select(3) end,                 desc = "3" },
  { "<leader>h4",        function() harpoon:list():select(4) end,                 desc = "4" },
  { "<leader>hp",        function() harpoon:list():prev() end,                    desc = "Prev" },
  { "<leader>hn",        function() harpoon:list():next() end,                    desc = "Next" },

  -- LSP Saga
  { "<leader>lc",        ":Lspsaga incoming_calls<CR>",                           desc = "Incoming calls" },
  { "<leader>lC",        ":Lspsaga outgoing_calls<CR>",                           desc = "Outgoing calls" },
  { "<leader>la",        ":Lspsaga code_action<CR>",                              desc = "Code actions" },
  { "<leader>lp",        ":Lspsaga peek_definition<CR>",                          desc = "Peek definition" },
  { "<leader>lP",        ":Lspsaga peek_type_definition<CR>",                     desc = "Peek type definition" },
  { "<leader>lf",        ":Lspsaga finder<CR>",                                   desc = "Finder" },
  { "<leader>lt",        ":Lspsaga term_toggle<CR>",                              desc = "Terminal toggle" },
  { "<leader>lo",        ":Lspsaga outline<CR>",                                  desc = "Outline" },
  { "<leader>lr",        ":Lspsaga rename<CR>",                                   desc = "Rename" },
  { "<leader>lF",        ":Format<CR>",                                           desc = "Format" },

  -- Debug (DAP)
  { "<leader>db",        function() dap.toggle_breakpoint() end,                  desc = "Toggle Breakpoint" },
  { "<leader>dc",        function() dap.continue() end,                           desc = "Continue/Start" },
  { "<leader>di",        function() dap.step_into() end,                          desc = "Step Into" },
  { "<leader>do",        function() dap.step_over() end,                          desc = "Step Over" },
  { "<leader>du",        function() dapui.toggle() end,                           desc = "Toggle UI" },
  { "<leader>dm",        function() neotest.run.run() end,                        desc = "Test Method" },
  { "<leader>dM",        function() neotest.run.run({ strategy = "dap" }) end,    desc = "Debug Method" },
  { "<leader>df",        function() neotest.run.run(vim.fn.expand("%")) end,      desc = "Test Class/File" },
  { "<leader>dS",        function() neotest.summary.toggle() end,                 desc = "Test Summary" },
  { "<leader>dn",        function() neotest.jump.next({ status = "failed" }) end, desc = "Next Failed Test" },
  { "<leader>dp",        function() neotest.jump.prev({ status = "failed" }) end, desc = "Prev Failed Test" },

  -- CodeCompanion
  { "<leader>a",         ":CodeCompanionActions<CR>",                             desc = "Apply AI" },

  -- NvimTree
  { "<leader>tv",        vim.cmd.Ex,                                              desc = "Explorer (Netrw)" },
  { "<leader>tt",        ":NvimTreeToggle<CR>",                                   desc = "Tree Toggle" },
  { "<leader>tf",        ":NvimTreeFocus<CR>",                                    desc = "Tree Focus" },
  { "<leader>tF",        ":NvimTreeFindFile<CR>",                                 desc = "Tree Find file" },
  { "<leader>tr",        ":NvimTreeRefresh<CR>",                                  desc = "Tree Refresh" },
  { "<leader>tg",        nvim_tree_api.tree.toggle_gitignore_filter,              desc = "Toggle Git Ignore" },

  -- Folding
  { "<leader>zR",        require("ufo").openAllFolds,                             desc = "Open all folds" },
  { "<leader>zM",        require("ufo").closeAllFolds,                            desc = "Close all folds" },
  { "<leader>za",        "za",                                                    desc = "Toggle fold" },

  -- Editor Movement & Actions
  { mode = { "v" },      "<leader>J",                                             ":m '>+1<CR>gv=gv",                                     desc = "Move Line down" },
  { mode = { "v" },      "<leader>K",                                             ":m '<-2<CR>gv=gv",                                     desc = "Move Line up" },
  { mode = { "v" },      "<leader>s",                                             [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], desc = "Replace word" },

  -- Paste Logic Redefinition
  { mode = { "x" },      "p",                                                     [["_dP]],                                               desc = "Paste (No Register Override)" },
  { mode = { "x" },      "P",                                                     "p",                                                    desc = "Paste (Standard)" },
  { mode = { "n", "v" }, "<leader>p",                                             [["_dP]],                                               desc = "Paste over (No Reg)" },

  -- Tabs
  { "<leader><Tab>",     vim.cmd.tabnew,                                          desc = "New Tab" },
  { "<S-Tab>",           vim.cmd.tabclose,                                        desc = "Close Tab" },
  { "<Tab>",             vim.cmd.tabnext,                                         desc = "Next tab" },
  { "<M-Tab>",           vim.cmd.tabprev,                                         desc = "Prev tab" },
  -- Layout de 3 Terminais
  { "<Tab>t",            open_multi_term,                                         desc = "3-Terminal Tab Layout" },

  -- Terminal
  {
    "<leader>T",
    function()
      vim.cmd("belowright split")
      vim.cmd("resize10")
      vim.cmd("term")
    end,
    desc = "Terminal Split",
  },
  {
    "<C-t>",
    function()
      if isLow then vim.cmd("resize10") else vim.cmd("resize1") end
      isLow = not isLow
    end,
    desc = "Toggle terminal height",
  },
  -- Voltar para modo normal dentro do terminal
  { mode = { "t" }, "<Esc>", [[<C-\><C-n>]], desc = "Exit Terminal Mode" },
})

-- Lualine
require('lualine').setup {
  options = {
    icons_enabled = true,
    theme = 'auto',
    component_separators = { left = '', right = '' },
    section_separators = { left = '', right = '' },
    disabled_filetypes = { statusline = {}, winbar = {} },
    ignore_focus = {},
    always_divide_middle = true,
    always_show_tabline = true,
    globalstatus = false,
    refresh = {
      statusline = 1000,
      tabline = 1000,
      winbar = 1000,
      refresh_time = 16,
      events = { 'WinEnter', 'BufEnter', 'BufWritePost', 'SessionLoadPost', 'FileChangedShellPost', 'VimResized', 'Filetype', 'CursorMoved', 'CursorMovedI', 'ModeChanged' },
    }
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { 'branch', 'diff', 'diagnostics' },
    lualine_c = { 'filename' },
    lualine_x = { 'encoding', 'fileformat', 'filetype', 'progress' },
    lualine_y = { { function()
      if not vim.g.loaded_mcphub then
        return "󰐻 -"
      end

      local count = vim.g.mcphub_servers_count or 0
      local status = vim.g.mcphub_status or "stopped"
      local executing = vim.g.mcphub_executing

      if status == "stopped" then
        return "󰐻 -"
      end

      if executing or status == "starting" or status == "restarting" then
        local frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
        local frame = math.floor(vim.loop.now() / 100) % #frames + 1
        return "󰐻 " .. frames[frame]
      end

      return "󰐻 " .. count
    end,
      color = function()
        if not vim.g.loaded_mcphub then
          return { fg = "#6c7086" }
        end

        local status = vim.g.mcphub_status or "stopped"
        if status == "ready" or status == "restarted" then
          return { fg = "#50fa7b" }
        elseif status == "starting" or status == "restarting" then
          return { fg = "#ffb86c" }
        else
          return { fg = "#ff5555" }
        end
      end,
    } },
    lualine_z = { 'location' }
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { 'filename' },
    lualine_x = { 'location' },
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {}
}

-- mcphub
require("mcphub").setup()
