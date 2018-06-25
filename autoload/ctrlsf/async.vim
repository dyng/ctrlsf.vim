" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 2.0.0
" ============================================================================

let s:job_id = -1
let s:timer_id = -1
let s:done = -1
let s:cancelled = 0

let s:buffer = []
let s:consumed = 0

" IsSearching()
"
func! ctrlsf#async#IsSearching() abort
    return !ctrlsf#async#IsSearchDone()
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
    let s:job_id = -1
    let s:timer_id = -1
    let s:done = -1
    let s:cancelled = 0

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
    " set state to 'searching'
    let s:done = 0
    let s:job_id = job_start(a:command, {
                \ 'out_cb': "ctrlsf#async#SearchCB",
                \ 'err_cb': "ctrlsf#async#SearchErrorCB",
                \ 'close_cb': "ctrlsf#async#SearchCloseCB",
                \ 'out_mode': 'nl',
                \ 'err_mode': 'raw',
                \ 'in_io': 'null',
                \ })
    let s:timer_id = timer_start(200, "ctrlsf#async#ParseAndDrawCB", {'repeat': -1})
    call ctrlsf#log#Debug("TimerStarted: id=%s", s:timer_id)
endf

" StopSearch()
"
" Stop a processing search.
"
func! ctrlsf#async#StopSearch() abort
    if type(s:job_id) != type(-1)
        let stopped = job_stop(s:job_id, "int")
        if stopped
            call s:DiscardResult()
            let s:cancelled = 1
            let s:done = 1
        else
            call ctrlsf#log#Error("Failed to stop Job.")
        endif
    endif
endf

" ParseAndDrawCB()
"
func! ctrlsf#async#ParseAndDrawCB(timer_id) abort
    let lines = s:ConsumeResult(g:ctrlsf_parse_speed)
    call ctrlsf#log#Debug("ConsumeResult: size=%s", len(lines))

    let done = ctrlsf#async#IsSearchDone() && s:IsAllConsumed()

    call ctrlsf#db#ParseBackendResultIncr(lines, done)
    call ctrlsf#win#DrawIncr()

    if done
        call ctrlsf#async#StopParse()
        call ctrlsf#profile#Sample("FinishParse")
        call ctrlsf#win#SetModifiableByViewMode(1)
        if !ctrlsf#async#IsCancelled()
            call ctrlsf#log#Notice("Done!")
        endif
        call ctrlsf#log#Debug("ParseFinish")
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

" StopParse()
"
func! ctrlsf#async#StopParse() abort
    call ctrlsf#log#Debug("StopTimer: id=%s", s:timer_id)
    call timer_stop(s:timer_id)
endf
