set nocompatible 

call plug#begin('~/.vim/plugged')

"---------=== Code/project navigation ===-------------
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'ctrlpvim/ctrlp.vim'
Plug 'majutsushi/tagbar'
Plug 'rking/ag.vim'

"------------------=== Colors ===---------------------
Plug 'tomasr/molokai'

"-------------------=== Git ===-----------------------
Plug 'tpope/vim-fugitive'

"------------------=== Python ===---------------------
Plug 'python-mode/python-mode'
Plug 'jmcantrell/vim-virtualenv'

"------------------=== Other ===----------------------
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
"Plug 'edkolev/tmuxline.vim'

call plug#end()

"=====================================================
" General settings
"=====================================================

"set backspace=indent,eol,start
" This must happen before the syntax system is enabled
"aunmenu Help.
"aunmenu Window.
"let no_buffers_menu=1
"set mousemodel=popup
"if has('mouse')
"    set mouse=a
"    set ttymouse=xterm2
"endif

syntax on

set relativenumber
set number
set ruler
set ttyfast
set laststatus=2
set noshowmode
set encoding=utf-8
set term=xterm-256color

colorscheme molokai
set guifont=DejaVu\ Sans\ Mono\ for\ Powerline:h12


"set completeopt-=preview
"set gcr=a:blinkon0
"if has("gui_running")
"    set cursorline
"endif

" Enable Syntax Colors
" in GUI mode we go with fruity and Monaco 13
" in CLI mode myterm looks better (fruity is GUI only)
"if has("gui_running")
"    set macmeta
"    set lines=50 columns=125
"endif
" special settings for vim
"if has("mac")
"    let macvim_hig_shift_movement = 1
"endif

" Customize the wildmenu
set wildmenu
set wildignore+=*.dll,*.o,*.pyc,*.bak,*.exe,*.jpg,*.jpeg,*.png,*.gif,*$py.class,*.class,*/*.dSYM/*,*.dylib
set wildmode=list:full

" split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Hide some panels
"set guioptions-=m   " remove menu bar
"set guioptions-=T   " remove toolbar
"set guioptions-=r   " remove right-hand scroll bar

" Vim-Airline
let g:airline_theme='solarized'
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1

" Use system clipboard
set clipboard=unnamedplus

" Tab Settings
set smarttab
set tabstop=2

let mapleader = ','

" NERDTree
map <leader>n :NERDTreeToggle<CR>

" Tagbar
map <leader>t :TagbarToggle<CR>
let g:tagbar_autofocus = 1
let g:tagbar_sort = 0
let g:tagbar_foldlevel = 0

" CtrlP
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlPMixed'

