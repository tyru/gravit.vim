" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Change Log: {{{
" }}}
" Document {{{
"
" Name: 
" Version: 0.0.0
" Author:  tyru <tyru.exe@gmail.com>
" Last Change: 2011-12-02.
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



nmap f <Plug>gravit->run
nnoremap <Plug>gravit->run :<C-u>call <SID>gravit_run()<CR>

function! s:gravit_run()
    call s:setup_highlight()
    let search_buf = ''
    let match_id = -1
    while 1
        " Echo prompt.
        redraw
        echo "\r⚡ " . search_buf
        " Remove previous highlight.
        if match_id >=# 0
            call matchdelete(match_id)
            let match_id = -1
        endif
        " Handle input char.
        let c = s:getchar()
        if c ==# "\<Esc>"
            break
        elseif c ==# "\<Return>"
            " TODO: Jump to the position.
            let idx = match(getline('w0', 'w$'), search_buf)
            if idx >=# 0
            else
                redraw
                echohl WarningMsg
                echomsg 'No match: '.search_buf
                echohl None
                " Fallback to '/' command.
                " call feedkeys("\<C-\>\<C-g>/".search_buf, 'n')
                " break
            endif
            break
        elseif c ==# "\<BS>" || c ==# "\<C-h>"
            let search_buf = search_buf[:-2]
        else
            let search_buf .= c
        endif
        " Add highlight.
        let match_id = matchadd('GraVitSearch', search_buf)
    endwhile
endfunction

function! s:setup_highlight()
    if !hlexists('GraVitSearch')
        highlight GraVitSearch term=underline cterm=underline gui=underline ctermfg=4 guifg=Cyan
    endif
    if !hlexists('GraVitCurrentMatch')
        highlight GraVitCurrentMatch term=underline cterm=underline gui=underline ctermfg=4 guifg=Red
    endif
endfunction

function! s:getchar()
    let c = getchar()
    return type(c) is type("") ? c : nr2char(c)
endfunction




" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
