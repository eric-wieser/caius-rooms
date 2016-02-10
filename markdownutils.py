from CommonMark import Parser, HtmlRenderer
from CommonMark.node import Node

def parse(content): return Parser().parse(content)


def children(ast):
    node = ast.first_child
    while node is not None:
        yield node
        node = node.nxt

def remove_html(ast):
	a = ast.walker()

	for data in iter(a.nxt, None):
		n = data['node']
		if n.t == u'HtmlBlock':
			n.unlink()
	return ast

def section(ast):
	sections = [ast]
	for n in children(ast):
		if n.t == u'Heading':
			doc = Node('Document', [[1, 1], [0, 0]])


			n.parent = doc
			doc.first_child = n
			doc.last_child = ast.last_child

			if n == ast.first_child:
				sections = []

			ast.last_child = n.prv
			if n.prv:
				n.prv.nxt = None
			else:
				ast.first_child = None
			n.prv = None

			sections.append(doc)

	return sections

def render(ast):
	return HtmlRenderer().render(ast)