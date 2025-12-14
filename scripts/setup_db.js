import crypto from 'crypto';

// Use credentials from turso_service.dart
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

async function execute(clientName, sql, args = []) {
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
    const res0 = json.results[0]; // execute result
    if (res0.type === 'error') {
        throw new Error(`DB Error: ${res0.error.message}`);
    }
    return res0;
}

// SHA-256 Hashing helper
function hashPassword(password) {
    return crypto.createHash('sha256').update(password).digest('hex');
}

async function run() {
    try {
        console.log("Starting database setup (via fetch)...");

        // 1. Tables (IF NOT EXISTS)

        // USERS
        await execute("db", `
      CREATE TABLE IF NOT EXISTS USERS (
        USERID INTEGER PRIMARY KEY,
        USERNAME TEXT NOT NULL,
        PASSWORD TEXT NOT NULL,
        EMAIL TEXT,
        MOBILE TEXT,
        DEPARTMENTID INTEGER
      )
    `);
        console.log("Verified USERS table.");

        // DEPARTMENTS
        await execute("db", `
      CREATE TABLE IF NOT EXISTS DEPARTMENTS (
        DEPTID INTEGER PRIMARY KEY,
        DEPARTMENT_NAME TEXT NOT NULL,
        ACTIVE TEXT CHECK(ACTIVE IN ('Y', 'N')) DEFAULT 'Y'
      )
    `);
        console.log("Verified DEPARTMENTS table.");

        // EXPENSE_TYPES
        await execute("db", `
      CREATE TABLE IF NOT EXISTS EXPENSE_TYPES (
        ID INTEGER PRIMARY KEY,
        EXPENSE_TYPE TEXT NOT NULL
      )
    `);
        console.log("Verified EXPENSE_TYPES table.");

        // MONTHS
        await execute("db", `
      CREATE TABLE IF NOT EXISTS MONTHS (
        ID INTEGER PRIMARY KEY AUTOINCREMENT,
        NAME TEXT NOT NULL UNIQUE
      )
    `);
        console.log("Verified MONTHS table.");

        // EXPENSE_LIMITS
        await execute("db", `
      CREATE TABLE IF NOT EXISTS EXPENSE_LIMITS (
        ID INTEGER PRIMARY KEY AUTOINCREMENT,
        DEPARTMENTID INTEGER NOT NULL,
        MONTHNAME TEXT NOT NULL,
        LIMIT_AMOUNT INTEGER NOT NULL,
        FOREIGN KEY(DEPARTMENTID) REFERENCES DEPARTMENTS(DEPTID)
      )
    `);
        console.log("Verified EXPENSE_LIMITS table.");

        // EXPENSES
        await execute("db", `
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
        console.log("Verified EXPENSES table.");


        // --- SEED (Only if empty) ---

        // Helper to check emptiness
        async function isEmpty(table) {
            const res = await execute("db", `SELECT COUNT(*) as c FROM ${table}`);
            return parseInt(res.response.result.rows[0][0].value) === 0;
        }

        // USERS
        if (await isEmpty("USERS")) {
            const users = [
                { id: 1, name: 'KARTHIK', pass: '123', email: 'KARTHIK@EMAIL.COM', mobile: '9003233312', dept: 5 },
                { id: 2, name: 'NIRMALA', pass: '1234', email: 'NIRMALA@EMAIL.COM', mobile: '8281333771', dept: 2 },
                { id: 3, name: 'RUDRA', pass: '1234', email: 'RUDRA@EMAIL.COM', mobile: '1252565255', dept: 1 },
            ];
            for (const u of users) {
                const hashedPass = hashPassword(u.pass);
                await execute("db", "INSERT INTO USERS (USERID, USERNAME, PASSWORD, EMAIL, MOBILE, DEPARTMENTID) VALUES (?, ?, ?, ?, ?, ?)",
                    [u.id, u.name, hashedPass, u.email, u.mobile, u.dept]);
            }
            console.log("Seeded USERS.");
        } else {
            console.log("Skipping seed for USERS (already data).");
        }

        // DEPARTMENTS
        if (await isEmpty("DEPARTMENTS")) {
            const depts = [
                { id: 1, name: 'ACCOUNTS', active: 'Y' },
                { id: 2, name: 'MARKETING', active: 'Y' },
                { id: 3, name: 'DEVELOPMENT', active: 'Y' },
                { id: 4, name: 'WEBSITE', active: 'N' },
                { id: 5, name: 'ADMIN', active: 'Y' },
            ];
            for (const d of depts) {
                await execute("db", "INSERT INTO DEPARTMENTS (DEPTID, DEPARTMENT_NAME, ACTIVE) VALUES (?, ?, ?)",
                    [d.id, d.name, d.active]);
            }
            console.log("Seeded DEPARTMENTS.");
        } else {
            console.log("Skipping seed for DEPARTMENTS (already data).");
        }


        // EXPENSE_TYPES
        if (await isEmpty("EXPENSE_TYPES")) {
            const types = [
                { id: 1, name: 'FUEL' },
                { id: 2, name: 'SNACKS' },
                { id: 3, name: 'INTERNET' },
                { id: 4, name: 'RENT' },
                { id: 5, name: 'KITCHEN' },
            ];
            for (const t of types) {
                await execute("db", "INSERT INTO EXPENSE_TYPES (ID, EXPENSE_TYPE) VALUES (?, ?)",
                    [t.id, t.name]);
            }
            console.log("Seeded EXPENSE_TYPES.");
        } else {
            console.log("Skipping seed for EXPENSE_TYPES (already data).");
        }

        // MONTHS
        if (await isEmpty("MONTHS")) {
            const monthNames = [
                "January", "February", "March", "April", "May", "June",
                "July", "August", "September", "October", "November", "December"
            ];
            for (const m of monthNames) {
                await execute("db", "INSERT INTO MONTHS (NAME) VALUES (?)", [m]);
            }
            console.log("Seeded MONTHS.");
        } else {
            console.log("Skipping seed for MONTHS (already data).");
        }


        // EXPENSE_LIMITS
        if (await isEmpty("EXPENSE_LIMITS")) {
            const limits = [
                // Dept 1
                { d: 1, m: 'January', l: 2500 }, { d: 1, m: 'February', l: 2500 }, { d: 1, m: 'March', l: 3000 },
                { d: 1, m: 'April', l: 2500 }, { d: 1, m: 'May', l: 3500 }, { d: 1, m: 'June', l: 2000 },
                { d: 1, m: 'July', l: 4000 }, { d: 1, m: 'August', l: 1500 }, { d: 1, m: 'September', l: 1000 },
                { d: 1, m: 'October', l: 500 }, { d: 1, m: 'November', l: 5000 }, { d: 1, m: 'December', l: 4500 },
                // Dept 5
                { d: 5, m: 'January', l: 6000 }, { d: 5, m: 'February', l: 5000 }, { d: 5, m: 'March', l: 4000 },
                { d: 5, m: 'April', l: 3500 }, { d: 5, m: 'May', l: 4000 }, { d: 5, m: 'June', l: 3500 },
                { d: 5, m: 'July', l: 3500 }, { d: 5, m: 'August', l: 2000 }, { d: 5, m: 'September', l: 500 },
                { d: 5, m: 'October', l: 600 }, { d: 5, m: 'November', l: 4200 }, { d: 5, m: 'December', l: 1350 },
            ];
            for (const l of limits) {
                await execute("db", "INSERT INTO EXPENSE_LIMITS (DEPARTMENTID, MONTHNAME, LIMIT_AMOUNT) VALUES (?, ?, ?)",
                    [l.d, l.m, l.l]);
            }
            console.log("Seeded EXPENSE_LIMITS.");
        } else {
            console.log("Skipping seed for EXPENSE_LIMITS (already data).");
        }


        console.log("Database setup/verification completed successfully.");

    } catch (error) {
        console.error("Error setting up database:", error);
    }
}

run();
