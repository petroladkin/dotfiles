set nocompatible

" vim-plug bootstrap: auto-download if missing
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

"---------=== Code/project navigation ===-------------
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'ctrlpvim/ctrlp.vim'

"------------------=== Colors ===---------------------
Plug 'tomasr/molokai'

"-------------------=== Git ===-----------------------
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

"------------------=== Other ===----------------------
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'edkolev/tmuxline.vim'
Plug 'fisadev/FixedTaskList.vim'

call plug#end()


"=====================================================
" General settings
"=====================================================

syntax on
filetype plugin on

set encoding=utf-8
set term=xterm-256color

set relativenumber
set number
set ruler

" Tab settings
set smarttab
set tabstop=2
set softtabstop=0
set shiftwidth=2
set expandtab

let mapleader = ','

colorscheme molokai


"=====================================================
" Key bindings
"=====================================================

" Split navigation
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>


"=====================================================
" Plugin settings
"=====================================================

" NERDTree
nnoremap <Leader>n :NERDTreeToggle<CR>
let NERDTreeIgnore=['\.pyc$']

" CtrlP
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlPMixed'

" Vim-Airline
let g:airline_theme='luna'
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1

" TaskList
nnoremap <Leader>l :TaskList<CR>
