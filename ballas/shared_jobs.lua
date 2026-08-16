-- ============================================================================
-- Ballas Gang - Job Registration
-- Framework: QBCore
-- QBCore stores jobs in qb-core/shared/jobs.lua. Add the block below to that
-- file (or to a resource that exports jobs to the core). Each grade must also
-- exist in the `jobs` / `job_grades` tables in the database so /setjob and
-- qb-bossmenu society functions work. The SQL below registers everything.
-- ============================================================================

-- Place this table inside qb-core/shared/jobs.lua (the `QBCore.Shared.Jobs`
-- table). It mirrors the SQL job_grades rows so the client and server agree.
QBCore.Shared.Jobs = QBCore.Shared.Jobs or {}
QBCore.Shared.Jobs['ballas'] = {
    label = 'Ballas',
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        ['0'] = { name = 'thug',       payment = 50,  label = 'Thug' },
        ['1'] = { name = 'hustler',    payment = 75,  label = 'Hustler' },
        ['2'] = { name = 'shotcaller', payment = 100, label = 'Shot Caller' },
        ['3'] = { name = 'og',         payment = 150, isboss = true, label = 'O.G.' },
    },
}

-- ============================================================================
-- SQL (MySQL / MariaDB) - run once to register the job + grades.
-- This is the authoritative source; the shared.lua block above must match it.
-- ============================================================================

--[[
INSERT INTO `jobs` (`name`, `label`, `whitelisted`) VALUES
  ('ballas', 'Ballas', 0);

INSERT INTO `job_grades`
  (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`, `isboss`) VALUES
  ('ballas', 0, 'thug',       'Thug',        50,  '{}', '{}', 0),
  ('ballas', 1, 'hustler',    'Hustler',     75,  '{}', '{}', 0),
  ('ballas', 2, 'shotcaller', 'Shot Caller', 100, '{}', '{}', 0),
  ('ballas', 3, 'og',         'O.G.',        150, '{}', '{}', 1);

-- Society account (qb-management) so qb-bossmenu can hold gang funds.
INSERT INTO `management_funds` (`id`, `job_name`, `amount`, `type`) VALUES
  (NULL, 'ballas', 0, 'boss');
]]

-- NOTE for QBCore users:
-- * qb-management / qb-bossmenu reads `isboss = 1` on grade 3 to gate the
--   society menu, so hire/fire/promote/demote + deposit/withdraw work out of
--   the box once the SQL above is applied.
-- * To make a player an O.G. in-game:  /setjob ballas 3
