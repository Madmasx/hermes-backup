set number
set mouse=a
set numberwidth=1
set clipboard=unnamedplus
if has('wsl')
  " config for wsl if needed
elseif executable('wl-copy')
  let g:clipboard = {
        \ 'name': 'wl-clipboard',
        \ 'copy': {
        \    '+': 'wl-copy',
        \    '*': 'wl-copy',
        \ },
        \ 'paste': {
        \    '+': 'wl-paste --no-newline',
        \    '*': 'wl-paste --no-newline',
        \ },
        \ 'cache_enabled': 1,
        \ }
endif
syntax on
set showcmd
set ruler
set cursorline
set encoding=utf-8
set showmatch
set termguicolors
set sw=2
set relativenumber
so ~/.vim/plugins.vim
so ~/.vim/plugin-config.vim
so ~/.vim/maps.vim

colorscheme dracula
highlight Normal guibg=NONE ctermbg=NONE
highlight NonText guibg=NONE ctermbg=NONE
highlight LineNr guibg=NONE ctermbg=NONE
highlight SignColumn guibg=NONE ctermbg=NONE
highlight EndOfBuffer guibg=NONE ctermbg=NONE
set laststatus=2
set noshowmode

au BufNewFile,BufRead *.html set filetype=htmldjango
lua require'colorizer'.setup()

"" Searching
set hlsearch                    " highlight matches
set incsearch                   " incremental searching
set ignorecase                  " searches are case insensitive...
set smartcase                   " ... unless they contain at least one capital letter



" --- Configuracion para Vim Clasico (Wildmenu + NERDTree) ---
set nocompatible
filetype plugin indent on
syntax on

" Wildmenu mejorado para autocompletar comandos y rutas
set wildmenu
set wildmode=longest:full,full
set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx

" Instalar vim-plug automaticamente si no existe
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Plugins
call plug#begin('~/.vim/plugged')
Plug 'preservim/nerdtree'
call plug#end()

" Atajo para abrir/cerrar NERDTree con Ctrl+n (o la tecla que prefieras)
nnoremap <C-n> :NERDTreeToggle<CR>

" Abrir NERDTree automaticamente si no se paso ningun archivo al iniciar vim
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists('s:std_in') && v:this_session == '' | NERDTree | endif
