## Why These Security Controls?

I built this baseline to lock down Nginx using layered host security instead of relying on default configurations. Here is the technical breakdown:

### 1. Mandatory Access Control (SELinux)
* **Custom Port Labeling:** Nginx is moved to port `8088`. SELinux enforces strict type enforcement via `semanage port -a -t http_port_t -p tcp 8088`.
* **Impact:** Even if the web process is compromised, it cannot bind to unauthorized network sockets.

### 2. Systemd Sandboxing (Drop-in Override)
Instead of letting Nginx run with broad system access, the process is isolated directly at the systemd level:
* `ProtectSystem=strict`: Mounts the whole root filesystem (`/`) as read-only. I chose `strict` over `full` to explicitly lock `/var` as well.
* `ReadWritePaths`: Nginx can only write to strictly required directories (`/var/log/nginx`, `/var/run`, `/var/lib/nginx`). This significantly restricts where the Nginx process can write, reducing the risk of unauthorized file modifications.
* `ProtectHome=true`: Completely hides `/home` and `/root` from the Nginx process table.
* `NoNewPrivileges=true`: Blocks privilege escalation via SUID/SGID binaries.

### 3. File Integrity Monitoring (Auditd)
* **Kernel Syscall Rule:** Added `auditctl -a always,exit -F path=/etc/nginx/nginx.conf -F perm=wa -k nginx_config_change`.
* **Purpose:** Monitors write and attribute changes to `nginx.conf` and records the original login identity (`auid`) for auditing and investigation purposes.
### 4. Network Perimeter (Firewalld)
* Closes standard HTTP port 80 and opens only `8088/tcp` to minimize exposure.
---

## Usage

### Prerequisites
- RHEL 9/10, Rocky Linux, AlmaLinux, or Fedora.
- Root privileges.

### Quick Start
```bash
git clone https://github.com/erdemnub/harden_nginx.git nginx-hardening-baseline
cd nginx-hardening-baseline
chmod +x harden_nginx.sh
sudo ./harden_nginx.sh
```
