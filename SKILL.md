---
name: save-restaurant
description: "Save a restaurant to Google Maps. Triggers when user mentions a restaurant recommendation, a place to try, 'save this place', 'add to my list', or any food/dining spot to remember. Also triggers when the user sends a photo (storefront, menu, receipt, screenshot of a text, Instagram post) with intent to save a restaurant."
metadata:
  {"openclaw":{"emoji":"📍","requires":{"bins":["goplaces"]}}}
---

# Save Restaurant to Google Maps

Save a restaurant recommendation to the user's Google Maps "restaurants that I want to go to" collection via goplaces lookup + browser automation.

## Target collection

**"restaurants that I want to go to"** — the default Google Maps saved list.
Browser profile: **openclaw** (Google account must be logged in).

## Workflow

### Step 1: Parse the restaurant mention AND collection name

Extract **two things** from the user's message:

1. **Restaurant name and location** — be flexible with formats:
   - Vague: "amazing Thai place near Mountain View"
   - Partial: "Amber India in Los Altos"
   - Specific: "Amber India, 4926 El Camino Real, Los Altos, CA"
   - **Photo/image**: If the user sends a photo, examine it carefully. It could be:
     - A restaurant storefront or sign → read the name
     - A menu or receipt → read the restaurant name (often at the top)
     - A screenshot of a text conversation → extract the restaurant being recommended
     - An Instagram/Yelp/Google Maps screenshot → read the restaurant name and location
     - A business card → read name and address
   - Extract whatever restaurant name and location you can see. If the image is unclear, ask the user to clarify.

2. **Collection name** (optional) — look for phrases like:
   - "save to my Japan list" → collection = "Japan"
   - "add to my Australia list" → collection = "Australia"
   - "put it on my date night list" → collection = "date night"
   - "save to Favorites" → collection = "Favorites"
   - If no list is mentioned → use the default: "Restaurants that I want to go to"

**Default location: Sunnyvale / South Bay.** The user lives in Sunnyvale, CA. Unless the user specifically mentions a different city or region, always search near Sunnyvale and the South Bay (Sunnyvale, Mountain View, Cupertino, Santa Clara, San Jose, Palo Alto, Los Altos, etc.). If there are also notable locations in SF or elsewhere in the Bay Area, mention them as alternatives.

If both name and location are too ambiguous to search, ask ONE clarifying question.

### Step 2: Search with goplaces

```bash
goplaces search "<restaurant name> <location>" --json --limit 5
```

If no results, try broader terms (cuisine type, neighborhood, city).

### Step 3: Confirm with user

Present the top match (or top 3 if ambiguous):

**Shin Jung Korean Restaurant Orlando** ⭐ 4.4 (1,124 reviews)
📍 1638 E Colonial Dr, Orlando, FL 32803

Ask: "Is this the one? (yes / no / pick a number)"

**Do NOT proceed without explicit confirmation.**

### Step 4: Save to Google Maps via script

On confirmation, run the save script with the place_id from goplaces. Pass the collection name as the second argument if the user specified one:

```bash
# Default collection ("Restaurants that I want to go to"):
bash /Users/mengmengchen/.openclaw/workspace/skills/save-restaurant/scripts/save-to-maps.sh <PLACE_ID>

# Custom collection (e.g., user said "save to my Japan list"):
bash /Users/mengmengchen/.openclaw/workspace/skills/save-restaurant/scripts/save-to-maps.sh <PLACE_ID> "Japan"
```

The script handles all browser automation (navigate, snapshot, click Save, select collection, verify). If the collection doesn't exist, the script will automatically create it. It outputs SUCCESS or ERROR with details.

If the script fails, provide the manual fallback link: `https://www.google.com/maps/place/?q=place_id:<place_id>`

### Step 5: Report back

Confirm it's saved. Include the Google Maps link:
`https://www.google.com/maps/place/?q=place_id:<place_id>`

## Error handling

- **Browser not running**: Start it with `openclaw browser --browser-profile openclaw start`, then proceed.
- **Not logged in**: If Save button is missing or Maps shows login prompt, tell the user: "I need you to log in to Google Maps in the OpenClaw browser. Run: `openclaw browser --browser-profile openclaw open https://maps.google.com`"
- **Place not found**: Ask for more details (full name, cross street, zip code).
- **Save failed**: Take a screenshot, report the issue, and provide the Google Maps link so user can save manually as fallback.
- **Collection not found**: List available collections and ask which one.
