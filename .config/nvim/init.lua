-- ==========================================================================
-- 1. CONFIGURACIÓN BÁSICA DE NEOVIM
-- ==========================================================================
vim.opt.number = true             -- Números de línea
vim.opt.relativenumber = true     -- Números relativos
vim.opt.mouse = 'a'               -- Habilitar mouse
vim.opt.termguicolors = true      -- Activar True Color (vital para Dracula y Colorizer)
vim.opt.tabstop = 4               -- Espacios por tabulación
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.clipboard = 'unnamedplus' -- Usa el portapapeles del sistema por defecto (evita depender de "+ manualmente)
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes'        -- Evita que el texto "salte" cuando aparecen signos de git/lsp
vim.g.mapleader = " "             -- Tecla Líder en Espacio

-- ==========================================================================
-- 2. GESTOR DE PLUGINS: LAZY.NVIM (Bootstrap automático)
-- ==========================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then  -- vim.loop está deprecado desde NVim 0.10, usar vim.uv
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
-- NOTA DE DISEÑO: se eliminó coc.nvim + ultisnips (stack Vimscript/Node) porque
-- convivía con telescope + which-key + gitsigns (stack Lua nativo) y generaba
-- doble diagnóstico, doble autocompletado y conflictos de teclas. Se optó por
-- el stack nativo (nvim-lspconfig + mason + nvim-cmp + luasnip), que es el
-- estándar moderno de facto y se integra mejor con el resto de tus plugins.
-- También se eliminó fzf.vim (duplicaba a Telescope) y vim-polyglot (Treesitter
-- da mejor resaltado y es el reemplazo recomendado desde hace años).
-- Si dependés fuertemente de flujos específicos de coc (p.ej. coc-extensions
-- muy particulares), avisame y lo dejamos en paralelo con cuidado, pero por
-- defecto no se recomienda.

require("lazy").setup({
    -- Estética y Temas
    -- Se cambió dracula/vim (Vimscript clásico, sin conocimiento de Treesitter)
    -- por Mofiqul/dracula.nvim (Lua, mapea explícitamente los grupos @variable,
    -- @function, etc. de Treesitter). Con dracula/vim el resaltado nativo caía
    -- a los colores por defecto de Neovim en vez de la paleta Dracula.
    {
        "Mofiqul/dracula.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("dracula").setup({})
            vim.cmd([[colorscheme dracula]])
        end
    },
    { "itchyny/lightline.vim" },
    { "maximbaz/lightline-ale" },
    { "yggdroot/indentline" },
    { "junegunn/goyo.vim", cmd = "Goyo" },
    { "norcalli/nvim-colorizer.lua", event = "BufReadPre", config = function() require("colorizer").setup() end },

    -- Sintaxis y Lenguajes (Treesitter reemplaza a vim-polyglot)
    -- ARQUITECTURA: "treesitter 100% nativo" con huella mínima de plugin.
    -- El repo original de nvim-treesitter fue reescrito y quedó archivado (ya no
    -- recibe mantenimiento), pero sigue siendo la única forma práctica de
    -- descargar y compilar parsers (Neovim core no trae descargador propio).
    -- Por eso el plugin se usa ÚNICAMENTE para eso (.install()); todo lo demás
    -- —resaltado, folds— corre 100% sobre la API nativa vim.treesitter.* de
    -- Neovim, sin pasar por wrappers del plugin.
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            local ts_langs = { "lua", "javascript", "typescript", "tsx", "html", "css", "json", "python", "bash", "markdown" }
            require("nvim-treesitter").install(ts_langs)  -- único uso del plugin: bajar/compilar parsers
            vim.api.nvim_create_autocmd("FileType", {
                pattern = ts_langs,
                callback = function()
                    -- pcall: install() es asíncrono, así que la primera vez que abrís
                    -- un archivo el parser puede no estar compilado todavía. Sin esto,
                    -- vim.treesitter.start() tira error duro en vez de fallar en silencio.
                    local ok = pcall(vim.treesitter.start)
                    if ok then
                        vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'       -- folds (100% nativo)
                        vim.wo.foldmethod = 'expr'
                        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" -- indentado (única excepción: Neovim core no trae motor de indentado propio basado en TS, usa este helper del plugin)
                    end
                end,
            })
        end
    },
    { "styled-components/vim-styled-components", branch = "main", ft = { "javascript", "typescriptreact" } },

    -- Edición y Productividad
    { "alvan/vim-closetag" },
    { "tpope/vim-surround" },
    { "tpope/vim-repeat" },
    { "tpope/vim-eunuch", cmd = { "Remove", "Rename", "Move", "Chmod" } },
    { "preservim/nerdcommenter" },
    { "terryma/vim-multiple-cursors" },
    { "easymotion/vim-easymotion" },
    { "editorconfig/editorconfig-vim" },

    -- Explorador de Archivos y Búsqueda (solo Telescope; se quitó fzf.vim por redundante)
    { "preservim/nerdtree", cmd = "NERDTreeToggle" },
    { "nvim-lua/plenary.nvim", lazy = true },
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.8",
        cmd = "Telescope",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" }, -- acelera Telescope con código nativo en C
        },
        config = function()
            require("telescope").setup({})
            pcall(require("telescope").load_extension, "fzf")
        end
    },

    -- Git y Terminal
    { "tpope/vim-fugitive", cmd = { "Git", "Gdiffsplit", "Gblame" } },
    { "mhinz/vim-signify" },
    { "benmills/vimux" },
    { "christoomey/vim-tmux-navigator" },

    -- LSP y Autocompletado (stack nativo, reemplaza a coc.nvim + ultisnips)
    { "williamboman/mason.nvim", config = true },
    { "williamboman/mason-lspconfig.nvim" },
    { "neovim/nvim-lspconfig" },
    { "hrsh7th/nvim-cmp" },
    { "hrsh7th/cmp-nvim-lsp" },
    { "hrsh7th/cmp-buffer" },
    { "hrsh7th/cmp-path" },
    { "L3MON4D3/LuaSnip" },
    { "saadparwaiz1/cmp_luasnip" },
    { "rafamadriz/friendly-snippets" },

    -- Calidad de vida / Pro
    { "windwp/nvim-autopairs", event = "InsertEnter", config = function() require("nvim-autopairs").setup({}) end },
    { "lewis6991/gitsigns.nvim", event = { "BufReadPre", "BufNewFile" }, config = function() require("gitsigns").setup() end },
    { "folke/which-key.nvim", event = "VeryLazy", opts = { preset = "modern" } },
    { "nvim-tree/nvim-web-devicons", lazy = true },
    {
        "akinsho/bufferline.nvim",
        version = "*",
        event = "VeryLazy",
        dependencies = "nvim-tree/nvim-web-devicons",
        config = function() require("bufferline").setup({}) end
    },
    {
        "rcarriga/nvim-notify",
        event = "VeryLazy",
        config = function()
            require("notify").setup({ background_colour = "#000000" })
            vim.notify = require("notify")
        end
    },

    -- Testing
    { "tyewang/vimux-jest-test" },
    { "janko-m/vim-test", cmd = { "TestNearest", "TestFile", "TestSuite" } },
})

-- ==========================================================================
-- 4. CONFIGURACIÓN DE LSP (mason + lspconfig + cmp)
-- ==========================================================================
require("mason-lspconfig").setup({
    ensure_installed = { "lua_ls", "ts_ls", "html", "cssls", "jsonls" },
})

local cmp = require("cmp")
local luasnip = require("luasnip")
require("luasnip.loaders.from_vscode").lazy_load()

cmp.setup({
    snippet = {
        expand = function(args) luasnip.lsp_expand(args.body) end,
    },
    mapping = cmp.mapping.preset.insert({
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        ["<Tab>"] = cmp.mapping.select_next_item(),
        ["<S-Tab>"] = cmp.mapping.select_prev_item(),
    }),
    sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" },
    }, {
        { name = "buffer" },
        { name = "path" },
    }),
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()
local lspconfig = require("lspconfig")
for _, server in ipairs({ "lua_ls", "ts_ls", "html", "cssls", "jsonls" }) do
    lspconfig[server].setup({ capabilities = capabilities })
end

vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = "Ir a definición" })
vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = "Documentación (hover)" })
vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = "Renombrar símbolo" })
vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = "Code action" })

-- ==========================================================================
-- 5. ATAJOS BÁSICOS
-- ==========================================================================
-- (el colorscheme ya se aplica dentro del config de Mofiqul/dracula.nvim, arriba)

-- Selección y edición
-- Ctrl+A: seleccionar todo el archivo y copiarlo al portapapeles del sistema
-- (reemplaza tu flujo manual de %y+). OJO: esto sobrescribe el atajo nativo
-- de Neovim para "incrementar número bajo el cursor" (Ctrl+A). Si lo usás
-- seguido, te recomiendo moverlo a otra tecla, p.ej. <leader>+ para incrementar.
vim.keymap.set('n', '<C-a>', 'ggVG"+y', { silent = true, desc = "Seleccionar todo y copiar" })
vim.keymap.set('i', '<C-a>', '<Esc>ggVG"+y', { silent = true, desc = "Seleccionar todo y copiar" })
-- Alternativa para no perder el incremento nativo de números:
vim.keymap.set('n', '<leader>+', '<C-a>', { silent = true, desc = "Incrementar número (antiguo Ctrl+A)" })

-- Atajos rápidos con la tecla líder
vim.keymap.set('n', '<leader>n', ':NERDTreeToggle<CR>', { silent = true })

-- Atajos para Telescope (buscador principal, ya sin fzf.vim duplicado)
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>f', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>g', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

-- Atajos para Bufferline (Navegar entre pestañas/buffers abiertos)
vim.keymap.set('n', '<S-l>', ':BufferLineCycleNext<CR>', { silent = true })
vim.keymap.set('n', '<S-h>', ':BufferLineCyclePrev<CR>', { silent = true })

-- ==========================================================================
-- 6. TRANSPARENCIA (Fondo transparente para integrarse con la terminal)
-- ==========================================================================
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
vim.api.nvim_set_hl(0, "CursorLineNr", { bg = "none" })

-- ==========================================================================
-- 7. GUÍA COMPLETA DE USO Y ATAJOS (Referencia Rápida en Neovim)
-- ==========================================================================
-- MODOS:
--   - Normal (ESC): Navegar, buscar, editar.
--   - Insertar (i, a, o): Escribir texto.
--   - Visual (v, Shift+v, Ctrl+v): Seleccionar texto / bloques.
--   - Comando (:): Guardar, salir, configurar.
--
-- ATAJOS CLAVE Y LÍDER (<leader> = Espacio):
--   - Ctrl + a            : Seleccionar TODO el archivo y copiarlo al portapapeles
--   - <leader> + +        : Incrementar número bajo el cursor (antiguo Ctrl+A)
--   - <leader>n           : Alternar árbol de archivos (NERDTreeToggle)
--   - <leader>f           : Buscar archivos (Telescope)
--   - <leader>g           : Buscar texto en proyecto (Telescope live_grep)
--   - <leader>fb          : Buscar entre buffers abiertos
--   - <leader>fh          : Buscar en la ayuda de Neovim
--   - gd                  : Ir a la definición (LSP)
--   - K                   : Ver documentación del símbolo (LSP hover)
--   - <leader>rn          : Renombrar símbolo (LSP)
--   - <leader>ca          : Code action (LSP)
--   - Ctrl + w + w        : Cambiar entre paneles (ej. de NERDTree al código)
--   - yy / p              : Copiar / pegar línea
--   - "+y / "+p           : Copiar / pegar desde/hacia el portapapeles (ya no es necesario a diario, ver clipboard=unnamedplus)
--   - u / Ctrl+r          : Deshacer / Rehacer
--   - :Goyo               : Modo Zen / Escritura sin distracciones
--   - :Remove / :Rename   : Borrar o renombrar archivo actual (Vim-Eunuch)
-- ==========================================================================