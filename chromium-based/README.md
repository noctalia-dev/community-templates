# Chromium based

One template for native Linux Chromium browsers: Chrome, Chromium, ungoogled
Chromium, Brave (including Origin), and Helium. It sets `BrowserThemeColor` to
Noctalia's current `surface` color. The browser generates a theme from that
color; this does not recolor web pages or guarantee an exact toolbar color.

## Enable with graphical setup

Enable **Chromium based** in Noctalia's Settings → Templates. On its first
application, the template detects installed browsers and requests administrator
authentication through `pkexec` to prepare their policy files. After approval,
the same application writes the colors; no terminal commands are needed.

The automatic flow needs `pkexec` and a graphical polkit authentication agent
running in your desktop session. It disables pkexec's terminal authentication
fallback, so a session without an agent does not hang waiting for terminal input.
Cancelling setup leaves files untouched and skips unprepared browsers. It does
not prompt again on every palette change. To retry, disable and re-enable the
template, or use the manual setup below. Installing another supported browser
can trigger a new setup prompt for that browser's policy path.

Only `noctalia-color.json` becomes writable by your user. The helper does not
change ownership or permissions on existing directories or other policies, and
refuses symlinks, unsafe parent directories, files owned by another user, and
files containing additional policy keys. Already prepared files need no prompt.
Ordinary palette changes never elevate privileges.

## Manual one-time setup (no polkit agent required)

The terminal setup remains available. Run this as your normal desktop user:

```sh
bash "${XDG_STATE_HOME:-$HOME/.local/state}/noctalia/community-templates/chromium-based/apply.sh" setup
```

From a checkout, use `bash chromium-based/apply.sh setup` instead. This uses
**sudo**, without depending on polkit or a graphical authentication agent.
Reapply the template in Noctalia after manual setup. Repeat setup after
installing another supported browser, if automatic setup is unavailable.
`bash chromium-based/apply.sh list` previews detected policy directories.

## Browser detection and output paths

Each selected directory receives a `noctalia-color.json` file:

| Browser / launcher | Policy directory |
| --- | --- |
| Chromium, ungoogled Chromium, Helium (`chromium`, `ungoogled-chromium`, `ungoogled-chromium-browser`, `helium`, `helium-browser`) | `/etc/chromium/policies/managed` |
| Chromium's `chromium-browser` launcher | `/etc/chromium-browser/policies/managed` |
| Google Chrome, stable/beta/unstable launchers | `/etc/opt/chrome/policies/managed` |
| Chrome for Testing (`google-chrome-for-testing`, `chrome-for-testing`) | `/etc/opt/chrome_for_testing/policies/managed` |
| Brave, beta/nightly, Brave Origin | `/etc/brave/policies/managed` |

Missing browsers are skipped. Browsers sharing a directory receive the same
color. Reserve `noctalia-color.json` for this template; other policies belong in
separate JSON files. The helper accepts only the browser identifiers above and
their fixed destinations, not arbitrary paths.

These are **machine-wide** policies affecting every profile and user of that
browser. This setup is intended for a personal Linux machine. A user who can
write a policy file can also place other browser policies in it; use
administrator-managed configuration on shared or centrally managed machines.

## Apply and remove

After writing the color, the post hook runs each detected browser launcher with
`--refresh-platform-policy --no-startup-window` to refresh running browsers
immediately. This needs a build supporting the refresh flag (upstream Chromium
142 or later; some derivatives backported it). Each request uses `timeout` from
GNU coreutils to limit its runtime to five seconds, with forced termination one
second later if needed; some builds otherwise stay alive when the browser is
closed. Refresh requests run as your desktop user without authentication.

Older or unsupported builds still watch the policy files and should apply
changes after a short delay. If needed, restart the browser or open its
`chrome://policy`, `brave://policy`, or `helium://policy` page and select
**Reload policies**. This fallback also applies after removing the policy.

Disabling the template runs its undo hook and requests graphical authentication
to remove this template's policy files, including those belonging to browsers
that have since been uninstalled. Other files and the policy directories stay
intact. Modified files containing extra policies or belonging to another user
are preserved.

If cleanup authentication is cancelled or unavailable, the files remain
unchanged and their theme policy remains active. The undo hook reports failure
so Noctalia can retry cleanup on a later theme change. Without a polkit agent,
use the manual sudo fallback as your normal user:

```sh
bash "${XDG_STATE_HOME:-$HOME/.local/state}/noctalia/community-templates/chromium-based/apply.sh" remove
```

From a checkout, use `bash chromium-based/apply.sh remove`. Neither operation
removes unrelated policy files or recursively deletes directories.

## Limits and conflicts

- This targets browsers implementing Chromium's `BrowserThemeColor` policy.
  Chromium ancestry alone does not guarantee support; custom interfaces such
  as Edge, Vivaldi, and Opera are not automatically configured.
- Flatpak and Snap packages have separate policy locations and sandbox rules;
  this template handles native packages only. Do not alias a sandboxed browser
  to one of the native launcher names above.
- Distribution builds can change policy locations; verify your package's path
  if the policy does not appear on its policy page.
- A managed theme overrides the browser's selected theme and can show a
  **Managed by your organization** notice. Disable older Brave/Chromium theme
  templates and avoid setting `BrowserThemeColor` in another policy file.
- `BrowserColorScheme` is not emitted: it is not a Chromium policy. Dark/light
  changes choose the matching Noctalia surface, while browser appearance mode
  follows its existing settings.

On NixOS, the one-time preparation can instead be declared in your system:

```nix
systemd.tmpfiles.settings."10-noctalia-chromium".
  "/etc/chromium/policies/managed/noctalia-color.json".f = {
    user = "your-user";
    group = "users";
    mode = "0644";
    argument = "{}";
  };
```

Use `f`, not `f+`, to preserve the rendered color on rebuilds. Repeat for other
needed paths. Do not make the generated file a Nix store symlink. Disabling the
template can remove the policy file, but tmpfiles will recreate an empty file
on a later rebuild or boot while this declaration remains enabled.

## Validation

Validated with Noctalia's renderer in dark and light modes and mocked
authentication/filesystem tests. Tests never invoke a real authentication
prompt or change system policies. No multi-browser UI testing is claimed.
Run `bash chromium-based/test.sh` and
`python3 .github/workflows/validate-templates.py` from the repository root.

References: [Chromium Linux setup](https://www.chromium.org/administrators/linux-quick-start/),
[Chrome for Testing policy paths](https://chromium.googlesource.com/chromium/src/+/main/docs/enterprise/policies.md),
[Brave policies](https://support.brave.app/hc/en-us/articles/360039248271-Group-Policy),
[BrowserThemeColor](https://raw.githubusercontent.com/chromium/chromium/main/components/policy/resources/templates/policy_definitions/Miscellaneous/BrowserThemeColor.yaml),
[policy refresh flag](https://github.com/chromium/chromium/blob/main/chrome/common/chrome_switches.h),
and [pkexec authentication behavior](https://www.freedesktop.org/software/polkit/docs/latest/pkexec.1.html).
