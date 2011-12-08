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
nnoremap        <Plug>gravit->forward   :<C-u>call gravit#run('n', 1)<CR>
onoremap        <Plug>gravit->forward   :<C-u>call gravit#run('o', 1)<CR>
vnoremap <expr> <Plug>gravit->forward   gravit#run('v', 1)

nnoremap        <Plug>gravit->backward  :<C-u>call gravit#run('n', 0)<CR>
onoremap        <Plug>gravit->backward  :<C-u>call gravit#run('o', 0)<CR>
vnoremap <expr> <Plug>gravit->backward  gravit#run('v', 0)

" Highlights
highlight! link GraVitSearch Search
highlight! link GraVitCurrentMatch Visual




" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
