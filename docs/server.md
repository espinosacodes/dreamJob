# Appendix — the `air` deployment box

**Status: ops note, not a spec.** Machine-specific infrastructure for one person's hardware, kept here because [02](02-architecture.md) and [19](19-configuration.md) both ask "where does the server actually run" and this is the candidate answer.

**Read [the ruling](#compliance-ruling) before deploying dreamJob to it.** [09](09-compliance.md) does not permit this unconditionally, and one of the conditions is not currently satisfiable on a headless box.

Repurposed MacBook Air (2015) running headless Debian, reachable over ZeroTier.

## Specs

| | |
|---|---|
| **Hostname** | `san-macbookair72` |
| **OS** | Debian 13 (trixie), kernel 6.12 |
| **CPU** | Intel i5-5250U — 2 cores / 4 threads @ 1.6 GHz |
| **RAM** | 7.7 GiB (~5.4 GiB free) |
| **Disk** | 102 GB SSD (~88 GB free) |
| **LAN IP** | `192.168.131.197` |
| **ZeroTier IP** | `10.13.164.81` (network `server` — `743993800fc70a0a`) |

Small but fine for a handful of small services (a Go backend, a DB, a static frontend).

## Compliance ruling

[09](09-compliance.md) says: *"No hosted deployment without revisiting this section. Putting the server on a VPS moves the resume off the user's machine and changes the whole privacy story."* This is the revisit.

**`air` is not a VPS**, and that distinction is the one that matters: it is the user's own hardware, in the user's own home, on a private overlay network with no public exposure. No third party has disk access — ZeroTier routes but cannot read, and the firewall rules below keep everything off the public internet. On that basis, running dreamJob here is **permitted**, under five conditions:

1. **Private overlay only.** The API binds the ZeroTier interface, never a public one. `ufw` denies everything else. If the box ever gets a public IP or a port-forward, this ruling is void.
2. **Full-disk encryption.** A laptop holding a resume, an application archive and a mailbox must not be readable when powered off. If the disk is not encrypted, encrypt it before the first sync — this is the condition most likely to be skipped.
3. **Backups stay under the user's control.** `rsync` to the user's own machine. Never a sync service, never object storage with someone else's keys ([09](09-compliance.md)).
4. **No multi-tenancy, ever.** One user. Adding a second voids [09](09-compliance.md) entirely, and that section says so.
5. **The M5a subsystems stay off** — see below.

### The blocker: no unlocked keychain on a headless box

[15](15-accounts-identity.md) requires an OS keychain for site passwords and the mailbox OAuth token, and explicitly refuses to store them anywhere else. On headless Debian there is no logged-in desktop session, so the Secret Service (`gnome-keyring` / `kwallet`) has **no unlocked keyring** — a `secret-tool` call either fails or prompts a UI nobody is looking at.

The consequence, stated plainly:

| Milestone | On `air` |
| --- | --- |
| M1–M4 — ingest, match, deck, tailoring | **Fine.** No secret beyond `ANTHROPIC_API_KEY`, which is an environment variable in a `systemd` unit |
| M5a — accounts, mailbox | **Blocked.** No unlocked keychain, so [15](15-accounts-identity.md)'s "refuse to store credentials" branch fires and every site drops to `manual-only` |
| M5b — browser submission | **Blocked** by M5a, and separately awkward: attended mode needs a display this box does not have |

Do not work around this with a file-backed secret store. That is precisely the design [09](09-compliance.md) forbids, and "it's my own box" is the reasoning that feels fine right up until the disk is imaged. If M5a is wanted, either run the server on the Mac, or solve the keyring properly — a keyring unlocked at boot from a key on an encrypted volume is a real design with real trade-offs, and it needs writing down before it is built.

**Practical recommendation:** run M1–M4 on `air` as an always-on ingest-and-tailor box, and keep M5a/M5b on the Mac where a real Keychain exists. That split also matches where the work happens.

## Access

```bash
ssh air          # key-based login as user `san`, no password
```

Alias lives in `~/.ssh/config` on the M4 Pro. Works only while both machines are on the ZeroTier `server` network. If the box's ZeroTier IP changes, update `HostName` in that config.

## First-time setup (run once on the box)

Nothing but Python 3.13 + systemd is installed yet. Install the deploy toolchain:

```bash
sudo apt update
sudo apt install -y git curl ufw
# Docker (recommended way to run deployments)
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker san     # log out/in after this
# Caddy — auto-HTTPS reverse proxy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update && sudo apt install -y caddy
```

For dreamJob specifically, add what [19](19-configuration.md) lists as prerequisites — at minimum `poppler-utils` for `pdftotext`, without which no application can be approved:

```bash
sudo apt install -y poppler-utils
```

### Firewall (keep it locked to ZeroTier)

```bash
sudo ufw default deny incoming
sudo ufw allow in on zt6q3fjcqf   # trust the ZeroTier interface
sudo ufw allow 22/tcp             # keep SSH
sudo ufw enable
```

This exposes services only to devices on the private ZeroTier network — nothing hits the public internet. **This is condition 1 of the ruling above, not a preference.**

## Deploy pattern

1. Push code from the Mac → the box (`git pull` on the box, or `rsync -avz ./ air:~/app/`).
2. Run each project as a container: `docker compose up -d` in the project dir.
3. Front it with Caddy so `10.13.164.81` routes to the right container.
4. Reboots survive automatically — Docker's `restart: unless-stopped` + systemd bring services back up.

For dreamJob, a static Go binary plus the Rust core is simpler than Docker — two files, one `systemd` unit, no image to rebuild. Cross-compile from the Mac:

```bash
GOOS=linux GOARCH=amd64 go build -o dreamjob-server ./cmd/server
cargo build --release --target x86_64-unknown-linux-gnu
rsync dreamjob-server target/x86_64-unknown-linux-gnu/release/dreamjob-core air:~/bin/
```

…then wrap `dreamjob-server` in a `systemd` unit with `ANTHROPIC_API_KEY` in an `EnvironmentFile` that is `chmod 600` and lives outside the repo.

## Caveats

- **Laptop chassis** — closing the lid may suspend it. Set `HandleLidSwitch=ignore` in `/etc/systemd/logind.conf` and reboot so it stays awake as a server.
- **Single disk, no backups** — put anything important in a volume and `rsync` it back to the Mac periodically. For dreamJob this is condition 3 of the ruling.
- **Two cores at 1.6 GHz.** Fine for ingestion and matching; the Rust core is a subprocess spawn per batch, which is cheap. Cross-compile rather than building on the box — a Rust release build here is slow enough to be annoying.
- Modest CPU/RAM — fine for dev/staging and low-traffic personal projects, not heavy production load.
