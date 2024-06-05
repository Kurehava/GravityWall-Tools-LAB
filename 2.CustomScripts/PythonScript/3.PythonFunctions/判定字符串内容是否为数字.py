from re import compile
def check_num(string):
    return bool(compile(r'^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$').match(string))

if check_num('1e3'):
    print('yes')
else:
    print('no')
