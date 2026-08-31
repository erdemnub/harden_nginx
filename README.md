# Nginx Host Hardening & Kernel-Level FIM Baseline

An automated security baseline script for Fedora/RHEL-based enterprise Linux environments. This project enforces the Principle of Least Privilege and Defense-in-Depth for Nginx web server instances using SELinux, Systemd sandboxing, stateful firewall rules, and Auditd File Integrity Monitoring (FIM).

---

## Security Architecture & Threat Model

1. **Mandatory Access Control (SELinux):**
   - Updates socket binding policy (`http_port_t`) to port `8088/tcp` using `semanage`.
   - Prevents unauthorized network namespace binding.

2. **Systemd Process Sandboxing (Namespace & Cgroups):**
   - `ProtectSystem=strict`: Mounts the entire root filesystem (`/`) as read-only, preventing attackers from writing web shells or malicious binaries into `/usr`, `/boot`, `/etc`, or unwhitelisted `/var` directories.
   - `ProtectHome=true`: Completely hides and isolates `/home`, `/root`, and `/run/user` from the Nginx process.
   - `NoNewPrivileges=true`: Disallows child processes from gaining elevated execution privileges via SUID/SGID binaries.
   - `ReadWritePaths`: Whitelists strictly necessary runtime paths (`/var/log/nginx`, `/var/run`, `/var/lib/nginx`).

3. **File Integrity Monitoring (Auditd / Linux Kernel):**
   - Enforces syscall monitoring on `/etc/nginx/nginx.conf` (`perm=wa`).
   - Identifies malicious configuration tampering at the kernel level and tracks the true originating session identity (`auid`), neutralizing privilege escalation masking via `sudo`.

4. **Network Exposure Control (Firewalld):**
   - Closes default HTTP port 80 and restricts exposure strictly to the hardened service port (`8088/tcp`).

---

## Usage

### Prerequisites
- RHEL 9/10, Rocky Linux, AlmaLinux, or Fedora.
- Root privileges.

### Quick Start
```bash

cd nginx-hardening-baseline
chmod +x harden_nginx.sh
sudo ./harden_nginx.sh