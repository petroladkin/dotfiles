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
Plug 'vim-scripts/Pydiction'

"------------------=== Thrift ===---------------------
Plug 'solarnz/thrift.vim'

"------------------=== Other ===----------------------
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
"Plug 'edkolev/tmuxline.vim'

call plug#end()


"=====================================================
" General settings
"=====================================================

syntax on

filetype plugin on

set backspace=indent,eol,start
set relativenumber
set number
set ruler
"set ttyfast
set laststatus=2
set noshowmode
set encoding=utf-8
set term=xterm-256color
set scrolloff=4

set autoread

" Tab Settings
set smarttab
set tabstop=2
set softtabstop=0
set shiftwidth=2
set expandtab

set autoindent
set smartindent

set noswapfile

set ignorecase
set hidden
set hlsearch
set incsearch

set cursorline

let mapleader = ','

colorscheme molokai
set guifont=DejaVu\ Sans\ Mono\ for\ Powerline:h12

" Customize the wildmenu
set wildmenu
set wildignore+=*.dll,*.o,*.pyc,*.bak,*.exe,*.jpg,*.jpeg,*.png,*.gif,*$py.class,*.class,*/*.dSYM/*,*.dylib
set wildmode=list:full


" keys binding
"
" split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

nnoremap <Leader><Right> :bn<CR>
nnoremap <Leader><Left> :bp<CR>

imap df <Esc>l

" Use system clipboard
"if has('unnamedplus')
"  set clipboard=unnamed,unnamedplus
"endif

" Vim-Airline
let g:airline_theme='solarized'
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1

" NERDTree
nnoremap <Leader>n :NERDTreeToggle<CR>
let NERDTreeIgnore=['\.pyc$']

" Tagbar
nnoremap <Leader>t :TagbarToggle<CR>
let g:tagbar_autofocus = 1
let g:tagbar_sort = 0
let g:tagbar_foldlevel = 0

" CtrlP
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlPMixed'

" python-mode
let g:pymode_options = 0

" Pydiction
let g:pydiction_location = '~/.vim/plugged/Pydiction/complete-dict'
let g:pydiction_menu_height = 3



