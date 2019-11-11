" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 2.1.2
" ============================================================================

let s:job_id = -1
let s:timer_id = -1
let s:done = -1
let s:cancelled = 0
let s:start_render = 0
let s:start_ts = -1

let s:buffer = []
let s:consumed = 0

" IsSearching()
"
func! ctrlsf#async#IsSearching() abort
    return s:done > -1 && !ctrlsf#async#IsSearchDone()
endf

" IsSearchDone()
"
func! ctrlsf#async#IsSearchDone() abort
    return s:done == 1 && s:IsAllConsumed()
endf

" IsCancelled()
"
func! ctrlsf#async#IsCancelled() abort
    return s:cancelled
endf

" Reset()
"
func! ctrlsf#async#Reset() abort
    call ctrlsf#async#ForceStopSearch()

    let s:job_id = -1
    let s:timer_id = -1
    let s:done = -1
    let s:cancelled = 0
    let s:start_render = 0
    let s:start_ts = -1

    let s:buffer = []
    let s:consumed = 0
endf

" s:IsAllConsumed()
"
func! s:IsAllConsumed() abort
    return s:consumed >= len(s:buffer)
endf

" s:DiscardResult()
"
func! s:DiscardResult() abort
    let s:consumed = len(s:buffer)
    return
endf

" s:ConsumeResult()
"
" Consume at most {max} lines from result buffer.
"
func! s:ConsumeResult(max) abort
    if s:consumed < len(s:buffer)
        let start = s:consumed
        let end = s:consumed + a:max
        let lines = s:buffer[start:end]
        let s:consumed = s:consumed + len(lines)
        return lines
    else
        return []
    endif
endf

"""""""""""""""""""""""""""""""""
" Callback
"""""""""""""""""""""""""""""""""

" StartSearch()
"
" Start an async search process and a timely parser.
"
func! ctrlsf#async#StartSearch(command) abort
    let s:done = 0
    let s:start_ts = reltime()

    if has('nvim')
        let s:job_id = jobstart(a:command, {
                    \ 'on_stdout': "ctrlsf#async#NeoVimSearchCBWrapper",
                    \ 'on_stderr': "ctrlsf#async#NeoVimSearchCBWrapper",
                    \ 'on_exit': "ctrlsf#async#NeoVimSearchCBWrapper",
                    \ })
    else
        let s:job_id = job_start(a:command, {
                    \ 'out_cb': "ctrlsf#async#SearchCB",
                    \ 'err_cb': "ctrlsf#async#SearchErrorCB",
                    \ 'close_cb': "ctrlsf#async#SearchCloseCB",
                    \ 'out_mode': 'nl',
                    \ 'err_mode': 'raw',
                    \ 'in_io': 'null',
                    \ })
    endif
    let s:timer_id = timer_start(200, "ctrlsf#async#ParseAndDrawCB", {'repeat': -1})
    call ctrlsf#log#Debug("TimerStarted: id=%s", s:timer_id)
endf

" StopSearch()
"
" Stop a processing search.
"
func! ctrlsf#async#StopSearch() abort
    call ctrlsf#log#Debug("StopSearch")
    call s:StopJob()
    if ctrlsf#async#IsSearching()
        call s:DiscardResult()
        let s:cancelled = 1
        let s:done = 1
    endif
endf

" ParseAndDrawCB()
"
func! ctrlsf#async#ParseAndDrawCB(timer_id) abort
    let lines = s:ConsumeResult(g:ctrlsf_parse_speed)
    call ctrlsf#log#Debug("ConsumeResult: size=%s", len(lines))

    let done = ctrlsf#async#IsSearchDone()

    call ctrlsf#db#ParseBackendResultIncr(lines, done)
    call ctrlsf#win#DrawIncr()

    " focus first match for auto-focus-mode: 'at start'
    if s:start_render == 0
        let s:start_render = 1
        if ctrlsf#win#InMainWindow()
            call ctrlsf#win#FocusFirstMatch()
        endif
    endif

    if done
        call s:SearchDone()
    endif
endf

" SearchCB()
"
func! ctrlsf#async#SearchCB(channel, msg) abort
    call ctrlsf#log#Debug("ReceiveMessage: %s", a:msg)
    call add(s:buffer, a:msg)
endf

" SearchErrorCB()
"
func! ctrlsf#async#SearchErrorCB(channel, msg) abort
    call ctrlsf#log#Debug("ReceiveError: %s", a:msg)
    call ctrlsf#log#Error('Backend Failure. Error messages: %s', a:msg)
endf

" SearchCloseCB()
"
func! ctrlsf#async#SearchCloseCB(channel) abort
    " set state to 'done'
    let s:done = 1
    call ctrlsf#log#Debug("ChannelClose")
    call ctrlsf#profile#Sample("FinishSearch")
endf

func! ctrlsf#async#NeoVimSearchCBWrapper(job_id, data, event) abort
    if a:event == 'exit'
        call ctrlsf#async#SearchCloseCB('unused')
        return
    endif

    " The last value is always a blank line - unlike in Vim8
    call remove(a:data, -1)

    if a:event == 'stdout'
        for l:line in a:data
            call ctrlsf#async#SearchCB('unused', l:line)
        endfor
    elseif a:event == 'stderr'
        for l:line in a:data
            call ctrlsf#async#SearchErrorCB('unused', l:line)
        endfor
    endif
endf

" StopParse()
"
func! ctrlsf#async#StopParse() abort
    call s:StopTimer()
endf

" ForceStopSearch()
"
func! ctrlsf#async#ForceStopSearch() abort
  call s:StopJob()
  call s:StopTimer()
endfunc

" SearchDone()
"
func! s:SearchDone() abort
    call ctrlsf#async#StopParse()
    call ctrlsf#profile#Sample("FinishParse")

    call ctrlsf#win#SetModifiableByViewMode(1)
    call ctrlsf#PopulateQFList()

    " focus result pane if search is short lived
    if g:ctrlsf_auto_focus['at'] ==# 'done'
        " elapsed time in milliseconds
        let elapsed = float2nr(str2float(reltimestr(reltime(s:start_ts))) * 1000)
        call ctrlsf#log#Debug("ElapsedTime: %s", elapsed)
        let max_duration = g:ctrlsf_auto_focus['duration_less_than']
        if max_duration == -1 || elapsed < max_duration
            call ctrlsf#Focus()
        endif
    endif

    if !ctrlsf#async#IsCancelled()
        call ctrlsf#log#Notice("Done!")
    endif

    call ctrlsf#log#Debug("ParseFinish")
endf

" StopJob()
"
func! s:StopJob() abort
    call ctrlsf#log#Debug("StopJob")
    if type(s:job_id) != type(-1)
        if has('nvim')
            call jobstop(s:job_id)
        else
            call job_stop(s:job_id, "int")
        endif
    endif
endfunc

" StopTimer()
"
func! s:StopTimer() abort
  call ctrlsf#log#Debug("StopTimer: id=%s", s:timer_id)
  call timer_stop(s:timer_id)
endf
