" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.9.0
" ============================================================================

let s:job_id = -1
let s:timer_id = -1
let s:done = -1

let s:buffer = []
let s:consumed = 0

func! ctrlsf#async#IsSearching() abort
    return s:done == 0
endf

func! ctrlsf#async#IsSearchDone() abort
    return s:done == 1
endf

func! ctrlsf#async#Reset() abort
    let s:job_id = -1
    let s:timer_id = -1
    let s:done = -1

    let s:buffer = []
    let s:consumed = 0
endf

func! ctrlsf#async#IsAllConsumed() abort
    return s:consumed >= len(s:buffer)
endf

func! ctrlsf#async#DiscardResult() abort
    let s:consumed = len(s:buffer)
    return
endf

func! ctrlsf#async#ConsumeResult(max) abort
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

func! ctrlsf#async#StartSearch(command) abort
    let s:done = 0

    " FIXME: not compatible for Windows
    let s:job_id = job_start(a:command,
                \ {'callback': "ctrlsf#async#SearchCB", 'close_cb': "ctrlsf#async#SearchCloseCB"})

    let s:timer_id = timer_start(200, "ctrlsf#async#ParseAndDrawCB", {'repeat': -1})
    call ctrlsf#log#Debug("TimerStarted: id=%s", s:timer_id)
endf

func! ctrlsf#async#StopSearch() abort
    if type(s:job_id) != type(-1)
        let stopped = job_stop(s:job_id, "int")
        if stopped
            call ctrlsf#async#DiscardResult()
            let s:done = 1
        else
            call ctrlsf#log#Error("Failed to stop Job.")
        endif
    endif
endf

func! ctrlsf#async#StopParse() abort
    call ctrlsf#log#Debug("StopTimer: id=%s", s:timer_id)
    call timer_stop(s:timer_id)
endf

func! ctrlsf#async#ParseAndDrawCB(timer_id) abort
    let lines = ctrlsf#async#ConsumeResult(300)
    call ctrlsf#log#Debug("ConsumeResult: size=%s", len(lines))

    let done = ctrlsf#async#IsSearchDone() && ctrlsf#async#IsAllConsumed()

    if !empty(lines)
        if ctrlsf#win#FindMainWindow() == -1
            call ctrlsf#win#OpenMainWindow()
            call ctrlsf#buf#WriteString("")
            call ctrlsf#hl#ReloadSyntax()
            call ctrlsf#hl#HighlightMatch()
            call ctrlsf#buf#ClearUndoHistory()
        endif

        call ctrlsf#db#ParseBackendResultIncr(lines, done)
        call ctrlsf#win#DrawIncr()
    end

    if done
        call ctrlsf#async#StopParse()
        call ctrlsf#profile#Sample("FinishParse")

        if ctrlsf#win#FocusMainWindow() != -1
            " make buffer modifiable
            if ctrlsf#CurrentMode() ==# 'normal'
                setl modifiable
            endif
        endif

        call ctrlsf#log#Notice("Done!")
    endif
endf

func! ctrlsf#async#SearchCB(channel, msg) abort
    call ctrlsf#log#Debug("ReceiveMessage: %s", a:msg)
    call add(s:buffer, a:msg)
endf

func! ctrlsf#async#SearchCloseCB(channel) abort
    let s:done = 1
    call ctrlsf#profile#Sample("FinishSearch")
endf
