if exists(':Chat')
  finish
endif

function! s:Chat(args, line1, line2)
  if !exists('g:chad_api_key')
    echo "You must set g:chad_api_key"
    return
  endif

  let lines = getline(a:line1, a:line2)
  let input = a:args .. "\n" .. join(lines, "\n")

  let nr = bufnr("ChadGPT")
  if nr < 0
    let nr = bufadd("ChadGPT")
    sp
    exe "b " .. nr
    setlocal buftype=prompt
    setlocal noswapfile
    setlocal buflisted
    setlocal modifiable
    setlocal filetype=markdown
    setlocal textwidth=100
    setlocal wrap
    call prompt_setprompt(bufnr(), 'input> ')
    call prompt_setcallback(bufnr(), function('s:PromptOutput'))
    call matchadd('@markup.link.url', '^input>')

    let b:chat_history = []
    inoremap <buffer> <C-d> <cmd>bdelete!<cr>
    inoremap <buffer> <C-w> <S-C-w>
    nnoremap <buffer> j gj
    nnoremap <buffer> k gk
  endif

  call win_gotoid(bufwinid(nr))
  if !empty(a:args)
    let line = line('.')
    call s:PromptOutput(input)
    call setline(line, 'input> ' .. a:args)
  endif
endfunction

command! -nargs=? -range Chat call s:Chat(<q-args>, <line1>, <line2>)

function! s:PromptOutput(request)
  call add(b:chat_history, #{role: "user", content: a:request})
  let opts = #{model: "gpt-4o-mini", messages: b:chat_history}
  let cmd = ["curl",
        \ "https://api.openai.com/v1/chat/completions",
        \ "-Ss",
        \ "-H", "Content-Type: application/json",
        \ "-H", "Authorization: Bearer " .. g:chad_api_key,
        \ "-d", json_encode(opts)]
  let output = system(cmd)
  if v:shell_error
    call append("$", "Failed to send command!")
    return
  endif
  let resp = json_decode(output)
  let choice = resp['choices'][0]
  if choice['finish_reason'] != "stop"
    call append("$", "Unkown finish_reason: " .. choice['finish_reason'])
    return
  endif
  let message = choice['message']
  call add(b:chat_history, message)
  let lines = split(message['content'], '\n', 1)

  let view = winsaveview()
  call append("$", lines)
  call append("$", "")
  stopi
  call winrestview(view)
endfunction
