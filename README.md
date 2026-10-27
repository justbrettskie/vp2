# VitalPulse — Base44 to Supabase migration starter

This is a **migration starter kit**, not a finished replacement APK or a complete reconstruction of the 44-file application.

## Included
- `src/lib/supabase.js`: Supabase client using `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY`.
- `src/data/vitalPulseData.js`: initial Supabase data helpers for health profiles, activity sessions, and checking completed payments.
- `supabase/migrations/202610270001_vitalpulse_schema.sql`: starter tables and row-level security policies.

## Environment
Set these in the web build environment (for local Vite builds, a `.env.local` file):

```env
VITE_SUPABASE_URL=https://pnxyowqmwnsnwodlexug.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
```

Use only the project's publishable/anon client key in a browser or APK. **Never put the Supabase service-role key, Stripe secret key, or an AI provider secret in client-side code.**

## Important migration work still required
1. Replace every `base44.entities.*` call in the actual React source with the appropriate helpers or direct Supabase queries.
2. Replace all Base44 auth calls (`loginViaEmailPassword`, `register`, OTP, OAuth, password reset) with the matching `supabase.auth.*` flows and configure redirect URLs in Supabase Auth.
3. Move `base44.integrations.Core.InvokeLLM`, `GenerateImage`, and `SendEmail` to secure Edge Functions or another trusted server. The provider keys must stay server-side.
4. Implement Stripe Checkout creation and a verified Stripe webhook/Edge Function. The client must not mark a payment as `completed` by itself.
5. Review every RLS policy against the app's intended access rules and test using non-admin accounts.
6. Restore the full source tree, including `package.json`, lockfile, Vite configuration, all UI components, assets, and the Android wrapper/build files. The provided source is an extracted text export, not a complete buildable repository.
7. Build and test the web app, then build the Android app using its actual wrapper/toolchain. Check login, password reset, data sync, AI, Stripe test payments, and offline/error behavior before distribution.

## Why this does not contain a new APK
An APK is a compiled binary. Replacing backend calls safely requires editing the source, building the web bundle, putting that bundle into the correct Android wrapper, and rebuilding/signing the Android package. The uploaded APK does not include the complete editable project/build configuration, and the text export alone omits essential project metadata and some dependencies. Producing an APK from only those two files would risk giving you an app that installs but does not work.

## Applying the SQL
Review the migration SQL first. Then open the Supabase Dashboard for project `pnxyowqmwnsnwodlexug`, go to SQL Editor, and run it in the intended environment. Do not run it blindly on a production database; inspect existing tables first to avoid conflicts.
