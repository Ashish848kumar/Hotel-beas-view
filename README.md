# Hotel Beas View

A responsive Next.js website for Hotel Beas View in Jawalamukhi, Himachal Pradesh. Property facts that have not been provided (contact details, prices, specific facilities and ratings) are intentionally left blank or marked as coming soon.

## Getting started

Requires Node.js 18.17 or newer.

```bash
npm install
npm run dev
```

Visit http://localhost:3000. Build for production with `npm run build`, then run `npm start`.

## Editing hotel information

Update `data/hotel.ts` to change property name, address, map search, phone, WhatsApp, email and social links. Set `phone` to an international-format number without punctuation and `whatsapp` to digits only. Update room descriptions, facilities, attractions and sample image URLs in the same file. Replace all sample Unsplash photos with approved hotel photography before launch. The map currently shows the Jawalamukhi area and can be refined to the verified hotel pin.

## Deploying

Push this project to a Git provider and import it into Vercel, or deploy to any Node.js host that supports Next.js. Set the build command to `npm run build` and start command to `npm start`. Add the domain and any required environment settings in your host dashboard. No environment variables are required by default.
