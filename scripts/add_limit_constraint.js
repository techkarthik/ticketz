import { createClient } from "@libsql/client";

const url = "libsql://ticketz-test-techkarthik.turso.io";
const authToken = "eyJhIjoiODAxYWY2N2E1YTBjZjc4NTViMTE0Y2FjYjVmZDU3N2IiLCJ0IjoiZGI5MGYxNzgtYzg2YS00NjZlLThjN2ItYjQyNzFmOTk5N2QxIiwicyI6ImNmNTg2NjMyM2RhYjU2OTQxYzc3YmJkMmI1ZDU4ZGUwYjQzNjg2ODgwZGUwODc1YjFhMTUzYjI0M2Q3NzExZGYifQ==";

const client = createClient({
    url: url,
    authToken: authToken,
});

async function main() {
    try {
        console.log("Adding unique constraint to EXPENSE_LIMITS...");

        // Create a unique index to enforce the constraint
        await client.execute(`
      CREATE UNIQUE INDEX IF NOT EXISTS idx_expense_limits_dept_month 
      ON EXPENSE_LIMITS(DEPARTMENTID, MONTHNAME);
    `);

        console.log("Unique index created successfully.");
    } catch (e) {
        if (e.message.includes("UNIQUE constraint failed")) {
            console.log("Constraint already exists or data violates it.");
        }
        console.error("Error creating unique index:", e);
    } finally {
        client.close();
    }
}

main();
