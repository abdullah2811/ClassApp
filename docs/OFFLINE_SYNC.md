# Offline and synchronization architecture

`AppDatabase` is the typed Drift cache. `OfflineSyncService` observes
`connectivity_plus`, queues mutations, marks entries `pending`/`syncing`/
`failed`, and delegates the actual upload to a feature repository. A cache
first repository should emit local rows immediately, then fetch remote rows,
replace the local snapshot, and refresh its stream.

Do not store access or refresh tokens in Drift. Tokens belong in
`flutter_secure_storage`. Before enabling offline writes, add idempotency keys
and server timestamps to mutation endpoints, then implement conflict policy
per entity (server-wins for notices, explicit merge for attendance).
