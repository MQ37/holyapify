# HolyApify scope

A minimal HolyC Apify client for stock TempleOS V5.03 using HolyNet as a separate sibling dependency.

Public commands are ApifyToken, ApifyMe and ApifyRun. Lower-level API functions return owned JSON buffers or NULL plus apify_last_error. The supported API slice is account lookup and synchronous Actor runs returning dataset items.

The shared HolyNet lab stages both repositories onto a fresh guest RAM drive. HOLYNET_DIR overrides dependency discovery. No library, VM or test executes on the host.

No license is granted for original project code; no owner identity is included in content. Branch name is master; publication requires explicit authorization.
