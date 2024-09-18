import sys
import ast

allowed_class = (
    ast.Assign,
    ast.FormattedValue,
    ast.JoinedStr,
    ast.List,
    ast.Load,
    ast.Module,
    ast.Name,
    ast.NameConstant,
    ast.Num,
    ast.Store,
    ast.Str,
)

if len(sys.argv) != 2:
    exit(1)

with open (sys.argv[1]) as f:
    node = ast.parse(f.read(), filename=sys.argv[1])

failed = False

for i in ast.walk(node):
    if not isinstance(i, allowed_class):
        failed = True
        try:
            print(f"disallowed class {type(i)} found on line {i.lineno} col {i.col_offset}")
        except:
            print(f"disallowed class {type(i)} found")

if failed:
    exit(1)
else:
    exit(0)
