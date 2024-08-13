import std/strutils
import std/sequtils
import std/os
import std/sets

const
  missingListPath = ".cache/missinglist"

createDir ".cache"

proc loadMissingList*: OrderedSet[string] =
  toOrderedSet try:
    missingListPath.readFile.splitLines
  except:
    @[]

proc writeMissingList*(list: OrderedSet[string]) =
  missingListPath.writeFile list.toSeq.join("\n")
