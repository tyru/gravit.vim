" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Change Log: {{{
" }}}
" Document {{{
"
" Name: 
" Version: 0.0.0
" Author:  tyru <tyru.exe@gmail.com>
" Last Change: 2011-12-03.
" License: Distributable under the same terms as Vim itself (see :help license)
"
" Description:
"   NO DESCRIPTION YET
"
" Usage: {{{
"   Commands: {{{
"   }}}
"   Mappings: {{{
"   }}}
"   Global Variables: {{{
"   }}}
" }}}
" }}}

" Load Once {{{
if (exists('g:loaded_') && g:loaded_) || &cp
    finish
endif
let g:loaded_ = 1
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




" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
