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
    let hl_manager = s:HighlightManager_new()
    let buffer = s:SearchBuffer_new()
    try
        while 1
            " Echo prompt.
            redraw
            echo "\r" . g:ravit_prompt . buffer.get_buffer()

            " Handle input char.
            let c = s:getchar()
            if c ==# "\<Esc>"
                break
            elseif c ==# "\<Tab>"
                call buffer.rotate_index()
            elseif c ==# "\<Return>"
                " Jump to the position.
                let pos = buffer.search()
                if !empty(pos)
                    call cursor(pos[0], pos[1])
                else
                    redraw
                    echohl WarningMsg
                    echomsg 'No match: '.buffer.get_buffer()
                    echohl None
                endif
                break
            elseif c ==# "\<BS>" || c ==# "\<C-h>"
                call buffer.pop_buffer()
            else
                call buffer.push_buffer(c)
            endif

            " Update highlight.
            if buffer.has_changed()
                call hl_manager.update(buffer.get_buffer(), buffer.get_index())
            endif
            call buffer.commit()

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

" SearchBuffer {{{

function! s:SearchBuffer_new()
    return {
    \   '__buffer': '',
    \   '__index': 0,
    \   '__changed': 0,
    \
    \   'get_buffer': function('s:SearchBuffer_get_buffer'),
    \   'pop_buffer': function('s:SearchBuffer_pop_buffer'),
    \   'push_buffer': function('s:SearchBuffer_push_buffer'),
    \
    \   'get_index': function('s:SearchBuffer_get_index'),
    \   'rotate_index': function('s:SearchBuffer_rotate_index'),
    \
    \   'search': function('s:SearchBuffer_search'),
    \
    \   'has_changed': function('s:SearchBuffer_has_changed'),
    \   'commit': function('s:SearchBuffer_commit'),
    \}
endfunction

function! s:SearchBuffer_get_buffer() dict
    return self.__buffer
endfunction

function! s:SearchBuffer_pop_buffer() dict
    let self.__buffer = self.__buffer[:-2]
    let self.__changed = 1
endfunction

function! s:SearchBuffer_push_buffer(c) dict
    let self.__buffer .= a:c
    let self.__changed = 1
endfunction

function! s:SearchBuffer_get_index() dict
    return self.__index
endfunction

function! s:SearchBuffer_rotate_index() dict
    let self.__index =
    \   (self.__index + 1)
    \   % len(s:match_as_possible(
    \       join(s:get_visible_lines(), "\n"),
    \       self.__buffer))
    let self.__changed = 1
endfunction

function! s:SearchBuffer_search() dict
    return s:search_pos(self.__buffer, self.__index)
endfunction

function! s:SearchBuffer_has_changed() dict
    return self.__changed
endfunction

function! s:SearchBuffer_commit() dict
    let self.__changed = 0
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
    for lnum in filter(s:get_visible_lnums(), 'getline(v:val) =~# a:search_buf')
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
