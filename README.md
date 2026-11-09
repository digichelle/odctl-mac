# ODCtl
OneDrive command-line control for macOS, written in Swift.

## Why This Exists

Honestly, you probably don’t need this program. If you want to start or stop OneDrive from Terminal or any other macOS terminal emulator, it’s as simple as `open -a OneDrive` to start and `killall OneDrive` to stop. Seriously, that’s it. This program runs those same exact commands.

I wrote this program anyway because ~~I’m a hardcore, insatiable masochist~~ I wanted an excuse to learn Swift and Xcode, and I wanted to see if writing this kind of program was even possible with these tools. Now that I know the answer, I somewhat regret asking the question. I could’ve avoided quite a few headaches by writing a shell script instead.

So really, this program is best approached as a proof of concept and a resource. There are some potentially useful bits of Swift code here. For example:

- If you’re looking for a working implementation of the [Swift Argument Parser](https://github.com/apple/swift-argument-parser), this program has one.
- If you’re looking for a way to execute a shell command, take a look at the `execShellCmd()` function.
- If you’re looking for a way to check if an app is installed (anywhere, not just in `/Applications`), take a look at the `isAppInstalled()` (which is called by `showOneDrivePath()`).
- If you’re looking for a way to check if an app is running, take a look at `isAppRunning()` (which is called by `showOneDriveStatus()`).

Keep in mind that I’m a Swift newbie, and that this program’s code may or may not conform to best practices. Use it at your own risk.

Not a Mac user? Variants for [Linux](https://github.com/digichelle/odctl-linux) and [Windows](https://github.com/digichelle/odctl-win) also exist.

## Requirements

### Build and Run

- macOS 27 Golden Gate or higher
- Xcode 27 or higher
- [OneDrive for Mac](https://apps.apple.com/us/app/onedrive/id823766827?mt=12)

> [!NOTE]
> Earlier versions of macOS and Xcode may work, but compatibility is not guaranteed.

### Run Only

- The minimum version of macOS specified in the [OneDrive for Mac system requirements](https://support.microsoft.com/en-us/onedrive/onedrive-system-requirements#tabpanel_1_mac)
- OneDrive for Mac

## Build and Install

### Build

```
swift build -c release
```

### Install

```
sudo cp .build/release/odctl /usr/local/bin
```

> [!NOTE]
> `/usr/local/bin` is only a recommendation. Feel free to choose a different directory.

### Clean

```
swift package clean
```

## Usage

### Start OneDrive

```
odctl start
```

### Stop OneDrive

```
odctl stop
```

### Restart OneDrive

```
odctl restart
```

### Help

```
odctl --help
```

> [!TIP]
> Help for subcommands is also available. For example, for help on the `start` subcommand, run `odctl start --help`.

## License

### MIT License

Copyright © 2026 Michelle Catherine Marcó

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.