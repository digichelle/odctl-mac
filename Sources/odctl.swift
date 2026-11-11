/*
odctl - OneDrive command-line control for macOS
Copyright © 2026 Michelle Catherine Marcó
MIT License: https://opensource.org/license/MIT
*/

import Foundation
import AppKit
import ArgumentParser

// Define version and license information (accessed via --version flag)
let versionText = """
    odctl - OneDrive command-line control for macOS
    Version 1.0.0-20261111-01
    Copyright © 2026 Michelle Catherine Marcó
    MIT License: https://opensource.org/license/MIT
    """

// Define functions
@MainActor class ODCtl {

    // Initialize mode flags
    var dryRunMode = false
    var quietMode = false
    var verboseMode = false

    // Struct to enable stderr output
    struct StandardError: TextOutputStream, Sendable {
        private static let handle = FileHandle.standardError
        public func write(_ string: String) {
            Self.handle.write(Data(string.utf8))
        }
    }

    // Function to write error messages
    func errorMessage(_ message: String) {
        var stderr = StandardError()
        print(message, to: &stderr)
    }

    // Function to write verbose messages
    func verboseMessage(_ message: String) {
        if verboseMode {
            print(message)
        }
    }

    // Function to write optional messages
    // If both quiet and verbose modes are specified, the latter takes priority
    func optionalMessage(_ message: String) {
        if verboseMode || !quietMode {
            print(message)
        }
    }

    // Function to execute a specified shell command, with options
    func execShellCmd(_ cmd: String) -> Int32 {
        // Convert cmd string to array
        let cmdArray = cmd.components(separatedBy: " ")
        // Create new instance of Process()
        let shellCmd = Process()
        do {
            // Set executable URL to /usr/bin/env so we can use executables in PATH
            shellCmd.executableURL = URL(filePath: "/usr/bin/env")
            // Pass cmdArray to arguments
            shellCmd.arguments = cmdArray
            // Try to run shell command
            try shellCmd.run()
            shellCmd.waitUntilExit()
        } catch {
            // If shell command execution fails, exit with error
            errorMessage("Error: shell command \"\(cmd)\" execution failed")
            exit(EXIT_FAILURE)
        }
        // Return shell command termination status
        return shellCmd.terminationStatus
    }

    // Function to get app path using Spotlight shell command (mdfind)
    func getAppPath(_ app: String) -> String {
        // Make app mutable (it's immutable by default)
        var app = app
        // If app doesn't end in ".app", add it
        if !app.hasSuffix(".app") { app.append(".app") }
        // Define cmd, first as string, then as array
        let cmd = "mdfind -name " + app
        let cmdArray = cmd.components(separatedBy: " ")
        // Create new instances of Process() and Pipe()
        let getAppPathCmd = Process()
        let pipe = Pipe()
        do {
            // Output stdout and stderr to pipe
            getAppPathCmd.standardOutput = pipe
            getAppPathCmd.standardError = pipe
            // Set executable URL to /usr/bin/env so we can use executables in PATH
            getAppPathCmd.executableURL = URL(filePath: "/usr/bin/env")
            // Pass commandArray to arguments
            getAppPathCmd.arguments = cmdArray
            // Prevent accidental user input
            getAppPathCmd.standardInput = nil
            // Try to run shell command
            try getAppPathCmd.run()
        } catch {
            // If shell command execution fails, exit with error
            errorMessage("Error: shell command \"\(cmd)\" execution failed")
            exit(EXIT_FAILURE)
        }
        // Capture shell command output by reading pipe like a file
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        // Convert data to output, a UTF-8 encoded string stripped of newlines
        let output = String(data: data, encoding: .utf8)!.trimmingCharacters(in: .newlines)
        // If output ends in app, extract only the app path and return it, else return an empty string
        if output.hasSuffix(app) {
            return String(output.suffix(from: output.firstIndex(of: "/") ?? output.startIndex))
        } else {
            return ""
        }
    }

    // Function to check if a process is running
    func isAppRunning(_ app: String) -> Bool {
        // Create array of running applications and reduce the array to just names
        let apps = NSWorkspace.shared.runningApplications.compactMap { $0.localizedName }
        // Search for specified app in array of running applications
        if apps.contains(app) {
            return true
        } else {
            return false
        }
    }

    // Function to show preamble when verbose mode is enabled
    func verbosePreamble() {
        verboseMessage("""
        \(versionText)
        
        Verbose mode enabled
        
        """)
    }

    // Function to define start commands
    func startCmd() -> Int {
        // If dry run mode, bypass command execution
        if dryRunMode {
            print("DRY RUN: START COMMAND DISABLED")
            return 0
        }
        // If OneDrive is running, exit with error
        if isAppRunning("OneDrive") {
            return 1
        }
        // Run shell command
        verboseMessage("Running shell command: open -a OneDrive")
        if execShellCmd("open -a OneDrive") == 0 {
            return 0
        } else {
            return 1
        }
    }

    // Function to define stop commands
    func stopCmd() -> Int {
        // If dry run mode, bypass command execution
        if dryRunMode {
            print("DRY RUN: STOP COMMAND DISABLED")
            return 0
        }
        // If OneDrive is not running, exit with error
        if !isAppRunning("OneDrive") {
            return 1
        }
        // Run shell command
        verboseMessage("Running shell command: killall OneDrive")
        if execShellCmd("killall OneDrive") == 0 {
            return 0
        } else {
            return 1
        }
    }

    // Function to show OneDrive status
    func showOneDriveStatus() {
        if isAppRunning("OneDrive") {
            print("OneDrive is running")
        } else {
            print("OneDrive is not running")
        }
    }

    // Function to show OneDrive path
    func showOneDrivePath() {
        let result = getAppPath("OneDrive")
        if !result.isEmpty {
            print(result)
        } else {
            errorMessage("Error: OneDrive is not installed")
        }
    }

    // Function to start OneDrive
    func startOneDrive() {
        optionalMessage("Starting OneDrive...")
        if startCmd() == 0 {
            optionalMessage("OneDrive started!")
        } else {
            errorMessage("Error: OneDrive is already running")
            exit(EXIT_FAILURE)
        }
    }

    // Function to stop OneDrive
    func stopOneDrive() {
        optionalMessage("Stopping OneDrive...")
        if stopCmd() == 0 {
            optionalMessage("OneDrive stopped!")
        } else {
            errorMessage("Error: OneDrive is not running")
            exit(EXIT_FAILURE)
        }
    }

    // Function to restart OneDrive
    func restartOneDrive() {
        optionalMessage("Restarting OneDrive...")
        if stopCmd() != 0 {
            errorMessage("Error: OneDrive is not running")
            exit(EXIT_FAILURE)
        }
        // Wait for termination before proceeding
        verboseMessage("Waiting for termination before proceeding...")
        Thread.sleep(forTimeInterval: 5)
        if startCmd() == 0 {
            optionalMessage("OneDrive restarted!")
        } else {
            errorMessage("Error: OneDrive unable to start")
            exit(EXIT_FAILURE)
        }
    }

}

// Command/option parsing begins here

// Mode flags
struct ModeFlags: ParsableArguments {
    @Flag(
        name: [.customLong("dry-run")],
        help: .hidden
    ) var dryRun = false
    @Flag(
        name: [.short, .customLong("quiet")],
        help: "Suppress optional messages."
    ) var quiet = false
    @Flag(
        name: [.short, .customLong("verbose")],
        help: "Show all messages."
    ) var verbose = false
}

// Root command
@main
struct Root: @preconcurrency ParsableCommand {
    // Declare version (enables --version flag) and subcommands
    @MainActor static let configuration = CommandConfiguration(
        commandName: "odctl",
        version: versionText,
        subcommands: [Status.self, Where.self, Which.self, Start.self, Stop.self, Restart.self]
    )
}

// Subcommands
extension Root {

    struct Status: @preconcurrency ParsableCommand {
        // Configure command name and help text
        @MainActor static let configuration = CommandConfiguration(
            commandName: "status",
            abstract: "Show OneDrive status."
        )
        // Run command
        @MainActor mutating func run() throws {
            let odctl = ODCtl()
            odctl.showOneDriveStatus()
        }
    }

    struct Where: @preconcurrency ParsableCommand {
        // Configure command name and help text
        @MainActor static let configuration = CommandConfiguration(
            commandName: "where",
            abstract: "Alias of which (hidden)",
            shouldDisplay: false
        )
        // Run command
        @MainActor mutating func run() throws {
            let odctl = ODCtl()
            odctl.showOneDrivePath()
        }
    }

    struct Which: @preconcurrency ParsableCommand {
        // Configure command name and help text
        @MainActor static let configuration = CommandConfiguration(
            commandName: "which",
            abstract: "Show OneDrive path."
        )
        // Run command
        @MainActor mutating func run() throws {
            let odctl = ODCtl()
            odctl.showOneDrivePath()
        }
    }

    struct Start: @preconcurrency ParsableCommand {
        // Configure command name and help text
        @MainActor static let configuration = CommandConfiguration(
            commandName: "start",
            abstract: "Start OneDrive."
        )
        // Add mode flags to command
        @OptionGroup var modeFlags: ModeFlags
        // Run command
        @MainActor mutating func run() throws {
            let odctl = ODCtl()
            if modeFlags.dryRun { odctl.dryRunMode = true }
            if modeFlags.quiet { odctl.quietMode = true }
            if modeFlags.verbose { odctl.verboseMode = true }
            odctl.verbosePreamble()
            odctl.startOneDrive()
        }
    }

    struct Stop: @preconcurrency ParsableCommand {
        // Configure command name and help text
        @MainActor static let configuration = CommandConfiguration(
            commandName: "stop",
            abstract: "Stop OneDrive."
        )
        // Add mode flags to command
        @OptionGroup var modeFlags: ModeFlags
        // Run command
        @MainActor mutating func run() throws {
            let odctl = ODCtl()
            if modeFlags.dryRun { odctl.dryRunMode = true }
            if modeFlags.quiet { odctl.quietMode = true }
            if modeFlags.verbose { odctl.verboseMode = true }
            odctl.verbosePreamble()
            odctl.stopOneDrive()
        }
    }

    struct Restart: @preconcurrency ParsableCommand {
        // Configure command name and help text
        @MainActor static let configuration = CommandConfiguration(
            commandName: "restart",
            abstract: "Restart OneDrive."
        )
        // Add mode flags to command
        @OptionGroup var modeFlags: ModeFlags
        // Run command
        @MainActor mutating func run() throws {
            let odctl = ODCtl()
            if modeFlags.dryRun { odctl.dryRunMode = true }
            if modeFlags.quiet { odctl.quietMode = true }
            if modeFlags.verbose { odctl.verboseMode = true }
            odctl.verbosePreamble()
            odctl.restartOneDrive()
        }
    }

}
