let s:Promise = vital#fila#import('Async.Promise')
let s:Lambda = vital#fila#import('Lambda')
let s:Revelator = vital#fila#import('App.Revelator')
let s:BufferWriter = vital#fila#import('Vim.Buffer.Writer')
let s:WindowCursor = vital#fila#import('Vim.Window.Cursor')
let s:Config = vital#fila#import('Config')

let s:STATUS_COLLAPSED = g:fila#node#STATUS_COLLAPSED
let s:STATUS_EXPANDED = g:fila#node#STATUS_EXPANDED

function! fila#node#helper#new(...) abort
  let bufnr = a:0 ? a:1 : bufnr('%')
  if exists('s:helper')
    return extend(copy(s:helper), {
          \ 'bufnr': bufnr,
          \ 'renderer': g:fila#node#helper#renderer,
          \ 'comparator': g:fila#node#helper#comparator,
          \})
  endif
  let s:helper = {
        \ 'get_nodes': funcref('s:get_nodes'),
        \ 'set_nodes': funcref('s:set_nodes'),
        \ 'get_marks': funcref('s:get_marks'),
        \ 'set_marks': funcref('s:set_marks'),
        \ 'get_hidden': funcref('s:get_hidden'),
        \ 'set_hidden': funcref('s:set_hidden'),
        \ 'get_root_node': funcref('s:get_root_node'),
        \ 'get_visible_nodes': funcref('s:get_visible_nodes'),
        \ 'get_marked_nodes': funcref('s:get_marked_nodes'),
        \ 'get_cursor_node': funcref('s:get_cursor_node'),
        \ 'get_selection_nodes': funcref('s:get_selection_nodes'),
        \ 'init': funcref('s:init'),
        \ 'redraw': funcref('s:redraw'),
        \ 'enter': funcref('s:enter'),
        \ 'cursor': funcref('s:cursor'),
        \ 'reload': funcref('s:reload'),
        \ 'expand': funcref('s:expand'),
        \ 'collapse': funcref('s:collapse'),
        \ 'enter_node': funcref('s:enter_node'),
        \ 'cursor_node': funcref('s:cursor_node'),
        \ 'reload_node': funcref('s:reload_node'),
        \ 'expand_node': funcref('s:expand_node'),
        \ 'collapse_node': funcref('s:collapse_node'),
        \}
  return extend(copy(s:helper), {
        \ 'bufnr': bufnr,
        \ 'renderer': g:fila#node#helper#renderer,
        \ 'comparator': g:fila#node#helper#comparator,
        \})
endfunction

" Getter/Setter
function! s:get_nodes() abort dict
  if !bufexists(self.bufnr)
    throw s:Revelator.error(printf(
          \ 'given buffer does not exist: %d',
          \ self.bufnr,
          \))
  endif
  let nodes = getbufvar(self.bufnr, 'fila_nodes', v:null)
  if nodes is# v:null
    throw s:Revelator.error(printf(
          \ 'given buffer does not have nodes: %d',
          \ self.bufnr,
          \))
  endif
  return nodes
endfunction

function! s:set_nodes(value) abort dict
  if !bufexists(self.bufnr)
    throw s:Revelator.error(printf(
          \ 'given buffer does not exist: %d',
          \ self.bufnr,
          \))
  endif
  call setbufvar(self.bufnr, 'fila_nodes', a:value)
endfunction

function! s:get_marks() abort dict
  if !bufexists(self.bufnr)
    throw s:Revelator.error(printf(
         \ 'given buffer does not exist: %d',
         \ self.bufnr,
         \))
  endif
  return getbufvar(self.bufnr, 'fila_marks', [])
endfunction

function! s:set_marks(value) abort dict
  if !bufexists(self.bufnr)
    throw s:Revelator.error(printf(
         \ 'given buffer does not exist: %d',
         \ self.bufnr,
         \))
  endif
  call setbufvar(self.bufnr, 'fila_marks', a:value)
endfunction

function! s:get_hidden() abort dict
  return get(g:, 'fila_hidden', 0)
endfunction

function! s:set_hidden(value) abort dict
  let g:fila_hidden = a:value
endfunction

" Getter
function! s:get_root_node() abort dict
  let nodes = self.get_nodes()
  return nodes[0]
endfunction

function! s:get_visible_nodes() abort dict
  let nodes = self.get_nodes()
  let hidden = self.get_hidden()
  if hidden
    return copy(nodes)
  else
    return filter(
          \ copy(nodes),
          \ { _, v -> !v.hidden || fila#node#is_expanded(v) },
          \)
  endif
endfunction

function! s:get_marked_nodes() abort dict
  let nodes = self.get_visible_nodes()
  let marks = self.get_marks()
  return filter(copy(nodes), { -> index(marks, v:val.key) isnot# -1 })
endfunction

function! s:get_cursor_node(range) abort dict
  let nodes = self.get_visible_nodes()
  let index = a:range[1] - 1
  let n = len(nodes)
  if n is# 0 || index >= n
    throw s:Revelator.error('index out of range')
  endif
  return nodes[index]
endfunction

function! s:get_selection_nodes(range) abort dict
  let nodes = self.get_visible_nodes()
  let si = a:range[0] - 1
  let ei = a:range[1] - 1
  let n = len(nodes)
  if n is# 0 || min([si, ei]) >= n
    throw s:Revelator.error('index out of range')
  endif
  return nodes[si : ei]
endfunction

" Method
function! s:init(root) abort dict
  call self.set_marks([])
  call self.set_nodes([a:root])
endfunction

function! s:redraw() abort dict
  if !bufloaded(self.bufnr)
    return s:Promise.reject(printf('buffer %d does not exist', self.bufnr))
  endif
  let winid = bufwinid(self.bufnr)
  let nodes = self.get_visible_nodes()
  let marks = self.get_marks()
  let contents = self.renderer.render(nodes, marks)
  let cursor = s:WindowCursor.get_cursor(winid)
  call s:BufferWriter.replace(self.bufnr, 0, -1, contents)
  call s:WindowCursor.set_cursor(winid, cursor)
  return s:Promise.resolve(self)
endfunction

function! s:enter(key) abort dict
  let node = fila#node#find(a:key, self.get_nodes())
  if node is# v:null
    return s:Promise.reject(printf('node %s does not exist', a:key))
  endif
  return self.enter_node(node)
endfunction

function! s:cursor(winid, key, ...) abort dict
  let offset = a:0 > 0 ? a:1 : 0
  let ignore = a:0 > 1 ? a:2 : 0
  if empty(getwininfo(a:winid))
    return s:Promise.reject(printf('no window %d exist', a:winid))
  endif
  let nodes = self.get_visible_nodes()
  let index = fila#node#index(a:key, nodes)
  let n = len(nodes)
  if n is# 0 || index >= n
    return ignore
          \ ? s:Promise.resolve(self)
          \ : s:Promise.reject(printf('node %s does not exist', a:key))
  endif
  let cursor = s:WindowCursor.get_cursor(a:winid)
  call s:WindowCursor.set_cursor(a:winid, [index + 1 + offset, cursor[1]])
  return s:Promise.resolve(self)
endfunction

function! s:reload(key) abort dict
  let nodes = self.get_nodes()
  return fila#node#reload(a:key, nodes, self.comparator.compare)
        \.then({ v -> self.set_nodes(v)})
        \.then({ -> self })
endfunction

function! s:expand(key) abort dict
  let nodes = self.get_nodes()
  return fila#node#expand(a:key, nodes, self.comparator.compare)
        \.then({ v -> self.set_nodes(v)})
        \.then({ -> self })
endfunction

function! s:collapse(key) abort dict
  let nodes = self.get_nodes()
  return fila#node#collapse(a:key, nodes, self.comparator.compare)
        \.then({ v -> self.set_nodes(v)})
        \.then({ -> self })
endfunction

function! s:enter_node(node) abort dict
  let marks = self.get_marks()
  let hidden = self.get_hidden()
  return fila#buffer#open(a:node.bufname, {
        \ 'opener': 'edit',
        \ 'locator': 0,
        \ 'notifier': 1,
        \})
        \.then({ c -> fila#node#helper#new(c.bufnr) })
endfunction

function! s:cursor_node(winid, node, ...) abort dict
  let offset = a:0 > 0 ? a:1 : 0
  let ignore = a:0 > 1 ? a:2 : 0
  return self.cursor(a:winid, a:node.key, offset, ignore)
endfunction

function! s:reload_node(node) abort dict
  return self.reload(a:node.key)
endfunction

function! s:expand_node(node) abort dict
  return self.expand(a:node.key)
endfunction

function! s:collapse_node(node) abort dict
  return self.collapse(a:node.key)
endfunction


call s:Config.config(expand('<sfile>:p'), {
      \ 'renderer': fila#node#renderer#default#new(),
      \ 'comparator': fila#node#comparator#default#new(),
      \})