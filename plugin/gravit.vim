" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Load Once {{{
if (exists('g:loaded_gravit') && g:loaded_gravit) || &cp
    finish
endif
let g:loaded_gravit = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



" Global variables
let g:ravit_prompt = get(g:, 'ravit_prompt', '⚡ ')

" Keymappings
nnoremap        <Plug>gravit->run :<C-u>call gravit#run('n')<CR>
onoremap        <Plug>gravit->run :<C-u>call gravit#run('o')<CR>
vnoremap <expr> <Plug>gravit->run gravit#run('v')

" Highlights
highlight! link GraVitSearch Search
highlight! link GraVitCurrentMatch Visual




" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
