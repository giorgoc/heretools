# HereTools

Temporary folder sharing for Windows, available from Explorer or the command line.

> Right-click a folder -> HereTools -> choose a protocol -> share it immediately.

The CLI provides the same workflow with commands such as `heretools http`, `heretools ftp`, and `heretools sftp`.

## What is HereTools?

HereTools is a lightweight, portable Windows utility suite for ad-hoc folder sharing. It is designed around a simple principle:

- simple
- temporary
- portable

There is no permanent server, Windows service, account-management system, or configuration database. Each session is started for a selected folder and ends when its utility window is closed.

HereTools supports:

- HTTP Here for temporary read-only web sharing
- FTP Here for temporary read/write FTP access
- SFTP Here for temporary encrypted file access
- Cloudflare Quick Tunnel for public HTTPS exposure of an HTTP Here session

## Features

- Windows Explorer context-menu integration
- Command-line access through `heretools.cmd`
- Current-directory fallback for CLI commands
- Explicit network-interface selection
- Automatic free-port suggestion with manual override
- Temporary random credentials for FTP and SFTP
- Read-only HTTP directory browsing and downloads
- Optional Cloudflare public HTTPS tunnel for HTTP
- Bundled SFTPGo and Cloudflared executables
- No permanent service or router configuration
- PowerShell 7+ preferred, with Windows PowerShell fallback where practical

## Explorer Usage

After installation, the context menu is arranged as follows:

```text
HereTools
├── SFTP Here
├── FTP Here
└── HTTP Here
```

It is available in both places:

1. Right-click a folder in Explorer.
2. Right-click the background inside an open folder.

Choose a protocol, select the network interface and port when prompted, then use the displayed connection information. Close the HereTools window when finished to stop the temporary service.

## CLI Usage

```text
heretools
heretools --help
heretools --version

heretools http
heretools ftp
heretools sftp
```

An explicit folder can be supplied. Quoted paths containing spaces are supported:

```text
heretools http "C:\Projects\Demo"
heretools ftp "C:\Transfer"
heretools sftp "C:\Shared Files"
```

When no path is supplied, HereTools uses the current working directory:

```text
cd "C:\Projects\Demo"
heretools http
```

The protocol names are case-insensitive. Unknown commands are rejected with a hint to display the help screen.

## HTTP Here

HTTP Here provides temporary, read-only HTTP sharing.

- Directory browsing
- File downloads
- `index.html` and `index.htm` default documents
- MIME type handling
- Directory redirects where appropriate
- Standard 403, 404, 405 and 500 responses
- Root-directory containment and path-traversal protection

HTTP Here does not provide upload, edit, delete, WebDAV, or authentication. Local HTTP sharing is plain HTTP and should be used only where that exposure is appropriate.

### Cloudflare Public Tunnel

When available, HTTP Here can use Cloudflare Quick Tunnel as a public exposure option:

```text
Selected folder
    -> HTTP Here on 127.0.0.1:<port>
    -> cloudflared
    -> https://random.trycloudflare.com
```

The public URL is temporary and randomly assigned; no fixed hostname is promised. Quick Tunnel use does not require router port-forwarding or a separate HereTools tunnel command. The local HTTP server binds to loopback, and closing the HereTools window terminates both the local server and the tunnel process.

## FTP Here

FTP Here provides temporary read/write access through plain FTP.

- The selected folder becomes the FTP root.
- A random username and password are generated for the session.
- A network interface and port are selected before launch.
- Files can be read and written within the selected root.
- The service is powered by the bundled SFTPGo executable.

FTP is plain FTP, not FTPS. Its traffic is not encrypted, so use it only on a network and in a situation where plain FTP is acceptable.

## SFTP Here

SFTP Here provides temporary read/write access over encrypted SSH/SFTP transport.

- The selected folder becomes the SFTP root.
- A random username and password are generated for the session.
- A network interface and port are selected before launch.
- Runtime data and host-key material are kept outside the shared folder.
- The service is powered by the bundled SFTPGo executable.

Example connection format:

```text
sftp -P 28419 u8k3m2x9ab@192.168.1.20
```

The displayed username, password, address and port are generated for the active session and should not be reused as permanent credentials.

## Network Interface Selection

HereTools lets you choose the exact local interface to which a service binds. A typical list may include loopback, Ethernet, Wi-Fi, Tailscale, ZeroTier, or virtual adapters:

```text
[1] 127.0.0.1        Loopback
[2] 192.168.1.20     Ethernet
[3] 100.x.x.x        Tailscale
[4] Public Tunnel    Cloudflare
```

HTTP Here can offer Cloudflare as a separate network-exposure option. FTP and SFTP currently use appropriate local interfaces and do not automatically become public tunnels.

Choose the interface deliberately: it determines where the service can be reached.

## Port Selection

HereTools suggests an available temporary port for each session.

- Press Enter to accept the displayed port.
- Enter another port when needed.
- Invalid port numbers are rejected.
- Availability is checked before the service starts.
- The application re-prompts instead of silently replacing the selected port.

## Installation

HereTools is portable. From the repository or extracted package directory, run:

```powershell
.\install.ps1
```

The installer:

- validates the expected package files
- installs the Explorer context-menu entries for folders and folder backgrounds
- adds the HereTools package root to the current user's `PATH`
- preserves unrelated user PATH entries
- does not modify the machine-wide PATH
- normally does not require Administrator rights

The package root is added because it contains `heretools.cmd`. Open a new terminal session after installation before using the `heretools` command, so the new PATH is visible to that session.

Running the installer again is safe and does not create duplicate PATH entries.

## Uninstallation

From the same package directory, run:

```powershell
.\uninstall.ps1
```

The uninstaller removes:

- current HereTools Explorer registrations
- legacy standalone HereTools protocol registrations, when present
- the exact HereTools package-root entry from the current user's PATH

It does not delete the repository or package files and does not modify the machine-wide PATH. Running it when HereTools is already absent is supported.

## Project Structure

```text
HereTools/
├── heretools.cmd             Windows CLI launcher
├── heretools.ps1             CLI dispatcher and version definition
├── install.ps1               Per-user installer
├── uninstall.ps1             Per-user uninstaller
├── icons/
│   ├── heretools.ico         Explorer menu icon
│   └── heretools.png         Project image asset
├── utils/
│   ├── HTTPHere.ps1          Temporary read-only HTTP server
│   ├── FTPHere.ps1           Temporary FTP launcher
│   └── SFTPHere.ps1          Temporary SFTP launcher
├── lib/
│   ├── sftpgo.exe            FTP/SFTP server dependency
│   └── cloudflared.exe       Cloudflare Quick Tunnel dependency
└── tests/                    Dependency-free automated test suite
```

## Dependencies

HereTools itself is implemented in PowerShell. The package includes:

- `lib\sftpgo.exe` for FTP and SFTP sessions
- `lib\cloudflared.exe` for optional Cloudflare Quick Tunnel exposure

The bundled third-party components remain subject to their own licenses and distribution terms.

## Requirements

- Windows 11 is the primary target.
- PowerShell 7+ is recommended.
- Windows PowerShell 5.1 is used as a fallback where practical.
- The required third-party binaries are bundled with the package.

## Security Notes

- SFTP encrypts the file-transfer connection.
- FTP is not encrypted.
- Local HTTP is plain HTTP and has no authentication.
- Cloudflare mode exposes the selected folder publicly over temporary HTTPS.
- HTTP is read-only; FTP and SFTP allow read/write access.
- Access is restricted to the selected root folder.
- Temporary FTP/SFTP credentials are generated per session and are not persisted.
- Closing the utility window stops the temporary service and its child processes.
- Select the network interface carefully, especially when using a non-loopback adapter.

## Testing and Development

The repository includes a dependency-free PowerShell test runner and focused test files:

```powershell
.\tests\Test-HereTools.ps1
```

The suite covers CLI behavior, protocol implementation invariants, installer and uninstaller PATH handling, registry integration, cleanup paths, and Cloudflare wiring. Tests that require a live SFTPGo process, a running HTTP session, child-process inspection, or external Cloudflare connectivity are marked opt-in so routine test runs remain safe and self-contained.

## License

HereTools source code is licensed under the MIT License. See [LICENSE](LICENSE). Bundled third-party binaries remain subject to their own licenses.

## Philosophy

> Simple. Temporary. Portable. Here.
