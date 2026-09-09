# docker-acs

Ubuntu 26.04-based Ansible controller. Build locally with:

```powershell
docker build -t docker-acs:cache-fix .
```

## NetBox inventory cache workaround

Upstream issue: https://github.com/ansible/ansible/issues/86292
Proposed upstream fix: https://github.com/ansible/ansible/pull/86551

As checked on 2026-09-09, the fix is an open draft, not a released fix.
Ansible repeatedly resolves data-tag type hints while decoding JSON inventory
caches. This can make a warm cache slower than expected even without network I/O.

This image applies a narrow adaptation of that proposed fix at build time.
It caches type hints inside Ansible; it does not monkey-patch Python globally.
The patch is guarded to ansible-core 2.21.4 and checks the expected source before
changing it. Upgrading core requires reviewing/removing the workaround. This is a
local workaround, not an upstream-supported release fix.

requirements.txt declares dependencies; requirements.lock constrains the complete
installed Python dependency set captured from the working controller. Ubuntu is
pinned to 26.04, but OS package updates and pip bootstrap remain floating. Revisit
constraints deliberately for updates rather than treating them as permanent.

ansible-pylibssh is installed so the netcommon network_cli connection uses libssh
rather than warning and falling back to paramiko. Its manylinux wheel bundles
libssh 4.11, so no extra apt packages are required in either build stage.

Existing pytz and libyaml additions are retained. Config context remains enabled
in the consuming inventory. No inventory filters or host variables are removed.

## Validation

The existing controller took 46.7-47.8 seconds for warm inventory runs. An isolated
image with the narrow patch took 5.6 and 4.2 seconds, with networking disabled and
copies of the same cache files. The full normalized JSON inventory matched the
unmodified inventory exactly (7 hosts), including flattened config context.
The device-information playbook passed syntax checking after copying its existing
installed roles into the isolated test container. No device tasks were executed.

## Using the image

Building here does not change the lab's running container. Its separate Compose
file still selects ghcr.io/colawebrunner/docker-acs:latest. Select the locally built
docker-acs:cache-fix image there when ready to roll out.

Before recreating the lab container, preserve or reinstall its container-local
roles under /root/.ansible/roles. Preserve /tmp/ansible_inventory and
/tmp/facts_cache if you want to retain warm caches. The current lab Compose file
only bind-mounts /code, so those other directories do not survive recreation.
For routine use, manage roles declaratively and use named volumes for caches.

Remove the workaround once an upstream release includes an equivalent fix, then
rerun warm-cache timing and full inventory comparisons before updating the pins.
