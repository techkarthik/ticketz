import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

class TursoService {
  static const String _backendUrl = "http://72.60.23.223:3000";
  // TOKEN REMOVED - SECURED ON BACKEND
  
  // --- INIT DATABASE ---
  Future<String> initDatabase() async {
    try {
      final statements = [
        "DROP TABLE IF EXISTS VERIFICATION_CODES",
        "DROP TABLE IF EXISTS EXPENSES",
        "DROP TABLE IF EXISTS EXPENSE_LIMITS",
        "DROP TABLE IF EXISTS MONTHS",
        "DROP TABLE IF EXISTS EXPENSE_TYPES",
        "DROP TABLE IF EXISTS DEPARTMENTS",
        "DROP TABLE IF EXISTS USERS",
        
        "CREATE TABLE USERS (USERID INTEGER PRIMARY KEY AUTOINCREMENT, ORGANIZATION_ID INTEGER, USERNAME TEXT, PASSWORD TEXT, EMAIL TEXT, MOBILE TEXT, DEPARTMENTID INTEGER, ROLE TEXT)",
        "CREATE TABLE DEPARTMENTS (DEPTID INTEGER PRIMARY KEY AUTOINCREMENT, ORGANIZATION_ID INTEGER, DEPARTMENT_NAME TEXT, DESCRIPTION TEXT, HEAD_OF_DEPARTMENT TEXT, ACTIVE TEXT)", 
        "CREATE TABLE EXPENSE_TYPES (ID INTEGER PRIMARY KEY AUTOINCREMENT, ORGANIZATION_ID INTEGER, EXPENSE_TYPE TEXT, DESCRIPTION TEXT)",
        "CREATE TABLE MONTHS (ID INTEGER PRIMARY KEY AUTOINCREMENT, NAME TEXT)",
        "CREATE TABLE EXPENSE_LIMITS (ID INTEGER PRIMARY KEY AUTOINCREMENT, ORGANIZATION_ID INTEGER, DEPARTMENTID INTEGER, MONTHNAME TEXT, LIMIT_AMOUNT INTEGER, UNIQUE(ORGANIZATION_ID, DEPARTMENTID, MONTHNAME))",
        "CREATE TABLE EXPENSES (ID INTEGER PRIMARY KEY AUTOINCREMENT, ORGANIZATION_ID INTEGER, USERID INTEGER, EXPENSE_TYPE_ID INTEGER, AMOUNT INTEGER, EXPENSE_DATE TEXT, DESCRIPTION TEXT, STATUS TEXT, APPROVED_BY INTEGER, REJECTION_REMARK TEXT)",
        "CREATE TABLE VERIFICATION_CODES (EMAIL TEXT PRIMARY KEY, CODE TEXT, EXPIRES_AT INTEGER)"
      ];

      for (var sql in statements) {
        await _execute(sql);
      }
      
      // Pre-populate Months
       final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      for (var m in months) {
        await _execute("INSERT INTO MONTHS (NAME) VALUES (?)", [{"type": "text", "value": m}]);
      }
      
      return "Database initialized via Backend";
    } catch (e) {
      return "Error initializing database: $e";
    }
  }

  // --- HELPER ---
  Future<Map<String, dynamic>> _execute(String sql, [List<Map<String, String>>? args]) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/execute'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "sql": sql,
          "args": args?.map((a) => a['value']).toList() ?? []
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Backend Request failed: ${response.statusCode}');
        return {'type': 'error', 'error': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      print('Backend Connection Error: $e');
      return {'type': 'error', 'error': e.toString()};
    }
  }

  // --- AUTH & REGISTRATION ---
  
  // Use Backend Specific Endpoint for reliability
  Future<bool> storeVerificationCode(String email, String code) async {
      // Logic moved to Backend /auth/send-code actually handles this
      // But keeping method signature for compatibility if called elsewhere
      // actually register_screen calls sendVerificationCode on EmailService
      // and TursoService.storeVerificationCode. 
      // We should probably rely on the Backend's /auth/send-code to do BOTH.
      return true; 
  }

  Future<bool> verifyCode(String email, String code) async {
    try {
        final response = await http.post(
            Uri.parse('$_backendUrl/auth/verify-code'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({ 'email': email, 'code': code })
        );
        if (response.statusCode == 200) {
            final res = jsonDecode(response.body);
            return res['success'] == true;
        }
    } catch (e) {
        print("Verify Error: $e");
    }
    return false;
  }

  Future<int> generateOrganizationId() async {
      // Backend handles this usually, but if needed:
      final response = await http.post(Uri.parse('$_backendUrl/auth/generate-org-id'));
      if(response.statusCode == 200) {
          final res = jsonDecode(response.body);
          if(res['success']) return res['orgId'];
      }
      return 0; 
  }

  Future<Map<String, dynamic>?> login(int organizationId, String username, String password) async {
      final bytes = utf8.encode(password);
      final hashedPassword = sha256.convert(bytes).toString();
      
      try {
          final response = await http.post(
            Uri.parse('$_backendUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({ 'orgId': organizationId, 'username': username, 'password': hashedPassword })
        );
        
        if (response.statusCode == 200) {
            final res = jsonDecode(response.body);
            if (res['success'] == true) {
                final u = res['user'];
                // Normalize keys from backend (usually lowercase)
               return {
                'id': u['USERID'] ?? u['userid'],
                'username': u['USERNAME'] ?? u['username'],
                'email': u['EMAIL'] ?? u['email'],
                'mobile': u['MOBILE'] ?? u['mobile'],
                'deptId': u['DEPARTMENTID'] ?? u['departmentid'] ?? 0,
                'deptName': u['DEPARTMENT_NAME'] ?? u['department_name'] ?? 'Unknown',
                'role': u['ROLE'] ?? u['role'] ?? 'USER',
                'organizationId': u['ORGANIZATION_ID'] ?? u['organization_id'],
              };
            }
        }
      } catch (e) { print("Login error: $e"); }
      return null;
  }
  
  // Registers a new organization with defaults via Backend
  Future<int?> registerNewOrganization(String username, String password, String email, String mobile) async {
      final bytes = utf8.encode(password);
      final hashedPassword = sha256.convert(bytes).toString();

      try {
          final response = await http.post(
            Uri.parse('$_backendUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({ 'username': username, 'password': hashedPassword, 'email': email, 'mobile': mobile })
        );
        if (response.statusCode == 200) {
            final res = jsonDecode(response.body);
            if(res['success']) return res['orgId'];
        }
      } catch (e) { print("Register Error: $e"); }
      return null;
  }

  Future<List<int>> getOrganizationIdsByEmail(String email) async {
    try {
      final res = await _execute(
        "SELECT ORGANIZATION_ID FROM USERS WHERE EMAIL = ?",
        [{"type": "text", "value": email}]
      );
      if (res['type'] == 'ok') {
        final rows = res['response']['result']['rows'];
        if (rows != null) {
          return rows.map<int>((r) => int.parse((r['ORGANIZATION_ID'] ?? r['organization_id']).toString())).toList();
        }
      }
    } catch (e) {
      print('Error finding org IDs: $e');
    }
    return [];
  }

  Future<bool> resetPassword(int organizationId, String email, String newPassword) async {
    try {
      final bytes = utf8.encode(newPassword);
      final hashedPassword = sha256.convert(bytes).toString();

      final res = await _execute(
        "UPDATE USERS SET PASSWORD = ? WHERE ORGANIZATION_ID = ? AND EMAIL = ?",
        [
          {"type": "text", "value": hashedPassword},
          {"type": "integer", "value": organizationId.toString()},
          {"type": "text", "value": email},
        ]
      );
      return res['type'] == 'ok';
    } catch (e) {
      print('Error resetting password: $e');
      return false;
    }
  }

  // --- USERS CRUD ---

  Future<List<Map<String, dynamic>>> getUsers(int organizationId) async {
    try {
      final res = await _execute(
        "SELECT U.USERID, U.USERNAME, U.PASSWORD, U.EMAIL, U.MOBILE, U.DEPARTMENTID, D.DEPARTMENT_NAME, U.ROLE "
        "FROM USERS U LEFT JOIN DEPARTMENTS D ON U.DEPARTMENTID = D.DEPTID "
        "WHERE U.ORGANIZATION_ID = ?",
        [{"type": "integer", "value": organizationId.toString()}]
      );
      if (res['type'] == 'ok') {
        final rows = res['response']['result']['rows'];
        if (rows != null) {
          return rows.map<Map<String, dynamic>>((r) => {
            'id': int.parse((r['USERID'] ?? r['userid']).toString()),
            'username': r['USERNAME'] ?? r['username'],
            'password': r['PASSWORD'] ?? r['password'],
            'email': r['EMAIL'] ?? r['email'],
            'mobile': r['MOBILE'] ?? r['mobile'],
            'deptId': (r['DEPARTMENTID'] ?? r['departmentid']) != null ? int.parse((r['DEPARTMENTID'] ?? r['departmentid']).toString()) : 0,
            'deptName': r['DEPARTMENT_NAME'] ?? r['department_name'] ?? 'Unknown',
            'role': r['ROLE'] ?? r['role'] ?? 'USER',
          }).toList();
        }
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
    return [];
  }

  Future<bool> registerAdmin(String username, String password, String email, String mobile) async {
    try {
      int orgId = await generateOrganizationId();
      return await createUser(orgId, username, password, email, mobile, 0, 'ADMIN'); // 0 deptId initially
    } catch (e) {
      print('Error registering admin: $e');
      return false;
    }
  }

  Future<bool> createUser(int organizationId, String username, String password, String email, String mobile, int deptId, String role) async {
    try {
      final bytes = utf8.encode(password);
      final hashedPassword = sha256.convert(bytes).toString();

      final res = await _execute(
        "INSERT INTO USERS (ORGANIZATION_ID, USERNAME, PASSWORD, EMAIL, MOBILE, DEPARTMENTID, ROLE) VALUES (?, ?, ?, ?, ?, ?, ?)",
        [
          {"type": "integer", "value": organizationId.toString()},
          {"type": "text", "value": username},
          {"type": "text", "value": hashedPassword},
          {"type": "text", "value": email},
          {"type": "text", "value": mobile},
          {"type": "integer", "value": deptId.toString()},
          {"type": "text", "value": role},
        ]
      );
      return res['type'] == 'ok';
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }

  Future<bool> updateUser(int id, String username, String? password, String email, String mobile, int deptId, String role) async {
    try {
      String sql;
      List<Map<String, String>> args;

      if (password != null && password.isNotEmpty) {
        final bytes = utf8.encode(password);
        final hashedPassword = sha256.convert(bytes).toString();
        sql = "UPDATE USERS SET USERNAME = ?, PASSWORD = ?, EMAIL = ?, MOBILE = ?, DEPARTMENTID = ?, ROLE = ? WHERE USERID = ?";
        args = [
          {"type": "text", "value": username},
          {"type": "text", "value": hashedPassword},
          {"type": "text", "value": email},
          {"type": "text", "value": mobile},
          {"type": "integer", "value": deptId.toString()},
          {"type": "text", "value": role},
          {"type": "integer", "value": id.toString()},
        ];
      } else {
        sql = "UPDATE USERS SET USERNAME = ?, EMAIL = ?, MOBILE = ?, DEPARTMENTID = ?, ROLE = ? WHERE USERID = ?";
        args = [
          {"type": "text", "value": username},
          {"type": "text", "value": email},
          {"type": "text", "value": mobile},
          {"type": "integer", "value": deptId.toString()},
          {"type": "text", "value": role},
          {"type": "integer", "value": id.toString()},
        ];
      }

      final res = await _execute(sql, args);
      return res['type'] == 'ok';
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      final res = await _execute("DELETE FROM USERS WHERE USERID = ?", [
        {"type": "integer", "value": id.toString()}
      ]);
      return res['type'] == 'ok';
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // --- DEPARTMENTS CRUD ---

  Future<List<Map<String, dynamic>>> getDepartments(int organizationId) async {
    try {
      final res = await _execute(
        "SELECT * FROM DEPARTMENTS WHERE ORGANIZATION_ID = ?",
        [{"type": "integer", "value": organizationId.toString()}]
      );
      if (res['type'] == 'ok') {
        final rows = res['response']['result']['rows'];
        if (rows != null) {
          return rows.map<Map<String, dynamic>>((r) => {
            'id': int.parse((r['DEPTID'] ?? r['deptid']).toString()),
            'name': r['DEPARTMENT_NAME'] ?? r['department_name'],
            'active': r['ACTIVE'] ?? r['active'],
          }).toList();
        }
      }
    } catch (e) {
      print('Error fetching departments: $e');
    }
    return [];
  }

  Future<bool> createDepartment(int organizationId, String name, String active) async {
    try {
      final res = await _execute(
        "INSERT INTO DEPARTMENTS (ORGANIZATION_ID, DEPARTMENT_NAME, ACTIVE) VALUES (?, ?, ?)",
        [
          {"type": "integer", "value": organizationId.toString()},
          {"type": "text", "value": name},
          {"type": "text", "value": active},
        ]
      );
      return res['type'] == 'ok';
    } catch (e) {
      print('Error creating department: $e');
      return false;
    }
  }

  Future<bool> updateDepartment(int id, String name, String active) async {
    try {
      final res = await _execute(
        "UPDATE DEPARTMENTS SET DEPARTMENT_NAME = ?, ACTIVE = ? WHERE DEPTID = ?",
        [
          {"type": "text", "value": name},
          {"type": "text", "value": active},
          {"type": "integer", "value": id.toString()},
        ]
      );
      return res['type'] == 'ok';
    } catch (e) {
      print('Error updating department: $e');
      return false;
    }
  }

  Future<bool> deleteDepartment(int id) async {
    try {
      final res = await _execute("DELETE FROM DEPARTMENTS WHERE DEPTID = ?", [
        {"type": "integer", "value": id.toString()}
      ]);
      return res['type'] == 'ok';
    } catch (e) {
      print('Error deleting department: $e');
      return false;
    }
  }

  // --- EXPENSE TYPES CRUD ---

  Future<List<Map<String, dynamic>>> getExpenseTypes(int organizationId) async {
    try {
      final res = await _execute(
        "SELECT * FROM EXPENSE_TYPES WHERE ORGANIZATION_ID = ?",
        [{"type": "integer", "value": organizationId.toString()}]
      );
      if (res['type'] == 'ok') {
        final rows = res['response']['result']['rows'];
        if (rows != null) {
          return rows.map<Map<String, dynamic>>((r) => {
            'id': int.parse((r['ID'] ?? r['id']).toString()),
            'type': r['EXPENSE_TYPE'] ?? r['expense_type'],
          }).toList();
        }
      }
    } catch (e) {
      print('Error fetching expense types: $e');
    }
    return [];
  }

  Future<bool> createExpenseType(int organizationId, String type) async {
    try {
      final res = await _execute(
        "INSERT INTO EXPENSE_TYPES (ORGANIZATION_ID, EXPENSE_TYPE) VALUES (?, ?)",
        [
          {"type": "integer", "value": organizationId.toString()},
          {"type": "text", "value": type}
        ]
      );
      return res['type'] == 'ok';
    } catch (e) {
      print('Error creating expense type: $e');
      return false;
    }
  }

  Future<bool> updateExpenseType(int id, String type) async {
    try {
      final res = await _execute(
        "UPDATE EXPENSE_TYPES SET EXPENSE_TYPE = ? WHERE ID = ?",
        [
          {"type": "text", "value": type},
          {"type": "integer", "value": id.toString()},
        ]
      );
      return res['type'] == 'ok';
    } catch (e) {
      print('Error updating expense type: $e');
      return false;
    }
  }

  Future<bool> deleteExpenseType(int id) async {
    try {
      final res = await _execute("DELETE FROM EXPENSE_TYPES WHERE ID = ?", [
        {"type": "integer", "value": id.toString()}
      ]);
      return res['type'] == 'ok';
    } catch (e) {
      print('Error deleting expense type: $e');
      return false;
    }
  }

  // --- MONTHS CRUD ---

  Future<List<Map<String, dynamic>>> getMonths() async {
    try {
      final res = await _execute("SELECT * FROM MONTHS");
      if (res['type'] == 'ok') {
        final rows = res['response']['result']['rows'];
        if (rows != null) {
          return rows.map<Map<String, dynamic>>((r) => {
            'id': int.parse((r['ID'] ?? r['id']).toString()),
            'name': r['NAME'] ?? r['name'],
          }).toList();
        }
      }
    } catch (e) {
      print('Error fetching months: $e');
    }
    return [];
  }



  // --- EXPENSE LIMITS CRUD ---

  Future<List<Map<String, dynamic>>> getExpenseLimits(int organizationId) async {
    try {
      final res = await _execute(
        "SELECT L.ID, L.DEPARTMENTID, L.MONTHNAME, L.LIMIT_AMOUNT, D.DEPARTMENT_NAME "
        "FROM EXPENSE_LIMITS L "
        "LEFT JOIN DEPARTMENTS D ON L.DEPARTMENTID = D.DEPTID "
        "WHERE L.ORGANIZATION_ID = ?",
        [{"type": "integer", "value": organizationId.toString()}]
      );
      if (res['type'] == 'ok') {
        final rows = res['response']['result']['rows'];
        if (rows != null) {
          return rows.map<Map<String, dynamic>>((r) => {
            'id': int.parse((r['ID'] ?? r['id']).toString()),
            'deptId': int.parse((r['DEPARTMENTID'] ?? r['departmentid']).toString()),
            'month': r['MONTHNAME'] ?? r['monthname'],
            'limit': int.parse((r['LIMIT_AMOUNT'] ?? r['limit_amount']).toString()),
            'deptName': r['DEPARTMENT_NAME'] ?? r['department_name'] ?? 'Unknown',
          }).toList();
        }
      }
    } catch (e) {
      print('Error fetching expense limits: $e');
    }
    return [];
  }

  Future<String?> createExpenseLimit(int organizationId, int deptId, String month, int limit) async {
    try {
      final res = await _execute(
        "INSERT INTO EXPENSE_LIMITS (ORGANIZATION_ID, DEPARTMENTID, MONTHNAME, LIMIT_AMOUNT) VALUES (?, ?, ?, ?)",
        [
          {"type": "integer", "value": organizationId.toString()},
          {"type": "integer", "value": deptId.toString()},
          {"type": "text", "value": month},
          {"type": "integer", "value": limit.toString()},
        ]
      );
      if (res['type'] == 'error') {
         if (res['error'].toString().contains("UNIQUE constraint failed")) {
           return "Limit already exists for this Department and Month.";
         }
         return "Database error: ${res['error']}";
      }
      return null; // Success
    } catch (e) {
      print('Error creating expense limit: $e');
      if (e.toString().contains("UNIQUE constraint failed")) {
           return "Limit already exists for this Department and Month.";
      }
      return "Error: $e";
    }
  }

  Future<String?> updateExpenseLimit(int id, int deptId, String month, int limit) async {
    try {
      final res = await _execute(
        "UPDATE EXPENSE_LIMITS SET DEPARTMENTID = ?, MONTHNAME = ?, LIMIT_AMOUNT = ? WHERE ID = ?",
        [
          {"type": "integer", "value": deptId.toString()},
          {"type": "text", "value": month},
          {"type": "integer", "value": limit.toString()},
          {"type": "integer", "value": id.toString()},
        ]
      );
      if (res['type'] == 'error') {
          if (res['error'].toString().contains("UNIQUE constraint failed")) {
           return "Limit already exists for this Department and Month.";
         }
         return "Database error: ${res['error']}";
      }
      return null; // Success
    } catch (e) {
      print('Error updating expense limit: $e');
      if (e.toString().contains("UNIQUE constraint failed")) {
           return "Limit already exists for this Department and Month.";
      }
      return "Error: $e";
    }
  }

  Future<bool> deleteExpenseLimit(int id) async {
    try {
      final res = await _execute("DELETE FROM EXPENSE_LIMITS WHERE ID = ?", [
        {"type": "integer", "value": id.toString()}
      ]);
      return res['type'] == 'ok';
    } catch (e) {
      print('Error deleting expense limit: $e');
      return false;
    }
  }

  // --- APPROVAL WORKFLOW ---

  Future<List<Map<String, dynamic>>> getPendingExpenses(int organizationId) async {
    try {
      final res = await _execute(
        "SELECT E.ID, E.USERID, E.EXPENSE_TYPE_ID, E.AMOUNT, E.EXPENSE_DATE, E.DESCRIPTION, E.STATUS, U.USERNAME, D.DEPARTMENT_NAME "
        "FROM EXPENSES E "
        "LEFT JOIN USERS U ON E.USERID = U.USERID "
        "LEFT JOIN DEPARTMENTS D ON U.DEPARTMENTID = D.DEPTID "
        "WHERE E.ORGANIZATION_ID = ? AND E.STATUS = 'Pending' ORDER BY E.ID DESC",
        [{"type": "integer", "value": organizationId.toString()}]
      );
      
      if (res['type'] == 'ok') {
         final rows = res['response']['result']['rows'];
         if (rows != null) {
           return rows.map<Map<String, dynamic>>((r) => {
             'id': int.parse((r['ID'] ?? r['id']).toString()),
             'userId': int.parse((r['USERID'] ?? r['userid']).toString()),
             'typeId': int.parse((r['EXPENSE_TYPE_ID'] ?? r['expense_type_id']).toString()),
             'amount': int.parse((r['AMOUNT'] ?? r['amount']).toString()),
             'date': r['EXPENSE_DATE'] ?? r['expense_date'],
             'description': r['DESCRIPTION'] ?? r['description'],
             'status': r['STATUS'] ?? r['status'],
             'username': r['USERNAME'] ?? r['username'],
             'deptName': r['DEPARTMENT_NAME'] ?? r['department_name'] ?? 'Unknown',
           }).toList();
         }
      }
    } catch (e) {
      print('Error fetching pending expenses: $e');
    }
    return [];
  }

  Future<bool> approveExpense(int id, int approverId) async {
    try {
      final res = await _execute(
        "UPDATE EXPENSES SET STATUS = 'Approved', APPROVED_BY = ? WHERE ID = ?",
        [
          {"type": "integer", "value": approverId.toString()},
          {"type": "integer", "value": id.toString()},
        ]
      );
      return res['type'] == 'ok';
    } catch (e) {
      print('Error approving expense: $e');
      return false;
    }
  }

  Future<bool> rejectExpense(int id, int rejectorId, String remark) async {
    try {
      final res = await _execute(
        "UPDATE EXPENSES SET STATUS = 'Rejected', APPROVED_BY = ?, REJECTION_REMARK = ? WHERE ID = ?",
        [
          {"type": "integer", "value": rejectorId.toString()},
          {"type": "text", "value": remark},
          {"type": "integer", "value": id.toString()},
        ]
      );
      return res['type'] == 'ok';
    } catch (e) {
      print('Error rejecting expense: $e');
      return false;
    }
  }

  // --- EXPENSES (USER Submission) ---

  Future<List<Map<String, dynamic>>> getUserExpenses(int userId, {String? monthPrefix}) async {
    try {
      String sql = "SELECT E.ID, E.USERID, E.EXPENSE_TYPE_ID, E.AMOUNT, E.EXPENSE_DATE, E.DESCRIPTION, E.STATUS, U.USERNAME, E.REJECTION_REMARK "
                   "FROM EXPENSES E "
                   "LEFT JOIN USERS U ON E.APPROVED_BY = U.USERID "
                   "WHERE E.USERID = ?";
      
      List<Map<String, String>> args = [{"type": "integer", "value": userId.toString()}];

      if (monthPrefix != null) {
        sql += " AND E.EXPENSE_DATE LIKE ?";
        args.add({"type": "text", "value": "$monthPrefix%"});
      }

      sql += " ORDER BY E.ID DESC";

      final res = await _execute(sql, args);
      if (res['type'] == 'ok') {
        final rows = res['response']['result']['rows'];
        if (rows != null) {
          return rows.map<Map<String, dynamic>>((r) => {
            'id': int.parse((r['ID'] ?? r['id']).toString()),
            'userId': int.parse((r['USERID'] ?? r['userid']).toString()),
            'typeId': int.parse((r['EXPENSE_TYPE_ID'] ?? r['expense_type_id']).toString()),
            'amount': int.parse((r['AMOUNT'] ?? r['amount']).toString()),
            'date': r['EXPENSE_DATE'] ?? r['expense_date'],
            'description': r['DESCRIPTION'] ?? r['description'],
            'status': r['STATUS'] ?? r['status'],
            'approverName': r['USERNAME'] ?? r['username'], 
            'remark': r['REJECTION_REMARK'] ?? r['rejection_remark'],
          }).toList();
        }
      }
    } catch (e) {
      print('Error fetching user expenses: $e');
    }
    return [];
  }

  Future<bool> createExpense(int organizationId, int userId, int typeId, int amount, String date, String description) async {
    try {
      final res = await _execute(
        "INSERT INTO EXPENSES (ORGANIZATION_ID, USERID, EXPENSE_TYPE_ID, AMOUNT, EXPENSE_DATE, DESCRIPTION, STATUS) VALUES (?, ?, ?, ?, ?, ?, 'Pending')",
        [
          {"type": "integer", "value": organizationId.toString()},
          {"type": "integer", "value": userId.toString()},
          {"type": "integer", "value": typeId.toString()},
          {"type": "integer", "value": amount.toString()},
          {"type": "text", "value": date},
          {"type": "text", "value": description},
        ]
      );
      return res['type'] == 'ok';
    } catch (e) {
      print('Error creating expense: $e');
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    try {
      // Only delete if NOT Approved. Extra safety check.
      final res = await _execute(
        "DELETE FROM EXPENSES WHERE ID = ? AND STATUS != 'Approved'",
        [{"type": "integer", "value": id.toString()}]
      );
      return res['type'] == 'ok';
    } catch (e) {
      print('Error deleting expense: $e');
      return false;
    }
  }

  Future<int> checkExpenseLimit(int organizationId, int deptId, String month) async {
     try {
      final res = await _execute("SELECT LIMIT_AMOUNT FROM EXPENSE_LIMITS WHERE ORGANIZATION_ID = ? AND DEPARTMENTID = ? AND MONTHNAME = ?", [
         {"type": "integer", "value": organizationId.toString()},
         {"type": "integer", "value": deptId.toString()},
         {"type": "text", "value": month},
      ]);
      if (res['type'] == 'ok') {
         final rows = res['response']['result']['rows'];
         if (rows != null && rows.isNotEmpty) {
           final row = rows[0];
           return int.parse((row['LIMIT_AMOUNT'] ?? row['limit_amount']).toString());
         }
      }
     } catch (e) {
       print('Error checking limit: $e');
     }
     return -1; // No limit found
  }

  // --- STATS ---

  Future<List<Map<String, dynamic>>> getDepartmentStats(int organizationId, String monthPrefix, String monthName) async {
    try {
      final res = await _execute(
        "SELECT D.DEPARTMENT_NAME, SUM(E.AMOUNT) as TOTAL_SPENT, L.LIMIT_AMOUNT "
        "FROM EXPENSES E "
        "JOIN USERS U ON E.USERID = U.USERID "
        "JOIN DEPARTMENTS D ON U.DEPARTMENTID = D.DEPTID "
        "LEFT JOIN EXPENSE_LIMITS L ON D.DEPTID = L.DEPARTMENTID AND L.MONTHNAME = ? "
        "WHERE E.ORGANIZATION_ID = ? AND E.STATUS != 'Rejected' AND E.EXPENSE_DATE LIKE ? "
        "GROUP BY D.DEPARTMENT_NAME",
        [
          {"type": "text", "value": monthName},
          {"type": "integer", "value": organizationId.toString()},
          {"type": "text", "value": "$monthPrefix%"}
        ]
      );

      if (res['type'] == 'ok') {
        final rows = res['response']['result']['rows'];
        if (rows != null) {
          return rows.map<Map<String, dynamic>>((r) => {
            'deptName': r['DEPARTMENT_NAME'] ?? r['department_name'],
            'total': double.parse((r['TOTAL_SPENT'] ?? r['total_spent'] ?? 0).toString()),
            'limit': (r['LIMIT_AMOUNT'] ?? r['limit_amount']) != null ? int.parse((r['LIMIT_AMOUNT'] ?? r['limit_amount']).toString()) : null,
          }).toList();
        }
      }
    } catch (e) {
      print('Error fetching department stats: $e');
    }
    return [];
  }

  Future<int> getDepartmentCurrentSpending(int organizationId, int deptId, String monthPrefix) async {
    try {
      final res = await _execute(
        "SELECT SUM(E.AMOUNT) as TOTAL_SPENT FROM EXPENSES E "
        "JOIN USERS U ON E.USERID = U.USERID "
        "WHERE E.ORGANIZATION_ID = ? AND U.DEPARTMENTID = ? AND E.STATUS != 'Rejected' AND E.EXPENSE_DATE LIKE ?",
        [
           {"type": "integer", "value": organizationId.toString()},
           {"type": "integer", "value": deptId.toString()},
           {"type": "text", "value": "$monthPrefix%"}
        ]
      );
      if (res['type'] == 'ok') {
         final rows = res['response']['result']['rows'];
         if (rows != null && rows.isNotEmpty) {
           final row = rows[0];
           final val = row['TOTAL_SPENT'] ?? row['total_spent'];
           if (val != null) return int.parse(val.toString());
         }
      }
    } catch (e) {
      print('Error verifying code: $e');
    }
    return 0;
  }
}
