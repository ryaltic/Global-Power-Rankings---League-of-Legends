-- Clean layer: the model's tables, built from the raw.* Leaguepedia tables (raw_schema.sql).
-- Parent tables come before the tables that reference them.
-- IDs reuse Leaguepedia keys: team_id = Teams.OverviewPage (latest name after renames),
-- person_id = Players.OverviewPage, tournament_id = Tournaments.OverviewPage,
-- match_id = MatchId, game_id = GameId.

CREATE TABLE region_map (
    league        VARCHAR,
    year          INTEGER,
    region        VARCHAR,
    league_level  VARCHAR,
    PRIMARY KEY (league, year)
);

CREATE TABLE teams (
    team_id         VARCHAR PRIMARY KEY,
    canonical_name  VARCHAR NOT NULL,
    short           VARCHAR,
    organization    VARCHAR,
    region          VARCHAR,
    team_type       VARCHAR DEFAULT 'club',  -- club or national
    nation          VARCHAR,                  -- national teams only
    is_disbanded    BOOLEAN,
    renamed_to      VARCHAR
);

CREATE TABLE people (
    person_id     VARCHAR PRIMARY KEY,
    handle        VARCHAR NOT NULL,
    real_name     VARCHAR,
    nationality   VARCHAR,
    residency     VARCHAR,
    birthdate     DATE,
    primary_role  VARCHAR,
    is_retired    BOOLEAN,
    is_substitute BOOLEAN
);

CREATE TABLE tournaments (
    tournament_id  VARCHAR PRIMARY KEY,
    overview_page  VARCHAR,
    league         VARCHAR,
    year           INTEGER,
    split          VARCHAR,
    level          VARCHAR,
    is_playoffs    BOOLEAN,
    weight         DOUBLE,
    FOREIGN KEY (league, year) REFERENCES region_map (league, year)
);

CREATE TABLE matches (
    match_id       VARCHAR PRIMARY KEY,
    tournament_id  VARCHAR REFERENCES tournaments (tournament_id),
    datetime_utc   TIMESTAMP,
    team1_id       VARCHAR REFERENCES teams (team_id),
    team2_id       VARCHAR REFERENCES teams (team_id),
    best_of        INTEGER,
    stage          VARCHAR,  -- from Tab, Round or Phase
    is_tiebreaker  BOOLEAN,
    is_fearless    BOOLEAN,
    is_forfeit     BOOLEAN,
    is_nullified   BOOLEAN,
    winner_id      VARCHAR REFERENCES teams (team_id)
);

CREATE TABLE games (
    game_id                VARCHAR PRIMARY KEY,
    match_id               VARCHAR REFERENCES matches (match_id),
    riot_platform_game_id  VARCHAR,
    oe_game_id             VARCHAR,
    game_num               INTEGER,  -- N_GameInMatch
    datetime_utc           TIMESTAMP,
    patch                  VARCHAR,
    patch_sort             VARCHAR,
    blue_team_id           VARCHAR REFERENCES teams (team_id),
    red_team_id            VARCHAR REFERENCES teams (team_id),
    winner_id              VARCHAR REFERENCES teams (team_id),
    side_selection_team_id VARCHAR REFERENCES teams (team_id),
    first_pick_team_id     VARCHAR REFERENCES teams (team_id),
    is_remake              BOOLEAN,
    length_s               INTEGER
);

CREATE TABLE champions (
    champion    VARCHAR PRIMARY KEY,
    attributes  VARCHAR[],  -- class tags
    resource    VARCHAR
);

CREATE TABLE game_draft (
    game_id    VARCHAR REFERENCES games (game_id),
    team_id    VARCHAR REFERENCES teams (team_id),
    action     VARCHAR,   -- pick or ban
    slot       INTEGER,   -- 1-5 in draft order
    champion   VARCHAR REFERENCES champions (champion),
    role       VARCHAR,   -- picks only
    PRIMARY KEY (game_id, team_id, action, slot)
);

CREATE TABLE rosters (
    roster_id      VARCHAR PRIMARY KEY,
    team_id        VARCHAR REFERENCES teams (team_id),
    top            VARCHAR REFERENCES people (person_id),
    jungle         VARCHAR REFERENCES people (person_id),
    mid            VARCHAR REFERENCES people (person_id),
    bot            VARCHAR REFERENCES people (person_id),
    support        VARCHAR REFERENCES people (person_id),
    head_coach_id  VARCHAR REFERENCES people (person_id),
    first_game     DATE,
    last_game      DATE
);

CREATE TABLE game_team_stats (
    game_id            VARCHAR REFERENCES games (game_id),
    team_id            VARCHAR REFERENCES teams (team_id),
    side               VARCHAR,
    win                BOOLEAN,
    roster_id          VARCHAR REFERENCES rosters (roster_id),
    continuity         DOUBLE,
    kills              INTEGER,
    towers             INTEGER,
    dragons            INTEGER,
    barons             INTEGER,
    final_gold_diff    INTEGER,
    gold_diff_15       INTEGER,  -- nullable: Leaguepedia timeline, else Oracle's Elixir; none for LPL
    xp_diff_15         INTEGER,  -- nullable, same sources
    data_completeness  VARCHAR,
    PRIMARY KEY (game_id, team_id)
);

CREATE TABLE player_games (
    game_id           VARCHAR,
    person_id         VARCHAR REFERENCES people (person_id),
    team_id           VARCHAR,
    role              VARCHAR,
    champion          VARCHAR,
    kills             INTEGER,
    deaths            INTEGER,
    assists           INTEGER,
    cs                INTEGER,
    damage_to_champs  INTEGER,
    vision_score      INTEGER,
    gold_diff_15      INTEGER,  -- nullable, same sources as game_team_stats
    cs_diff_15        INTEGER,  -- nullable
    PRIMARY KEY (game_id, person_id),
    FOREIGN KEY (game_id, team_id) REFERENCES game_team_stats (game_id, team_id)
);

CREATE TABLE team_aliases (
    alias           VARCHAR PRIMARY KEY,
    team_id         VARCHAR REFERENCES teams (team_id),
    change_type     VARCHAR,  -- rename or slot sale
    effective_date  DATE
);

CREATE TABLE person_aliases (
    alias           VARCHAR PRIMARY KEY,
    person_id       VARCHAR REFERENCES people (person_id),
    effective_date  DATE
);

CREATE TABLE tenures (
    person_id      VARCHAR REFERENCES people (person_id),
    team_id        VARCHAR REFERENCES teams (team_id),
    date_join      DATE,
    date_leave     DATE,
    role           VARCHAR,
    is_staff       BOOLEAN,
    is_substitute  BOOLEAN,
    PRIMARY KEY (person_id, team_id, date_join)
);

CREATE TABLE tournament_participants (
    tournament_id  VARCHAR REFERENCES tournaments (tournament_id),
    team_id        VARCHAR REFERENCES teams (team_id),
    person_id      VARCHAR REFERENCES people (person_id),
    role           VARCHAR,
    is_staff       BOOLEAN,
    PRIMARY KEY (tournament_id, team_id, person_id)
);

CREATE TABLE team_placements (
    tournament_id   VARCHAR REFERENCES tournaments (tournament_id),  -- TournamentResults.RosterPage
    team_id         VARCHAR REFERENCES teams (team_id),
    event_name      VARCHAR,  -- e.g. 'Worlds 2025'
    date_decided    DATE,     -- use for as-of résumé counts
    place           INTEGER,
    place_text      VARCHAR,  -- e.g. '15-16'
    prize_usd       DOUBLE,
    is_achievement  BOOLEAN,
    PRIMARY KEY (tournament_id, team_id)
);

CREATE TABLE individual_awards (
    person_id      VARCHAR REFERENCES people (person_id),
    tournament_id  VARCHAR REFERENCES tournaments (tournament_id),
    award_type     VARCHAR,  -- normalized, e.g. all_pro_1, mvp, finals_mvp, best_coach
    award_display  VARCHAR,  -- raw Leaguepedia text
    team_id        VARCHAR REFERENCES teams (team_id),
    place          INTEGER,
    PRIMARY KEY (person_id, tournament_id, award_type)
);

CREATE TABLE ratings_history (
    team_id        VARCHAR REFERENCES teams (team_id),
    as_of_date     DATE,
    team_type      VARCHAR,  -- club or national
    rating         DOUBLE,
    rd             DOUBLE,
    region_offset  DOUBLE,
    global_rating  DOUBLE,
    global_rank    INTEGER,
    PRIMARY KEY (team_id, as_of_date)
);

CREATE TABLE person_ratings_history (
    person_id    VARCHAR REFERENCES people (person_id),
    as_of_date   DATE,
    rating_type  VARCHAR,  -- player or coach
    role         VARCHAR,
    rating       DOUBLE,
    rd           DOUBLE,
    games        INTEGER,
    PRIMARY KEY (person_id, as_of_date)
);

-- Future state: national teams
CREATE TABLE national_selections (
    tournament_id         VARCHAR REFERENCES tournaments (tournament_id),
    nation_team_id        VARCHAR REFERENCES teams (team_id),
    person_id             VARCHAR REFERENCES people (person_id),
    role                  VARCHAR,
    club_team_id_at_time  VARCHAR REFERENCES teams (team_id),
    PRIMARY KEY (tournament_id, nation_team_id, person_id)
);
