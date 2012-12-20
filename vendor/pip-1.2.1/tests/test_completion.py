import os
from tests.test_pip import reset_env, run_pip, get_env


def test_completion_for_bash():
    """
    Test getting completion for bash shell
    """
    reset_env()
    bash_completion = """\
_pip_completion()
{
    COMPREPLY=( $( COMP_WORDS="${COMP_WORDS[*]}" \\
                   COMP_CWORD=$COMP_CWORD \\
                   PIP_AUTO_COMPLETE=1 $1 ) )
}
complete -o default -F _pip_completion pip"""

    result = run_pip('completion', '--bash')
    assert bash_completion in result.stdout, 'bash completion is wrong'


def test_completion_for_zsh():
    """
    Test getting completion for zsh shell
    """
    reset_env()
    zsh_completion = """\
function _pip_completion {
  local words cword
  read -Ac words
  read -cn cword
  reply=( $( COMP_WORDS="$words[*]" \\
             COMP_CWORD=$(( cword-1 )) \\
             PIP_AUTO_COMPLETE=1 $words[1] ) )
}
compctl -K _pip_completion pip"""

    result = run_pip('completion', '--zsh')
    assert zsh_completion in result.stdout, 'zsh completion is wrong'


def test_completion_for_unknown_shell():
    """
    Test getting completion for an unknown shell
    """
    reset_env()
    error_msg = 'error: no such option: --myfooshell'
    result = run_pip('completion', '--myfooshell', expect_error=True)
    assert error_msg in result.stderr, 'tests for an unknown shell failed'


def test_completion_alone():
    """
    Test getting completion for none shell, just pip completion
    """
    reset_env()
    result = run_pip('completion', expect_error=True)
    assert 'ERROR: You must pass --bash or --zsh' in result.stderr,\
            'completion alone failed -- ' + result.stderr


def test_completion_for_un_snippet():
    """
    Test getting completion for ``un`` should return
    uninstall and unzip
    """
    environ = os.environ.copy()
    reset_env(environ)
    environ['PIP_AUTO_COMPLETE'] = '1'
    environ['COMP_WORDS'] = 'pip un'
    environ['COMP_CWORD'] = '1'
    env = get_env()
    # expect_error is True because autocomplete exists with 1 status code
    result = env.run('python', '-c', 'import pip;pip.autocomplete()',
            expect_error=True)
    assert result.stdout.strip().split() == ['unzip', 'uninstall'],\
           "autocomplete function could not complete ``un`` snippet"


def test_completion_for_default_parameters():
    """
    Test getting completion for ``--`` should contain --help
    """
    environ = os.environ.copy()
    reset_env(environ)
    environ['PIP_AUTO_COMPLETE'] = '1'
    environ['COMP_WORDS'] = 'pip --'
    environ['COMP_CWORD'] = '1'
    env = get_env()
    # expect_error is True because autocomplete exists with 1 status code
    result = env.run('python', '-c', 'import pip;pip.autocomplete()',
            expect_error=True)
    assert '--help' in result.stdout,\
           "autocomplete function could not complete ``--``"
