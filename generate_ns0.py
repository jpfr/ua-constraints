# 2025, Julius Pfrommer (o6 Automation GmbH)
#
#!/usr/bin/env python3

import logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# Add local open62541 tools to path and import the nodeset compiler
import sys
from os.path import dirname, abspath, join
project_root = dirname(abspath(__file__))
open62541_nc = join(project_root, "open62541/tools")
print(open62541_nc)
sys.path.insert(0, open62541_nc)
import nodeset_compiler as nc
from nodeset_compiler.datatypes import NodeId
from nodeset_compiler.nodeset import *
from nodeset_compiler.nodes import *

import argparse
parser = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter)
parser.add_argument('-x', '--xml',
                    metavar="<nodeSetXML>",
                    type=argparse.FileType('rb'),
                    action='append',
                    dest="infiles",
                    default=[],
                    help='NodeSet XML files with nodes that shall be generated.')
parser.add_argument('aspOut', metavar='<aspOut>', help='Output file for the ASP definitions')
args = parser.parse_args()

# Load the nodeset files
ns = NodeSet()
for xmlfile in args.infiles:
    logger.info("Loading " + str(xmlfile.name))
    ns.addNodeSet(xmlfile)

# Finalize the nodeset
ns.sanitize()
ns.addInverseReferences()
ns.setNodeParent()

logger.info(f"Generating ASP Definitions")

def lowerCaml(s):
    return s[:1].lower() + s[1:]

def nodeClass(node):
    return lowerCaml(type(node).__name__)

# Map the NodeId of a ReferenceType to a symbol name
referenceSyms = {}
for node in ns.nodes.values():
    if type(node) == ReferenceTypeNode:
        referenceSyms[str(node.id)] = lowerCaml(node.browseName.name)
def refSym(n):
    if isinstance(n, str):
        return referenceSyms[n]
    return referenceSyms[str(n)]

with open(args.aspOut, "w") as f:
    # Print the hierarchy of ReferenceTypes
    f.write("% ReferenceType Hierarchy\n")
    f.write("% ReferenceTypes imply their parent ReferenceTypes\n\n")
    for node in ns.nodes.values():
        if type(node) != ReferenceTypeNode:
            continue
        f.write(f"impliedRef(X,Y,{refSym(node.id)}) :- ref(X,Y,{refSym(node.id)}) .\n")
        p = node.getParentReference()
        if p == None:
            continue
        f.write(f"impliedRef(X,Y,{refSym(p.target)}) :- ref(X,Y,{refSym(node.id)}) .\n")
    f.write("\n")

    # Print out the nodes
    f.write("% Node Definitions\n\n")
    for node in ns.nodes.values():
        f.write(f"node(\"{str(node.id)}\", {nodeClass(node)}, \"{str(node.browseName)}\") .\n")
        for r in node.references.keys():
            source = r.source if r.isForward else r.target
            target = r.target if r.isForward else r.source
            f.write(f"ref(\"{str(source)}\", \"{str(target)}\", {refSym(r.referenceType)}) .\n")
        f.write("\n")

logger.info("ASP Definitions successfully printed")
