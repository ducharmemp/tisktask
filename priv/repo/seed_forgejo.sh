#!/usr/bin/env bash
set -e

# Configuration
USERNAME="testuser"
PASSWORD="testpassword123"
EMAIL="testuser@example.com"
REPO_NAME="tisktask"
TOKEN_NAME="dev-token"
CONTAINER_NAME="forgejo"

echo "Creating Forgejo user: $USERNAME"
podman exec "$CONTAINER_NAME" forgejo admin user create \
  --username "$USERNAME" \
  --password "$PASSWORD" \
  --email "$EMAIL" \
  --must-change-password=false

echo "User created successfully!"

echo "Creating repository: $REPO_NAME"
# Use the Forgejo API to create a repo (no direct admin CLI for repos)
podman exec "$CONTAINER_NAME" curl -s -X POST \
  -H "Content-Type: application/json" \
  -u "$USERNAME:$PASSWORD" \
  -d "{\"name\": \"$REPO_NAME\", \"private\": false, \"auto_init\": true}" \
  "http://localhost:3000/api/v1/user/repos"

echo ""
echo "Repository created successfully!"

echo "Creating access token: $TOKEN_NAME"
ACCESS_TOKEN=$(podman exec "$CONTAINER_NAME" forgejo admin user generate-access-token \
  --username "$USERNAME" \
  --token-name "$TOKEN_NAME" \
  --scopes "all" \
  --raw)

echo "Access token created successfully!"
echo "Remember to reset the token in the DB if you've already got a dev environment running."

echo "Writing access token to ./tmp/forgejo_token..."
mkdir -p ./tmp
echo "$ACCESS_TOKEN" > ./tmp/forgejo_token

echo "Creating webhook for $REPO_NAME..."
podman exec "$CONTAINER_NAME" curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: token $ACCESS_TOKEN" \
  -d '{
    "type": "forgejo",
    "config": {
      "url": "http://host.containers.internal:4000/api/triggers/forgejo",
      "content_type": "json"
    },
    "events": ["*"],
    "active": true
  }' \
  "http://localhost:3000/api/v1/repos/$USERNAME/$REPO_NAME/hooks"

echo ""
echo "Webhook created successfully!"

FORGEJO_REMOTE="http://$USERNAME:$ACCESS_TOKEN@localhost:3000/$USERNAME/$REPO_NAME.git"

echo "Adding Forgejo as remote 'local'..."
git remote add local "$FORGEJO_REMOTE" 2>/dev/null || git remote set-url local "$FORGEJO_REMOTE"

echo ""
echo "=== Forgejo Seed Complete ==="
echo "Access Forgejo at: http://localhost:3000"
echo "Login with: $USERNAME / $PASSWORD"
echo "Repository URL: http://localhost:3000/$USERNAME/$REPO_NAME"
echo "Access Token: $ACCESS_TOKEN"
echo "Git remote 'local' configured (use: git push local)"
