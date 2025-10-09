from sqlalchemy import create_engine, inspect

engine = create_engine('sqlite:///./hackathon.db')
inspector = inspect(engine)

tables = inspector.get_table_names()
print('Tables in database:', tables)

if 'audit_logs' in tables:
    columns = inspector.get_columns('audit_logs')
    print('\nAudit logs columns:')
    for col in columns:
        print(f"{col['name']}: nullable={col['nullable']}")
else:
    print('\naudit_logs table does not exist yet')