#!/bin/bash
# save-to-maps.sh — Save a place to Google Maps collection via OpenClaw browser
# Usage: save-to-maps.sh <place_id> [collection_name]
#
# Example: save-to-maps.sh ChIJFwkVC72wj4ARgFhN7WeNqAY "Restaurants that I want to go to"

set -euo pipefail

PLACE_ID="${1:?Usage: save-to-maps.sh <place_id> [collection_name]}"
COLLECTION="${2:-Restaurants that I want to go to}"
PROFILE="openclaw"
BROWSER_CMD="openclaw browser --browser-profile $PROFILE"

echo "=== Saving place_id=$PLACE_ID to collection '$COLLECTION' ==="

# Step 1: Ensure browser is running
STATUS=$($BROWSER_CMD status 2>&1 | grep "running:" | awk '{print $2}')
if [ "$STATUS" != "true" ]; then
  echo "Starting browser..."
  $BROWSER_CMD start 2>&1
  sleep 3
fi

# Step 2: Navigate to place page
echo "Navigating to place page..."
$BROWSER_CMD navigate "https://www.google.com/maps/place/?q=place_id:$PLACE_ID" 2>&1
sleep 5

# Step 3: Take snapshot and find Save button
echo "Looking for Save button..."
SNAPSHOT=$($BROWSER_CMD snapshot --interactive 2>&1)

SAVE_REF=$(echo "$SNAPSHOT" | grep -i 'button "Save"' | head -1 | sed -n 's/.*ref=\([^]]*\).*/\1/p' | head -1)
if [ -z "$SAVE_REF" ]; then
  echo "ERROR: Save button not found. User may not be logged in."
  echo "SNAPSHOT: $SNAPSHOT" | head -20
  exit 1
fi

# Step 4: Click Save
echo "Clicking Save (ref=$SAVE_REF)..."
$BROWSER_CMD click "$SAVE_REF" 2>&1
sleep 3

# Step 5: Take snapshot and find collection
echo "Looking for collection '$COLLECTION'..."
SNAPSHOT2=$($BROWSER_CMD snapshot --interactive 2>&1)

COLLECTION_REF=$(echo "$SNAPSHOT2" | grep -i "$COLLECTION" | head -1 | sed -n 's/.*ref=\([^]]*\).*/\1/p' | head -1)

if [ -z "$COLLECTION_REF" ]; then
  echo "Collection '$COLLECTION' not found. Creating new list..."

  # Click "New list" button
  NEW_LIST_REF=$(echo "$SNAPSHOT2" | grep -i '"New list"' | head -1 | sed -n 's/.*ref=\([^]]*\).*/\1/p' | head -1)
  if [ -z "$NEW_LIST_REF" ]; then
    echo "ERROR: Could not find 'New list' button."
    exit 1
  fi

  $BROWSER_CMD click "$NEW_LIST_REF" 2>&1
  sleep 2

  # Take snapshot to find the name input field
  SNAPSHOT_NEW=$($BROWSER_CMD snapshot --interactive 2>&1)

  # Find the text input for list name and type the collection name
  INPUT_REF=$(echo "$SNAPSHOT_NEW" | grep -i 'textbox\|input\|text field' | head -1 | sed -n 's/.*ref=\([^]]*\).*/\1/p' | head -1)
  if [ -z "$INPUT_REF" ]; then
    echo "ERROR: Could not find name input for new list."
    exit 1
  fi

  # Clear any default text and type the new name
  $BROWSER_CMD fill "$INPUT_REF" "$COLLECTION" 2>&1
  sleep 1

  # Take snapshot to find Save/Create button
  SNAPSHOT_CREATE=$($BROWSER_CMD snapshot --interactive 2>&1)
  CREATE_REF=$(echo "$SNAPSHOT_CREATE" | grep -i '"Save"\|"Create"' | head -1 | sed -n 's/.*ref=\([^]]*\).*/\1/p' | head -1)
  if [ -z "$CREATE_REF" ]; then
    echo "ERROR: Could not find Save/Create button for new list."
    exit 1
  fi

  $BROWSER_CMD click "$CREATE_REF" 2>&1
  sleep 3
  echo "Created new list '$COLLECTION' and saved place to it."
else
  # Step 6: Click existing collection
  echo "Clicking collection (ref=$COLLECTION_REF)..."
  $BROWSER_CMD click "$COLLECTION_REF" 2>&1
  sleep 2
fi

# Step 7: Verify
echo "Verifying save..."
SNAPSHOT3=$($BROWSER_CMD snapshot --interactive 2>&1)

if echo "$SNAPSHOT3" | grep -qi "Dismiss"; then
  echo "SUCCESS: Place saved to '$COLLECTION'"
  exit 0
else
  echo "UNCERTAIN: Could not confirm save. Check Google Maps manually."
  echo "Link: https://www.google.com/maps/place/?q=place_id:$PLACE_ID"
  exit 0
fi
