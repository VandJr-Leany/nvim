vim.g.mapleader = ' '

vim.opt.nu = true
vim.opt.relativenumber = true

function set_indent(size)
  vim.opt.tabstop = size
  vim.opt.softtabstop = size
  vim.opt.shiftwidth = size
end

vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = 'yes'
vim.opt.isfname:append('@-@')

vim.opt.updatetime = 50

vim.cmd([[autocmd FileType * set formatoptions-=ro]])

set_indent(4)

vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, {
  callback = function()
    -- Pega apenas o nome da pasta (ex: "meu-projeto-fastapi")
    local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
    -- Define o título do terminal
    vim.opt.title = true
    vim.opt.titlestring = project_name
    -- Força o escape code para alguns terminais específicos
    io.write("\27]2;" .. project_name .. "\7")
  end,
})
