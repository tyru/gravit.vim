" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! gravit#load()
    " dummy function to load this script.
endfunction

function! gravit#run(mode, forward)
    let dest_pos   = {
    \   'winnr': winnr(),
    \   'lnum': line('.'),
    \   'col': virtcol('.'),
    \}
    let hl_manager = s:HighlightManager_new()
    let buffer     = s:SearchBuffer_new()
    try
        while 1
            " Echo prompt.
            redraw
            echo "\r" . g:ravit_prompt . buffer.get_buffer()

            " Handle input char.
            let c = s:getchar()
            " TODO: Make keys configurable.
            if c ==# "\<Esc>"
                return
            elseif c ==# "\<Tab>"
                call buffer.rotate_index()
            elseif c ==# "\<Return>"
                " Jump to the position.
                let pos = buffer.get_position()
                if !empty(pos)
                    if a:mode ==# 'v'
                        if winnr() isnot pos.winnr
                            return ''
                        endif
                        let dx = pos.col - col('.')
                        let dy = pos.lnum - line('.')
                        return
                        \   (dx isnot 0 ?
                        \       abs(dx) . (dx <# 0 ? 'h' : 'l') :
                        \       '') .
                        \   (dy isnot 0 ?
                        \       abs(dy) . (dy <# 0 ? 'k' : 'j') :
                        \       '')
                    else
                        let dest_pos.winnr = pos.winnr
                        let dest_pos.lnum  = pos.lnum
                        let dest_pos.col   = pos.col
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

            if buffer.has_changed()
                " Select match after current pos.
                if c !=# "\<Tab>"
                    call buffer.adjust_index(a:forward)
                endif
                " Update highlight.
                call hl_manager.update(buffer)
            endif
            call buffer.commit()
        endwhile
    finally
        call hl_manager.stop_highlight()
        " Move to destination.
        " XXX: Also work on visual-mode?
        execute dest_pos.winnr 'wincmd w'
        call cursor(dest_pos.lnum, dest_pos.col)
    endtry
endfunction


" HighlightManager {{{

function! s:HighlightManager_new()
    return {
    \   '__highlighted': 0,
    \
    \   'update': function('s:HighlightManager_update'),
    \   'stop_highlight': function('s:HighlightManager_stop_highlight'),
    \   'start_highlight': function('s:HighlightManager_start_highlight'),
    \}
endfunction

function! s:HighlightManager_update(search_buf) dict
    call self.stop_highlight()
    call self.start_highlight(a:search_buf)
endfunction

function! s:HighlightManager_stop_highlight() dict
    if !self.__highlighted
        return
    endif
    " Remove previous highlight.
    windo call s:HighlightManager_remove_highlight()
    let self.__highlighted = 0
endfunction

function! s:HighlightManager_remove_highlight()
    for _ in getmatches()
        if _.group ==# 'GraVitSearch'
        \   || _.group ==# 'GraVitCurrentMatch'
            call matchdelete(_.id)
        endif
    endfor
endfunction

function! s:HighlightManager_start_highlight(search_buf) dict
    if self.__highlighted
        return
    endif
    let pos = a:search_buf.get_position()
    if empty(pos)
        return
    endif
    " Add highlight.
    windo call s:HighlightManager_add_highlight(a:search_buf, pos)
    let self.__highlighted = 1
endfunction

function! s:HighlightManager_add_highlight(search_buf, pos)
    call matchadd('GraVitSearch', a:search_buf.get_buffer())
    if winnr() is a:pos.winnr
        call matchadd('GraVitCurrentMatch',
        \               '\%' . a:pos.lnum . 'l'
        \             . '\%' . a:pos.col . 'v'
        \             . a:search_buf.make_pattern())
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
    \   'adjust_index': function('s:SearchBuffer_adjust_index'),
    \
    \   'get_position': function('s:SearchBuffer_get_position'),
    \   'make_pattern': function('s:SearchBuffer_make_pattern'),
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
    \   % len(s:win_search_pos_list(self.make_pattern()))
    if self.__index isnot old
        let self.__changed = 1
    endif
endfunction

function! s:SearchBuffer_adjust_index(forward) dict
    let curpos = {
    \   'lnum': line('.'),
    \   'col': virtcol('.'),
    \   'winnr': winnr(),
    \}
    let pos_list = s:win_search_pos_list(self.make_pattern())
    let index = 0
    for index in range(len(pos_list))
        if curpos.winnr <# pos_list[index].winnr
        \   || curpos.lnum <# pos_list[index].lnum
        \   || curpos.lnum is pos_list[index].lnum
        \   && curpos.col <# pos_list[index].col
            " Overtake current position.
            " `pos_list[index]` must be the
            " right of current position.
            break
        endif
    endfor
    if a:forward
        let self.__index = index
    else
        if index isnot 0
        \   && curpos.lnum is pos_list[index-1].lnum
        \   && curpos.col is pos_list[index-1].col
            let self.__index = index ># 1 ? index - 2 : 0
        else
            let self.__index = index ># 0 ? index - 1 : 0
        endif
    endif
endfunction

function! s:SearchBuffer_get_position() dict
    return get(s:win_search_pos_list(self.make_pattern()), self.__index, [])
endfunction

function! s:SearchBuffer_make_pattern() dict
    let ic =
    \   &ignorecase
    \   && !(&smartcase && self.__buffer =~# '[A-Z]')
    return
    \   self.__buffer
    \   . (ic ? '\c' : '\C')
endfunction

function! s:SearchBuffer_has_changed() dict
    return self.__changed
endfunction

function! s:SearchBuffer_commit() dict
    let self.__changed = 0
endfunction


" }}}

" Return value: [{winnr: ..., lnum: ..., col: ..., len: ...}, ...]
" Positions are sorted by left to right, up to down.
function! s:win_search_pos_list(search_buf)
    let _ = []
    windo let _ +=
    \   map(s:search_pos_list(a:search_buf),
    \       'extend(v:val, {"winnr": winnr()}, "error")')
    return _
endfunction

" Return value: [{lnum: ..., col: ..., len: ...}, ...]
" Positions are sorted by left to right, up to down.
function! s:search_pos_list(search_buf)
    let result = []
    for lnum in s:get_visible_lnums()
        let line = s:get_visible_line(lnum)
        if line !~# a:search_buf
            continue
        endif
        for pos in s:match_pos_list(line, a:search_buf)
            let pos.lnum = lnum
            call add(result, pos)
        endfor
    endfor
    return result
endfunction

" Return value: [{col: ..., len: ...}, ...]
function! s:match_pos_list(expr, pat)
    let result = []
    let start = 0
    while 1
        let [start, len] = s:match_with_len(a:expr, a:pat, start)
        if start is -1
            break
        endif
        call add(result, {'col': start + 1, 'len': len})
        " Search next match.
        let start += 1
    endwhile
    return result
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
