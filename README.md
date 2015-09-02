*This gets a suprising amount of traffic for something that I'm not working on anymore!*
*Things that I'm actually working on:*
- *my (in progress) [thesis], which has a pipeline for building html and pdf from markdown / ipynb.*
- *[notedown], a tool for converting markdown <-> notebook*
- *my internal referencing [pandoc filter]*

[pandoc filter]: https://github.com/aaren/pandoc-reference-filter
[notedown]: https://github.com/aaren/notedown
[thesis]: https://github.com/aaren/thesis

---

## IPython notebook thesis template

I want to make the IPython Notebook into an environment in which
a thesis can be written.

To me, this means two things:

1. Internal references (especially figures)

2. Citations

We assume the development version of IPython (2.0-dev) and pandoc as
the markdown backend.


### Workflow

I want the following workflow:

- Write in markdown, using [vim-ipython] for interactivity.
- Convert markdown to notebook with [notedown]
- Fiddle around, execute
- Convert notebook to html / latex with nbconvert.

[vim-ipython]: http://www.github.com/ivanov/vim-ipython
[notedown]: http://www.github.com/aaren/notedown


### Approach

I want things to be rendered differently depending on the output
type. The only outputs that I care about beyond the notebook itself
are html and latex.

Nbconvert allows you to use custom templates to modify the rendering
of output in a given format. I need to extend the templates for html
and latex.


Figure references
-----------------

Two things to do here:

1. Allow referencing internally in html and latex using anchor
   links.

2. Let objects know what their anchor link is.


Let's address the first one:

The markdown reference

    reference to [the thing](#anchor-ref)

should be rendered as the html

    reference to <a href="#anchor-ref">the thing</a>

and as the latex

    reference to \autoref{anchor-ref}


#### Html

This is already covered by pandoc.


#### Latex

We need to replace the pattern `'[the thing](#anchor-ref)'`
with the latex '`\autoref{anchor-ref}'` before the markdown is
passed through the `markdown2latex` filter.


### Customising nbconvert

We can use custom templates with nbconvert:

    ipython nbconvert --to latex --template my_template.tplx --stdout


We can use custom filters using a config file. Run nbconvert like
this:

    ipython nbconvert --config config.py --to latex ...


Where config.py is a python file that looks like:

    c = get_config()

    c.Exporter.filters = {'name_of_filter': 'python_module.path'}


The filters are functions that the text of the block as a single
argument and return modified text. They need to be importable from
the config file (via `python_module.path`).

An example is [here](https://github.com/ipython/nbconvert-examples/tree/master/custom_filter)


#### Example

I have the following in `custom_filters.py`:


    import re

    def latex_internal_references(text):
        """Take markdown text and replace instances of
        '[blah](#anchor-ref)' with 'autoref{anchor-ref}'
        """
        ref_pattern = re.compile(r'\[(?P<text>.*?)\]\(#(?P<reference>.*?)\)')
        replacement = r'\\autoref{\g<reference>}'

        return ref_pattern.sub(replacement, text)

and a `config.py`:


    c = get_config()

    c.Exporter.filters = {'latex_internal_refs':
                            'custom_filters.latex_internal_references'}

and a `custom_latex.tplx`:

    
    ((*- extends 'base.tplx' -*))

    % Override markdown rendering, sorting out internal references
    ((* block markdowncell scoped *))
        ((( cell.source | citation2latex | strip_files_prefix | latex_internal_refs | markdown2latex )))
    ((* endblock markdowncell *))


Then we can generate latex with autoref like this:

    # convert markdown to notebook
    notedown example.md > example.ipynb
    
    # convert notebook to custom latex
    ipython nbconvert example.ipynb --to latex --config config.py --template custom_latex


We can actually specify all of these in the config file:

    c = get_config()

    c.NbConvertApp.notebooks = ['*.ipynb']
    c.NbConvertApp.export_format = 'latex'

    c.Exporter.template_file = 'custom_latex.tplx'

then run `ipython nbconvert --config config.py`.


### Making objects aware of their anchor link

This is more tricky.

I think the way to do it is by altering the metadata of code block
output. We can then create a latex / html template which parses the
metadata and includes the anchor link in the final text.

You need some way to alter the metadata of a code block.

We could alter notedown so that it parses code attributes as things
to put in the metadata of new code cells.

Something like this in the markdown:

    ```python {ref=fig:blah}
    code
    ```

where `fig:blah` is used as the internal link.

This seems the easiest way to do it. Is there a way to do it from
inside a notebook? Yes. In Ipython 2.0 we can turn on the cell
toolbar to edit metadata. Then we can set the cell metadata to
whatever JSON we like.

This is a bit fiddly but it will do for now. Long term we could have
a line magic that sets the metadata.

Assumming we've got the reference into the metadata, we can fiddle
with the output using a template. In html:

    {% block data_png scoped %}                                                                                                                                                        
    <div class="output_png output_subarea {{extra_class}}">                                                                                                                            
    {%- if output.png_filename %}                                                                                                                                                      
    <img src="{{output.png_filename | posix_path}}"                                                                                                                                    
    {%- else %}                                                                                                                                                                        
    <img src="data:image/png;base64,{{ output.png }}"                                                                                                                                  
    {%- endif %}                                                                                                                                                                       
    {%- if 'metadata' in output and 'width' in output.metadata.get('png', {}) %}                                                                                                       
    width={{output.metadata['png']['width']}}                                                                                                                                          
    {%- endif %}                                                                                                                                                                       
    {%- if 'metadata' in output and 'height' in output.metadata.get('png', {}) %}                                                                                                      
    height={{output.metadata['png']['height']}}                                                                                                                                        
    {%- endif %}                                                                                                                                                                       
    {%- if 'metadata' in output and 'ref' in output.metadata %}
    id={{output.metadata['ref']}}
    {%- endif %}
    >                                                                                                                                                                                  
    </div>                                                                                                                                                                             
    {%- endblock data_png %}

BUT! this is probably not the best way to do it. Functionally, all
we'll ever be doing is referencing the output from a code block.
This is all that we can influence using the metadata right now
anyway. We should place the id tag on the output area instead:

    {% block output %}                                                                                                                                                                 
    <div class="output_area">                                                                                                                                                          
    {%- if output.output_type == 'pyout' -%}                                                                                                                                           
        <div class="prompt output_prompt">                                                                                                                                             
        Out[{{ cell.prompt_number }}]:                                                                                                                                                 
    {%- else -%}                                                                                                                                                                       
        <div class="prompt">                                                                                                                                                           
    {%- endif -%}                                                                                                                                                                      
    {%- if 'metadata' in output and 'ref' in output.metadata %}
    id={{output.metadata['ref']}}
    {%- endif %}
        </div>                                                                                                                                                                         
    {{ super() }}                                                                                                                                                                      
    </div>                                                                                                                                                                             
    {% endblock output %}            


Another problem that we have is that we can't actually set the
metadata on the output area! We can only set on the input area. Ways
around this: 

1. Just set it on the input area
2. Find a way to get the complementary output for an input
3. Create a magic that transfers certain metadata from the input to
   the output.

We can do it by method (2). In Jinja templating we can access
variables that were defined in an outer block *if* the inner blocks
have the 'scoped' keyword. The default IPython html blocks do have
this (see IPython.nbconvert.templates.html.skeleton.null.tpl).

We can also place the block that we are replacing by using 
`{{ super() }}`. Let's just wrap the output in an extra div and
stick an id on it *if* the cell has metadata['ref']:

    {%- extends 'full.tpl' -%}

    {% block output %}
    {%- if 'metadata' in cell and 'ref' in cell.metadata %}
    <div id={{cell.metadata['ref']}}>
    {{ super() }}
    </div>
    {%- else -%}
    {{ super() }}
    {%- endif %}
    {% endblock output %}

and in latex (not sure yet!):

    % Draw a figure using the graphicx package.                                                                                                                                        
    ((* macro draw_figure(filename) -*))                                                                                                                                               
    ((* set filename = filename | posix_path *))                                                                                                                                       
    ((*- block figure scoped -*))                                                                                                                                                      
        \begin{figure}                                                                                                                                                                 
        \adjustimage{max size={0.9\linewidth}{0.9\paperheight}}{((( filename )))}                                                                                                      
        \end{center}                                                                                                                                                                   
        { \hspace*{\fill} \\}                                                                                                                                                          
    ((*- endblock figure -*))                                                                                                                                                          
    ((*- endmacro *))                                                                                                                                                                  



Citations
---------

There are two output formats: html and latex. The input is markdown.

We can do our citations in pandoc style, i.e. `@citekey` and
`[@citekey]'.

With the `--natbib` switch, these get rendered as `\citet` and
`\citep` in latex and we can then use our normal latex citation
method.

    pandoc test.md --natbib --to latex

For html output we can use pandoc-citeproc, with the switch
`--bibliography ref.bib` and a bibtex file `ref.bib`. This renders a
citation for us.

    pandoc test.md --bibliography ref.bib --to html

Problem: we get a 'references' div at the end of every chunk. We
operate on a notebook chunk by chunk - is this unavoidable? Can we
collect all of the references at the end of the document?

Is it a problem? Can we just hide the references div at the end of
each markdown chunk?


Solutions:

1. create a list of citations used as we go along and somehow create
   bibliography from this at the end.

2. create html with `pandoc --to html` and then regex replace the
   <span class='citation'>@citekey</span> with whatever html we want
   it to become.

   We then have to create a list of references at the end. We'd have
   to create a new cell with this in or we would put it in a special
   references cell that we've already created.

   Can the filters that we use be methods on a class instance that
   we alter the state of as we go along? We could then keep track of
   the citations list as we go along. How do we initialise the
   class?
