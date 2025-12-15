
import crypto from 'crypto';

const url = "https://tickets-techkarthik.aws-ap-south-1.turso.io/v2/pipeline";
const authToken = "eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJhIjoicnciLCJpYXQiOjE3NjU2MTY0MzksImlkIjoiMWVhYTU1ZDktMGQzZS00ZWVlLTlmYjAtNjcwOGI4OGE0ZWFlIiwicmlkIjoiOThhNDIwZjYtNGE0Ny00Y2I1LWIyZWQtM2EwMjYyNjQ4N2E5In0.NQYUbloh5lgkGJnrExit0Jsho-e0b_P6YnaHOFjIXPfXuEgrYJ60ROB6fRZFJyz2PZf3B3yIxDzrh9isYrbkBQ";

function toSqlVal(val) {
    if (val === null || val === undefined) return { type: "null" };
    if (typeof val === 'number') {
        if (Number.isInteger(val)) return { type: "integer", value: String(val) };
        return { type: "float", value: val };
    }
    return { type: "text", value: String(val) };
}

async function execute(sql, args = []) {
    const mappedArgs = args.map(toSqlVal);
    const body = {
        requests: [
            { type: "execute", stmt: { sql, args: mappedArgs } },
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

    if (!resp.ok) {
        const text = await resp.text();
        throw new Error(`HTTP Error ${resp.status}: ${text}`);
    }

    const json = await resp.json();
    const res0 = json.results[0];
    if (res0.type === 'error') {
        // Ignore "duplicate column name" error if run multiple times
        if (res0.error.message.includes('duplicate column name')) {
            console.log("Column likely already exists, skipping creation.");
            return res0;
        }
        throw new Error(`DB Error: ${res0.error.message}`);
    }
    return res0;
}

async function run() {
    try {
        console.log("Adding ROLE column to USERS table...");

        // 1. Add Column
        try {
            await execute("ALTER TABLE USERS ADD COLUMN ROLE TEXT DEFAULT 'USER'");
            console.log("Column ROLE added successfully.");
        } catch (e) {
            console.log("Note: " + e.message);
        }

        // 2. Update KARTHIK to ADMIN
        console.log("Updating KARTHIK to ADMIN...");
        await execute("UPDATE USERS SET ROLE = 'ADMIN' WHERE UPPER(USERNAME) = 'KARTHIK'");

        // 3. Verify
        console.log("Verifying users...");
        const res = await execute("SELECT USERNAME, ROLE FROM USERS");
        const rows = res.response.result.rows;
        if (rows) {
            rows.forEach(r => {
                console.log(`User: ${r[0].value}, Role: ${r[1].value}`);
            });
        }

    } catch (e) {
        console.error("Migration failed:", e);
    }
}

run();
