# rename_voter_db_improved.py
import sqlite3
import os

INPUT_DB  = "voter_identity.db"                     # your input file (must be valid SQLite now!)
OUTPUT_DB = "voter_list_readable.db"

TABLE_MAPPING = {
    "t1": "province", "t2": "district", "t3": "municipality", "t4": "ward",
    "t5": "election_booth", "t6": "voter", "t7": "voterdetails", "t8": "tags",
    "t9": "voter_tag", "t10": "main_ethnic_category", "t11": "sub_ethnic_category",
    "t12": "lastnames", "t13": "categorized",
}

COLUMN_MAPPING = {  # same as before
    "t1": {"c1": "id", "c2": "name"},
    "t2": {"c3": "id", "c4": "province_id", "c5": "name"},
    "t3": {"c6": "id", "c7": "district_id", "c8": "name", "c9": "type"},
    "t4": {"c10": "id", "c11": "municipality_id", "c12": "ward_no"},
    "t5": {"c13": "id", "c14": "ward_id", "c15": "booth_code", "c16": "booth_name"},
    "t6": {"c17": "id", "c18": "booth_id", "c19": "voter_no",
           "c20": "name_np", "c21": "age", "c22": "gender",
           "c23": "spouse_name_np", "c24": "parent_name_np"},
    "t7": {"c25": "id", "c26": "voterid", "c27": "name",
           "c28": "phone", "c29": "landline", "c30": "social_media"},
    "t8": {"c31": "id", "c32": "name", "c33": "category", "c34": "created_at"},
    "t9": {"c35": "voterdetail_id", "c36": "tag_id", "c37": "assigned_at"},
    "t10": {"c38": "MID", "c39": "Mname", "c40": "description",
            "c41": "created_at", "c42": "updated_at"},
    "t11": {"c43": "SID", "c44": "MID", "c45": "Sname", "c46": "description",
            "c47": "created_at", "c48": "updated_at"},
    "t12": {"c49": "id", "c50": "SID", "c51": "lastname", "c52": "root",
            "c53": "root_np", "c54": "variants_en", "c55": "variants_np",
            "c56": "is_ambiguous", "c57": "notes",
            "c58": "created_at", "c59": "updated_at"},
    "t13": {"c60": "id", "c61": "voter_no", "c62": "name",
            "c63": "Mname", "c64": "Sname", "c65": "Lastname", "c66": "created_at"},
}

def main():
    if not os.path.isfile(INPUT_DB):
        print(f"Error: Input file '{INPUT_DB}' not found.")
        return

    if os.path.exists(OUTPUT_DB):
        os.remove(OUTPUT_DB)
        print(f"Removed old output file: {OUTPUT_DB}")

    conn_in = sqlite3.connect(INPUT_DB)
    conn_out = sqlite3.connect(OUTPUT_DB)
    cur_in = conn_in.cursor()
    cur_out = conn_out.cursor()

    cur_in.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
    tables = [row[0] for row in cur_in.fetchall()]

    for old_table in tables:
        if old_table not in TABLE_MAPPING:
            print(f"Skipping unmapped table: {old_table}")
            continue

        new_table = TABLE_MAPPING[old_table]
        col_map = COLUMN_MAPPING.get(old_table, {})

        # Get column info
        cur_in.execute(f"PRAGMA table_info(\"{old_table}\")")
        columns_info = cur_in.fetchall()  # (cid, name, type, notnull, dflt_value, pk)

        col_defs = []
        for col in columns_info:
            cid, old_name, col_type, notnull, dflt_value, pk = col
            new_name = col_map.get(old_name, old_name)

            parts = [new_name, col_type]

            if notnull:
                parts.append("NOT NULL")
            if pk:
                parts.append("PRIMARY KEY")
            if dflt_value is not None:
                # Quote string defaults properly; functions like datetime('now') need parentheses
                if isinstance(dflt_value, str) and not dflt_value.startswith('('):
                    dflt_value = f"'{dflt_value.replace('\'', '\'\'')}'"
                parts.append(f"DEFAULT {dflt_value}")

            col_defs.append(" ".join(parts))

        create_stmt = f"CREATE TABLE \"{new_table}\" (\n  " + ",\n  ".join(col_defs) + "\n)"
        
        print(f"\nCreating table: {new_table}")
        print("Generated SQL:")
        print(create_stmt)
        print("-" * 60)

        try:
            cur_out.execute(create_stmt)
            print("Table created successfully")
        except sqlite3.Error as e:
            print(f"ERROR creating {new_table}: {e}")
            print("→ You may need to manually adjust DEFAULT values or constraints")
            continue

        # Copy data (same as before)
        old_columns = [info[1] for info in columns_info]
        new_columns = [col_map.get(c, c) for c in old_columns]

        placeholders = ", ".join(["?" for _ in old_columns])
        select_sql = f"SELECT {', '.join(old_columns)} FROM \"{old_table}\""
        insert_sql = f"INSERT INTO \"{new_table}\" ({', '.join(new_columns)}) VALUES ({placeholders})"

        cur_in.execute(select_sql)
        rows = cur_in.fetchall()

        if rows:
            cur_out.executemany(insert_sql, rows)
            print(f"Copied {len(rows):,} rows")
        else:
            print("Table is empty")

    conn_out.commit()
    conn_out.close()
    conn_in.close()

    print(f"\nDone! Output database: {os.path.abspath(OUTPUT_DB)}")

if __name__ == "__main__":
    main()