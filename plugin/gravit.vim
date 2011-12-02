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



nnoremap <Plug>gravit->run :<C-u>call <SID>gravit_run()<CR>


function! s:gravit_run()
    call s:setup_highlight()
    let search_buf = ''
    let ids = {'search': -1, 'current_match': -1}
    let match_index = 0
    while 1
        " Echo prompt.
        redraw
        echo "\r⚡ " . search_buf
        " Remove previous highlight.
        for _ in keys(ids)
            if ids[_] >=# 0
                call matchdelete(ids[_])
                let ids[_] = -1
            endif
        endfor

        " Handle input char.
        let c = s:getchar()
        if c ==# "\<Esc>"
            break
        elseif c ==# "\<Tab>"
            let match_index =
            \   (match_index + 1)
            \   % len(s:match_as_possible(
            \       join(s:get_visible_lines(), "\n"),
            \       search_buf))
        elseif c ==# "\<Return>"
            " Jump to the position.
            let pos = s:search_pos(search_buf, match_index)
            if !empty(pos)
                call cursor(pos[0], pos[1])
            else
                redraw
                echohl WarningMsg
                echomsg 'No match: '.search_buf
                echohl None
            endif
            break
        elseif c ==# "\<BS>" || c ==# "\<C-h>"
            let search_buf = search_buf[:-2]
        else
            let search_buf .= c
        endif
        " Add highlight.
        let pos = s:search_pos(search_buf, match_index)
        if !empty(pos)
            let ids.search
            \   = matchadd('GraVitSearch', search_buf)
            let ids.current_match
            \   = matchadd('GraVitCurrentMatch', '\%'.pos[0].'l'.'\%'.pos[1].'v'.repeat('.', pos[2]))
        else
            redraw
            echohl WarningMsg
            echomsg 'No match: '.search_buf
            echohl None
        endif
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

function! s:search_pos(search_buf, skip_num)
    let skip_num = a:skip_num
    " Get lnums of matched lines.
    for lnum in filter(
    \   range(line('w0'), line('w$')),
    \   'getline(v:val) =~# a:search_buf'
    \)
        " Get the col at where a:search_buf matched.
        let idx = 0
        let [idx, len] = s:match_with_len(getline(lnum), a:search_buf, idx)
        while skip_num isnot 0 && idx isnot -1
            let [idx, len] = s:match_with_len(getline(lnum), a:search_buf, idx + 1)
            let skip_num -= 1
        endwhile
        if skip_num is 0
            return [lnum, idx + 1, len]
        endif
    endfor
    return []
endfunction

function! s:match_as_possible(expr, pat)
    let result = []
    let start = 0
    while start isnot -1
        let start = match(a:expr, a:pat, start is 0 ? 0 : start + 1)
        if start is -1
            break
        endif
        call add(result, start)
    endwhile
    return result
endfunction

function! s:get_visible_lines()
    let lnum = line('w0')
    let lines = []
    while lnum <=# line('w$')
        if foldclosed(lnum) isnot -1
            " Folding is closed.
            call add(lines, foldtextresult(lnum))
            let lnum  = foldclosedend(lnum) + 1
        else
            call add(lines, getline(lnum))
            let lnum += 1
        endif
    endwhile
    return lines
endfunction

function! s:match_with_len(...)
    let start = call('match', a:000)
    return [start, call('matchend', a:000) - start]
endfunction

function! s:getchar()
    let c = getchar()
    return type(c) is type("") ? c : nr2char(c)
endfunction




" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
