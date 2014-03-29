c = get_config()

# c.NbConvertApp.notebooks = ['*.ipynb']
c.NbConvertApp.export_format = 'latex'
c.Exporter.template_file = 'simple_latex.tplx'

c.Exporter.filters = {
    'latex_internal_refs': 'custom_filters.latex_internal_references',
    'markdown2latex':      'custom_filters.markdown2latex'
}
