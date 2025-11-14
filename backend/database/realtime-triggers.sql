-- Flow-Space Real-time Database Triggers
-- PostgreSQL LISTEN/NOTIFY implementation for real-time synchronization

-- Create notification function for real-time updates
CREATE OR REPLACE FUNCTION notify_table_change()
RETURNS TRIGGER AS $$
DECLARE
    payload JSON;
    operation TEXT;
    table_name TEXT;
    record_id TEXT;
    user_id TEXT;
    user_role TEXT;
BEGIN
    -- Determine operation type
    IF TG_OP = 'INSERT' THEN
        operation := 'created';
        payload := row_to_json(NEW);
        record_id := NEW.id::TEXT;
    ELSIF TG_OP = 'UPDATE' THEN
        operation := 'updated';
        payload := json_build_object(
            'old', row_to_json(OLD),
            'new', row_to_json(NEW)
        );
        record_id := NEW.id::TEXT;
    ELSIF TG_OP = 'DELETE' THEN
        operation := 'deleted';
        payload := row_to_json(OLD);
        record_id := OLD.id::TEXT;
    END IF;

    table_name := TG_TABLE_NAME;

    -- Try to extract user_id and role from the record if available
    BEGIN
        IF TG_OP != 'DELETE' THEN
            user_id := COALESCE(NEW.created_by::TEXT, NEW.assigned_to::TEXT, NEW.user_id::TEXT, NULL);
            user_role := COALESCE(
                (SELECT role FROM users WHERE id::TEXT = user_id LIMIT 1),
                NULL
            );
        ELSE
            user_id := COALESCE(OLD.created_by::TEXT, OLD.assigned_to::TEXT, OLD.user_id::TEXT, NULL);
            user_role := COALESCE(
                (SELECT role FROM users WHERE id::TEXT = user_id LIMIT 1),
                NULL
            );
        END IF;
    EXCEPTION WHEN OTHERS THEN
        user_id := NULL;
        user_role := NULL;
    END;

    -- Construct the notification payload
    PERFORM pg_notify(
        'table_changes',
        json_build_object(
            'table', table_name,
            'operation', operation,
            'id', record_id,
            'user_id', user_id,
            'user_role', user_role,
            'timestamp', CURRENT_TIMESTAMP,
            'data', payload
        )::TEXT
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for users table
CREATE OR REPLACE TRIGGER users_realtime_notify
    AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW
    EXECUTE FUNCTION notify_table_change();

-- Create trigger for projects table
CREATE OR REPLACE TRIGGER projects_realtime_notify
    AFTER INSERT OR UPDATE OR DELETE ON projects
    FOR EACH ROW
    EXECUTE FUNCTION notify_table_change();

-- Create trigger for deliverables table
CREATE OR REPLACE TRIGGER deliverables_realtime_notify
    AFTER INSERT OR UPDATE OR DELETE ON deliverables
    FOR EACH ROW
    EXECUTE FUNCTION notify_table_change();

-- Create trigger for sprints table
CREATE OR REPLACE TRIGGER sprints_realtime_notify
    AFTER INSERT OR UPDATE OR DELETE ON sprints
    FOR EACH ROW
    EXECUTE FUNCTION notify_table_change();

-- Create trigger for notifications table
CREATE OR REPLACE TRIGGER notifications_realtime_notify
    AFTER INSERT OR UPDATE OR DELETE ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION notify_table_change();

-- Create trigger for project_members table
CREATE OR REPLACE TRIGGER project_members_realtime_notify
    AFTER INSERT OR UPDATE OR DELETE ON project_members
    FOR EACH ROW
    EXECUTE FUNCTION notify_table_change();

-- Create trigger for sign_off_reports table
CREATE OR REPLACE TRIGGER sign_off_reports_realtime_notify
    AFTER INSERT OR UPDATE OR DELETE ON sign_off_reports
    FOR EACH ROW
    EXECUTE FUNCTION notify_table_change();

-- Create trigger for audit_logs table
CREATE OR REPLACE TRIGGER audit_logs_realtime_notify
    AFTER INSERT OR UPDATE OR DELETE ON audit_logs
    FOR EACH ROW
    EXECUTE FUNCTION notify_table_change();

-- Create function for role-specific notifications
CREATE OR REPLACE FUNCTION notify_role_change()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM pg_notify(
        'role_changes',
        json_build_object(
            'user_id', NEW.id::TEXT,
            'old_role', OLD.role,
            'new_role', NEW.role,
            'timestamp', CURRENT_TIMESTAMP
        )::TEXT
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for role changes on users table
CREATE OR REPLACE TRIGGER users_role_change_notify
    AFTER UPDATE OF role ON users
    FOR EACH ROW
    WHEN (OLD.role IS DISTINCT FROM NEW.role)
    EXECUTE FUNCTION notify_role_change();

-- Create function for user presence notifications
CREATE OR REPLACE FUNCTION notify_user_presence()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM pg_notify(
        'user_presence',
        json_build_object(
            'user_id', NEW.id::TEXT,
            'last_login', NEW.last_login_at,
            'is_active', NEW.is_active,
            'timestamp', CURRENT_TIMESTAMP
        )::TEXT
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for user presence changes
CREATE OR REPLACE TRIGGER users_presence_notify
    AFTER UPDATE OF last_login_at, is_active ON users
    FOR EACH ROW
    EXECUTE FUNCTION notify_user_presence();