# Google Maps Save Flow (Browser Automation)

Follow these steps exactly. Use the `openclaw` browser profile.

## Prerequisites

1. Ensure browser is running:
   ```bash
   openclaw browser --browser-profile openclaw status
   ```
   If not running:
   ```bash
   openclaw browser --browser-profile openclaw start
   ```

## Navigate to the place

2. Open the Google Maps place page using the place_id from goplaces:
   ```bash
   openclaw browser --browser-profile openclaw navigate "https://www.google.com/maps/place/?q=place_id:<PLACE_ID>"
   ```

3. Wait for page load:
   ```bash
   openclaw browser --browser-profile openclaw wait --load networkidle --timeout-ms 10000
   ```

4. Take a snapshot to verify the correct place loaded:
   ```bash
   openclaw browser --browser-profile openclaw snapshot --interactive
   ```
   Verify the place name matches. If it shows a login page, abort and tell user to log in.

## Click Save

5. Find the "Save" button in the snapshot. Look for a button with text "Save" or aria-label containing "Save". Note its ref.

6. Click it:
   ```bash
   openclaw browser --browser-profile openclaw click <save-ref>
   ```

7. Wait for the save menu to appear:
   ```bash
   openclaw browser --browser-profile openclaw wait --timeout-ms 3000
   ```

8. Re-snapshot to see the collection list:
   ```bash
   openclaw browser --browser-profile openclaw snapshot --interactive
   ```

## Select the collection

9. Find "restaurants that I want to go to" in the collection list. Note its ref.

10. Click it:
    ```bash
    openclaw browser --browser-profile openclaw click <collection-ref>
    ```

11. Wait for save to register:
    ```bash
    openclaw browser --browser-profile openclaw wait --timeout-ms 2000
    ```

12. Take a final snapshot to verify the save indicator changed (icon becomes filled/highlighted):
    ```bash
    openclaw browser --browser-profile openclaw snapshot --interactive
    ```

## Verify

13. If the Save button now shows as "Saved" or the icon is filled, success.

14. If verification fails, take a screenshot for debugging:
    ```bash
    openclaw browser --browser-profile openclaw screenshot
    ```

## Troubleshooting

- No "Save" button visible → user may not be logged in. Look for "Sign in" links.
- Place page shows wrong place or "not found" → fall back to text search URL: `https://www.google.com/maps/search/<URL-encoded name and address>`
- Collection list doesn't appear after clicking Save → re-click with a short delay.
- If flow breaks completely → take screenshot, report to user, provide direct Google Maps link as manual fallback.
