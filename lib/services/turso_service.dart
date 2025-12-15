import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class TursoService {
 // static const String _url = "https://tickets-techkarthik.aws-ap-south-1.turso.io/v2/pipeline";
 static const String _url = "https://tickets-techkarthik.aws-ap-south-1.turso.io/v2/pipeline";
  static const String _authToken = "eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJhIjoicnciLCJpYXQiOjE3NjU2MTY0MzksImlkIjoiMWVhYTU1ZDktMGQzZS00ZWVlLTlmYjAtNjcwOGI4OGE0ZWFlIiwicmlkIjoiOThhNDIwZjYtNGE0Ny00Y2I1LWIyZWQtM2EwMjYyNjQ4N2E5In0.NQYUbloh5lgkGJnrExit0Jsho-e0b_P6YnaHOFjIXPfXuEgrYJ60ROB6fRZFJyz2PZf3B3yIxDzrh9isYrbkBQ";

  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final bytes = utf8.encode(password);
      final hashedPassword = sha256.convert(bytes).toString();

      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "requests": [
            {
              "type": "execute",
              "stmt": {
                "sql": "SELECT U.USERID, U.USERNAME, U.PASSWORD, U.EMAIL, U.MOBILE, U.DEPARTMENTID, D.DEPARTMENT_NAME, U.ROLE FROM USERS U LEFT JOIN DEPARTMENTS D ON U.DEPARTMENTID = D.DEPTID WHERE LOWER(U.USERNAME) = LOWER(?) AND U.PASSWORD = ?",
                "args": [
                  {"type": "text", "value": username},
                  {"type": "text", "value": hashedPassword}
                ]
              }
            },
            {"type": "close"}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final results = json['results'];
        if (results != null && results.isNotEmpty) {
          final executeResult = results[0];
          if (executeResult['type'] == 'ok') {
            final rows = executeResult['response']['result']['rows'];
            if (rows != null && rows.isNotEmpty) {
              // User found
              final row = rows[0]; 
              return {
                'id': int.parse(row[0]['value']),
                'username': row[1]['value'],
                'email': row[3]['value'],
                'mobile': row[4]['value'],
                'deptId': int.parse(row[5]['value']),
                'deptName': row[6]['value'] ?? 'Unknown',
                'role': row[7]['value'] ?? 'USER',
              };
            }
          }
        }
      } else {
        print('Request failed with status: ${response.statusCode}.');
      }
    } catch (e) {
      print('Error logging in: $e');
    }
    return null;
  }

  // --- USERS CRUD ---

  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final res = await _execute("SELECT U.USERID, U.USERNAME, U.PASSWORD, U.EMAIL, U.MOBILE, U.DEPARTMENTID, D.DEPARTMENT_NAME, U.ROLE FROM USERS U LEFT JOIN DEPARTMENTS D ON U.DEPARTMENTID = D.DEPTID");
      if (res['type'] == 'ok') {
        final rows = res['response']['result']['rows'];
        if (rows != null) {
          return rows.map<Map<String, dynamic>>((r) => {
            'id': int.parse(r[0]['value']),
            'username': r[1]['value'],
            'password': r[2]['value'], // Hashed
            'email': r[3]['value'],
            'mobile': r[4]['value'],
            'deptId': int.parse(r[5]['value']),
            'deptName': r[6]['value'] ?? 'Unknown',
            'role': r[7]['value'] ?? 'USER',
          }).toList();
        }
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
    return [];
  }

  Future<bool> createUser(String username, String password, String email, String mobile, int deptId, String role) async {
    try {
      final bytes = utf8.encode(password);
      final hashedPassword = sha256.convert(bytes).toString();

      final res = await _execute(
        "INSERT INTO USERS (USERNAME, PASSWORD, EMAIL, MOBILE, DEPARTMENTID, ROLE) VALUES (?, ?, ?, ?, ?, ?)",
        [
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

  Future<List<Map<String, dynamic>>> getDepartments() async {
    try {
      final res = await _execute("SELECT * FROM DEPARTMENTS");
      if (res['type'] == 'ok') {
        final rows = res['response']['result']['rows'];
        if (rows != null) {
          return rows.map<Map<String, dynamic>>((r) => {
            'id': int.parse(r[0]['value']),
            'name': r[1]['value'],
            'active': r[2]['value'],
          }).toList();
        }
      }
    } catch (e) {
      print('Error fetching departments: $e');
    }
    return [];
  }

  Future<bool> createDepartment(String name, String active) async {
    try {
      final res = await _execute(
        "INSERT INTO DEPARTMENTS (DEPARTMENT_NAME, ACTIVE) VALUES (?, ?)",
        [
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

  Future<List<Map<String, dynamic>>> getExpenseTypes() async {
    try {
      final res = await _execute("SELECT * FROM EXPENSE_TYPES");
      if (res['type'] == 'ok') {
        final rows = res['response']['result']['rows'];
        if (rows != null) {
          return rows.map<Map<String, dynamic>>((r) => {
            'id': int.parse(r[0]['value']),
            'type': r[1]['value'],
          }).toList();
        }
      }
    } catch (e) {
      print('Error fetching expense types: $e');
    }
    return [];
  }

  Future<bool> createExpenseType(String type) async {
    try {
      final res = await _execute(
        "INSERT INTO EXPENSE_TYPES (EXPENSE_TYPE) VALUES (?)",
        [{"type": "text", "value": type}]
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
            'id': int.parse(r[0]['value']),
            'name': r[1]['value'],
          }).toList();
        }
      }
    } catch (e) {
      print('Error fetching months: $e');
    }
    return [];
  }

  Future<bool> createMonth(String name) async {
    try {
      final res = await _execute(
        "INSERT INTO MONTHS (NAME) VALUES (?)",
        [{"type": "text", "value": name}]
      );
      return res['type'] == 'ok';
    } catch (e) {
      print('Error creating month: $e');
      return false;
    }
  }

  Future<bool> updateMonth(int id, String name) async {
    try {
      final res = await _execute(
        "UPDATE MONTHS SET NAME = ? WHERE ID = ?",
        [
          {"type": "text", "value": name},
          {"type": "integer", "value": id.toString()},
        ]
      );
      return res['type'] == 'ok';
    } catch (e) {
      print('Error updating month: $e');
      return false;
    }
  }

  Future<bool> deleteMonth(int id) async {
    try {
      final res = await _execute("DELETE FROM MONTHS WHERE ID = ?", [
        {"type": "integer", "value": id.toString()}
      ]);
      return res['type'] == 'ok';
    } catch (e) {
      print('Error deleting month: $e');
      return false;
    }
  }

  // --- EXPENSE LIMITS CRUD ---

  // --- EXPENSE LIMITS CRUD ---

  Future<List<Map<String, dynamic>>> getExpenseLimits() async {
    try {
      final res = await _execute("SELECT L.ID, L.DEPARTMENTID, L.MONTHNAME, L.LIMIT_AMOUNT, D.DEPARTMENT_NAME FROM EXPENSE_LIMITS L LEFT JOIN DEPARTMENTS D ON L.DEPARTMENTID = D.DEPTID");
      if (res['type'] == 'ok') {
        final rows = res['response']['result']['rows'];
        if (rows != null) {
          return rows.map<Map<String, dynamic>>((r) => {
            'id': int.parse(r[0]['value']),
            'deptId': int.parse(r[1]['value']),
            'month': r[2]['value'],
            'limit': int.parse(r[3]['value']),
            'deptName': r[4]['value'] ?? 'Unknown',
          }).toList();
        }
      }
    } catch (e) {
      print('Error fetching expense limits: $e');
    }
    return [];
  }

  Future<String?> createExpenseLimit(int deptId, String month, int limit) async {
    try {
      final res = await _execute(
        "INSERT INTO EXPENSE_LIMITS (DEPARTMENTID, MONTHNAME, LIMIT_AMOUNT) VALUES (?, ?, ?)",
        [
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

  // --- EXPENSES (USER Submission) ---

  Future<List<Map<String, dynamic>>> getUserExpenses(int userId) async {
    try {
      // Joining with EXPENSE_TYPES to get type name if needed, but let's keep it simple first
      final res = await _execute("SELECT * FROM EXPENSES WHERE USERID = ? ORDER BY ID DESC", [
        {"type": "integer", "value": userId.toString()}
      ]);
      if (res['type'] == 'ok') {
        final rows = res['response']['result']['rows'];
        if (rows != null) {
          return rows.map<Map<String, dynamic>>((r) => {
            'id': int.parse(r[0]['value']),
            'userId': int.parse(r[1]['value']),
            'typeId': int.parse(r[2]['value']),
            'amount': int.parse(r[3]['value']),
            'date': r[4]['value'],
            'description': r[5]['value'],
            'status': r[6]['value'],
          }).toList();
        }
      }
    } catch (e) {
      print('Error fetching user expenses: $e');
    }
    return [];
  }

  Future<bool> createExpense(int userId, int typeId, int amount, String date, String description) async {
    try {
      final res = await _execute(
        "INSERT INTO EXPENSES (USERID, EXPENSE_TYPE_ID, AMOUNT, EXPENSE_DATE, DESCRIPTION, STATUS) VALUES (?, ?, ?, ?, ?, 'Pending')",
        [
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

  Future<int> checkExpenseLimit(int deptId, String month) async {
     try {
      final res = await _execute("SELECT LIMIT_AMOUNT FROM EXPENSE_LIMITS WHERE DEPARTMENTID = ? AND MONTHNAME = ?", [
         {"type": "integer", "value": deptId.toString()},
         {"type": "text", "value": month},
      ]);
      if (res['type'] == 'ok') {
         final rows = res['response']['result']['rows'];
         if (rows != null && rows.isNotEmpty) {
           return int.parse(rows[0][0]['value']);
         }
      }
     } catch (e) {
       print('Error checking limit: $e');
     }
     return -1; // No limit found
  }
  
  Future<int> getCurrentMonthSpending(int userId, String monthStr) async {
    // This is a simplification. Ideally we'd filter by date range in SQL.
    // Assuming monthStr is something we can match or we fetch all and filter in app (not scalable but ok for now).
    // Let's rely on fetching all expenses for user and filtering in Dart for now to save complex SQL for this prototype.
    return 0; 
  }

  // Helper for executing SQL
  Future<Map<String, dynamic>> _execute(String sql, [List<Map<String, String>>? args]) async {
    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Authorization': 'Bearer $_authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "requests": [
          {
            "type": "execute",
            "stmt": {
              "sql": sql,
              "args": args ?? []
            }
          },
          {"type": "close"}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['results'] != null && json['results'].isNotEmpty) {
        return json['results'][0];
      }
    }
    throw Exception('Failed to execute query');
  }
}
