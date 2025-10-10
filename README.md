# toll_cam_finder

## Toll segment data workflow

The application bundles a starter CSV at `assets/data/toll_segments.csv`. The
file only needs to contain a valid header so the app can boot while the first
Supabase sync runs. During runtime the sync service downloads the latest public
segments and caches them in memory, while the local CSV that lives in the app
support directory is trimmed to hold personal (user-created) segments only.

This means you **do not** need to manually copy the remote dataset into the
repository anymore. Keep the asset file in place with the header row so a fresh
install still has a valid schema, and let the automatic sync refresh the remote
data whenever the map screen opens.
