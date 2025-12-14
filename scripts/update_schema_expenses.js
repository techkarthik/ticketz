const url = "https://tickets-techkarthik.aws-ap-south-1.turso.io/v2/pipeline";
const authToken = "eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJhIjoicnciLCJpYXQiOjE3NjU2MTY0MzksImlkIjoiMWVhYTU1ZDktMGQzZS00ZWVlLTlmYjAtNjcwOGI4OGE0ZWFlIiwicmlkIjoiOThhNDIwZjYtNGE0Ny00Y2I1LWIyZWQtM2EwMjYyNjQ4N2E5In0.NQYUbloh5lgkGJnrExit0Jsho-e0b_P6YnaHOFjIXPfXuEgrYJ60ROB6fRZFJyz2PZf3B3yIxDzrh9isYrbkBQ";

async function execute(sql) {
    const body = {
        requests: [
            { type: "execute", stmt: { sql } },
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

async function run() {
    try {
        console.log("Creating EXPENSES table...");

        // Create EXPENSES table
        await execute(`
      CREATE TABLE IF NOT EXISTS EXPENSES (
        ID INTEGER PRIMARY KEY AUTOINCREMENT,
        USERID INTEGER,
        EXPENSE_TYPE_ID INTEGER,
        AMOUNT INTEGER,
        EXPENSE_DATE TEXT,
        DESCRIPTION TEXT,
        STATUS TEXT DEFAULT 'Pending'
      )
    `);

        console.log("EXPENSES table created.");

        // Verify
        const res = await execute("SELECT name FROM sqlite_master WHERE type='table' AND name='EXPENSES'");
        if (res.response.result.rows.length > 0) {
            console.log("Verification SUCCESS: EXPENSES table exists.");
        } else {
            console.error("Verification FAILED: EXPENSES table not found.");
        }

    } catch (e) {
        console.error("Error:", e);
    }
}

run();
