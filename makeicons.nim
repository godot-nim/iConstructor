import std/strutils
import std/sequtils
import std/os
import std/httpclient
import std/json
import std/sets
import std/tables
import std/strformat
import std/xmltree
import std/xmlparser
import std/terminal

type IconMissingDefect = object of HttpRequestError

type
  Class = ref object
    name: string
    parent: Class
    children: seq[Class]
  ClassList = TableRef[string, Class]

const
  extensionApiPath = ".downloads/extension_api.json"
  classListPath = ".cache/classlist"
  missingListPath = ".cache/missinglist"

createDir ".downloads"
createDir ".cache"
createDir "icons"

proc getExtensionAPI(client: HttpClient): string =
  const apitag {.strdefine: "api.tag".} = "master"
  const apiURI = &"https://raw.githubusercontent.com/godotengine/godot-cpp/{apitag}/gdextension/extension_api.json"
  result = client.getContent(apiURI)
  extensionApiPath.writeFile result

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
    echo repr record
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

proc loadOrRequestClassList(client: HttpClient): ClassList =
  if fileExists classListPath: loadClassList()
  else: client.getExtensionAPI.extractClassList()

proc loadMissingList: seq[string] =
  try:
    missingListPath.readFile.splitLines
  except:
    @[]
var missingList = loadMissingList()

proc iconPath(name: string): string = ".downloads"/name & ".svg"
proc crownPath(name: string): string = "materials"/name & ".svg"

proc getIcon(client: HttpClient; name: string): string =
  if name in missingList:
    echo "[missing] ", name
    raise newException(IconMissingDefect, "missing")
  try:
    echo "[downloading] ", name, ".svg"
    result = client.getContent &"https://raw.githubusercontent.com/godotengine/godot/master/editor/icons/{name}.svg"
    iconPath(name).writeFile result
    stdout.cursorUp(1)
    stdout.eraseLine

  except HttpRequestError:
    stdout.cursorUp(1)
    stdout.eraseLine
    echo "[", getCurrentExceptionMsg(), "] ", name
    missingList.add name
    raise newException(IconMissingDefect, getCurrentExceptionMsg())

proc loadIcon(name: string): string =
    readFile iconPath(name)

proc loadOrGetIcon(client: HttpClient; name: string): string =
  if fileExists iconPath(name): loadIcon name
  else: client.getIcon name

proc loadCrown(classList: ClassList; name: string): XmlNode =
  var current = classList[name]
  while current != nil:
    if fileExists crownPath(current.name):
      return crownPath(current.name).readFile.parseXml
    current = current.parent


proc writeMissingList(list: seq[string]) =
  missingListPath.writeFile list.join("\n")

let client = newHttpClient()
let classlist = client.loadOrRequestClassList

var classDefines: string
var classRegister: string
var iconEntries: string
var sceneEntries: string

for name, class in classList:
  try:
    let svg = client.loadOrGetIcon(name).parseXml
    # svg.insert(crown.toSeq, 0)
    var cons = classList.loadCrown(name)
    if cons == nil:
      cons = svg
    else:
      for i in 0..<cons.len:
        if cons[i].tag == "icon":
          cons.delete(i)
          cons.insert(svg.toSeq, i)

    var text = ""
    text.add(cons, indWidth= 0, addNewLines= false)

    ("icons"/name & ".svg").writeFile text

    classDefines.add &"type {name}Preview = ref object of Node\n"
    classRegister.add &"  register {name}Preview\n"
    iconEntries.add &"{name}Preview = \"res://icons/{name}.svg\"\n"
    sceneEntries.add &"[node name=\"{name}\" type=\"{name}Preview\" parent=\".\"]\n"
  except IconMissingDefect:
    discard

"preview/preview/bootstrap.nim".writeFile &"""
import gdext

{classDefines}
process initialize_scene:
{classRegister}
GDExtensionEntryPoint name= init_library
"""

"preview/preview/preview.gdextension".writeFile &"""
[configuration]
entry_symbol = "init_library"
compatibility_minimum = 4.2

[libraries]

linux = "res://preview/lib/libpreview.so"
windows = "res://preview/lib/preview.dll"


[icons]
{iconEntries}
"""
"preview/main.tscn".writeFile &"""
[gd_scene format=3 uid="uid://cqitsd6rcvlsp"]

[node name="Main" type="Node"]
{sceneEntries}
"""

writeMissingList missingList