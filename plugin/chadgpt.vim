if exists(':Chat')
  finish
endif

function! s:Chat()
  if !exists('g:chad_api_key')
    echo "You must set g:chad_api_key"
    return
  endif
  sp
  enew
  setlocal buftype=prompt
  setlocal noswapfile
  setlocal buflisted
  setlocal modifiable
  setlocal filetype=markdown
  setlocal textwidth=100
  setlocal wrap
  call prompt_setprompt(bufnr(), 'input> ')
  call prompt_setcallback(bufnr(), function('s:PromptOutput'))
  call matchadd('Bold', '^input>')

  let b:chat_history = []
  inoremap <buffer> <C-d> <cmd>bdelete!<cr>
  inoremap <buffer> <C-w> <S-C-w>
  nnoremap <buffer> j gj
  nnoremap <buffer> k gk
endfunction

command! Chat call s:Chat()

function! s:PromptOutput(request)
  call add(b:chat_history, #{role: "user", content: a:request})
  let opts = #{model: "gpt-4o-mini", messages: b:chat_history}
  let cmd = ["curl",
        \ "https://api.openai.com/v1/chat/completions",
        \ "-Ss",
        \ "-H", "Content-Type: application/json",
        \ "-H", "Authorization: Bearer " .. s:api_key,
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
