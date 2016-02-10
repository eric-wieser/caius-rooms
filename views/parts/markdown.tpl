
<%
from markdownutils import *
ast = parse(content)
if not get('allow_unsafe'):
	ast = remove_html(ast)
end
%>
% if not get('columnize'):
	{{! render(ast) }}
% else:
	<div class="row">
		% for a in section(ast):
			<div class='col-md-4'>
				{{! render(a) }}
			</div>
		% end
	</div>
%end
