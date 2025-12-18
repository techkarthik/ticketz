#!/bin/bash
HOST="72.60.23.223"
USER="root"
PASS="Canada@2022#winterfel"
REMOTE_DIR="/var/www/ticketz-api"

# 1. Update OS & Install Node.js
echo "Installing Node.js..."
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$HOST "apt update && apt install -y nodejs npm"

# 2. Create Directory
echo "Creating Remote Directory..."
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$HOST "mkdir -p $REMOTE_DIR"

# 3. Upload Files
echo "Uploading Files..."
sshpass -p "$PASS" scp -o StrictHostKeyChecking=no backend/package.json $USER@$HOST:$REMOTE_DIR/
sshpass -p "$PASS" scp -o StrictHostKeyChecking=no backend/server.js $USER@$HOST:$REMOTE_DIR/

# 4. Install Dependencies & Start PM2
echo "Starting Server..."
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$HOST "cd $REMOTE_DIR && npm install && npm install -g pm2 && pm2 delete all || true && pm2 start server.js --name ticketz-api && pm2 save"

echo "Deployment Complete!"
