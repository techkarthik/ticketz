
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
        // Ignore if already exists (simplistic check)
        if (res0.error.message.includes('duplicate column name')) {
            console.log("Column likely already exists, skipping.");
            return res0;
        }
        throw new Error(`DB Error: ${res0.error.message}`);
    }
    return res0;
}

async function run() {
    try {
        console.log("Adding approval columns to EXPENSES table...");

        // 1. APPROVED_BY
        try {
            await execute("ALTER TABLE EXPENSES ADD COLUMN APPROVED_BY INTEGER");
            console.log("Column APPROVED_BY added successfully.");
        } catch (e) {
            console.log("Note for APPROVED_BY: " + e.message);
        }

        // 2. REJECTION_REMARK
        try {
            await execute("ALTER TABLE EXPENSES ADD COLUMN REJECTION_REMARK TEXT");
            console.log("Column REJECTION_REMARK added successfully.");
        } catch (e) {
            console.log("Note for REJECTION_REMARK: " + e.message);
        }

        console.log("Migration complete.");

    } catch (e) {
        console.error("Migration failed:", e);
    }
}

run();
