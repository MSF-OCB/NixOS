with import <nixpkgs> {};

(vimUtils.makeCustomizable vim).customize {

  name = "vim";

  vimrcConfig = {

    customRC = ''
      set nocompatible
      set modeline
      set backspace=2
      set showmode
      set autoindent
      if has("autocmd")
        autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
          \| exe "normal! g`\"" | endif
        autocmd BufWritePre * :%s/\s\+$//e
      endif

      set encoding=utf-8
      set termencoding=utf-8

      if has('syntax')
        syntax on
      endif

      colorscheme desert

      set ruler
      set number

      if version >= 700
        set cursorline
      endif

      set laststatus=2
      set statusline=%-3.3n\ %f%(\ %r%)%(\ %#WarningMsg#%m%0*%)%=(%l/%L,\ %c)\ %P\ [%{&encoding}:%{&fileformat}]%(\ %w%)\ %y

      set shortmess+=axr

      set showmatch

      set tabstop=2
      set shiftwidth=2
      set softtabstop=2
      set expandtab
      set wrapmargin=0

      set nohlsearch
      set ignorecase
      set smartcase
      set incsearch

      filetype on
    '';

    packages.m.start = with pkgs.vimPlugins; [ vim-nix ];

  };

}

