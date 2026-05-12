from flask import Flask, request, jsonify
from flask_cors import CORS
import oracledb
import os

# --- ORACLE THICK MODE SETUP ---
try:
    # Path to your Oracle bin folder
    oracledb.init_oracle_client(lib_dir=r"C:\oraclexe\app\oracle\product\11.2.0\server\bin")
    print("✅ Oracle Thick Mode initialized!")
except Exception as e:
    print(f"⚠️ Thick Mode Warning (May already be initialized): {e}")

app = Flask(__name__)
CORS(app)

# --- DATABASE CREDENTIALS ---
DB_CONFIG = {
    "user": "hunny",
    "password": "6659",
    "dsn": "localhost:1521/xe"
}

@app.route('/')
def home():
    return "DataLock Cloud Server is ONLINE"

# 1. REGISTER ROUTE (Saves profile to Oracle)
@app.route('/register', methods=['POST'])
def register():
    data = request.json
    try:
        conn = oracledb.connect(**DB_CONFIG)
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO datalock_users (u_id, full_name, phone_number, email_id) VALUES (user_seq.NEXTVAL, :1, :2, :3)",
            [data['name'], data['phone'], data['email']]
        )
        conn.commit()
        cursor.close()
        conn.close()
        print(f"👤 Successfully Registered: {data['name']}")
        return jsonify({"status": "success"}), 200
    except Exception as e:
        print(f"❌ Registration Error: {e}")
        return jsonify({"error": str(e)}), 500

# 2. SEARCH ROUTE (Fetches profile from Oracle)
@app.route('/search/<name>', methods=['GET'])
def search(name):
    try:
        conn = oracledb.connect(**DB_CONFIG)
        cursor = conn.cursor()
        # Case-insensitive search
        cursor.execute("SELECT full_name, phone_number, email_id FROM datalock_users WHERE LOWER(full_name) = LOWER(:1)", [name])
        row = cursor.fetchone()
        cursor.close()
        conn.close()
        if row:
            print(f"🔍 Search Success for: {name}")
            return jsonify({"name": row[0], "phone": row[1], "email": row[2]}), 200
        else:
            print(f"❓ User not found: {name}")
            return jsonify({"error": "User not found"}), 404
    except Exception as e:
        print(f"❌ Search Error: {e}")
        return jsonify({"error": str(e)}), 500

# 3. LOG ALERT ROUTE (Records attack in Oracle)
@app.route('/log_alert', methods=['POST'])
def log_alert():
    data = request.json
    try:
        conn = oracledb.connect(**DB_CONFIG)
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO security_logs (log_id, user_name, target_profile, activity_type) VALUES (security_log_seq.NEXTVAL, :1, :2, :3)", 
            [data['user'], data['target_profile'], data['activity']]
        )
        conn.commit()
        cursor.close()
        conn.close()
        print(f"🚨 BREACH LOGGED: {data['user']} -> {data['target_profile']}")
        return jsonify({"status": "success"}), 200
    except Exception as e:
        print(f"❌ Logging Error: {e}")
        return jsonify({"error": str(e)}), 500

# 4. OWNER CHECK ROUTE (Triggers the non-ignorable popup)
@app.route('/check_alerts/<target_name>', methods=['GET'])
def check_alerts(target_name):
    try:
        conn = oracledb.connect(**DB_CONFIG)
        cursor = conn.cursor()
        # Checks if an alert happened in the last 15 seconds for THIS user
        query = """
            SELECT user_name, activity_type 
            FROM security_logs 
            WHERE LOWER(target_profile) = LOWER(:1) 
            AND event_time > (SYSTIMESTAMP - INTERVAL '15' SECOND)
            ORDER BY event_time DESC
        """
        cursor.execute(query, [target_name])
        row = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if row:
            return jsonify({"status": "breach", "attacker": row[0], "activity": row[1]}), 200
        return jsonify({"status": "secure"}), 200
    except Exception as e:
        print(f"❌ Heartbeat Guard Error: {e}")
        return jsonify({"status": "error"}), 500

if __name__ == '__main__':
    print("--- DATALOCK SYSTEM: ADVANCED CLOUD MODEL READY ---")
    # Port 5050 matched with ngrok
    app.run(host='0.0.0.0', port=5050, debug=True)