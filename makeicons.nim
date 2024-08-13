import iConstructor/classlists
import iConstructor/icons
import iConstructor/xmltree

import std/strutils
import std/sequtils
import std/os
import std/httpclient
import std/tables
import std/strformat
import std/sets
import std/algorithm
import std/re
import std/xmlparser

const badgeDir = "materials"

proc get(str, default: string): string =
  if str.len == 0: default
  else: str

type Badge = object
  name: string
  node: XmlNode

proc loadBadges(path: string): seq[Badge] =
  for kind, path in path.walkDir:
    case kind
    of pcDir, pcLinkToDir:
      result.add loadBadges path
    of pcFile, pcLinkToFile:
      if path.endsWith(".svg"):
        result.add Badge(
          name: path.relativePath(getCurrentDir()),
          node: path.readFile.parsexml,
        )
  result.sorted proc(a, b: Badge): int = cmp a.name, b.name

let client = newHttpClient()
let classlist = client.loadOrRequestClassList
let badges = loadBadges(badgeDir)

client.storeIcons classlist

var generated: HashSet[tuple[outdir, class: string]]


for badge in badges:
  for name, class in classList:
    if class.svg == nil: continue
    var outdir: string
    let new_badge = badge.node.copy
    new_badge.replaceAll "icon", proc(icon: XmlNode): seq[XmlNode] =
      let
        a_type = icon.attr"type"
        a_regex = icon.attr"regex"
        match = `or`(
          `and`( a_regex.len != 0, name =~ re a_regex),
          `and`( a_type.len != 0, class.isInheritsOf a_type))
      if match:
        outdir = icon.attr"outdir".get"icons"
        class.svg.toSeq
      else:
        @[]

    if outdir.len != 0:
      var text = ""
      text.add(new_badge, indWidth= 0, addNewLines= false)

      createDir(outdir)
      echo badge.name, " --> ", outdir/name, ".svg"
      (outdir/name & ".svg").writeFile text

      generated.incl (outdir, name)


var classDefines: string
var classRegister: string
var iconEntries: string
var sceneEntries: string

proc identify(outdir, class: string): string =
  result = class
  result.add "Preview_"
  result.add outdir.replace("/", "_")

for (outdir, class) in generated:
  classDefines.add &"type {identify outdir, class} = ref object of Node\n"
  classRegister.add &"  register {identify outdir, class}\n"
  iconEntries.add &"{identify outdir, class} = \"res://{outdir}/{class}.svg\"\n"
  sceneEntries.add &"[node name=\"{outdir/class}\" type=\"{identify outdir, class}\" parent=\".\"]\n"

"preview/bootstrap.nim".writeFile &"""
import gdext

{classDefines}
process initialize_scene:
{classRegister}
GDExtensionEntryPoint name= init_library
"""

"preview/preview.gdextension".writeFile &"""
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
