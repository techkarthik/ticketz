const url = "https://tickets-techkarthik.aws-ap-south-1.turso.io/v2/pipeline";
const authToken = "eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJhIjoicnciLCJpYXQiOjE3NjU2MTY0MzksImlkIjoiMWVhYTU1ZDktMGQzZS00ZWVlLTlmYjAtNjcwOGI4OGE0ZWFlIiwicmlkIjoiOThhNDIwZjYtNGE0Ny00Y2I1LWIyZWQtM2EwMjYyNjQ4N2E5In0.NQYUbloh5lgkGJnrExit0Jsho-e0b_P6YnaHOFjIXPfXuEgrYJ60ROB6fRZFJyz2PZf3B3yIxDzrh9isYrbkBQ";

async function execute(sql) {
    const body = {
        requests: [
            { type: "execute", stmt: { sql, args: [] } },
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
    return json.results[0]; // execute result
}

async function verify() {
    try {
        const tables = ["USERS", "DEPARTMENTS", "EXPENSE_TYPES", "MONTHS", "EXPENSE_LIMITS"];
        for (const t of tables) {
            const res = await execute(`SELECT COUNT(*) as count FROM ${t}`);
            if (res.type === 'ok') {
                // Result rows are [[ { type: 'integer', value: '3' } ]]
                const count = res.response.result.rows[0][0].value;
                console.log(`${t}: ${count} rows`);
            } else {
                console.error(`Error querying ${t}:`, res);
            }
        }
    } catch (e) {
        console.error(e);
    }
}

verify();
