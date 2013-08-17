" Global Variables
let g:repo_vimrc_dir = '~/.vim/repo_vimrcs/'
let g:repo_vimrc_ext = '.vimrc'

" Functions
function! s:get_repo_vimrc()
    let l:repo_hash = s:get_repo_hash()
    if l:repo_hash != '0'
        " XXX this could return multiple files, which would break things. We
        " should probably error in that case
        let l:glob = g:repo_vimrc_dir . l:repo_hash . '*' . g:repo_vimrc_ext
        let l:repo_vimrc = glob(l:glob)
        if filereadable(l:repo_vimrc)
            return l:repo_vimrc
        else
            return 0
        endif
    else
        return 0
    endif
endfunction

function! s:get_repo_hash()
    let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd ' : 'cd '
    let dir = getcwd()
    try
        execute cd.'%:p:h'
        return system("git log --pretty=format:%H 2> /dev/null | tail -1")
    finally
        execute cd.'`=dir`'
    endtry
endfunction

" User Functions
function! s:edit_repo_vimrc()
    " Make sure we are actually in a git repo
    let l:repo_hash = s:get_repo_hash()
    if l:repo_hash == '0'
        echoerr "You are not in a git repo"
        return 0
    endif

    let l:repo_vimrc = s:get_repo_vimrc()
    if l:repo_vimrc != '0'
        exec 'vsp ' . l:repo_vimrc
    else
        echo "You don't have a .vimrc for this repo yet, let's create one."

        " Make sure the repo_vimrc_dir exits
        if !isdirectory(g:repo_vimrc_dir)
            call mkdir(g:repo_vimrc_dir, "p")
        endif

        call inputsave()
        let l:name = input("Enter a string for the human readable part for this .vimrc's filename: ")
        call inputrestore()

        if l:name != ''
            let l:name = '-'.l:name
        endif

        let l:repo_vimrc_filename = l:repo_hash . l:name . g:repo_vimrc_ext
        let l:repo_vimrc = g:repo_vimrc_dir . l:repo_vimrc_filename
        exec 'vsp ' . l:repo_vimrc
    endif
endfunction

function! s:source_repo_vimrc()
    let l:repo_vimrc = s:get_repo_vimrc()
    if l:repo_vimrc != '0'
        exec 'source ' . l:repo_vimrc
    endif
endfunction


" Global Commands
command! -nargs=* RepoVimrcEdit call s:edit_repo_vimrc()
command! -nargs=* RepoVimrcSource call s:source_repo_vimrc()
command! -nargs=* RepoVimrcCreate call s:create_repo_vimrc()

" Startup Code
autocmd! BufReadPost,BufNewFile * call s:source_repo_vimrc()
