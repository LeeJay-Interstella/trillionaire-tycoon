# Trillionaire Tycoon

Idle tycoon browser game: build businesses, collect cash, upgrade, dodge jail and climb the rich list from lemonade stand to trillionaire.

This guide turns on **accounts with cloud saves**, so your progress and a friend's progress are each synced across devices.

---

## What's in this folder

| File | What it is |
|---|---|
| `index.html` | The whole game. This is the file Vercel serves. |
| `config.js` | Where your two Supabase keys go. Kept separate so game updates never wipe them. |
| `supabase-setup.sql` | A one-time script that creates the table where saves are stored. |
| `README.md` | This guide. GitHub shows it on your repo's front page. |

You'll set up Supabase once (about 10 minutes). After that, each player creates their own account inside the game.

---

## Before you start: protect existing progress

You and your friend already have progress saved on your phones. Nothing below deletes it, but take two precautions:

1. **Keep the same Vercel project.** Saves are tied to the game's web address. Update the existing repo; don't make a new project or move to a new domain.
2. **Make a backup code after the update is live** (Part 2, step 9). It's a copy of your save you can paste back in if anything goes wrong.

---

## Part 1: Set up Supabase (you only, once)

1. **Create a project.** Sign up at [supabase.com](https://supabase.com) and click **New project**.
   - Name: `trillionaire`
   - Database password: anything strong. Save it somewhere; the game doesn't need it.
   - Region: somewhere near you, such as **Stockholm** or **Frankfurt**.
   - Plan: **Free** is enough.

   Wait a minute or two while it finishes setting up.

2. **Create the saves table.** In the left menu, open **SQL Editor** › **New query**. Open `supabase-setup.sql`, copy everything in it, paste it into the editor and click **Run**. You should see "Success. No rows returned."

   This creates a `saves` table and locks it so each player can only read and write their own save.

3. **Turn on email sign-in.** Go to **Authentication** › **Sign In / Providers** › **Email** and make sure it's enabled.

4. **Turn off "Confirm email"** (recommended). In the same Email settings, switch off **Confirm email** and save. New accounts then work straight away, with no confirmation email.

   *If you'd rather keep confirmation emails on:* go to **Authentication** › **URL Configuration** and set **Site URL** to your game's Vercel link (for example `https://trillionaire-tycoon.vercel.app`). Players then tap the link in the email before their first sign-in.

5. **Copy your two keys.** Go to **Project Settings** › **API** (sometimes called **Data API** or **API Keys**) and copy:
   - **Project URL**, which looks like `https://abcdefghijkl.supabase.co`
   - **anon public** key (or **publishable** key), a long string

   The anon key is safe to put in a public website. The locked table is what keeps each save private.
   **Never use the `service_role` or secret key** in the game.

---

## Part 2: Add the keys and deploy (you only, once)

6. **Upload the files to GitHub.** In your game's repo, click **Add file** › **Upload files**, drag in all four files (`index.html`, `config.js`, `supabase-setup.sql`, `README.md`) and click **Commit changes**. The new `index.html` replaces the old one. All four sit at the top level of the repo, next to each other.

7. **Paste your keys into config.js.** In the repo, click `config.js`, then the **pencil icon** to edit. It looks like this:

   ```js
   window.TRILLIONAIRE_CONFIG = {
     supabaseUrl: '',
     supabaseAnonKey: ''
   };
   ```

   Paste your values between the quotes, so it looks like this:

   ```js
   window.TRILLIONAIRE_CONFIG = {
     supabaseUrl: 'https://abcdefghijkl.supabase.co',
     supabaseAnonKey: 'eyJhbGciOi...your-long-key...'
   };
   ```

   Keep the quotes and the comma. Click **Commit changes**. Vercel redeploys automatically in about 30 seconds.

8. **Reload the game on your phone.** Close the game fully (swipe it away in the app switcher), then open it from your home screen. Your progress should still be there.

9. **Make a backup code.** Tap the **Boss** tile › **Back up or move my save** › **Copy code**, and paste the code into your Notes app.

---

## Part 3: Create your account (you)

Do this **on the phone you've been playing on**, so its progress becomes your cloud save.

10. Tap the **Boss** tile. At the top you'll see **Save to the cloud** with a **Sign in** button.
11. Tap **Sign in** › **New here? Create an account**.
12. Enter **your** email and a password (6+ characters), then tap **Create**.

The box now shows your email and "Synced … ago". Your save is in the cloud.

---

## Part 4: Your friend creates their account

Send your friend these steps:

> 1. Close the game fully and reopen it, so you're on the latest version. Your progress will still be there.
> 2. Tap the **Boss** tile › **Back up or move my save** › **Copy code**, and keep the code in your notes.
> 3. In the same Boss screen, tap **Sign in** › **New here? Create an account**.
> 4. Use **your own email** and a password, then tap **Create**.
>
> Do this on the phone you've been playing on. Don't sign in with anyone else's email, or you could replace your progress with theirs.

Each email is a separate account with its own save. Neither of you can see or change the other's progress.

---

## Check it's working

In your Supabase dashboard:

- **Authentication** › **Users** lists both email addresses.
- **Table Editor** › **saves** shows one row per player, with an `updated_at` time that changes as you play.

To test syncing: sign in with the same email on a second device (a laptop or tablet). It should load the same game within a few seconds.

---

## How syncing works

- The game uploads your progress **every 30 seconds** and **whenever you leave it**.
- When you open it, it checks whether another device has played since, and loads that newer progress.
- **Offline**, it keeps saving on the device and syncs when you're back online.
- If you sign in on a device that already has **different** progress, the game shows both saves side by side and asks which to keep. The other one is replaced.
- **Signing out** keeps the game on that device; it just stops syncing.
- Playing on two devices **at the same moment** isn't supported: the most recently played save wins.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| No "Save to the cloud" box in the Boss screen | The keys aren't in `config.js` yet, `config.js` isn't next to `index.html` in the repo, or the phone is showing the old version. Check steps 6–7, then close the game fully and reopen it. |
| "That email and password don't match" | Check the email and password. On first use, tap **Create an account** instead of signing in. |
| "Confirm your email first" | Either tap the link in the confirmation email, or turn off **Confirm email** (step 4). |
| "Couldn't sync" | You're offline, or the Supabase project is paused. The game keeps saving on the phone and retries automatically. |
| Supabase project paused | Free projects pause after about a week with no activity. Open the Supabase dashboard and click **Restore project**. |
| Lost progress | Boss › **Back up or move my save**, paste your backup code into the bottom box and tap **Load code**. |

---

## For future updates

- Keep pushing updates to the **same repo and Vercel project**, so the web address never changes.
- To update the game, **upload only the new `index.html`**. Leave `config.js` alone: it holds your keys, and the game reads them from there.
- If you ever overwrite `config.js` by mistake, the game falls back to saving on each device. Nobody loses progress, but syncing pauses until you paste the keys back in.
- Don't change a business's short code (like `lem` for Lemonade Stand) in the game data. Saves rely on those codes; display names can change freely.
