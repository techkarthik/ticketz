import { createClient } from "file:///C:/Users/Karthik/.gemini/antigravity/scratch/Ticketz/scripts/node_modules/@libsql/client/lib-esm/index.js";

const url = "libsql://ticketz-test-techkarthik.turso.io";
const authToken = "eyJhIjoiODAxYWY2N2E1YTBjZjc4NTViMTE0Y2FjYjVmZDU3N2IiLCJ0IjoiZGI5MGYxNzgtYzg2YS00NjZlLThjN2ItYjQyNzFmOTk5N2QxIiwicyI6ImNmNTg2NjMyM2RhYjU2OTQxYzc3YmJkMmI1ZDU4ZGUwYjQzNjg2ODgwZGUwODc1YjFhMTUzYjI0M2Q3NzExZGYifQ==";

const client = createClient({
    url: url,
    authToken: authToken,
});

async function main() {
    try {
        console.log("Fetching EXPENSE_LIMITS...");
        const res = await client.execute("SELECT * FROM EXPENSE_LIMITS");
        console.table(res.rows);

        console.log("\nFetching DEPARTMENTS...");
        const deptRes = await client.execute("SELECT * FROM DEPARTMENTS");
        console.table(deptRes.rows);
    } catch (e) {
        console.error("Error fetching data:", e);
    } finally {
        client.close();
    }
}

main();
