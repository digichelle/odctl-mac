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
    Version 1.0.0-20261109-01
    Copyright © 2026 Michelle Catherine Marcó
    MIT License: https://opensource.org/license/MIT
    """

// Define functions
@MainActor
class ODCtl {
    
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
    
    // Function to check if a process is running
    func isAppRunning(_ app: String) -> Bool {
        let apps = NSWorkspace().runningApplications.compactMap { $0.localizedName }
        if apps.contains(app) {
            return true
        } else {
            return false
        }
    }
    
    // Function to check if app is installed
    // Returns both installed status and path
    @available(macOS 13.0, *)
    func isAppInstalled(_ app: String) -> (installed: Bool, appPath: String) {
        // Make app mutable (it's immutable by default)
        var app = app
        // If supplied app name doesn't end in ".app", add it
        if !app.hasSuffix(".app") {
            app.append(".app")
        }
        // Use Spotlight search (mdfind) to locate app
        let spotlightCmd = Process()
        let pipe = Pipe()
        do {
            spotlightCmd.standardOutput = pipe
            spotlightCmd.standardError = pipe
            spotlightCmd.executableURL = URL(filePath: "/usr/bin/env")
            spotlightCmd.arguments = ["mdfind", app]
            spotlightCmd.standardInput = nil
            try spotlightCmd.run()
        } catch {
            errorMessage("Error: shell command \"mdfind \(app)\" execution failed")
            exit(EXIT_FAILURE)
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        // If output ends in app, return installed status true and app path
        // Else return installed status false and empty path
        // This is accomplished by checking if the output ends in app (if it doesn't, it's not installed)
        if output.trimmingCharacters(in: .newlines).hasSuffix(app) {
            // Determining the app path is accomplished by searching output for the first instance of "/" and extracting everything from that point forward (except newlines)
            return (installed: true, appPath: String(output.suffix(from: output.firstIndex(of: "/") ?? output.startIndex)).trimmingCharacters(in: .newlines))
        } else {
            return (installed: false, appPath: "")
        }
    }
    
    // Function to execute a specified shell command, with options
    @available(macOS 13.0, *)
    func execShellCmd(_ cmd: String) -> Int32 {
        let cmdArray = cmd.components(separatedBy: " ")
        let shellCmd = Process()
        do {
            shellCmd.executableURL = URL(filePath: "/usr/bin/env")
            shellCmd.arguments = cmdArray
            try shellCmd.run()
            shellCmd.waitUntilExit()
        } catch {
            errorMessage("Error: shell command \"\(cmd)\" execution failed")
            exit(EXIT_FAILURE)
        }
        return shellCmd.terminationStatus
    }
    
    // Function to show preamble when verbose mode is enabled
    func verbosePreamble() {
        verboseMessage("""
        \(versionText)
        
        Verbose mode enabled
        
        """)
    }
    
    // Function to define start commands
    @available(macOS 13.0, *)
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
    @available(macOS 13.0, *)
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
        // Note: killall sends SIGTERM by default, as opposed to SIGKILL
        // (In other words: don't worry, this is a clean termination)
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
    @available(macOS 13.0, *)
    func showOneDrivePath() {
        let result: (installed: Bool, appPath: String) = isAppInstalled("OneDrive")
        if result.installed {
            print(result.appPath)
        } else {
            errorMessage("Error: OneDrive is not installed")
        }
    }
    
    // Function to start OneDrive
    @available(macOS 13.0, *)
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
    @available(macOS 13.0, *)
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
    @available(macOS 13.0, *)
    func restartOneDrive() {
        optionalMessage("Restarting OneDrive...")
        if stopCmd() != 0 {
            errorMessage("Error: OneDrive is not running")
            exit(EXIT_FAILURE)
        }
        // Wait 5 seconds until start
        verboseMessage("Waiting 5 seconds until start...")
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
@available(macOS 13.0, *)
struct RootCmd: ParsableCommand {
    // Declare version (enables --version flag) and subcommands
    static let configuration = CommandConfiguration(
        commandName: "odctl",
        version: versionText,
        subcommands: [StatusCmd.self, WhereCmd.self, WhichCmd.self, StartCmd.self, StopCmd.self, RestartCmd.self]
    )
}

// Subcommands
@available(macOS 13.0, *)
extension RootCmd {

    struct StatusCmd: @preconcurrency ParsableCommand {
        // Configure command name and help text
        static let configuration = CommandConfiguration(
            commandName: "status",
            abstract: "Show OneDrive status."
        )
        // Run command
        @MainActor
        mutating func run() throws {
            let odctl = ODCtl()
            odctl.showOneDriveStatus()
        }
    }

    struct WhereCmd: @preconcurrency ParsableCommand {
        // Configure command name and help text
        static let configuration = CommandConfiguration(
            commandName: "where",
            abstract: "Alias of which (hidden)",
            shouldDisplay: false
        )
        // Run command
        @MainActor
        mutating func run() throws {
            let odctl = ODCtl()
            odctl.showOneDrivePath()
        }
    }

    struct WhichCmd: @preconcurrency ParsableCommand {
        // Configure command name and help text
        static let configuration = CommandConfiguration(
            commandName: "which",
            abstract: "Show OneDrive path."
        )
        // Run command
        @MainActor
        mutating func run() throws {
            let odctl = ODCtl()
            odctl.showOneDrivePath()
        }
    }

    @available(macOS 13.0, *)
    struct StartCmd: @preconcurrency ParsableCommand {
        // Configure command name and help text
        static let configuration = CommandConfiguration(
            commandName: "start",
            abstract: "Start OneDrive."
        )
        // Add mode flags to command
        @OptionGroup var modeFlags: ModeFlags
        // Run command
        @MainActor
        mutating func run() throws {
            let odctl = ODCtl()
            if modeFlags.dryRun { odctl.dryRunMode = true }
            if modeFlags.quiet { odctl.quietMode = true }
            if modeFlags.verbose { odctl.verboseMode = true }
            odctl.verbosePreamble()
            odctl.startOneDrive()
        }
    }

    @available(macOS 13.0, *)
    struct StopCmd: @preconcurrency ParsableCommand {
        // Configure command name and help text
        static let configuration = CommandConfiguration(
            commandName: "stop",
            abstract: "Stop OneDrive."
        )
        // Add mode flags to command
        @OptionGroup var modeFlags: ModeFlags
        // Run command
        @MainActor
        mutating func run() throws {
            let odctl = ODCtl()
            if modeFlags.dryRun { odctl.dryRunMode = true }
            if modeFlags.quiet { odctl.quietMode = true }
            if modeFlags.verbose { odctl.verboseMode = true }
            odctl.verbosePreamble()
            odctl.stopOneDrive()
        }
    }

    @available(macOS 13.0, *)
    struct RestartCmd: @preconcurrency ParsableCommand {
        // Configure command name and help text
        static let configuration = CommandConfiguration(
            commandName: "restart",
            abstract: "Restart OneDrive."
        )
        // Add mode flags to command
        @OptionGroup var modeFlags: ModeFlags
        // Run command
        @MainActor
        mutating func run() throws {
            let odctl = ODCtl()
            if modeFlags.dryRun { odctl.dryRunMode = true }
            if modeFlags.quiet { odctl.quietMode = true }
            if modeFlags.verbose { odctl.verboseMode = true }
            odctl.verbosePreamble()
            odctl.restartOneDrive()
        }
    }
    
}
