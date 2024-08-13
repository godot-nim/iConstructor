import std/xmltree {.all.}
import std/importutils

export xmltree

proc copy*(node: XmlNode): XmlNode =
  privateAccess XmlNodeObj
  case node.kind
  of xnElement:
    new result
    result[] = node[]
    for i, child in node.s:
      result.s[i] = child.copy
  else:
    result = node

proc replaceAll*(node: XmlNode; tag: string; expr: proc(node: XmlNode): seq[XmlNode]) =
  for i in countdown(node.len.pred, 0):
    case node[i].kind
    of xnElement:
      if node[i].tag == tag:
        node.replace(i, expr node[i])
      else:
        node[i].replaceAll(tag, expr)
    else:
      discard