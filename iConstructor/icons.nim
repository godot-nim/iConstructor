import classlists
import missinglists

import std/os
import std/httpclient
import std/tables
import std/strformat
import std/xmlparser
import std/terminal
import std/sets

createDir ".downloads"
var missingList = loadMissingList()

proc iconPath(name: string): string = ".downloads"/name & ".svg"

proc getIcon(client: HttpClient; name: string): string =
  if name in missingList:
    echo "[missing] ", name
    return
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

proc loadIcon(name: string): string =
    readFile iconPath(name)

proc loadOrGetIcon(client: HttpClient; name: string): string =
  if fileExists iconPath(name): loadIcon name
  else: client.getIcon name

proc storeIcons*(client: HttpClient; list: ClassList) =
  for name, class in list:
    let str = client.loadOrGetIcon(name)
    if str.len == 0:
      missingList.incl name
    else:
      class.svg = client.loadOrGetIcon(name).parseXml
  writeMissingList missingList
