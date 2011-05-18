#!/usr/bin/env python2.7
import os
import sys
from lib2to3 import pygram, pytree
from lib2to3.pgen2 import driver

ROOTDIR = os.path.dirname(__file__)

def find(node, leaf):
    if node == leaf:
        return node
    for c in node.children:
        if find(c, leaf):
            return find(c, leaf)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print "Usage: inject_dbs.py FILENAME"
        sys.exit(1)

    src     = sys.argv[1]
    patch   = os.path.join(ROOTDIR, "dbs.py")
    dest    = "_settings.py"

    drv = driver.Driver(pygram.python_grammar, pytree.convert)
    root = drv.parse_file(src)

    node = find(root, pytree.Leaf(1, "DATABASES")) # Find first DATABASES
    end  = node.parent.next_sibling

    with open(src) as _src:
        head = [_src.next() for x in xrange(end.lineno)]
        tail = [l for x,l in enumerate(_src)]

    with open(patch) as _patch:
        body = [l for x,l in enumerate(_patch)]

    with open(dest, "w") as _dest:
        _dest.writelines(head)
        _dest.writelines(body)
        _dest.writelines(tail)
