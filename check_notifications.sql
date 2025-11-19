-- Check Recent Notifications
-- Run this to verify notifications were created

-- 1. Show all recent notifications
SELECT 
  n.id,
  n.title,
  n.type,
  n.message,
  n.is_read,
  n.created_at,
  u.email as recipient_email,
  u.name as recipient_name,
  u.role as recipient_role
FROM notifications n
LEFT JOIN users u ON n.user_id = u.id
WHERE n.created_at > NOW() - INTERVAL '1 day'
ORDER BY n.created_at DESC;

-- 2. Count notifications by type
SELECT 
  type,
  COUNT(*) as count,
  COUNT(CASE WHEN is_read = false THEN 1 END) as unread_count
FROM notifications
WHERE created_at > NOW() - INTERVAL '1 day'
GROUP BY type
ORDER BY count DESC;

-- 3. Show unread notifications for specific user
-- Replace 'USER_EMAIL_HERE' with actual email
SELECT 
  n.title,
  n.type,
  n.message,
  n.created_at
FROM notifications n
JOIN users u ON n.user_id = u.id
WHERE u.email = 'kasikash34@gmail.com'
  AND n.is_read = false
ORDER BY n.created_at DESC;

-- 4. Show notification flow for a specific report
-- Replace 'REPORT_ID_HERE' with actual report ID
SELECT 
  n.title,
  n.type,
  n.message,
  n.created_at,
  u.email as recipient
FROM notifications n
LEFT JOIN users u ON n.user_id = u.id
WHERE n.message LIKE '%48acb6d5-7535-4d9e-bdf7-ec5ecfac171c%'
   OR n.message LIKE '%New Developments%'
ORDER BY n.created_at DESC;

