"""
Report generation service for sign-off reports
"""

from typing import Optional, List, Dict, Any
from sqlalchemy.orm import Session
from fastapi import HTTPException
from datetime import datetime
import json

from crud import get_signoffs_by_sprint, get_signoffs_by_deliverable
from models import Signoff, AuditLog
from schemas import Signoff as SignoffSchema, AuditLog as AuditLogSchema


def _get_sprint_report_template() -> str:
    """Get HTML template for sprint reports."""
    return """
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Sign-off Report - {{entity_type}} #{{entity_id}}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #333; }
        .summary { background: #f5f5f5; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
        .approved { background-color: #e8f5e8; }
        .rejected { background-color: #ffe6e6; }
        .pending { background-color: #fff9e6; }
        .status-badge { padding: 4px 8px; border-radius: 12px; font-size: 12px; font-weight: bold; }
        .approved-badge { background: #4caf50; color: white; }
        .rejected-badge { background: #f44336; color: white; }
        .pending-badge { background: #ff9800; color: white; }
    </style>
</head>
<body>
    <h1>Sign-off Report</h1>
    <p><strong>Generated:</strong> {{generation_date}}</p>
    <p><strong>Entity:</strong> {{entity_type}} #{{entity_id}}</p>
    
    <div class="summary">
        <h2>Summary</h2>
        <p><strong>Total Sign-offs:</strong> {{total_signoffs}}</p>
        <p><strong>Approved:</strong> {{approved_count}}</p>
        <p><strong>Rejected:</strong> {{rejected_count}}</p>
        <p><strong>Pending:</strong> {{pending_count}}</p>
        <p><strong>Completion Rate:</strong> {{completion_rate}}%</p>
    </div>
    
    <h2>Sign-off Details</h2>
    {{signoffs_table}}
    
    {{#if include_audit_logs}}
    <h2>Audit Logs</h2>
    {{audit_logs}}
    {{/if}}
</body>
</html>
"""


def _get_deliverable_report_template() -> str:
    """Get HTML template for deliverable reports."""
    return _get_sprint_report_template()  # Use same template for now


def _get_text_report_template() -> str:
    """Get plain text template for reports."""
    return """
SIGN-OFF REPORT
===============

Generated: {{generation_date}}
Entity: {{entity_type}} #{{entity_id}}

SUMMARY
-------
Total Sign-offs: {{total_signoffs}}
Approved: {{approved_count}}
Rejected: {{rejected_count}}
Pending: {{pending_count}}
Completion Rate: {{completion_rate}}%

SIGN-OFF DETAILS
----------------
{{signoffs_text}}

{{#if include_audit_logs}}
AUDIT LOGS
----------
{{audit_logs_text}}
{{/if}}
"""

def generate_signoff_report(
    db: Session,
    entity_type: str,
    entity_id: int,
    format: str = "html",
    include_audit_logs: bool = True
) -> Dict[str, Any]:
    """
    Generate a sign-off report for a specific entity (sprint or deliverable).
    
    Args:
        db: Database session
        entity_type: Type of entity ("sprint" or "deliverable")
        entity_id: ID of the entity
        format: Output format ("html", "pdf", "json", "text")
        include_audit_logs: Whether to include audit logs in the report
        
    Returns:
        Dictionary containing the report data and metadata
    """
    # Get signoffs based on entity type
    if entity_type == "sprint":
        signoffs = get_signoffs_by_sprint(db, entity_id)
    elif entity_type == "deliverable":
        signoffs = get_signoffs_by_deliverable(db, entity_id)
    else:
        raise HTTPException(status_code=400, detail="Invalid entity type. Must be 'sprint' or 'deliverable'")
    
    # Calculate statistics
    total_signoffs = len(signoffs)
    approved_count = sum(1 for s in signoffs if s.decision == "approved")
    rejected_count = sum(1 for s in signoffs if s.decision == "rejected")
    pending_count = sum(1 for s in signoffs if s.decision == "pending")
    change_requested_count = sum(1 for s in signoffs if s.decision == "change_requested")
    
    completion_rate = 0
    if total_signoffs > 0:
        completion_rate = round(((approved_count + rejected_count + change_requested_count) / total_signoffs) * 100, 2)
    
    # Prepare report data
    report_data = {
        "metadata": {
            "entity_type": entity_type,
            "entity_id": entity_id,
            "format": format,
            "generated_at": datetime.now().isoformat(),
            "include_audit_logs": include_audit_logs
        },
        "statistics": {
            "total_signoffs": total_signoffs,
            "approved_count": approved_count,
            "rejected_count": rejected_count,
            "pending_count": pending_count,
            "change_requested_count": change_requested_count,
            "completion_rate": completion_rate
        },
        "signoffs": [{
            "id": s.id,
            "signer_name": s.signer_name,
            "signer_email": s.signer_email,
            "signer_role": s.signer_role,
            "signer_company": s.signer_company,
            "decision": s.decision,
            "comments": s.comments,
            "change_request_details": s.change_request_details,
            "submitted_at": s.submitted_at.isoformat() if s.submitted_at else None,
            "reviewed_at": s.reviewed_at.isoformat() if s.reviewed_at else None,
            "responded_at": s.responded_at.isoformat() if s.responded_at else None
        } for s in signoffs]
    }
    
    # Generate content based on format
    if format == "json":
        report_data["content"] = json.dumps(report_data, indent=2)
    elif format == "text":
        report_data["content"] = _generate_text_report(report_data, include_audit_logs, entity_type)
    elif format == "html":
        report_data["content"] = _generate_html_report(report_data, include_audit_logs, entity_type)
    elif format == "pdf":
        # For PDF, we'll generate HTML first and could convert it later
        html_content = _generate_html_report(report_data, include_audit_logs, entity_type)
        report_data["content"] = html_content
        report_data["metadata"]["notes"] = "PDF format returns HTML content for conversion"
    
    return report_data


def _generate_html_report(report_data: Dict[str, Any], include_audit_logs: bool, entity_type: str) -> str:
    """Generate HTML report using appropriate template."""
    if entity_type == "sprint":
        template = _get_sprint_report_template()
    else:
        template = _get_deliverable_report_template()
    
    # Prepare template variables
    variables = {
        "entity_type": report_data["metadata"]["entity_type"],
        "entity_id": report_data["metadata"]["entity_id"],
        "generation_date": report_data["metadata"]["generated_at"],
        "total_signoffs": report_data["statistics"]["total_signoffs"],
        "approved_count": report_data["statistics"]["approved_count"],
        "rejected_count": report_data["statistics"]["rejected_count"],
        "pending_count": report_data["statistics"]["pending_count"],
        "completion_rate": report_data["statistics"]["completion_rate"],
        "include_audit_logs": include_audit_logs,
        "signoffs_table": _generate_signoffs_html_table(report_data["signoffs"]),
        "audit_logs": _generate_audit_logs_html(report_data.get("audit_logs", [])) if include_audit_logs else ""
    }
    
    # Simple template rendering (replace placeholders)
    html_content = template
    for key, value in variables.items():
        placeholder = "{{" + key + "}}"
        html_content = html_content.replace(placeholder, str(value))
    
    # Handle conditional blocks
    if not include_audit_logs:
        html_content = html_content.replace("{{#if include_audit_logs}}", "")
        html_content = html_content.replace("{{/if}}", "")
    else:
        html_content = html_content.replace("{{#if include_audit_logs}}", "")
        html_content = html_content.replace("{{/if}}", "")
    
    return html_content


def _generate_text_report(report_data: Dict[str, Any], include_audit_logs: bool, entity_type: str) -> str:
    """Generate plain text report."""
    template = _get_text_report_template()
    
    # Prepare template variables
    variables = {
        "entity_type": report_data["metadata"]["entity_type"],
        "entity_id": report_data["metadata"]["entity_id"],
        "generation_date": report_data["metadata"]["generated_at"],
        "total_signoffs": report_data["statistics"]["total_signoffs"],
        "approved_count": report_data["statistics"]["approved_count"],
        "rejected_count": report_data["statistics"]["rejected_count"],
        "pending_count": report_data["statistics"]["pending_count"],
        "completion_rate": report_data["statistics"]["completion_rate"],
        "include_audit_logs": include_audit_logs,
        "signoffs_text": _generate_signoffs_text(report_data["signoffs"]),
        "audit_logs_text": _generate_audit_logs_text(report_data.get("audit_logs", [])) if include_audit_logs else ""
    }
    
    # Simple template rendering
    text_content = template
    for key, value in variables.items():
        placeholder = "{{" + key + "}}"
        text_content = text_content.replace(placeholder, str(value))
    
    # Handle conditional blocks
    if not include_audit_logs:
        text_content = text_content.replace("{{#if include_audit_logs}}", "")
        text_content = text_content.replace("{{/if}}", "")
    else:
        text_content = text_content.replace("{{#if include_audit_logs}}", "")
        text_content = text_content.replace("{{/if}}", "")
    
    return text_content


def _generate_signoffs_html_table(signoffs: List[Dict[str, Any]]) -> str:
    """Generate HTML table for signoffs."""
    if not signoffs:
        return "<p>No sign-offs found.</p>"
    
    table_html = """
    <table>
        <thead>
            <tr>
                <th>ID</th>
                <th>Signer</th>
                <th>Role</th>
                <th>Company</th>
                <th>Status</th>
                <th>Comments</th>
                <th>Submitted At</th>
            </tr>
        </thead>
        <tbody>
    """
    
    for signoff in signoffs:
        status_class = ""
        status_badge = ""
        if signoff["decision"] == "approved":
            status_class = "approved"
            status_badge = "<span class='status-badge approved-badge'>Approved</span>"
        elif signoff["decision"] == "rejected":
            status_class = "rejected"
            status_badge = "<span class='status-badge rejected-badge'>Rejected</span>"
        elif signoff["decision"] == "change_requested":
            status_class = "pending"
            status_badge = "<span class='status-badge pending-badge'>Change Requested</span>"
        else:
            status_class = "pending"
            status_badge = "<span class='status-badge pending-badge'>Pending</span>"
        
        table_html += f"""
            <tr class="{status_class}">
                <td>{signoff['id']}</td>
                <td>{signoff['signer_name'] or 'N/A'}</td>
                <td>{signoff.get('signer_role', 'N/A')}</td>
                <td>{signoff.get('signer_company', 'N/A')}</td>
                <td>{status_badge}</td>
                <td>{signoff['comments'] or 'No comments'}</td>
                <td>{signoff['submitted_at'] or 'N/A'}</td>
            </tr>
        """
    
    table_html += """
        </tbody>
    </table>
    """
    
    return table_html


def _generate_signoffs_text(signoffs: List[Dict[str, Any]]) -> str:
    """Generate text representation of signoffs."""
    if not signoffs:
        return "No sign-offs found.\n"
    
    text = ""
    for i, signoff in enumerate(signoffs, 1):
        text += f"{i}. ID: {signoff['id']}\n"
        text += f"   Signer: {signoff['signer_name'] or 'N/A'}\n"
        text += f"   Role: {signoff.get('signer_role', 'N/A')}\n"
        text += f"   Company: {signoff.get('signer_company', 'N/A')}\n"
        text += f"   Status: {signoff['decision'].upper()}\n"
        text += f"   Comments: {signoff['comments'] or 'No comments'}\n"
        text += f"   Submitted: {signoff['submitted_at'] or 'N/A'}\n\n"
    
    return text


def _generate_audit_logs_html(audit_logs: List[Dict[str, Any]]) -> str:
    """Generate HTML for audit logs."""
    if not audit_logs:
        return "<p>No audit logs available.</p>"
    
    logs_html = """
    <div class="audit-logs">
        <table>
            <thead>
                <tr>
                    <th>Timestamp</th>
                    <th>Action</th>
                    <th>User</th>
                    <th>Details</th>
                </tr>
            </thead>
            <tbody>
    """
    
    for log in audit_logs:
        logs_html += f"""
                <tr>
                    <td>{log.get('timestamp', 'N/A')}</td>
                    <td>{log.get('action', 'N/A')}</td>
                    <td>{log.get('user', 'N/A')}</td>
                    <td>{log.get('details', 'No details')}</td>
                </tr>
        """
    
    logs_html += """
            </tbody>
        </table>
    </div>
    """
    
    return logs_html


def _generate_audit_logs_text(audit_logs: List[Dict[str, Any]]) -> str:
    """Generate text representation of audit logs."""
    if not audit_logs:
        return "No audit logs available.\n"
    
    text = ""
    for i, log in enumerate(audit_logs, 1):
        text += f"{i}. {log.get('timestamp', 'N/A')} - {log.get('action', 'N/A')}\n"
        text += f"   User: {log.get('user', 'N/A')}\n"
        text += f"   Details: {log.get('details', 'No details')}\n\n"
    
    return text





def _generate_pdf_report(report_data: Dict[str, Any]) -> str:
    """Generate PDF report (placeholder - would require PDF generation library)"""
    # This would require libraries like reportlab or weasyprint
    # For now, return HTML content that can be converted to PDF
    return _generate_html_report(report_data)