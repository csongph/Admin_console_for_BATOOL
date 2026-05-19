"""
migrate_mappings.py
───────────────────
แปลงข้อมูลจาก SQL backup แล้ว insert เข้า mapping_rules ใน Render DB

วิธีใช้:
  pip install asyncpg sqlalchemy
  python migrate_mappings.py
"""

import asyncio
import asyncpg

# ── Render DB connection ──────────────────────────────────────────────────────
RENDER_DSN = (
    "postgresql://postgres:YOUR_PASSWORD@localhost:5432/sql_converter-multiple_database"
)

# ── Mapping ข้อมูลจาก SQL backup ─────────────────────────────────────────────

DB_TYPE = {
    1: "sqlserver",
    2: "postgresql",
    3: "mysql",
    4: "oracle",
}

DATATYPE_STANDARD = {
    1:  "INTEGER",        2:  "BIGINT",         3:  "DECIMAL",
    4:  "FLOAT",          5:  "DOUBLE PRECISION",6:  "BOOLEAN",
    7:  "CHAR",           8:  "VARCHAR",         9:  "TEXT",
    10: "DATE",           11: "TIME",            12: "TIMESTAMP",
    13: "BINARY",         14: "UUID",            15: "JSON",
    16: "XML",            17: "TINYINT",         18: "SMALLINT",
    19: "NVARCHAR",       20: "NCHAR",           21: "NTEXT",
    22: "DATETIME",       23: "DATETIME2",       24: "SMALLDATETIME",
    25: "DATETIMEOFFSET", 26: "GEOMETRY",        27: "INTERVAL",
    28: "NETWORK",        29: "ENUM",
}

# datatype_raw_mapping: (db_id, raw_type, logical_type, source_type, standard_id)
RAW_MAPPINGS = [
    (2,"int","int","smallint",18),(2,"long","timestamp-millis","timestamptz",25),
    (2,"string","json","jsonb",15),(3,"string","json","json",15),
    (4,"string","xml","xmltype",16),(2,"string","xml","xml",16),
    (1,"long","long","bigint",2),(1,"bytes","decimal","decimal",3),
    (1,"float","float","real",4),(1,"double","double","float",5),
    (1,"boolean","boolean","bit",6),(1,"string","uuid","uniqueidentifier",14),
    (1,"long","timestamp-millis","datetime",22),(2,"long","long","bigint",2),
    (2,"int","int","integer",1),(3,"int","int","int",1),(4,"int","int","number(10)",1),
    (3,"long","timestamp-millis","timestamp",12),(3,"bytes","decimal","decimal",3),
    (3,"float","float","float",4),(3,"double","double","double",5),
    (3,"boolean","boolean","tinyint(1)",6),(1,"string","datetime-offset","datetimeoffset",25),
    (1,"int","date","date",10),(4,"string","interval","interval day to second",27),
    (4,"string","interval","interval year to month",27),
    (2,"int","date","date",10),(3,"int","date","date",10),(3,"int","date","year",10),
    (1,"int","time","time",11),(1,"string","json","json",15),
    (2,"long","time","time",11),(3,"int","time","time",11),
    (1,"string","xml","xml",16),(4,"long","long","number(19)",2),
    (4,"bytes","decimal","number",3),(4,"float","float","binary_float",4),
    (4,"double","double","binary_double",5),(4,"boolean","boolean","number(1)",6),
    (1,"string","string","char",7),(1,"string","string","text",9),
    (1,"int","int","tinyint",17),(1,"int","int","smallint",18),
    (1,"string","string","nvarchar",19),(1,"string","string","nchar",20),
    (1,"string","string","ntext",21),(1,"long","timestamp-micros","datetime2",23),
    (1,"long","timestamp-millis","smalldatetime",24),
    (1,"string","datetime-offset","datetimeoffset",25),
    (1,"bytes","decimal","money",3),(1,"bytes","decimal","smallmoney",3),
    (2,"string","string","char",7),(2,"string","string","text",9),
    (3,"string","string","char",7),(3,"string","string","text",9),
    (4,"string","string","char",7),(4,"string","string","clob",9),
    (4,"long","timestamp-millis","date",22),
    (1,"string","spatial","geometry",26),(1,"string","spatial","geography",26),
    (2,"string","interval","interval",27),(2,"string","network","inet",28),
    (2,"string","network","cidr",28),(2,"string","network","macaddr",28),
    (2,"string","spatial","geometry",26),(3,"string","enum","enum",29),
    (3,"string","enum","set",29),(4,"string","string","long",9),
    (1,"string","string","varchar",8),(2,"string","string","varchar",8),
    (3,"string","string","varchar",8),(4,"string","string","varchar2",8),
    (1,"string","string","hierarchyid",8),
    (1,"int","int","int",1),(2,"int","int","integer",1),
    (3,"int","int","int",1),(4,"int","int","number(10)",1),
    (3,"int","int","mediumint",1),
    (2,"long","timestamp-micros","timestamp",12),
    (3,"long","timestamp-millis","timestamp",12),
    (4,"long","timestamp-micros","timestamp",12),
    (2,"string","enum","enum",29),(3,"long","timestamp-micros","datetime(6)",12),
    (3,"int","int","tinyint",17),(3,"int","int","smallint",18),
    (3,"string","string","nvarchar",19),(3,"string","uuid","char(36)",14),
    (4,"bytes","bytes","bfile",13),(1,"bytes","bytes","binary",13),
    (4,"string","json","json",15),(4,"string","spatial","sdo_geometry",26),
    (4,"string","uuid","raw(16)",14),(4,"int","int","smallint",18),
    (1,"bytes","bytes","timestamp",12),(1,"bytes","bytes","varbinary",13),
    (2,"bytes","bytes","bytea",13),(3,"bytes","bytes","binary",13),
    (3,"bytes","bytes","blob",13),(4,"bytes","bytes","blob",13),
    (4,"bytes","bytes","raw",13),(3,"long","timestamp-millis","datetime",22),
    (3,"string","datetime-offset","varchar(35)",25),
    (3,"string","spatial","geometry",26),(4,"bytes","bytes","long raw",13),
    (4,"int","date","date",10),(4,"bytes","bytes","bfile",13),
    (4,"int","int","number(3)",17),(4,"string","string","nvarchar2",19),
    (4,"string","string","nchar",20),(4,"string","string","nclob",21),
    (4,"string","datetime-offset","timestamp with time zone",25),
]

# datatype_mapping: (db_id, standard_id, final_type)
FINAL_MAPPINGS = {
    (1,1):"int",(1,2):"bigint",(1,3):"decimal",(1,4):"real",(1,5):"float",
    (1,6):"bit",(1,7):"char",(1,8):"varchar",(1,9):"text",(1,10):"date",
    (1,11):"time",(1,12):"datetime2",(1,13):"varbinary",(1,14):"uniqueidentifier",
    (1,15):"nvarchar(max)",(1,16):"xml",(1,17):"tinyint",(1,18):"smallint",
    (1,19):"nvarchar",(1,20):"nchar",(1,21):"ntext",(1,22):"datetime",
    (1,23):"datetime2",(1,24):"smalldatetime",(1,25):"datetimeoffset",
    (1,26):"geometry",(1,27):"varchar",(1,28):"varchar",(1,29):"varchar",
    (2,1):"integer",(2,2):"bigint",(2,3):"numeric",(2,4):"real",
    (2,5):"double precision",(2,6):"boolean",(2,7):"char",(2,8):"varchar",
    (2,9):"text",(2,10):"date",(2,11):"time",(2,12):"timestamp",
    (2,13):"bytea",(2,14):"uuid",(2,15):"jsonb",(2,16):"xml",
    (2,17):"smallint",(2,18):"smallint",(2,19):"varchar",(2,20):"char",
    (2,21):"text",(2,22):"timestamp",(2,23):"timestamp",(2,24):"timestamp",
    (2,25):"timestamptz",(2,26):"geometry",(2,27):"interval",(2,28):"inet",
    (2,29):"varchar",
    (3,1):"int",(3,2):"bigint",(3,3):"decimal",(3,4):"float",(3,5):"double",
    (3,6):"tinyint(1)",(3,7):"char",(3,8):"varchar",(3,9):"text",(3,10):"date",
    (3,11):"time",(3,12):"timestamp",(3,13):"blob",(3,14):"char(36)",
    (3,15):"json",(3,16):"text",(3,17):"tinyint",(3,18):"smallint",
    (3,19):"varchar",(3,20):"char",(3,21):"text",(3,22):"datetime",
    (3,23):"datetime",(3,24):"datetime",(3,25):"datetime",(3,26):"geometry",
    (3,27):"varchar",(3,28):"varchar",(3,29):"enum",
    (4,1):"number(10)",(4,2):"number(19)",(4,3):"number",(4,4):"binary_float",
    (4,5):"binary_double",(4,6):"number(1)",(4,7):"char",(4,8):"varchar2",
    (4,9):"clob",(4,10):"date",(4,11):"timestamp",(4,12):"timestamp",
    (4,13):"blob",(4,14):"varchar2(36)",(4,15):"clob",(4,16):"xmltype",
    (4,17):"number(3)",(4,18):"number(5)",(4,19):"nvarchar2",(4,20):"nchar",
    (4,21):"nclob",(4,22):"timestamp",(4,23):"timestamp",(4,24):"date",
    (4,25):"timestamp with time zone",(4,26):"sdo_geometry",
    (4,27):"interval day to second",(4,28):"varchar2",(4,29):"varchar2",
}


def build_mapping_rules():
    """Join raw_mappings + final_mappings → mapping_rules rows"""
    rows = []
    seen = set()
    for (db_id, raw_type, logical_type, source_type, standard_id) in RAW_MAPPINGS:
        src_db      = DB_TYPE.get(db_id, "unknown")
        master_type = DATATYPE_STANDARD.get(standard_id, "")

        for dest_db_id, dest_db_name in DB_TYPE.items():
            if dest_db_id == db_id:
                continue
            final_type = FINAL_MAPPINGS.get((dest_db_id, standard_id), "")
            if not final_type:
                continue

            key = (src_db, raw_type, source_type, dest_db_name)
            if key in seen:
                continue
            seen.add(key)

            rows.append({
                "src_db":       src_db,
                "raw_type":     raw_type,
                "source_type":  source_type,
                "logical_type": logical_type,
                "master_type":  master_type,
                "dest_db":      dest_db_name,
                "final_type":   final_type,
                "confidence":   100,
                "status":       "active",
                "updated":      "2026-05-19",
            })
    return rows


async def main():
    print("🔌 Connecting to Render DB...")
    conn = await asyncpg.connect(RENDER_DSN, ssl="require")

    # ลบข้อมูลเก่าแล้ว insert ใหม่พร้อม source_type
    print("🗑  Clearing old mapping_rules...")
    await conn.execute("DELETE FROM mapping_rules")

    # เพิ่ม column source_type ถ้ายังไม่มี
    await conn.execute("""
        ALTER TABLE mapping_rules
        ADD COLUMN IF NOT EXISTS source_type VARCHAR(128) DEFAULT ''
    """)

    rows = build_mapping_rules()
    print(f"📦 Built {len(rows)} mapping rules — inserting...")

    inserted = 0
    skipped  = 0
    for r in rows:
        try:
            await conn.execute("""
                INSERT INTO mapping_rules
                    (src_db, raw_type, source_type, logical_type, master_type,
                     dest_db, final_type, confidence, status, updated)
                VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
                ON CONFLICT DO NOTHING
            """,
                r["src_db"], r["raw_type"], r["source_type"], r["logical_type"],
                r["master_type"], r["dest_db"], r["final_type"],
                r["confidence"], r["status"], r["updated"],
            )
            inserted += 1
        except Exception as e:
            print(f"  ⚠ skip: {e}")
            skipped += 1

    await conn.close()
    print(f"✅ Done! inserted={inserted}, skipped={skipped}")


if __name__ == "__main__":
    asyncio.run(main())