{% macro clean_text(text) -%}
{{ text | lower | replace(' ', '_') }}
{%- endmacro %}