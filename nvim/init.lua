-----------------------------------------------------------
-- lazy.nvim bootstrap（插件管理器）
-----------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    lazyrepo,
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-----------------------------------------------------------
-- 基本設定
-----------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

opt.number = true
opt.relativenumber = true

opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true

opt.termguicolors = true
opt.cursorline = true
opt.scrolloff = 4

-- 系統剪貼簿（WSL + Windows Terminal 用這個就能互相複製）
opt.clipboard = "unnamedplus"

-- 關掉內建 netrw，交給 nvim-tree 處理檔案瀏覽
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-----------------------------------------------------------
-- 插件設定（lazy.nvim）
-----------------------------------------------------------
require("lazy").setup({
  spec = {
    -------------------------------------------------------
    -- 顏色主題：catppuccin（mocha 暗色）
    -------------------------------------------------------
    {
      "catppuccin/nvim",
      name = "catppuccin",
      priority = 1000,
      config = function()
        require("catppuccin").setup({
          flavour = "mocha",
          integrations = {
            telescope = true,
            nvimtree = true,
            treesitter = true,
            gitsigns = true,
            lualine = true,
          },
        })
        vim.cmd.colorscheme("catppuccin")
      end,
    },

    -- 圖示（nvim-tree / lualine / bufferline 都會用到）
    {
      "nvim-tree/nvim-web-devicons",
      lazy = true,
    },

    -------------------------------------------------------
    -- 檔案樹：nvim-tree
    -------------------------------------------------------
    {
      "nvim-tree/nvim-tree.lua",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      config = function()
        require("nvim-tree").setup({})
        vim.keymap.set("n", "<F2>", ":NvimTreeToggle<CR>", {
          silent = true,
          noremap = true,
          desc = "Toggle file tree",
        })
      end,
    },

    -------------------------------------------------------
    -- 狀態列：lualine
    -------------------------------------------------------
    {
      "nvim-lualine/lualine.nvim",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      config = function()
        require("lualine").setup({
          options = {
            theme = "catppuccin",
            icons_enabled = true,
            globalstatus = true,
          },
        })
      end,
    },

    -------------------------------------------------------
    -- buffer tabs：bufferline（像 VSCode tabs）
    -------------------------------------------------------
    {
      "akinsho/bufferline.nvim",
      version = "*",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      config = function()
        require("bufferline").setup({})
        -- Shift+h / Shift+l 切換 buffer（tab）
        vim.keymap.set("n", "<S-l>", ":bnext<CR>", { silent = true })
        vim.keymap.set("n", "<S-h>", ":bprevious<CR>", { silent = true })
      end,
    },

    -------------------------------------------------------
    -- 模糊搜尋：telescope
    -------------------------------------------------------
    {
      "nvim-telescope/telescope.nvim",
      tag = "0.1.5",
      dependencies = { "nvim-lua/plenary.nvim" },
      config = function()
        local builtin = require("telescope.builtin")
        -- Ctrl+p 找檔案
        vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
        -- <leader>fg 全文 grep
        vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
        -- <leader>fb buffer 清單
        vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "List buffers" })
      end,
    },

    -------------------------------------------------------
    -- treesitter：高品質語法高亮 / 結構
    -------------------------------------------------------
    {
      "nvim-treesitter/nvim-treesitter",
      build = ":TSUpdate",
      config = function()
        require("nvim-treesitter.configs").setup({
          highlight = { enable = true },
          indent = { enable = true },
        })
      end,
    },

    -------------------------------------------------------
    -- Git gutter：gitsigns
    -------------------------------------------------------
    {
      "lewis6991/gitsigns.nvim",
      config = function()
        require("gitsigns").setup({})
      end,
    },

    -------------------------------------------------------
    -- 註解工具：Comment.nvim（gcc / gc）
    -------------------------------------------------------
    {
      "numToStr/Comment.nvim",
      config = function()
        require("Comment").setup({})
      end,
    },

    -------------------------------------------------------
    -- 自動補全：nvim-cmp + LuaSnip + snippets
    -------------------------------------------------------
    {
      "hrsh7th/nvim-cmp",
      dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "rafamadriz/friendly-snippets",
      },
      config = function()
        local cmp = require("cmp")
        local luasnip = require("luasnip")

        require("luasnip.loaders.from_vscode").lazy_load()

        cmp.setup({
          snippet = {
            expand = function(args)
              luasnip.lsp_expand(args.body)
            end,
          },
          mapping = cmp.mapping.preset.insert({
            ["<C-b>"] = cmp.mapping.scroll_docs(-4),
            ["<C-f>"] = cmp.mapping.scroll_docs(4),
            ["<C-Space>"] = cmp.mapping.complete(),
            ["<C-e>"] = cmp.mapping.abort(),
            ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Enter 接受補全
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
            { name = "path" },
          }, {
            { name = "buffer" },
          }),
        })
      end,
    },

    -------------------------------------------------------
    -- mason：LSP server 管理
    -------------------------------------------------------
    {
      "williamboman/mason.nvim",
      config = function()
        require("mason").setup({})
      end,
    },

    -------------------------------------------------------
    -- mason-lspconfig + lspconfig：LSP 啟動
    -------------------------------------------------------
    {
      "williamboman/mason-lspconfig.nvim",
      dependencies = {
        "williamboman/mason.nvim",
        "neovim/nvim-lspconfig",
        "hrsh7th/cmp-nvim-lsp",
      },
      config = function()
        local mason_lspconfig = require("mason-lspconfig")
        local lspconfig = require("lspconfig")
        local cmp_nvim_lsp = require("cmp_nvim_lsp")

        local capabilities = cmp_nvim_lsp.default_capabilities()

        local on_attach = function(_, bufnr)
          local bufmap = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
          end

          bufmap("n", "gd", vim.lsp.buf.definition, "Goto definition")
          bufmap("n", "K", vim.lsp.buf.hover, "Hover")
          bufmap("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          bufmap("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
          bufmap("n", "gr", vim.lsp.buf.references, "References")
          bufmap("n", "[d", vim.diagnostic.goto_prev, "Prev diagnostic")
          bufmap("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
          bufmap("n", "<leader>e", vim.diagnostic.open_float, "Line diagnostics")
        end

        mason_lspconfig.setup({
          ensure_installed = { "lua_ls", "pyright", "clangd" },
          automatic_installation = true,
          handlers = {
            -- 預設 handler：其他語言直接用這個
            function(server_name)
              lspconfig[server_name].setup({
                capabilities = capabilities,
                on_attach = on_attach,
              })
            end,

            -- 特別設定 lua_ls（讓它認得 vim 這個 global）
            ["lua_ls"] = function()
              lspconfig.lua_ls.setup({
                capabilities = capabilities,
                on_attach = on_attach,
                settings = {
                  Lua = {
                    diagnostics = { globals = { "vim" } },
                    workspace = { checkThirdParty = false },
                  },
                },
              })
            end,
          },
        })
      end,
    },
  },

  checker = { enabled = false },
})

local lsp = vim.lsp

-- 如果沒有啟用 LSP，呼叫這些只會印一行錯誤，不會壞掉
vim.keymap.set("n", "gd", function()
  lsp.buf.definition()
end, { desc = "LSP goto definition" })

vim.keymap.set("n", "gD", function()
  lsp.buf.declaration()
end, { desc = "LSP goto declaration" })

vim.keymap.set("n", "gi", function()
  lsp.buf.implementation()
end, { desc = "LSP goto implementation" })

vim.keymap.set("n", "gr", function()
  lsp.buf.references()
end, { desc = "LSP references" })
