-- ============================================================================
-- Ballas Gang - Job Registration
-- Framework: ESX Legacy
--
-- ESX stores jobs in the database, NOT in a shared Lua file. Run the SQL below
-- once against your ESX database (the same DB oxmysql / es_extended connects
-- to). It registers:
--   * the `jobs` row
--   * the four `job_grades` rows (grade 3 = boss, so esx_society works)
--   * the `addon_account` + `addon_account_data` rows for society money
--
-- IMPORTANT: grade 3's `name` column is 'boss'. esx_society authorizes the
-- boss menu by matching grade_name against Config.BossGrades = { ['boss'] = true }.
-- The label shown to players is 'O.G.'.
-- ============================================================================

--[[
-- 1. Register the job.
INSERT INTO `jobs` (`name`, `label`) VALUES
  ('ballas', 'Ballas');

-- 2. Register the four ranks/grades.
--    ESX job_grades columns: job_name, grade, name, label, salary,
--    skin_male, skin_female.
INSERT INTO `job_grades`
  (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
  ('ballas', 0, 'thug',       'Thug',        50,  '{}', '{}'),
  ('ballas', 1, 'hustler',    'Hustler',     75,  '{}', '{}'),
  ('ballas', 2, 'shotcaller', 'Shot Caller', 100, '{}', '{}'),
  ('ballas', 3, 'boss',       'O.G.',        150, '{}', '{}');

-- 3. Society bank account (esx_addonaccount / esx_society).
--    esx_society expects the account name to be 'society_<job>'.
INSERT INTO `addon_account` (`name`, `label`, `shared`) VALUES
  ('society_ballas', 'Ballas', 1);

INSERT INTO `addon_account_data` (`account_name`, `money`) VALUES
  ('society_ballas', 0);
]]

-- ============================================================================
-- In-game commands (run as an admin)
-- ============================================================================
-- Give a player the gang job at a specific rank:
--   /setjob <id> ballas <grade>
-- Examples:
--   /setjob 12 ballas 0   -> Thug
--   /setjob 12 ballas 3   -> O.G. (boss, can open the boss menu)
--
-- After running the SQL, restart the resource:
--   restart ballas
