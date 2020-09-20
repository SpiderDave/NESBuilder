import ast
import operator

_OP_MAP = {
    ast.Add: operator.add,
    ast.Sub: operator.sub,
    ast.Mult: operator.mul,
    ast.Div: operator.truediv,
    ast.Invert: operator.neg,
    ast.Pow: operator.pow,
    ast.USub: operator.neg,
}

class Calculator(ast.NodeVisitor):

    def __call__(self, expression="None"):
        if expression:
            expression = expression.replace("^","**")
            try:
                return self.evaluate(expression)
            except:
                return "E"
    
    def visit_UnaryOp(self, node):
        return _OP_MAP[type(node.op)](self.visit(node.operand))

    def visit_BinOp(self, node):
        left = self.visit(node.left)
        right = self.visit(node.right)
        return _OP_MAP[type(node.op)](left, right)

    def visit_Num(self, node):
        return node.n

    def visit_Expr(self, node):
        return self.visit(node.value)

    @classmethod
    def evaluate(cls, expression):
        tree = ast.parse(expression)
        calc = cls()
        return calc.visit(tree.body[0])

if __name__ == '__main__':
    calc = Calculator()
    print(calc('1 + 3 * (2 + 7) + 2**2'))
    print(calc('2^8'))
    
    print(calc('01.0+02.0'))
    
    print(calc('-5+1'))
    print(calc('01+02'))
