# AGENTS.md

# HereTools

HereTools is a lightweight, portable Windows utility suite for instantly exposing the current folder through common network protocols.

The core product idea is:

> Right-click a folder -> HereTools -> choose a protocol -> the folder is immediately available.

HereTools is designed for temporary, ad-hoc sharing rather than permanent server deployment.

Closing the utility window must stop the share and terminate any processes created for that session.

## Project Status

HereTools currently supports:

- HTTP Here
- FTP Here
- SFTP Here
- Cloudflare Quick Tunnel support for HTTP Here

Current Explorer context menu:

- HereTools
  - SFTP Here
  - FTP Here
  - HTTP Here

The existing protocol implementations are working.

Preserve existing behavior unless a requested change explicitly requires modifying it.

## Core Product Philosophy

HereTools follows a:

> Here. Now. Temporary.

model.

The user should not need to understand server configuration, firewall rules, daemon management, or networking internals.

The intended experience is:

1. Select a folder.
2. Choose a HereTools protocol.
3. Select how the service should be exposed.
4. Accept or choose a port.
5. Receive connection information.
6. Close the window when finished.

There should be no permanent daemon, Windows service, configuration database, account-management system, or admin interface unless explicitly required by a future feature.

Temporary behavior is a core design requirement.

## Repository Structure

Expected structure:

    HereTools/
    ├── install.ps1
    ├── uninstall.ps1
    ├── README.md
    ├── LICENSE
    │
    ├── icons/
    │   └── heretools.ico
    │
    ├── utils/
    │   ├── HTTPHere.ps1
    │   ├── FTPHere.ps1
    │   └── SFTPHere.ps1
    │
    └── lib/
        ├── sftpgo.exe
        └── cloudflared.exe

Planned CLI additions:

    HereTools/
    ├── heretools.ps1
    └── heretools.cmd

Do not hardcode the developer's local filesystem paths.

Internal files must be resolved relative to the HereTools installation directory whenever possible.

Paths containing spaces must work correctly.

# Technologies

## PowerShell

PowerShell is the main implementation language.

It is responsible for:

- Console UI
- Windows Explorer integration
- Network-interface discovery
- Port selection and validation
- Secure temporary credential generation
- Process orchestration
- HTTP serving
- Installer/uninstaller behavior
- Future CLI dispatching

Prefer PowerShell 7+.

Windows PowerShell 5.1 should remain a fallback where practical.

The installer should prefer `pwsh.exe` when available and fall back to `powershell.exe` only when PowerShell 7+ is unavailable.

Do not unnecessarily restrict new code to PowerShell 5.1 if PowerShell 7 provides a better implementation.

## SFTPGo

Bundled binary:

    lib/sftpgo.exe

SFTPGo currently provides the underlying temporary server functionality for:

- SFTP Here
- FTP Here

HereTools launches SFTPGo in portable mode.

SFTPGo must not require a machine-wide installation.

When locating SFTPGo:

1. Prefer the bundled executable under `lib`.
2. Optionally support installed copies as fallback.
3. Never require a hardcoded developer-specific path.

Suppress unnecessary SFTPGo console output in the normal UI.

## cloudflared

Bundled binary:

    lib/cloudflared.exe

It provides Cloudflare Quick Tunnel functionality for HTTP Here.

Cloudflare Quick Tunnel currently allows:

    HTTP Here
        |
    127.0.0.1:<temporary-port>
        |
    cloudflared
        |
    https://random.trycloudflare.com
        |
    Public Internet

Cloudflare tunneling is considered a network-exposure method, not a separate HereTools protocol.

Do not create a separate `Tunnel Here` command unless product requirements change.

For Cloudflare public exposure, the local HTTP server should bind to loopback and be exposed externally by `cloudflared`.

Do not unnecessarily expose the local listener on all interfaces.

Closing HTTP Here must also terminate its `cloudflared` child process.

# Protocols

## HTTP Here

HTTP Here is implemented directly in PowerShell.

Purpose:

> Temporary read-only HTTP file sharing.

Current expected functionality:

- HTTP GET
- HTTP HEAD
- Directory browsing
- File downloads
- MIME type handling
- `index.html` default document
- `index.htm` default document
- Directory redirects where appropriate
- Path traversal protection
- Root-directory containment enforcement

Expected HTTP responses include:

- 200 OK
- 301 Moved Permanently
- 400 Bad Request
- 403 Forbidden
- 404 Not Found
- 405 Method Not Allowed
- 500 Internal Server Error

Unexpected processing failures should return:

    500 Internal Server Error

instead of leaking PowerShell/.NET exception details to remote clients.

HTTP Here intentionally does not currently support:

- Upload
- Edit
- Delete
- Authentication
- WebDAV

HTTP Here is read-only by design.

## FTP Here

FTP Here provides temporary FTP access through SFTPGo.

Expected behavior:

- Selected folder becomes the FTP root.
- Read/write access is allowed inside that root.
- Random username is generated for each session.
- Random password is generated for each session.
- User chooses a network interface.
- A free port is suggested.
- User may override the suggested port.
- Requested port must be validated before starting.
- Closing the window stops FTP access.

FTP is intentionally plain FTP, not FTPS.

The UI should make no misleading security claims about plain FTP.

## SFTP Here

SFTP Here provides temporary SFTP access through SFTPGo.

Expected behavior:

- Selected folder becomes the SFTP root.
- Read/write access is allowed inside that root.
- Random username is generated for each session.
- Random password is generated for each session.
- User chooses a network interface.
- A free port is suggested.
- User may override the suggested port.
- Requested port must be validated before starting.
- Closing the window stops SFTP access.

SFTPGo host keys/configuration must not be created inside the shared directory.

Runtime/config data should live outside the shared folder, for example under a HereTools/SFTPHere area in `%LOCALAPPDATA%`.

# Network Interface UX

Explicit network-interface selection is an important HereTools concept.

Example:

    SELECT NETWORK INTERFACE

    [1]  127.0.0.1         Loopback
    [2]  192.168.199.254   Ethernet
    [3]  192.168.56.1      Ethernet 2
    [4]  100.107.236.72    Tailscale
    [5]  172.22.80.1       vEthernet (Default Switch)
    [6]  172.29.160.1      vEthernet (WSL (Hyper-V firewall))
    [7]  172.24.49.195     ZeroTier One
    [8]  Public Tunnel     Cloudflare

    Select interface [8]:

Important behavior:

- Do not insert unnecessary blank lines between local interfaces and tunnel options.
- Keep columns visually aligned.
- Avoid accidental extra spaces before labels such as `Cloudflare`.
- For HTTP Here, when Cloudflare Quick Tunnel is available, the Cloudflare option is the default selection.
- Pressing Enter should accept the displayed default.
- FTP and SFTP currently expose only appropriate local interfaces unless future tunneling support is explicitly added.

Protocol and exposure mechanism are separate concepts.

Conceptually:

    HTTP
    ├── Loopback
    ├── Ethernet
    ├── Tailscale
    ├── ZeroTier
    └── Cloudflare Public Tunnel

Future exposure mechanisms may be added within this model.

# Port Selection

HereTools suggests an available random port.

Example:

    Port [28419]:

Behavior:

- Press Enter to accept the suggested port.
- User may type another port.
- Validate the requested port.
- Reject invalid port numbers.
- Reject ports that cannot be bound on the selected interface.
- Re-prompt cleanly rather than failing the whole application.

Do not assume that a random port is available merely because it was randomly selected.

# Credentials

FTP and SFTP use temporary randomly generated credentials.

Requirements:

- Random username per session.
- Random password per session.
- Avoid ambiguous characters where useful for manual copying.
- Do not use static usernames such as `hermes`.
- Do not persist credentials.
- Display them clearly only for the active session.

Example:

    CONNECT

    sftp -P 28419 u9f4m2k7qx@192.168.1.10

    CREDENTIALS

    Username : u9f4m2k7qx
    Password : generated-password

Do not include FTP passwords inside FTP URLs by default.

# Console UI / UX

The current console UI is intentional.

Preserve its visual language unless specifically asked to redesign it.

## Colors

Current color hierarchy:

- Cyan: application title / H1 / key accents
- Magenta: section headings / H2
- White: primary values
- DarkGray: secondary information
- Green: success, listening state, connection URL/command
- Yellow: warnings / transient status / credentials where currently used
- Red: errors

Example header:

    HTTP HERE v1.2.x
    Instant temporary read-only HTTP sharing
    Copyright (c) 2026 Aria. All rights reserved.

Do not add a separate `By Aria` line.

The copyright line already provides authorship.

## UI Style

Prefer:

- Whitespace
- Alignment
- Color
- Simple typography
- Compact spacing

Avoid decorative ASCII boxes such as:

    +----------------------------------------------------+
    |                    TITLE                           |
    +----------------------------------------------------+

Avoid long divider lines such as:

    ------------------------------------------------------------

These are considered visually dated and should not be reintroduced.

Do not use decorative Unicode box-drawing characters.

They have previously caused encoding problems under Windows PowerShell.

The UI should remain clean in both PowerShell 7 and fallback environments.

Small spacing/alignment inconsistencies should be treated as UI defects.

# Explorer Integration

`install.ps1` creates a nested Windows Explorer context menu.

Expected hierarchy:

    HereTools
    ├── SFTP Here
    ├── FTP Here
    └── HTTP Here

The HereTools parent menu uses:

    icons/heretools.ico

Child items should not currently have separate icons.

The context menu should be installed for:

1. Right-click on a folder.
2. Right-click on the background inside a folder.

The installer should use per-user registry locations where possible and should not require Administrator rights unnecessarily.

The installer must be idempotent.

Running it multiple times should update/recreate the HereTools registration cleanly.

# Installer

`install.ps1` is responsible for:

- Validating expected package files.
- Discovering PowerShell 7+.
- Falling back to Windows PowerShell 5.1.
- Removing legacy HereTools context-menu registrations.
- Installing the current nested HereTools menu.
- Registering the parent HereTools icon.
- Registering protocol commands.
- In the future, installing CLI/PATH support.

The installer should display clear success or failure feedback and remain open long enough for the user to read the result.

Avoid machine-specific paths.

Use `$PSScriptRoot` to derive the package root.

# Uninstaller

`uninstall.ps1` must remove only resources created by HereTools.

Current responsibilities:

- Remove HereTools parent context-menu registrations.
- Remove legacy standalone `HTTPHere`, `FTPHere`, and `SFTPHere` context entries if present.
- Leave project files untouched.

Future responsibilities:

- Remove HereTools CLI PATH registration.
- Remove only the exact PATH entry installed by HereTools.
- Never damage or rewrite unrelated PATH entries.

The uninstaller must be safe to run even if HereTools is already absent.

# Planned CLI

HereTools should gain a proper CLI.

Desired commands:

    heretools
    heretools --help
    heretools --version

    heretools http
    heretools ftp
    heretools sftp

Explicit folders should be supported:

    heretools http "C:\Sites\Demo"
    heretools ftp "D:\Transfer"
    heretools sftp "C:\Files"

Without an explicit folder:

    heretools http

the current working directory should be used.

Preferred architecture:

    heretools.cmd
        |
    heretools.ps1
        |
    utils/HTTPHere.ps1
    utils/FTPHere.ps1
    utils/SFTPHere.ps1

`heretools.cmd` exists so Windows users can type:

    heretools http

instead of needing to invoke a `.ps1` file manually.

The installer should add the appropriate HereTools CLI location to the current user's PATH.

The uninstaller must remove that exact PATH entry safely.

# CLI Design Principles

Prefer:

    heretools http
    heretools ftp
    heretools sftp

rather than:

    heretools --http
    heretools --ftp
    heretools --sftp

Use flags for modifiers and metadata, for example:

    heretools --help
    heretools --version

The CLI should be thin.

Do not duplicate protocol implementation logic inside the CLI dispatcher.

The CLI should dispatch to the existing protocol scripts.

Explorer and CLI workflows should use the same underlying implementations.

# Security and Safety

HereTools exposes local files over networks.

Treat security-related behavior as production code, even though the utility is small.

Requirements:

- Never expose paths outside the selected root.
- Prevent directory traversal.
- Bind only to the selected interface.
- Do not silently replace a selected interface with `0.0.0.0`.
- Validate ports before binding.
- Generate temporary credentials securely.
- Do not persist temporary credentials.
- Do not leak internal exceptions over HTTP.
- Do not expose server implementation details in HTTP 500 pages.
- Public Internet exposure must be visually obvious.
- Cloudflare Quick Tunnel must use loopback for its local origin.
- Child processes must be terminated when the HereTools session ends.
- Do not leave orphaned `sftpgo.exe` or `cloudflared.exe` processes.
- Do not create configuration or SSH host-key files inside shared directories.

# Portability

HereTools is intended to be portable.

Target user flow:

    Download / clone HereTools
            |
    Run install.ps1
            |
    Use Explorer or CLI

Third-party executables are bundled under `lib`.

The project must not require SFTPGo or cloudflared to be separately installed.

Relative package paths should be preferred.

The package should continue working if the HereTools directory is moved and `install.ps1` is run again.

# External Dependencies

Current bundled third-party components:

    lib/sftpgo.exe
    lib/cloudflared.exe

Do not modify, recompile, patch, or replace these binaries casually.

Do not change licensing or third-party distribution strategy without explicit instruction.

The HereTools source is currently licensed under MIT.

Bundled third-party software remains subject to its own licenses.

The repository is currently private.

Before any public distribution/release, licensing and third-party attribution/compliance should receive a dedicated review.

# Product Scope

HereTools should not become a general network-administration suite.

A feature belongs in HereTools when it naturally answers:

> I am in this folder. Do something useful with it here.

Good examples:

- HTTP Here
- FTP Here
- SFTP Here
- Temporary public HTTP tunnel
- Future lightweight "Here" operations

Questionable examples:

- Persistent server management
- General firewall administration
- Router configuration
- Permanent Cloudflare infrastructure
- User/account administration
- Full web hosting control panels
- Generic network scanning suites

Favor simplicity over feature count.

# Engineering Rules for Agents

When modifying HereTools:

1. Inspect the existing implementation before changing it.
2. Preserve known-working behavior.
3. Do not perform speculative refactors.
4. Do not redesign the console UI unless explicitly requested.
5. Do not introduce new dependencies without a concrete reason.
6. Keep Explorer and future CLI behavior consistent.
7. Resolve project resources relative to the repository/package root.
8. Test paths containing spaces.
9. Keep installation and uninstallation idempotent.
10. Avoid requiring Administrator privileges unless technically unavoidable.
11. Preserve temporary-session semantics.
12. Ensure child processes terminate with their owning utility.
13. Do not silently broaden network exposure.
14. Treat file-root containment and traversal protection as critical.
15. Keep implementation understandable; HereTools should remain a small utility suite.

# Agent Change Discipline

Do not change unrelated code while implementing a requested task.

Before editing:

- Identify the exact files involved.
- Understand the existing flow.
- Preserve UI/UX conventions.
- Preserve protocol semantics.

After editing:

- Validate PowerShell syntax.
- Test the affected utility.
- Verify paths with spaces.
- Verify selected-interface binding.
- Verify port validation.
- Verify child-process cleanup where relevant.
- Verify installer/uninstaller behavior when changed.
- Verify no unrelated behavior regressed.

Do not declare completion solely because code was written.

Completion requires reasonable validation of the requested behavior.

# Current Priority

The immediate planned milestone is:

## HereTools CLI

Implement:

    heretools
    heretools --help
    heretools --version
    heretools http [path]
    heretools ftp [path]
    heretools sftp [path]

Requirements:

- Use current directory when `[path]` is omitted.
- Reuse existing protocol scripts.
- Add a clean Windows command launcher.
- Update installer to add HereTools CLI to the user PATH.
- Update uninstaller to safely remove the HereTools PATH entry.
- Preserve the current Explorer context-menu workflow.
- Preserve the existing protocol UI/UX.
- Avoid unnecessary refactoring of HTTPHere, FTPHere, or SFTPHere.

# Guiding Principle

When uncertain, prefer the solution that best preserves:

> Simple. Temporary. Portable. Here.