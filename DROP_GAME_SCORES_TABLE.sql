-- ==========================================
-- DROP GAME_SCORES TABLE
-- ==========================================
-- Run this SQL command in your MySQL database to remove the unused game_scores table

-- Drop the table (will also remove all data)
DROP TABLE IF EXISTS `game_scores`;

-- Verify the table is gone (should return empty result)
SHOW TABLES LIKE 'game_scores';

-- ==========================================
-- NOTES
-- ==========================================
-- This will permanently delete:
-- - The game_scores table structure
-- - All score records stored in the table
-- 
-- This is safe because:
-- - Flutter app no longer writes to this table
-- - Backend endpoints have been removed
-- - No other features depend on this table
-- 
-- After running this command:
-- 1. Restart your Express.js server
-- 2. Test the gyro game in Flutter app
-- 3. Verify no errors appear in console
