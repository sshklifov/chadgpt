
function! s:Chat()
  sp
  enew
  setlocal buftype=prompt
  setlocal noswapfile
  setlocal buflisted
  setlocal nowrap
  setlocal modifiable
  call prompt_setprompt(bufnr(), 'input> ')
  call prompt_setcallback(bufnr(), function('s:PromptOutput'))
endfunction

function! s:PromptOutput(request)
  " TODO
endfunction
