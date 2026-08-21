-- ==========================================================================
-- 1. CONFIGURACIÓN BÁSICA DE NEOVIM
-- ==========================================================================
vim.opt.number = true             -- Números de línea
vim.opt.relativenumber = true     -- Números relativos
vim.opt.mouse = 'a'               -- Habilitar mouse
vim.opt.encoding = 'utf-8'        -- Codificación
vim.opt.termguicolors = true      -- Activar True Color (vital para Dracula y Colorizer)
vim.opt.tabstop = 4               -- Espacios por tabulación
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.g.mapleader = " "             -- Tecla Líder en Espacio

-- ==========================================================================
-- 2. GESTOR DE PLUGINS: LAZY.NVIM (Bootstrap automático)
-- ==========================================================================
local lazypath = vim.fn.stdpath("data") .."/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ==========================================================================
-- 3. LISTA DE PLUGINS
-- ==========================================================================
require("lazy").setup({
    -- Estética y Temas
    { "dracula/vim", name = "dracula" },
    { "itchyny/lightline.vim" },
    { "maximbaz/lightline-ale" },
    { "yggdroot/indentline" },
    { "junegunn/goyo.vim" },
    { "norcalli/nvim-colorizer.lua", config = function() require("colorizer").setup() end },

    -- Sintaxis y Lenguajes
    { "sheerun/vim-polyglot" },
    { "styled-components/vim-styled-components", branch = "main" },

    -- Edición y Productividad
    { "alvan/vim-closetag" },
    { "tpope/vim-surround" },
    { "tpope/vim-repeat" },
    { "tpope/vim-eunuch" },
    { "preservim/nerdcommenter" },
    { "terryma/vim-multiple-cursors" },
    { "easymotion/vim-easymotion" },
    { "editorconfig/editorconfig-vim" },

    -- Explorador de Archivos y Búsqueda
    { "preservim/nerdtree" },
    { "junegunn/fzf", build = ":call fzf#install()" },
    { "junegunn/fzf.vim" },

    -- Git y Terminal
    { "tpope/vim-fugitive" },
    { "mhinz/vim-signify" },
    { "benmills/vimux" },
    { "christoomey/vim-tmux-navigator" },

    -- Autocompletado y LSP
    { "sirver/ultisnips" },
    { "neoclide/coc.nvim", branch = "release" },

    -- Nuevos Plugins Pro
    { "windwp/nvim-autopairs", event = "InsertEnter", config = function() require("nvim-autopairs").setup({}) end },
    { "lewis6991/gitsigns.nvim", config = function() require("gitsigns").setup() end },
    { "nvim-lua/plenary.nvim" },
    { "nvim-telescope/telescope.nvim", tag = "0.1.8", dependencies = { "nvim-lua/plenary.nvim" } },
    { "folke/which-key.nvim", event = "VeryLazy", opts = {} },

    -- Estética Adicional: Bufferline (Pestañas de buffers) y Notificaciones Nvim-notify
    { "nvim-tree/nvim-web-devicons" },
    { 
        "akinsho/bufferline.nvim", 
        version = "*", 
        dependencies = "nvim-tree/nvim-web-devicons",
        config = function()
            require("bufferline").setup({})
        end
    },
    {
        "rcarriga/nvim-notify",
        config = function()
            require("notify").setup({
                background_colour = "#000000",
            })
            vim.notify = require("notify")
        end
    },

    -- Testing
    { "tyewang/vimux-jest-test" },
    { "janko-m/vim-test" },
})

-- ==========================================================================
-- 4. CONFIGURACIÓN DE TEMA Y ATAJOS BÁSICOS
-- ==========================================================================
vim.cmd([[colorscheme dracula]])

-- Atajos rápidos con la tecla líder (<leader>)
vim.keymap.set('n', '<leader>n', ':NERDTreeToggle<CR>', { silent = true })
vim.keymap.set('n', '<leader>f', ':Files<CR>', { silent = true })
vim.keymap.set('n', '<leader>g', ':Rg<CR>', { silent = true })

-- Atajos para Telescope (súper buscador moderno)
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

-- Atajos para Bufferline (Navegar entre pestañas/buffers abiertos)
vim.keymap.set('n', '<S-l>', ':BufferLineCycleNext<CR>', { silent = true })
vim.keymap.set('n', '<S-h>', ':BufferLineCyclePrev<CR>', { silent = true })


-- ==========================================================================
-- 5. TRANSPARENCIA (Fondo transparente para integrarse con la terminal)
-- ==========================================================================
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
vim.api.nvim_set_hl(0, "CursorLineNr", { bg = "none" })


-- ==========================================================================
-- 6. GUÍA COMPLETA DE USO Y ATAJOS (Referencia Rápida en Neovim)
-- ==========================================================================
-- MODOS:
--   - Normal (ESC): Navegar, buscar, editar.
--   - Insertar (i, a, o): Escribir texto.
--   - Visual (v, Shift+v, Ctrl+v): Seleccionar texto / bloques.
--   - Comando (:): Guardar, salir, configurar.
--
-- ATAJOS CLAVE Y LÍDER (<leader> = Espacio):
--   - <leader>n          : Alternar árbol de archivos (NERDTreeToggle)
--   - <leader>f          : Buscar archivos (FZF Files)
--   - <leader>g          : Buscar texto en proyecto (Rg)
--   - Ctrl + w + w       : Cambiar entre paneles (ej. de NERDTree al código)
--   - yy / p             : Copiar / pegar línea
--   - "+y / "+p          : Copiar / pegar desde/hacia el portapapeles del sistema
--   - u / Ctrl+r         : Deshacer / Rehacer
--   - :Goyo              : Modo Zen / Escritura sin distracciones
--   - :Remove / :Rename  : Borrar o renombrar archivo actual (Vim-Eunuch)
-- ==========================================================================
