# NT Softphone for BreezeRMM

Windows Installer repack of the supplied NT Softphone 3.21.3 installer, revision 3. The application files and bundled license are unchanged. This repository is packaging and validation material, not the application source code or an official vendor release.

- 32-bit application, machine-wide installation into Program Files (x86).
- Start menu and desktop shortcuts for all users.
- Native MSI installation, repair and removal; no nested EXE installer or custom actions.
- SIP accounts and passwords are configured separately per user. No SIP credentials are included.
- Existing per-user EXE installations are not automatically migrated or removed.
- No autostart or protocol association is imposed.
- The package is unsigned.

## BreezeRMM

Download the versioned `.msi` release asset. Install silently with:

```text
msiexec.exe /i "NT-Softphone-3.21.3-3.msi" /qn /norestart
```

If Breeze adds `msiexec /i` automatically, supply only `/qn /norestart` as arguments. Accept return codes 0 (success) and 3010 (success, reboot required).

Validate on one pilot device before deploying broadly. Confirm audio, calling, and user account configuration in that environment.

## Packaging

`Product.wxs` targets WiX Toolset 3.14.1. `payload-manifest.json` records SHA-256 hashes of all 14 original application files installed by the MSI. The NSIS installer plugins and its uninstaller are not included; Windows Installer handles removal.

The validation workflow installs, repairs, checks file hashes and all-users shortcuts, and uninstalls the exact release candidate as `NT AUTHORITY\SYSTEM` on a disposable Windows runner. This verifies deployment mechanics, not SIP calling or audio hardware.
