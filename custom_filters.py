"""Custom filters to be used with IPython nbconvert."""

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
    args = ['--chapter', '--natbib']
    return pandoc(source, 'markdown', 'latex', args)
