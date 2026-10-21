-- Raw layer: one table per Leaguepedia Cargo table, columns named exactly as in Leaguepedia.
-- Primary keys only where uniqueness was verified on 2025-2026 tier 1 data; no foreign keys,
-- because raw data is loaded as-is and checked with validation queries instead.
-- List fields (picks, bans, roles) are stored as delimited text and split in the clean layer.

CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE raw.leagues (
    League        VARCHAR PRIMARY KEY,
    League_Short  VARCHAR,
    Region        VARCHAR,   -- current region only; use Tournaments.Region for history
    Level         VARCHAR,
    IsOfficial    VARCHAR    -- 'Yes' / 'No' text
);

CREATE TABLE raw.tournaments (
    OverviewPage      VARCHAR PRIMARY KEY,
    Name              VARCHAR,
    StandardName      VARCHAR,
    League            VARCHAR,
    Region            VARCHAR,
    Year              VARCHAR,   -- stored as text in Leaguepedia
    Split             VARCHAR,
    SplitNumber       INTEGER,
    DateStart         DATE,
    Date              DATE,
    TournamentLevel   VARCHAR,
    IsQualifier       BOOLEAN,
    IsPlayoffs        BOOLEAN,
    IsOfficial        BOOLEAN,
    EventType         VARCHAR,
    Organizer         VARCHAR,
    Country           VARCHAR,
    BasePage          VARCHAR,
    AlternativeNames  VARCHAR    -- list, ',' delimited
);

CREATE TABLE raw.match_schedule (
    MatchId            VARCHAR PRIMARY KEY,
    OverviewPage       VARCHAR,
    Team1              VARCHAR,   -- series Team1; NOT the same as game Team1
    Team2              VARCHAR,
    Winner             VARCHAR,   -- '1' / '2' as text
    Team1Score         INTEGER,
    Team2Score         INTEGER,
    FF                 INTEGER,
    IsNullified        BOOLEAN,
    IsTiebreaker       BOOLEAN,
    BestOf             INTEGER,
    DateTime_UTC       TIMESTAMP,
    HasTime            BOOLEAN,
    Tab                VARCHAR,   -- often the only stage label (e.g. 'Quarterfinals')
    Round              VARCHAR,
    Phase              VARCHAR,
    GroupName          VARCHAR,
    MatchDay           INTEGER,
    Patch              VARCHAR,
    DisabledChampions  VARCHAR    -- list, ',' delimited
);

CREATE TABLE raw.match_schedule_game (
    GameId              VARCHAR PRIMARY KEY,
    MatchId             VARCHAR,
    OverviewPage        VARCHAR,
    N_GameInMatch       INTEGER,
    Blue                VARCHAR,
    Red                 VARCHAR,
    Winner              INTEGER,
    IsRemake            BOOLEAN,
    IsChronobreak       BOOLEAN,
    FF                  INTEGER,
    Selection           VARCHAR,   -- team that had side selection
    PickSelection       VARCHAR,
    FirstPick           VARCHAR,
    FirstSelection      VARCHAR,
    HasSelection        BOOLEAN,
    MVP                 VARCHAR,
    RiotPlatformGameId  VARCHAR
);

CREATE TABLE raw.scoreboard_games (
    GameId              VARCHAR PRIMARY KEY,
    MatchId             VARCHAR,
    OverviewPage        VARCHAR,
    Tournament          VARCHAR,
    N_GameInMatch       INTEGER,
    DateTime_UTC        TIMESTAMP,
    Team1               VARCHAR,   -- blue side in this game
    Team2               VARCHAR,   -- red side in this game
    WinTeam             VARCHAR,
    LossTeam            VARCHAR,
    Winner              INTEGER,
    Gamelength_Number   DOUBLE,    -- minutes
    Patch               VARCHAR,
    PatchSort           VARCHAR,
    RiotPlatformGameId  VARCHAR    -- empty for LPL and some Chinese-hosted events
);

CREATE TABLE raw.scoreboard_teams (
    GameTeamId    VARCHAR PRIMARY KEY,
    GameId        VARCHAR,
    MatchId       VARCHAR,
    OverviewPage  VARCHAR,
    Team          VARCHAR,
    Side          VARCHAR,   -- 'Blue' / 'Red'
    Number        INTEGER,
    IsWinner      BOOLEAN,
    Bans          VARCHAR,   -- list, ',' delimited
    Picks         VARCHAR,   -- list, ',' delimited
    Roster        VARCHAR,   -- list, ',' delimited
    Dragons       INTEGER,
    Clouds        INTEGER,
    Infernals     INTEGER,
    Mountains     INTEGER,
    Oceans        INTEGER,
    Hextechs      INTEGER,
    Chemtechs     INTEGER,
    Elders        INTEGER,
    Barons        INTEGER,
    Towers        INTEGER,
    Gold          INTEGER,
    Kills         INTEGER,
    RiftHeralds   INTEGER,
    VoidGrubs     INTEGER,
    Atakhans      INTEGER,
    Inhibitors    INTEGER
);

CREATE TABLE raw.scoreboard_players (
    GameRoleId         VARCHAR PRIMARY KEY,
    GameId             VARCHAR,
    GameTeamId         VARCHAR,
    MatchId            VARCHAR,
    OverviewPage       VARCHAR,
    Link               VARCHAR,   -- player page = Players.OverviewPage (first letter may be lowercase)
    Name               VARCHAR,   -- display name only
    Team               VARCHAR,
    TeamVs             VARCHAR,
    Role               VARCHAR,
    Role_Number        INTEGER,
    Side               INTEGER,   -- 1 = blue, 2 = red
    Champion           VARCHAR,
    Kills              INTEGER,
    Deaths             INTEGER,
    Assists            INTEGER,
    Gold               INTEGER,
    CS                 INTEGER,
    DamageToChampions  INTEGER,
    VisionScore        INTEGER,
    TeamKills          INTEGER,
    TeamGold           INTEGER,
    PlayerWin          VARCHAR,   -- 'Yes' / 'No' text
    DateTime_UTC       TIMESTAMP
);

CREATE TABLE raw.picks_and_bans (
    GameId                 VARCHAR PRIMARY KEY,
    MatchId                VARCHAR,
    OverviewPage           VARCHAR,
    N_GameInMatch          INTEGER,
    Team1                  VARCHAR,
    Team2                  VARCHAR,
    Winner                 INTEGER,
    SwitchedSides          BOOLEAN,
    Team1Ban1 VARCHAR, Team1Ban2 VARCHAR, Team1Ban3 VARCHAR, Team1Ban4 VARCHAR, Team1Ban5 VARCHAR,
    Team2Ban1 VARCHAR, Team2Ban2 VARCHAR, Team2Ban3 VARCHAR, Team2Ban4 VARCHAR, Team2Ban5 VARCHAR,
    Team1Pick1 VARCHAR, Team1Pick2 VARCHAR, Team1Pick3 VARCHAR, Team1Pick4 VARCHAR, Team1Pick5 VARCHAR,
    Team2Pick1 VARCHAR, Team2Pick2 VARCHAR, Team2Pick3 VARCHAR, Team2Pick4 VARCHAR, Team2Pick5 VARCHAR,
    Team1Role1 VARCHAR, Team1Role2 VARCHAR, Team1Role3 VARCHAR, Team1Role4 VARCHAR, Team1Role5 VARCHAR,
    Team2Role1 VARCHAR, Team2Role2 VARCHAR, Team2Role3 VARCHAR, Team2Role4 VARCHAR, Team2Role5 VARCHAR,
    Team1PicksByRoleOrder  VARCHAR,
    Team2PicksByRoleOrder  VARCHAR,
    IsComplete             BOOLEAN
);

CREATE TABLE raw.postgame_json_metadata (
    GameId              VARCHAR PRIMARY KEY,
    RiotPlatformGameId  VARCHAR,
    StatsPage           VARCHAR,   -- e.g. 'V5 data:LOLTMNT02 375568'
    TimelinePage        VARCHAR    -- per-minute gold/xp/cs; source of *_at_15 stats
);

-- Stats at 10/15 minutes, extracted from each TimelinePage (one row per player per game).
CREATE TABLE raw.timeline_player_frames (
    GameId         VARCHAR,
    ParticipantId  INTEGER,   -- 1-5 blue, 6-10 red
    Minute         INTEGER,   -- 10 and 15
    TotalGold      INTEGER,
    XP             INTEGER,
    MinionsKilled  INTEGER,
    JungleMinions  INTEGER,
    Level          INTEGER,
    PRIMARY KEY (GameId, ParticipantId, Minute)
);

CREATE TABLE raw.teams (
    OverviewPage      VARCHAR PRIMARY KEY,
    Name              VARCHAR,
    Short             VARCHAR,
    Region            VARCHAR,
    Location          VARCHAR,
    OrganizationPage  VARCHAR,
    IsDisbanded       BOOLEAN,
    RenamedTo         VARCHAR
);

CREATE TABLE raw.team_redirects (
    AllName    VARCHAR PRIMARY KEY,  -- alias as written in other tables
    _pageName  VARCHAR               -- target team page (OtherName is empty; do not use it)
);

CREATE TABLE raw.team_renames (
    Date          TIMESTAMP,
    OriginalName  VARCHAR,
    NewName       VARCHAR,
    Verb          VARCHAR,   -- rename / rebrand / acquire ...
    Slot          VARCHAR,
    IsSamePage    VARCHAR,   -- 'Yes' / 'No': 'No' means old and new names have separate pages
    NewsId        VARCHAR
);

CREATE TABLE raw.players (
    OverviewPage        VARCHAR PRIMARY KEY,  -- unique; ID is not (two players use ID 'Cube')
    ID                  VARCHAR,
    Player              VARCHAR,
    Name                VARCHAR,
    NativeName          VARCHAR,
    Country             VARCHAR,
    NationalityPrimary  VARCHAR,
    Nationality         VARCHAR,   -- list, ',' delimited
    Birthdate           DATE,
    Residency           VARCHAR,   -- current value only
    ResidencyFormer     VARCHAR,
    Role                VARCHAR,   -- current role only
    IsRetired           BOOLEAN,
    IsSubstitute        BOOLEAN,
    IsTrainee           BOOLEAN,
    IsPersonality       BOOLEAN    -- casters/hosts; exclude from player tables
);

CREATE TABLE raw.player_redirects (
    AllName       VARCHAR PRIMARY KEY,
    OverviewPage  VARCHAR,
    ID            VARCHAR
);

CREATE TABLE raw.player_renames (
    Date          TIMESTAMP,
    OriginalName  VARCHAR,
    NewName       VARCHAR,
    IsRestyle     BOOLEAN,
    NewsId        VARCHAR
);

CREATE TABLE raw.tenures (
    Player               VARCHAR,
    Team                 VARCHAR,   -- team name at the time (e.g. 'SK Telecom T1')
    DateJoin             DATE,
    DateLeave            DATE,
    ContractEnd          VARCHAR,
    RosterChangeIdJoin   VARCHAR,   -- join to roster_changes for role
    RosterChangeIdLeave  VARCHAR,
    NextTeam             VARCHAR,
    NextIsRetired        BOOLEAN,
    IsCurrent            BOOLEAN
);

CREATE TABLE raw.roster_changes (
    RosterChangeId  VARCHAR,
    Date_Sort       TIMESTAMP,
    Player          VARCHAR,
    Direction       VARCHAR,   -- 'Join' / 'Leave'
    Team            VARCHAR,
    RolesIngame     VARCHAR,   -- list, ';' delimited
    RolesStaff      VARCHAR,   -- list, ';' delimited: Coach, Head Coach, Interim Head Coach ...
    Role            VARCHAR,
    Status          VARCHAR,
    Tournaments     VARCHAR,   -- list, ',' delimited
    NewsId          VARCHAR
);

CREATE TABLE raw.tournament_players (
    OverviewPage    VARCHAR,   -- stage page; matches TournamentResults.RosterPage
    Team            VARCHAR,
    Link            VARCHAR,
    Player          VARCHAR,
    Role            VARCHAR,   -- includes 'Coach'
    N_PlayerInTeam  INTEGER
);

CREATE TABLE raw.tournament_results (
    OverviewPage   VARCHAR,   -- event page, e.g. '2025 Season World Championship'
    RosterPage     VARCHAR,   -- stage page where the roster is listed
    Event          VARCHAR,
    Tier           VARCHAR,
    Date           DATE,      -- date the placement was decided
    Team           VARCHAR,
    Place          VARCHAR,   -- text, e.g. '15-16'
    Place_Number   INTEGER,
    Phase          VARCHAR,
    Qualified      BOOLEAN,
    Prize_USD      DOUBLE,
    IsAchievement  BOOLEAN,
    Showmatch      BOOLEAN
);

CREATE TABLE raw.individual_achievements (
    Player           VARCHAR,
    Link             VARCHAR,   -- almost always empty; map Player via player_redirects
    Team             VARCHAR,
    OverviewPage     VARCHAR,
    Display          VARCHAR,   -- inconsistent spelling; normalize in clean layer
    Place            VARCHAR,
    Place_Number     INTEGER,
    AchievementType  VARCHAR
);

CREATE TABLE raw.champions (
    Name        VARCHAR PRIMARY KEY,
    Attributes  VARCHAR,   -- list, ',' delimited (class tags)
    Resource    VARCHAR,
    ReleaseDate DATE
);
