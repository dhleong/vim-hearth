" Internal repl handling
"
" I rarely use this nowadays, but importing for now just in case.
" The idea is to spawn `lein repl` processes that fireplace can
" connect to without us having to leave Vim.

pyx << EOF
import os, platform, subprocess, vim

try:
    # only define once, please
    hearth_clj_repl_procs
except:
    hearth_clj_repl_procs = []

def hearth_hearth_open_repl():
    win = platform.system() == "Windows"
    env = None
    if platform.system() == "Darwin":
        env = os.environ.copy()
        env["PATH"] += ":/usr/local/bin"

    dir = os.path.dirname(vim.current.buffer.name)
    proc = subprocess.Popen(['lein', 'repl'],
                          env=env, cwd=dir,
                          stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT, shell=win)

    hearth_clj_repl_procs.append(proc)

    line = proc.stdout.readline()
    if not line:
        print("Error")
    else:
        # re-open the file to auto-connect
        # do like this to suppress the "return to continue"
        # and make it look fancy
        vim.command('e | redraw | echohl IncSearch | echo "Repl Started" | echohl None')


def hearth_close_all_repl():
    for proc in hearth_clj_repl_procs:
        proc.stdin.close()
        proc.kill()

def hearth_restart_repl():
    vim.command('redraw | echo "Closing Repl..."')
    hearth_close_all_repl()
    vim.command('redraw | echo "Restaring Repl..."')
    hearth_open_repl()

EOF

func! hearth#repl#internal#CloseAll()
    pyx hearth_close_all_repl()
endfunc

func! hearth#repl#internal#Restart()
    pyx hearth_restart_repl()
endfunc


augroup LeinShutDownGroup
    autocmd!
    autocmd VimLeavePre * call hearth#repl#internal#CloseAll()
augroup END
