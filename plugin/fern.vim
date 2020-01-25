if exists('g:fern_loaded')
  finish
endif
let g:fern_loaded = 1

command! -nargs=*
      \ -complete=customlist,fern#command#fern#complete
      \ Fern
      \ call fern#command#fern#command(<q-mods>, <q-args>)

command! -nargs=*
      \ -complete=customlist,fern#command#focus#complete
      \ FernFocus
      \ call fern#command#focus#command(<q-mods>, <q-args>)

augroup fern_internal
  autocmd! *
  autocmd BufReadCmd fern:*/* nested call fern#internal#viewer#init()
augroup END

let g:fern_debug = get(g:, 'fern_debug', 0)
