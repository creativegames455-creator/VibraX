# VibraX roadmap

Stack: Flutter app (lib/main.dart), Supabase (project rqsyygahmvfmmehbenan), APK GitHub Actions se banti hai.
Tables: posts, profiles, follows, post_likes, comments (parent_id), comment_likes, wallets. Bucket: media.

## Done
- Moments (photo/video), Trending=photo, Video tab=video, seedha gallery picker
- Real like count, comments (Moments/Like tab, reply, comment like, avatars)
- Profile: avatar upload, Fans/Following/Coins/Diamond, VibraX Member/Gold
- Fixed font scale

## Todo (is tarteeb se)
1. Follow button (Fans/Following)
2. Message / DM (Supabase Realtime)
3. Live streaming MVP (LiveKit/Agora/ZEGOCLOUD + live chat)
4. Gifts + Coins kharch, Diamond broadcaster ko
5. Recharge (Google Play Billing)
6. Level, VIP, Badge, Store, My Bag, Task Center
7. Report / Block / Moderation (live se pehle)

## Kaam ka tareeqa
Backup (cp lib/main.dart ~/main_backupN.dart) -> python patch script -> flutter analyze -> git push -> Actions build -> APK test.
