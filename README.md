# SecureChat (static site + Supabase)

Files: `index.html` (app), `config.js` (your keys), `setup.sql` (database), `vercel.json` (security headers).

## Setup
1. Supabase > SQL Editor: run `setup.sql`.
2. Supabase > Authentication > Sign In / Providers: enable **Allow anonymous sign-ins**.
3. Supabase > Project Settings > API: copy Project URL and anon/publishable key into `config.js`.
4. Put all 4 files in the root of your Vercel project (Framework: Other, no build command) and deploy.
5. Test in two browsers: create invite in one, join in the other.

## What changed in the API (old -> new)
| App call | Was (claude.ai only) | Now (Supabase) |
|---|---|---|
| Who am I | `claude.use('user').id()` | `POST /auth/v1/signup` with `{}` (anonymous user) -> `user.id`; refresh via `POST /auth/v1/token?grant_type=refresh_token` |
| doc.get | `db.doc(path).get()` | `GET /rest/v1/kv?path=eq.<path>` |
| doc.set | `db.doc(path).set(data)` | `POST /rest/v1/kv` + `Prefer: resolution=merge-duplicates` |
| doc.update | read, merge, set | same, via the two calls above |
| doc.delete | `.delete()` | `DELETE /rest/v1/kv?path=eq.<path>` |
| messages list | `collection().orderBy('ts').onSnapshot` | `GET /rest/v1/kv?parent=eq.<path>&order=ts.asc` polled every 2.5 s |
| Headers | automatic | `apikey: <anon key>`, `Authorization: Bearer <access_token>` |

Data layout (single table `kv`): `profiles/<uid>`, `chats/<chatId>` (members), `chats/<chatId>/messages/<id>` (from, iv, ct, ts). Messages are AES-GCM ciphertext; the key is only in the invite code.

## If you prefer Firestore
Same layout works: collections `profiles`, `chats`, `chats/{id}/messages`. Replace the `mkdb()` function in `index.html` with Firebase v9 calls (`getDoc/setDoc/updateDoc/deleteDoc`, `onSnapshot(query(collection(...), orderBy('ts')))`, `signInAnonymously`) and use `request.auth.uid` in Firestore rules, mirroring `setup.sql`. Real-time listeners replace polling.

## Security notes
- Never use the `service_role` key in `config.js`.
- Not audited. Server still sees who talks to whom and when.
- Invite code = chat key. Share it only over a secure channel.
- Deleting a chat removes it only from your device. Your own messages can be deleted from the DB manually.
