" Specify a directory for plugins
" - For Neovim: stdpath('data') . '/plugged'
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

" Make sure you use single quotes

" Shorthand notation; fetches https://github.com/junegunn/vim-easy-align
Plug 'junegunn/vim-easy-align'

" Any valid git URL is allowed
Plug 'https://github.com/junegunn/vim-github-dashboard.git'

" Multiple Plug commands can be written in a single line using | separators
Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'

" On-demand loading
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'tpope/vim-fireplace', { 'for': 'clojure' }

" Using a non-master branch
Plug 'rdnetto/YCM-Generator', { 'branch': 'stable' }

" Using a tagged release; wildcard allowed (requires git 1.9.2 or above)
Plug 'fatih/vim-go', { 'tag': '*' }

" Plugin options
Plug 'nsf/gocode', { 'tag': 'v.20150303', 'rtp': 'vim' }

" Plugin outside ~/.vim/plugged with post-update hook
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }

" Airline
Plug 'vim-airline/vim-airline'

" Airline Themes
Plug 'vim-airline/vim-airline-themes'

" Powerline
Plug 'powerline/powerline'

" Gruvbox Theme
Plug 'morhetz/gruvbox'

" Monokai theme
Plug 'sickill/vim-monokai'

" Initialize plugin system
call plug#end()

" let g:gruvbox_contrast_dark = 'medium'
let g:airline_powerline_fonts = 1
let g:colors_name = "monokai"
au ColorScheme * hi Normal ctermbg=None
colorscheme monokai
let g:node_host_prog = '/usr/local/bin/neovim-node-host'
:set number
:set cursorline
:set cursorcolumn
:syntax enable
