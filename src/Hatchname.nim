import os
import strutils
import json
import sequtils
import tables
import sugar
import strformat

const updatesHost = "https://updates.goosemod.com"
const moduleIds = {"1": "betterdiscord", "2": "smartcord", "3": "goosemod", "4": "reactdevtools"}.toTable

let fileName = os.extractFilename(os.getAppFilename()).split(".exe")[0]
var baseDirectory: string

when system.hostOS == "windows":
    baseDirectory = os.getEnv("appdata")
elif system.hostOS == "macosx":
    baseDirectory = os.joinPath(os.getHomeDir(), "Library", "Application Support")
else:
    baseDirectory = os.joinPath(os.getHomeDir(), ".config")

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

var updatesEndpoint: string

if noUnderscore.len == 1:
    updatesEndpoint = "goosemod"
else:
    updatesEndpoint = (block: collect(newSeq): (for i in deduplicate(mapIt(noUnderscore[1], $it)): moduleIds[i])).join("+")

let settingsPath = os.joinPath(getChannelPath(selectedChannel), "settings.json")
if fileExists(settingsPath):
    let settings = parseFile(settingsPath)
    settings.add("NEW_UPDATE_ENDPOINT", %fmt"{updatesHost}/{updatesEndpoint}/")
    settings.add("UPDATE_ENDPOINT", %fmt"{updateshost}/{updatesEndpoint}")
    writeFile(settingsPath, settings.pretty())