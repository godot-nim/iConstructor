import std/strutils
import std/os
import std/httpclient
import std/json
import std/sets
import std/tables
import std/strformat
import std/xmltree

type
  Class* = ref object
    name*: string
    svg*: XmlNode
    parent*: Class
    children*: seq[Class]
  ClassList* = TableRef[string, Class]

const
  classListPath = ".cache/classlist"
createDir ".cache"

proc getExtensionAPI(client: HttpClient): string =
  const apitag {.strdefine: "api.tag".} = "master"
  const apiURI = &"https://raw.githubusercontent.com/godotengine/godot-cpp/{apitag}/gdextension/extension_api.json"
  result = client.getContent(apiURI)

proc removeNonNode(classList: JsonNode) =
  var sets: HashSet[string]
  while true:
    var changed: bool
    for i in countdown(classList.elems.high, 0):
      let class = classList.elems[i]
      let name = class["name"].getStr
      if name == "Node": continue
      if (not class.hasKey "inherits") or class["inherits"].str in sets:
        classList.elems.delete i
        sets.incl name
        changed = true
    if not changed: break

proc addClassList(classList: ClassList; name, inheritsName: string) =
    var class: Class
    if classList.hasKey name:
      class = classList[name]
    else:
      class = Class(name: name)
      classList[name] = class

    if inheritsName.len != 0:
      var inherits: Class
      if classList.hasKey inheritsName:
        inherits = classList[inheritsName]
      else:
        inherits = Class(name: inheritsName)
        classList[inheritsName] = inherits

      inherits.children.add class
      class.parent = inherits

proc encodeClassList(list: ClassList): string =
  for name, class in list:
    result.add name
    result.add ","
    if class.parent != nil:
      result.add class.parent.name
    result.add "\n"

proc decodeClassList(encoded: string): ClassList =
  new result
  for row in encoded.splitLines:
    if row.isEmptyOrWhitespace: continue
    let record = row.split(',')
    result.addClassList(record[0], record[1])


proc extractClassList(api: string): ClassList =
  let jsonlist = api.parseJson["classes"]

  removeNonNode jsonlist

  new result

  for json in jsonlist:
    let name = json["name"].getStr
    result.addClassList(name,
      (if name == "Node": "" else: json["inherits"].getStr))

  classListPath.writeFile encodeClassList result

proc loadClassList: ClassList =
  classListPath.readFile.decodeClassList

proc loadOrRequestClassList*(client: HttpClient): ClassList =
  if fileExists classListPath: loadClassList()
  else: client.getExtensionAPI.extractClassList()

proc isInheritsOf*(class: Class; operand: string): bool =
  if class.name == operand:
    true
  elif class.parent.isNil:
    false
  else:
    class.parent.isInheritsOf operand

proc isInheritsOf*(class: Class; operand: Class): bool =
  class.isInheritsOf operand.name