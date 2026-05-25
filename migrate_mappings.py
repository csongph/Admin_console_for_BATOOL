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
from datetime import date

# ── Render DB connection ──────────────────────────────────────────────────────
RENDER_DSN = (
    "postgresql://postgres:131047@localhost:5432/sql_converter-multiple_database"
)
IS_LOCAL = "localhost" in RENDER_DSN  # ตรวจอัตโนมัติ — เปลี่ยน DSN เป็น Render URL ตอน deploy

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

# datatype_raw_mapping: (db_id, source_type, raw_type, logical_type, standard_id)
RAW_MAPPINGS = [
    (2,"smallint","int","int",18),(2,"timestamptz","long","timestamp-millis",25),
    (2,"jsonb","string","json",15),(3,"json","string","json",15),
    (4,"xmltype","string","xml",16),(2,"xml","string","xml",16),
    (1,"bigint","long","long",2),(1,"decimal","bytes","decimal",3),
    (1,"real","float","float",4),(1,"float","double","double",5),
    (1,"bit","boolean","boolean",6),(1,"uniqueidentifier","string","uuid",14),
    (1,"datetime","long","timestamp-millis",22),(2,"bigint","long","long",2),
    (2,"integer","int","int",1),(3,"int","int","int",1),(4,"number(10)","int","int",1),
    (3,"timestamp","long","timestamp-millis",12),(3,"decimal","bytes","decimal",3),
    (3,"float","float","float",4),(3,"double","double","double",5),
    (3,"tinyint(1)","boolean","boolean",6),(1,"datetimeoffset","string","datetime-offset",25),
    (1,"date","int","date",10),(4,"interval day to second","string","interval",27),
    (4,"interval year to month","string","interval",27),
    (2,"date","int","date",10),(3,"date","int","date",10),(3,"year","int","date",10),
    (1,"time","int","time",11),(1,"json","string","json",15),
    (2,"time","long","time",11),(3,"time","int","time",11),
    (1,"xml","string","xml",16),(4,"number(19)","long","long",2),
    (4,"number","bytes","decimal",3),(4,"binary_float","float","float",4),
    (4,"binary_double","double","double",5),(4,"number(1)","boolean","boolean",6),
    (1,"char","string","string",7),(1,"text","string","string",9),
    (1,"tinyint","int","int",17),(1,"smallint","int","int",18),
    (1,"nvarchar","string","string",19),(1,"nchar","string","string",20),
    (1,"ntext","string","string",21),(1,"datetime2","long","timestamp-micros",23),
    (1,"smalldatetime","long","timestamp-millis",24),
    (1,"datetimeoffset","string","datetime-offset",25),
    (1,"money","bytes","decimal",3),(1,"smallmoney","bytes","decimal",3),
    (2,"char","string","string",7),(2,"text","string","string",9),
    (3,"char","string","string",7),(3,"text","string","string",9),
    (4,"char","string","string",7),(4,"clob","string","string",9),
    (4,"date","long","timestamp-millis",22),
    (1,"geometry","string","spatial",26),(1,"geography","string","spatial",26),
    (2,"interval","string","interval",27),(2,"inet","string","network",28),
    (2,"cidr","string","network",28),(2,"macaddr","string","network",28),
    (2,"geometry","string","spatial",26),(3,"enum","string","enum",29),
    (3,"set","string","enum",29),(4,"long","string","string",9),
    (1,"varchar","string","string",8),(2,"varchar","string","string",8),
    (3,"varchar","string","string",8),(4,"varchar2","string","string",8),
    (1,"hierarchyid","string","string",8),
    (1,"int","int","int",1),(2,"integer","int","int",1),
    (3,"int","int","int",1),(4,"number(10)","int","int",1),
    (3,"mediumint","int","int",1),
    (2,"timestamp","long","timestamp-micros",12),
    (3,"timestamp","long","timestamp-millis",12),
    (4,"timestamp","long","timestamp-micros",12),
    (2,"enum","string","enum",29),(3,"datetime(6)","long","timestamp-micros",12),
    (3,"tinyint","int","int",17),(3,"smallint","int","int",18),
    (3,"nvarchar","string","string",19),(3,"char(36)","string","uuid",14),
    (4,"bfile","bytes","bytes",13),(1,"binary","bytes","bytes",13),
    (4,"json","string","json",15),(4,"sdo_geometry","string","spatial",26),
    (4,"raw(16)","string","uuid",14),(4,"smallint","int","int",18),
    (1,"timestamp","bytes","bytes",12),(1,"varbinary","bytes","bytes",13),
    (2,"bytea","bytes","bytes",13),(3,"binary","bytes","bytes",13),
    (3,"blob","bytes","bytes",13),(4,"blob","bytes","bytes",13),
    (4,"raw","bytes","bytes",13),(3,"datetime","long","timestamp-millis",22),
    (3,"varchar(35)","string","datetime-offset",25),
    (3,"geometry","string","spatial",26),(4,"long raw","bytes","bytes",13),
    (4,"date","int","date",10),(4,"bfile","bytes","bytes",13),
    (4,"number(3)","int","int",17),(4,"nvarchar2","string","string",19),
    (4,"nchar","string","string",20),(4,"nclob","string","string",21),
    (4,"timestamp with time zone","string","datetime-offset",25),
]

# datatype_mapping: (db_id, standard_id, final_type)
FINAL_MAPPINGS = {
    (1,1):"int",
    (1,2):"bigint",
    (1,3):"decimal",
    (1,4):"real",
    (1,5):"float",
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
    for (db_id, source_type, raw_type, logical_type, standard_id) in RAW_MAPPINGS:
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
                "source_type":  source_type,
                "raw_type":     raw_type,
                "logical_type": logical_type,
                "standard_type":   master_type,
                "dest_db":      dest_db_name,
                "final_type":   final_type,
                "confidence":   100,
                "status":       "active",
                "updated":      date(2026, 5, 19),
            })
    return rows


async def main():
    print("🔌 Connecting to Render DB...")
    ssl_mode = None if IS_LOCAL else "require"
    conn = await asyncpg.connect(RENDER_DSN, ssl=ssl_mode)

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
                    (src_db, source_type, raw_type, logical_type, master_type,
                     dest_db, final_type, confidence, status, updated)
                VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
                ON CONFLICT DO NOTHING
            """,
                r["src_db"], r["source_type"], r["raw_type"], r["logical_type"], r["standard_type"],
                r["dest_db"], r["final_type"], r["confidence"], r["status"], r["updated"],
            )
            inserted += 1
        except Exception as e:
            print(f"  ⚠ skip: {e}")
            skipped += 1

    await conn.close()
    print(f"✅ Done! inserted={inserted}, skipped={skipped}")


if __name__ == "__main__":
    asyncio.run(main())