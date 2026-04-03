# Feed Production TODO

This list is ordered for the safest production hardening path with the current feed architecture.

1. Make refresh recover the feed from stale or failed realtime state
- Status: Done
- Files:
  - `lib/features/feed/service/feed_repository.dart`
  - `lib/features/feed/view/feed_view.dart`
- Notes:
  - Pull to refresh should refetch posts from Supabase instead of only delaying in the UI.

2. Add pagination for main feed and profile feed
- Status: Pending
- Goal:
  - Stop loading every post at once.
  - Add `limit` and `range` based loading with duplicate protection.
  - Keep existing post card behavior and route contracts unchanged.

3. Move post counts to database-backed aggregates
- Status: Pending
- Goal:
  - Avoid counting likes and comments by fetching all rows on every map.
  - Prefer stored counters, RPC, or a view that returns aggregated counts.

4. Add feed moderation actions for users
- Status: Pending
- Goal:
  - Add report, hide post, and block user actions.
  - Preserve delete flow for the post owner.

5. Make comment UX more resilient
- Status: Pending
- Goal:
  - Add retry affordance on comment load failure.
  - Consider optimistic comment insert with rollback.

6. Add feed-focused tests
- Status: Pending
- Goal:
  - Cover model parsing, repository mapping, refresh behavior, like rollback, and comment submission states.

7. Fix text encoding issues in feed messages
- Status: Pending
- Goal:
  - Replace mojibake Thai strings in snack bars and dialogs with valid UTF-8 text.
