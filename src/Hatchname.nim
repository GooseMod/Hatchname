import os
import strutils
import json
import sequtils
import tables
import sugar
import strformat

const updatesUrl = "https://updates.goosemod.com"
const modules = {"1": "betterdiscord", "2": "smartcord", "3": "goosemod", "4": "reactdevtools"}.toTable

var fileName: string
var baseDirectory: string

when system.hostOS == "windows":
    baseDirectory = os.getEnv("appdata")
    fileName = os.extractFilename(os.getAppFilename()).split(".exe")[0]
elif system.hostOS == "macosx":
    baseDirectory = os.joinPath(os.getHomeDir(), "Library/Application Support")
    fileName = os.extractFilename(os.getAppFilename())
else:
    baseDirectory = os.joinPath(os.getHomeDir(), ".config")
    fileName = os.extractFilename(os.getAppFilename())

# Function for formatting Discord paths
proc getChannelPath(channel: string): string =
    # Path to passed Discord channel's modules directory
    var channelPath = os.joinPath(baseDirectory, "discord")

    # Discord stable doesn't have a suffix so it's ignored
    if channel != "stable":
        channelPath = channelPath & channel
    
    return channelPath

let gmRemoved = fileName.split("GM")[1]
let noUnderscore = gmRemoved.split("_")
let selectedChannel = noUnderscore[0].toLower()

var moduleString: string

if noUnderscore.len == 1:
    moduleString = modules["3"]
else:
    moduleString = (block: collect(newSeq): (for i in deduplicate(mapIt(noUnderscore[1], $it)): modules[i])).join("+")

let settingsPath = os.joinPath(getChannelPath(selectedChannel), "settings.json")
if fileExists(settingsPath):
    let settings = parseFile(settingsPath)
    settings.add("NEW_UPDATE_ENDPOINT", %fmt"{updatesUrl}/{moduleString}/")
    settings.add("UPDATE_ENDPOINT", %fmt"{updatesUrl}/{moduleString}")
    writeFile(settingsPath, settings.pretty())