" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! gravit#load()
    " dummy function to load this script.
endfunction

function! gravit#run(mode)
    let  hl_manager = s:HighlightManager_new()
    call hl_manager.setup()
    let  buffer = s:SearchBuffer_new()
    try
        while 1
            " Echo prompt.
            redraw
            echo "\r" . g:ravit_prompt . buffer.get_buffer()

            " Handle input char.
            let c = s:getchar()
            if c ==# "\<Esc>"
                return
            elseif c ==# "\<Tab>"
                call buffer.rotate_index()
            elseif c ==# "\<Return>"
                " Jump to the position.
                let pos = buffer.search()
                if !empty(pos)
                    if a:mode ==# 'v'
                        let dx = pos[1] - col('.')
                        let dy = pos[0] - line('.')
                        return
                        \   (dx isnot 0 ?
                        \       abs(dx) . (dx <# 0 ? 'h' : 'l') :
                        \       '') .
                        \   (dy isnot 0 ?
                        \       abs(dy) . (dy <# 0 ? 'k' : 'j') :
                        \       '')
                    else
                        call cursor(pos[0], pos[1])
                    endif
                else
                    redraw
                    echohl WarningMsg
                    echomsg 'No match: '.buffer.get_buffer()
                    echohl None
                endif
                return
            elseif c ==# "\<BS>" || c ==# "\<C-h>"
                call buffer.pop_buffer()
            else
                call buffer.push_buffer(c)
            endif

            " Update highlight.
            if buffer.has_changed()
                call hl_manager.update(buffer)
            endif
            call buffer.commit()

        endwhile
    finally
        call hl_manager.stop_highlight()
    endtry
endfunction


" HighlightManager {{{

function! s:HighlightManager_new()
    return {
    \   '__ids': {'search': -1, 'current_match': -1},
    \   'setup': function('s:HighlightManager_setup'),
    \   'update': function('s:HighlightManager_update'),
    \   'stop_highlight': function('s:HighlightManager_stop_highlight'),
    \   'start_highlight': function('s:HighlightManager_start_highlight'),
    \}
endfunction

function! s:HighlightManager_setup() dict
    if !hlexists('GraVitSearch')
        highlight GraVitSearch term=underline cterm=underline gui=underline ctermfg=4 guifg=Cyan
    endif
    if !hlexists('GraVitCurrentMatch')
        highlight GraVitCurrentMatch term=underline cterm=underline gui=underline ctermfg=4 guifg=Red
    endif
endfunction

function! s:HighlightManager_update(search_buf) dict
    call self.stop_highlight()
    call self.start_highlight(a:search_buf)
endfunction

function! s:HighlightManager_stop_highlight() dict
    " Remove previous highlight.
    let ids = self.__ids
    for _ in keys(ids)
        if ids[_] >=# 0
            call matchdelete(ids[_])
            let ids[_] = -1
        endif
    endfor
endfunction

function! s:HighlightManager_start_highlight(search_buf) dict
    let pos = a:search_buf.search()
    if empty(pos)
        return
    endif
    " Add highlight.
    let self.__ids.search
    \   = matchadd('GraVitSearch', a:search_buf.get_buffer())
    let self.__ids.current_match
    \   = matchadd('GraVitCurrentMatch', '\%'.pos[0].'l'.'\%'.pos[1].'v'.repeat('.', pos[2]))
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
    let old = self.__index
    let self.__index =
    \   (self.__index + 1)
    \   % len(s:match_pos_list(
    \       join(s:get_visible_lines(), "\n"),
    \       self.__buffer))
    if self.__index isnot old
        let self.__changed = 1
    endif
endfunction

function! s:SearchBuffer_search() dict
    return get(s:search_pos_list(self.__buffer), self.__index, [])
endfunction

function! s:SearchBuffer_has_changed() dict
    return self.__changed
endfunction

function! s:SearchBuffer_commit() dict
    let self.__changed = 0
endfunction


" }}}

" Return value: [[lnum, col, len], ...]
function! s:search_pos_list(search_buf)
    let result = []
    for lnum in filter(s:get_visible_lnums(), 'getline(v:val) =~# a:search_buf')
        for pos in s:match_pos_list(
        \               s:get_visible_line(lnum), a:search_buf)
            call add(result, [lnum] + pos)
        endfor
    endfor
    return result
endfunction

" Return value: [col, len]
function! s:match_pos_list(expr, pat)
    let [start, len] = s:match_with_len(a:expr, a:pat, 0)
    if start is -1
        return []
    endif
    " Add [col, len]
    let result = [[start + 1, len]]
    while 1
        let [start, len] = s:match_with_len(a:expr, a:pat, start + 1)
        if start is -1
            break
        endif
        " Add [col, len]
        call add(result, [start + 1, len])
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
    return [start, start isnot -1 ? call('matchend', a:000) - start : -1]
endfunction

function! s:getchar()
    let c = getchar()
    return type(c) is type("") ? c : nr2char(c)
endfunction


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
