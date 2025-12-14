const url = "https://tickets-techkarthik.aws-ap-south-1.turso.io/v2/pipeline";
const authToken = "eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJhIjoicnciLCJpYXQiOjE3NjU2MTY0MzksImlkIjoiMWVhYTU1ZDktMGQzZS00ZWVlLTlmYjAtNjcwOGI4OGE0ZWFlIiwicmlkIjoiOThhNDIwZjYtNGE0Ny00Y2I1LWIyZWQtM2EwMjYyNjQ4N2E5In0.NQYUbloh5lgkGJnrExit0Jsho-e0b_P6YnaHOFjIXPfXuEgrYJ60ROB6fRZFJyz2PZf3B3yIxDzrh9isYrbkBQ";

async function execute(sql, args = []) {
    try {
        const response = await fetch(url, {
            method: "POST",
            headers: {
                "Authorization": `Bearer ${authToken}`,
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                requests: [
                    {
                        type: "execute",
                        stmt: { sql: sql, args: args },
                    },
                    { type: "close" },
                ],
            }),
        });

        if (!response.ok) {
            throw new Error(`HTTP Error: ${response.status} ${response.statusText}`);
        }

        const data = await response.json();
        return data;
    } catch (e) {
        console.error("Execution error:", e);
        return null;
    }
}

async function main() {
    console.log("Cleaning up duplicates...");
    // Delete duplicates, keeping the one with valid ID (assuming MIN ID is the one to keep, or MAX)
    // SQLite doesn't support DELETE with JOIN/subquery fully in all versions in the same way, but common pattern:
    // DELETE FROM table WHERE rowid NOT IN (SELECT min(rowid) FROM table GROUP BY col1, col2)
    const deleteRes = await execute(`
    DELETE FROM EXPENSE_LIMITS 
    WHERE ID NOT IN (
      SELECT MIN(ID) 
      FROM EXPENSE_LIMITS 
      GROUP BY DEPARTMENTID, MONTHNAME
    )
  `);
    console.log("Delete Result:", JSON.stringify(deleteRes, null, 2));

    console.log("Creating unique index...");
    const indexRes = await execute(`
    CREATE UNIQUE INDEX IF NOT EXISTS idx_expense_limits_dept_month 
    ON EXPENSE_LIMITS(DEPARTMENTID, MONTHNAME)
  `);
    console.log("Index Creation Result:", JSON.stringify(indexRes, null, 2));
}

main();
