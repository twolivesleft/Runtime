require("require")
require("vscode-userdata")

viewer = require("viewer")

require("tableExtensions")
require("pasteboard")
pcall(require, "pickers") -- iOS-only (uses objc); safe to skip on Android
require("symbols")
require("trampoline")

_debuggee = ""
