const url = "https://tickets-techkarthik.aws-ap-south-1.turso.io/v2/pipeline";
const authToken = "eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJhIjoicnciLCJpYXQiOjE3NjU2MTY0MzksImlkIjoiMWVhYTU1ZDktMGQzZS00ZWVlLTlmYjAtNjcwOGI4OGE0ZWFlIiwicmlkIjoiOThhNDIwZjYtNGE0Ny00Y2I1LWIyZWQtM2EwMjYyNjQ4N2E5In0.NQYUbloh5lgkGJnrExit0Jsho-e0b_P6YnaHOFjIXPfXuEgrYJ60ROB6fRZFJyz2PZf3B3yIxDzrh9isYrbkBQ";
import crypto from 'crypto';

async function execute(sql, args = []) {
    const body = {
        requests: [
            { type: "execute", stmt: { sql, args } },
            { type: "close" }
        ]
    };

    const resp = await fetch(url, {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${authToken}`,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(body)
    });

    const json = await resp.json();
    if (json.results && json.results[0].type === 'error') {
        throw new Error(json.results[0].error.message);
    }
    return json.results[0];
}

function hashPassword(password) {
    return crypto.createHash('sha256').update(password).digest('hex');
}

async function run() {
    try {
        console.log("Fetching users...");
        // 1. Get all users
        const res = await execute("SELECT USERID, PASSWORD FROM USERS");
        if (!res.response || !res.response.result) {
            console.log("No users found or error.");
            return;
        }

        const rows = res.response.result.rows;
        console.log(`Found ${rows.length} users.`);

        // 2. Update each user
        for (const row of rows) {
            // row is [ {type: 'integer', value: '1'}, {type: 'text', value: '123'} ]
            const id = row[0].value;
            const pass = row[1].value;

            // Check if already hashed (length 64 for hex sha256)
            if (pass.length === 64) {
                console.log(`User ${id} already has hashed password. Skipping.`);
                continue;
            }

            const hashed = hashPassword(pass);
            console.log(`Updating User ${id}: ${pass} -> ${hashed}`);

            await execute("UPDATE USERS SET PASSWORD = ? WHERE USERID = ?", [
                { type: "text", value: hashed },
                { type: "integer", value: id }
            ]);
        }
        console.log("Migration complete.");

    } catch (e) {
        console.error("Error:", e);
    }
}

run();
