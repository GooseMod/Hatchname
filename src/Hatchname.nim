import os
import strutils
import json
import sequtils
import tables
import sugar
import strformat
import osproc

const updatesHost = "https://updates.goosemod.com"

# IDs for modules encoded via filename (eg: GMStable_134 = betterdiscord+goosemod+reactdevtools)
const moduleIds = {"1": "betterdiscord", "2": "smartcord", "3": "goosemod", "4": "reactdevtools"}.toTable


let fileName = os.extractFilename(os.getAppFilename()).split(".exe")[0]
var baseDirectory: string

when system.hostOS == "windows": # Use when to have this at compile time
    baseDirectory = os.getEnv("appdata")
elif system.hostOS == "macosx":
    baseDirectory = os.joinPath(os.getHomeDir(), "Library", "Application Support")
else:
    baseDirectory = os.joinPath(os.getHomeDir(), ".config")


# Function for formatting Discord paths
proc getChannelPath(channel: string): string =
    # Path to passed Discord channel's modules directory
    var channelPath = os.joinPath(baseDirectory, "discord")

    # Discord stable doesn't have a suffix so don't append channel
    if channel != "stable":
        channelPath = channelPath & channel
    
    return channelPath


proc quitDiscord(channel: string) =
    var binaryName = "Discord"

    if channel != "stable":
        binaryName = binaryName & ($channel[0]).toUpper() & channel[1..channel.len-1]

    when system.hostOS == "windows":
        discard execShellCmd(fmt"taskkill /f /im {binaryName}.exe")
    else:
        discard execShellCmd(fmt"killall {binaryName}")

proc startDiscord(channel: string) =
    var binaryName = "Discord"
    var linuxBootstrap = "discord"

    if channel != "stable":
        binaryName = binaryName & ($channel[0]).toUpper() & channel[1..channel.len-1]
        linuxBootstrap = linuxBootstrap & fmt"-{channel}"

    when system.hostOS == "windows":
        discard startProcess(fmt"'%localappdata%\{binaryName}\Update.exe' --processStart {binaryName}.exe", options = {poStdErrToStdOut, poUsePath, poEvalCommand})
    else:
        discard startProcess(linuxBootstrap, options = {poStdErrToStdOut, poUsePath, poEvalCommand})


let gmRemoved = fileName.split("GM")[1]
let noUnderscore = gmRemoved.split("_")
let selectedChannel = noUnderscore[0].toLower()

var updatesEndpoint: string

echo("Exiting Discord...")
quitDiscord(selectedChannel)
sleep(3000) # Wait for Discord to finish closing

# todo: Sanity check filename, if not error out

# Default endpoint to GM if no options are provided (eg: GMStable)
if noUnderscore.len == 1:
    updatesEndpoint = "goosemod"
else: # Generate endpoint from modules encoded in filename
    updatesEndpoint = (block: collect(newSeq): (for i in deduplicate(mapIt(noUnderscore[1], $it)): moduleIds[i])).join("+")

echo("Injecting GooseMod...")

# Get settings path via 
let settingsPath = os.joinPath(getChannelPath(selectedChannel), "settings.json")

if fileExists(settingsPath):
    let settings = parseFile(settingsPath)

    settings.add("UPDATE_ENDPOINT", %fmt"{updateshost}/{updatesEndpoint}")
    settings.add("NEW_UPDATE_ENDPOINT", %fmt"{updatesHost}/{updatesEndpoint}/")

    writeFile(settingsPath, settings.pretty())
# else:
    # todo: Error out (no settings.json)

echo("Starting Discord...")
startDiscord(selectedChannel)