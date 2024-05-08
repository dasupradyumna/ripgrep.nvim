"------------------------------------------ PROMPT BUFFER -----------------------------------------"

" script guard
if exists('b:did_ftplugin') | finish | endif
let b:did_ftplugin = 1

" setup buffer as prompt
setlocal buftype=prompt
call prompt_setprompt(bufnr(), printf(' %s ', v:lua.require('ripgrep-nvim.config').options.prefix))

" disable <Enter> prompt callback
inoremap <buffer> <CR> <NOP>
" disable window navigation
inoremap <buffer> <C-W> <NOP>
" prevent exiting insert mode
inoremap <buffer> <C-O> <NOP>
inoremap <buffer> <C-\><C-G> <NOP>
inoremap <buffer> <C-\><C-N> <NOP>
inoremap <buffer> <C-\><C-O> <NOP>

let b:handlers = v:lua.require('ripgrep-nvim.handlers')

" exit search
inoremap <buffer> <Esc> <Cmd>call b:handlers.stop()<CR>
inoremap <buffer> <C-C> <Cmd>call b:handlers.stop()<CR>

" navigate results
inoremap <buffer> <C-N> <Cmd>call b:handlers.choose_entry(1)<CR>
inoremap <buffer> <C-P> <Cmd>call b:handlers.choose_entry(-1)<CR>

" go to preview
inoremap <buffer> <C-G>p <Cmd>call b:handlers.go_to('preview')<CR>

" prompt watcher
autocmd ripgrep_nvim TextChangedI,TextChangedP <buffer> call b:handlers.on_prompt_changed()
