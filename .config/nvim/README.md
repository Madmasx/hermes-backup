# Neovim Config

Configuración personal de Neovim de [@madmasx](https://github.com/madmasx).

Tema **Dracula** con un stack moderno y 100% nativo (`nvim-lspconfig`, `mason`, `nvim-cmp`, `telescope` y Treesitter).

## Requisitos y Versión de Neovim

Neovim debe mantenerse actualizado a la versión más reciente para garantizar la compatibilidad con las APIs modernas y plugins.

Para instalar o actualizar Neovim en tu sistema (Linux x86_64), ejecutá el siguiente comando en la terminal:

```bash
cd ~/.local/bin  # o donde tengas tu PATH de usuario; creá el directorio si no existe
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
chmod u+x nvim-linux-x86_64.appimage
mv nvim-linux-x86_64.appimage nvim
```

## Estructura

```
.
├── init.lua           # Configuración principal integrada
└── lazy-lock.json     # Lockfile de lazy.nvim
```

## Créditos

Configuración creada por [@madmasx](https://github.com/madmasx) y Hermes (asistente IA), en colaboración.
