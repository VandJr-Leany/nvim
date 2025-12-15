local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

  -- ==========================================================================
  -- THEMES
  -- ==========================================================================

  -- Catppuccin theme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
  },

  -- Kanagawa theme
  {
    "rebelot/kanagawa.nvim",
  },

  -- Tokyonight theme
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
  },

  -- ==========================================================================
  -- LSP & COMPLETION
  -- ==========================================================================

  -- Mason & Configs
  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim" },
  { "neovim/nvim-lspconfig",            lazy = false },

  -- Nvim CMP (Completion)
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
      "onsails/lspkind.nvim",
    },
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      table.insert(opts.sources, {
        name = "lazydev",
        group_index = 0,
      })
    end,
  },

  -- Lazydev (Lua dev)
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },

  -- SchemaStore (JSON/YAML schemas)
  { "b0o/schemastore.nvim" },

  -- Lspsaga (UI for LSP)
  {
    "nvimdev/lspsaga.nvim",
    config = function() require("lspsaga").setup({}) end,
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  },

  -- Conform (Formatting)
  { "stevearc/conform.nvim",       opts = {} },

  -- Nvim-lint (Linting)
  { "mfussenegger/nvim-lint" },

  -- LSP Signature
  { "ray-x/lsp_signature.nvim",    event = "InsertEnter", opts = {} },

  -- ==========================================================================
  -- DEBUGGING & TESTING (Backend Essentials)
  -- ==========================================================================

  -- DAP (Debugging)
  { "jay-babu/mason-nvim-dap.nvim" },
  { "mfussenegger/nvim-dap" },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "nvim-neotest/nvim-nio" }
  },

  -- Neotest (Testing Runner for Jest/Pytest)
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/neotest-python", -- Adapter for Python
      "nvim-neotest/neotest-jest",   -- Adapter for Jest (NestJS)
    }
  },

  -- ==========================================================================
  -- DATABASE (Backend Essentials)
  -- ==========================================================================

  -- Vim-Dadbod (Database Interface)
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod",                     lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
    },
    init = function()
      -- Your DBUI configuration
      vim.g.db_ui_use_nerd_fonts = 1
    end,
  },

  -- Lazydocker (Docker Visualizer)
  -- lazydocker.nvim
  {
    "mgierada/lazydocker.nvim",
    dependencies = { "akinsho/toggleterm.nvim" },
    config = function()
      require("lazydocker").setup({
        border = "curved", -- valid options are "single" | "double" | "shadow" | "curved"
        width = 0.9,       -- width of the floating window (0-1 for percentage, >1 for absolute columns)
        height = 0.9,      -- height of the floating window (0-1 for percentage, >1 for absolute rows)
      })
    end,
    event = "BufRead",
    keys = {
      {
        "<leader>ld",
        function()
          require("lazydocker").open()
        end,
        desc = "Open Lazydocker floating window",
      },
    },
  },

  -- ==========================================================================
  -- NAVIGATION & FILES
  -- ==========================================================================

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  -- Harpoon
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  -- Nvim Tree
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function() require("nvim-tree").setup({}) end,
  },

  -- ==========================================================================
  -- EDITOR UI & UTILITIES
  -- ==========================================================================

  -- Treesitter
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

  -- Colorizer
  { "norcalli/nvim-colorizer.lua",     event = "BufEnter",                              opts = { "*" } },

  -- Lualine
  { 'nvim-lualine/lualine.nvim',       dependencies = { 'nvim-tree/nvim-web-devicons' } },

  -- Which-Key
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = { delay = 0 },
    keys = {
      {
        "<leader>?",
        function() require("which-key").show({ global = false }) end,
        desc = "Buffer Local Keymaps",
      },
    },
  },

  -- Trouble (Diagnostics list)
  {
    "folke/trouble.nvim",
    opts = {},
    cmd = "Trouble",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>",                        desc = "Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",           desc = "Buffer Diagnostics (Trouble)" },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>",                desc = "Symbols (Trouble)" },
      { "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP Definitions (Trouble)" },
      { "<leader>xL", "<cmd>Trouble loclist toggle<cr>",                            desc = "Location List (Trouble)" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>",                             desc = "Quickfix List (Trouble)" },
    },
  },

  -- Ufo (Folding)
  { "kevinhwang91/nvim-ufo", dependencies = { "kevinhwang91/promise-async" } },

  -- Comment
  { "numToStr/Comment.nvim" },

  -- autopairs
  {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    config = true
    -- use opts = {} for passing setup options
    -- this is equivalent to setup({}) function
  },

  -- ==========================================================================
  -- GIT
  -- ==========================================================================

  -- Fugitive
  { "tpope/vim-fugitive" },

  -- Gitsigns (Visual Git indicators in gutter)
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true, -- Show blame on current line
      current_line_blame_opts = {
        delay = 500,
      },
    }
  },

  -- ==========================================================================
  -- AI & MARKDOWN
  -- ==========================================================================

  -- CodeCompanion
  {
    "olimorris/codecompanion.nvim",
    version = "^18.0.0",
    opts = {},
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
  {
    "ravitemer/mcphub.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    build = "pnpm install -g mcp-hub@latest"
  },

  -- Copilot
  { "github/copilot.vim" },

  -- Render Markdown
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ft = { "markdown", "codecompanion" },
    opts = {},
  },
})
