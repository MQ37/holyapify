# HolyApify

Read README.md, SPEC.md and docs/ARCHITECTURE.md before changing code.

- All project execution, tests, builds and rendering run inside rootless Podman or a VM. Never execute project Python, QEMU, HolyC or downloaded code on the host. Host launchers only orchestrate containers.
- Keep scratch and VM output in RAM under /dev/shm. Do not install host packages.
- HolyNet is a sibling dependency, overridable with HOLYNET_DIR. lab/tos invokes its shared lab with TOS_APP_DIR. Both trees are mounted read-only and staged into the guest RAM drive.
- Only the Apify adapter, user commands and client tests belong here. Network, crypto, TLS, HTTP, JSON and the shared lab belong in holynet.
- No original-code license and no owner's name in the repository. Preserve third-party notices. No personal paths, private hosts or secrets. Credentials are runtime-only TOS_SECRET_ globals.
- TLS does not authenticate the server. Use disposable tokens and non-sensitive data only.
- Follow the existing two-space HolyC style. Tests use HolyNet's tests/Test.HC and print TOS-DONE fail=N over serial.
- Branch: master. No push or publication without explicit authorization. The lead handles commits; do not change git identity or add attribution.
