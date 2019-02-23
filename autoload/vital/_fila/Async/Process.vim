" ___vital___
" NOTE: lines between '" ___vital___' is generated by :Vitalize.
" Do not mofidify the code nor insert new lines before '" ___vital___'
function! s:_SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
endfunction
execute join(['function! vital#_fila#Async#Process#import() abort', printf("return map({'_vital_depends': '', 'start': '', '_vital_created': '', 'new': '', '_vital_loaded': ''}, \"vital#_fila#function('<SNR>%s_' . v:key)\")", s:_SID()), 'endfunction'], "\n")
delfunction s:_SID
" ___vital___
function! s:_vital_created(module) abort
  let a:module.operators = {
        \ 'focus': { -> call(s:Process.operators.focus, a:000, s:Process.operators) },
        \ 'squash': { -> call(s:Process.operators.squash, a:000, s:Process.operators) },
        \ 'stretch': { -> call(s:Process.operators.stretch, a:000, s:Process.operators) },
        \ 'pile': { -> call(s:Process.operators.pile, a:000, s:Process.operators) },
        \ 'line': { -> call(s:Process.operators.line, a:000, s:Process.operators) },
        \}
  echohl Error
  echo 'vital: Async.Process is deprecated. Use Async.Observable.Process instead.'
  echohl None
endfunction

function! s:_vital_loaded(V) abort
  let s:Process = a:V.import('Async.Observable.Process')
endfunction

function! s:_vital_depends() abort
  return ['Async.Observable.Process']
endfunction

function! s:new(...) abort
  return call(s:Process.new, a:000, s:Process)
endfunction

function! s:start(...) abort
  return call(s:Process.start, a:000, s:Process)
endfunction