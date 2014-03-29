"""Custom filters to be used with IPython nbconvert."""
import subprocess
import re

from IPython.nbconvert.utils.pandoc import pandoc


def latex_internal_references(text):
    """Take markdown text and replace instances of
    '[blah](#anchor-ref)' with 'autoref{anchor-ref}'
    """
    ref_pattern = re.compile(r'\[(?P<text>.*?)\]\(#(?P<reference>.*?)\)')
    replacement = r'\\autoref{\g<reference>}'

    return ref_pattern.sub(replacement, text)


def markdown2latex(source):
    """Custom markdown2latex converter with additional options."""
    # args = ['--chapter', '--natbib']
    # return pandoc(source, 'markdown', 'latex', args)
    cmd = ['pandoc',
           '--from', 'markdown',
           '--to', 'latex',
           '--chapter',
           '--natbib']

    p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    stdout, stderr = p.communicate(source)
    # TODO: why does this come out weird? (has extra indentation at start)
    # out = TextIOWrapper(BytesIO(out), encoding, 'replace').read()
    return stdout.rstrip('\n')  # strip trailing whitespace
