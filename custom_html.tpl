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
