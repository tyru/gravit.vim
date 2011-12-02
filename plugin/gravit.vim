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



let g:ravit_prompt = get(g:, 'ravit_prompt', '⚡ ')

nnoremap <Plug>gravit->run :<C-u>call <SID>gravit_run()<CR>


function! s:gravit_run()
    call s:setup_highlight()
    let search_buf = ''
    let old_search_buf = ''
    let hl_manager = s:HighlightManager_new()
    let match_index = 0
    try
        while 1
            " Echo prompt.
            redraw
            echo "\r" . g:ravit_prompt . search_buf

            " Handle input char.
            let old_search_buf = search_buf
            let c = s:getchar()
            if c ==# "\<Esc>"
                break
            elseif c ==# "\<Tab>"
                let match_index =
                \   (match_index + 1)
                \   % len(s:match_as_possible(
                \       join(s:get_visible_lnums(), "\n"),
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

            " Update highlight.
            if search_buf !=# old_search_buf
                call hl_manager.update(search_buf, match_index)
            endif
        endwhile
    finally
        call hl_manager.unregister()
    endtry
endfunction

" HighlightManager {{{

function! s:HighlightManager_new()
    return {
    \   '__ids': {'search': -1, 'current_match': -1},
    \   'update': function('s:HighlightManager_update'),
    \   'unregister': function('s:HighlightManager_unregister'),
    \   'register': function('s:HighlightManager_register'),
    \}
endfunction

function! s:HighlightManager_update(search_buf, match_index) dict
    call self.unregister()
    call self.register(a:search_buf, a:match_index)
endfunction

function! s:HighlightManager_unregister() dict
    " Remove previous highlight.
    let ids = self.__ids
    for _ in keys(ids)
        if ids[_] >=# 0
            call matchdelete(ids[_])
            let ids[_] = -1
        endif
    endfor
endfunction

function! s:HighlightManager_register(search_buf, match_index) dict
    " Add highlight.
    let pos = s:search_pos(a:search_buf, a:match_index)
    if !empty(pos)
        let self.__ids.search
        \   = matchadd('GraVitSearch', a:search_buf)
        let self.__ids.current_match
        \   = matchadd('GraVitCurrentMatch', '\%'.pos[0].'l'.'\%'.pos[1].'v'.repeat('.', pos[2]))
    else
        redraw
        echohl WarningMsg
        echomsg 'No match: '.a:search_buf
        echohl None
    endif
endfunction

" }}}

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
    for lnum in s:get_visible_lnums()
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
    return map(s:get_visible_lnums(), 's:get_visible_line(v:val)')
endfunction

function! s:get_visible_line(lnum)
    return foldclosed(a:lnum) isnot -1 ?
    \           foldtextresult(a:lnum) :
    \           getline(a:lnum)
endfunction

function! s:get_visible_lnums()
    let lnum   = line('w0')
    let result = []
    while lnum <=# line('w$')
        call add(result, lnum)
        let lnum =
        \   foldclosed(lnum) isnot -1 ?
        \       foldclosedend(lnum) + 1 : lnum + 1
    endwhile
    return result
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
