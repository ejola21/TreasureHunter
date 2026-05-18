-- ============================================================================
-- Play Spot — MySQL 8.4 데이터베이스 구축 SQL
-- ----------------------------------------------------------------------------
-- 출처:
--   1. 레거시 SQLite 스키마 (PlaySpot/Resources/treasure.sqlite)
--      → Mission / MissionItem / ItemQuiz / ItemRnP / MissionInPlay /
--        MissionItemInPlay / ItemRnPInPlay
--   2. research.md §7 (테이블 스키마) + §8 (서버 트랜잭션) 분석
--   3. research2.md §부록 A (모든 코드값 사전)
--
-- 추가된 서버 측 테이블 (레거시 클라이언트 SQLite 에는 없음):
--   - User              : 회원 정보 (TR=tr_user_reg / tr_user_sel / tr_user_chg)
--   - MissionReply      : 미션 댓글/리뷰 (TR=300 / TR=400)
--   - MissionPlayRecord : 플레이 기록 — 랭킹 산출용 (TR=c_mission_play_*)
--   - IAPTransaction    : StoreKit 구매 로그 (solution_add_10 / time_add_10)
--   - 통합 코드 테이블 (CodeRef) — 레거시 4개 lookup 통합
--
-- 호환성: MySQL 8.4 (utf8mb4_0900_ai_ci, InnoDB, 윈도 함수 사용 가능)
-- ============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
SET TIME_ZONE = '+09:00';   -- 레거시 [NSDate date] 기준 KST. 운영 환경에 맞게 조정.

-- ============================================================================
-- 1. 데이터베이스
-- ============================================================================

CREATE DATABASE IF NOT EXISTS playspot
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE playspot;

-- ============================================================================
-- 2. 통합 코드 테이블 (CodeRef)
--    레거시 ItemTypeRef / ShowTypeRef / MissionStatusRef / ItemGameRef 4개를
--    하나의 (CodeGroup, Code) 복합키 테이블로 통합. FK 미사용 — 클라이언트의
--    Swift enum (ItemType / ShowType / MissionStatus / PlayMode) 이 무결성을 보장.
--
--    매핑:
--      ITEM_TYPE       : Code=레거시 itemType ('00'~'91'), CodeName=Macro(I_*),    CodeValue=KoLabel
--      SHOW_TYPE       : Code='1'~'4',                     CodeName=Macro(SHOW_*), CodeValue=KoLabel
--      MISSION_STATUS  : Code='0'~'3',                     CodeName=Name,          CodeValue=Description
--      ITEM_GAME       : Code='0'~'3',                     CodeName=EnLabel,       CodeValue=KoLabel
-- ============================================================================

DROP TABLE IF EXISTS CodeRef;
CREATE TABLE CodeRef (
    CodeGroup  VARCHAR(32)  NOT NULL,                              -- 'ITEM_TYPE' | 'SHOW_TYPE' | 'MISSION_STATUS' | 'ITEM_GAME'
    Code       VARCHAR(8)   NOT NULL,                              -- 그룹 내 코드값 (business 컬럼이 저장하는 raw value)
    CodeName   VARCHAR(64)  NOT NULL,                              -- 식별자 (매크로명 또는 영문명)
    CodeValue  VARCHAR(128) NOT NULL,                              -- 표시값 (한국어 라벨)
    PRIMARY KEY (CodeGroup, Code)
) ENGINE=InnoDB COMMENT='통합 코드 테이블. FK/인덱스 없음 (클라이언트 enum 이 게이트키퍼)';

INSERT INTO CodeRef (CodeGroup, Code, CodeName, CodeValue) VALUES
    -- ItemType (32개) — research2.md §A.1
    ('ITEM_TYPE','00','I_NUM00','숫자 0'),
    ('ITEM_TYPE','01','I_NUM01','숫자 1'),
    ('ITEM_TYPE','02','I_NUM02','숫자 2'),
    ('ITEM_TYPE','03','I_NUM03','숫자 3'),
    ('ITEM_TYPE','04','I_NUM04','숫자 4'),
    ('ITEM_TYPE','05','I_NUM05','숫자 5'),
    ('ITEM_TYPE','06','I_NUM06','숫자 6'),
    ('ITEM_TYPE','07','I_NUM07','숫자 7'),
    ('ITEM_TYPE','08','I_NUM08','숫자 8'),
    ('ITEM_TYPE','09','I_NUM09','숫자 9'),
    ('ITEM_TYPE','10','I_ALPHABET','알파벳'),
    ('ITEM_TYPE','40','I_QUIZ','퀴즈'),
    ('ITEM_TYPE','41','I_QUIZ20','확장 퀴즈'),
    ('ITEM_TYPE','42','I_TIMEOUT_S','런 시작'),
    ('ITEM_TYPE','43','I_TIMEOUT_E','런 종료'),
    ('ITEM_TYPE','48','I_END','종료'),
    ('ITEM_TYPE','49','I_START','시작'),
    ('ITEM_TYPE','50','I_RANDOM','갬블링'),
    ('ITEM_TYPE','51','I_SIMPLE','힌트'),
    ('ITEM_TYPE','52','I_SOLUTION','솔루션'),
    ('ITEM_TYPE','54','I_PENALTY_REMOVE','페널티 제거'),
    ('ITEM_TYPE','55','I_MINE','지뢰'),
    ('ITEM_TYPE','56','I_BLACK','다크'),
    ('ITEM_TYPE','59','I_COUPON','쿠폰'),
    ('ITEM_TYPE','61','I_MINE_NOBOMB','방어'),
    ('ITEM_TYPE','65','I_RADAR_AR','스텔스 레이더'),
    ('ITEM_TYPE','66','I_RADAR_MAP','맵 레이더'),
    ('ITEM_TYPE','67','I_RADAR_ALL','전체 레이더'),
    ('ITEM_TYPE','68','I_RADAR_MINE','지뢰 레이더'),
    ('ITEM_TYPE','69','I_RADAR_BLACK','다크 레이더'),
    ('ITEM_TYPE','91','I_STORE','상점'),
    -- ShowType (4개) — research2.md §A.2
    ('SHOW_TYPE','1','SHOW_TRANSPARENT','전체 숨김'),
    ('SHOW_TYPE','2','SHOW_AR','지도 숨김'),
    ('SHOW_TYPE','3','SHOW_MAP','AR 정보 숨김'),
    ('SHOW_TYPE','4','SHOW_ALL','일반'),
    -- MissionStatus (4개) — pch:25-30
    ('MISSION_STATUS','0','DESIGNING','편집 중'),
    ('MISSION_STATUS','1','TESTED','테스트 완료'),
    ('MISSION_STATUS','2','SERVER_UPLOAD','서버 업로드 완료 (수정 불가)'),
    ('MISSION_STATUS','3','FIRST_DESIGN','최초 디자인 (취소 시 삭제)'),
    -- ItemGame (4개) — research2.md §A.4
    ('ITEM_GAME','0','None','없음'),
    ('ITEM_GAME','1','Beginer Level','난이도 하'),
    ('ITEM_GAME','2','Normal Level','난이도 중'),
    ('ITEM_GAME','3','Senior Level','난이도 상');

-- ============================================================================
-- 3. 사용자 (User) — 서버 측 추가 (레거시 SQLite 에는 없음)
--    레거시 TR=800 (login), tr_user_reg, tr_pwd_chg, tr_user_sel, tr_user_chg
-- ============================================================================

DROP TABLE IF EXISTS User;
CREATE TABLE User (
    UserID          VARCHAR(100) NOT NULL,                        -- 이메일 또는 Guest@<timestamp>
    PasswordMD5     CHAR(32)     NULL,                            -- 레거시는 MD5 전송 (현대 운영시 bcrypt 권장)
    EmailAddr       VARCHAR(255) NULL,
    PhoneNo         VARCHAR(32)  NULL,
    Nickname        VARCHAR(64)  NULL,
    IsGuest         TINYINT(1)   NOT NULL DEFAULT 0,
    SolutionCount   INT          NOT NULL DEFAULT 0,              -- IAP solution_add_10 잔고 (NSUserDefaults `solution`)
    TimeAddCount    INT          NOT NULL DEFAULT 0,              -- IAP time_add_10 잔고 (NSUserDefaults `timeAdd`)
    CreatedAt       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    LastLoginAt     DATETIME     NULL,
    PRIMARY KEY (UserID)
) ENGINE=InnoDB COMMENT='회원 + 게스트. SolutionCount/TimeAddCount 는 IAP 잔고. 인덱스 없음';

-- ============================================================================
-- 4. Mission — 미션 카탈로그 (레거시 SQLite Mission + 서버 응답 필드 통합)
-- ============================================================================

DROP TABLE IF EXISTS Mission;
CREATE TABLE Mission (
    MissionID       VARCHAR(64)  NOT NULL,                        -- userID + yyyyMMddHHmmss 또는 시스템 ID (예: tutorial001)
    Title           VARCHAR(255) NOT NULL,
    Description     TEXT         NULL,
    Place           VARCHAR(255) NULL,
    Designer        VARCHAR(100) NULL,                            -- → User.UserID
    StartTime       DATETIME     NULL,
    RunLimitTime    INT          NULL DEFAULT 0,                  -- 미션 전체 제한 시간 (초). 레거시는 DATETIME 이지만 의미상 초 환산
    Status          TINYINT      NOT NULL DEFAULT 0,              -- → CodeRef(CodeGroup='MISSION_STATUS')
    Quiz            TEXT         NULL,                            -- 미션 레벨 퀴즈 질문
    `Answer`        VARCHAR(255) NULL,                            -- 미션 레벨 정답
    `Virtual`       TINYINT(1)   NOT NULL DEFAULT 0,              -- 0=Real only, 1=Virtual mode 가능 (MySQL 예약어 → backtick 필수)
    Lang            VARCHAR(8)   NULL,                            -- 미션 언어 (예: 'ko', 'en')
    BadgeImageName  VARCHAR(128) NULL,                            -- {MissionID}.png (CDN/이미지 서버에 저장)
    -- 집계 필드 (서버 응답 TR=200)
    PlayCnt         INT          NOT NULL DEFAULT 0,
    FailCnt         INT          NOT NULL DEFAULT 0,
    RecommendCnt    INT          NOT NULL DEFAULT 0,
    RecommendSum    INT          NOT NULL DEFAULT 0,              -- 평점 합계 (RecommendAvg = RecommendSum / RecommendCnt)
    -- 기록 필드 (서버 응답 TR=200)
    FirstRecordID   VARCHAR(100) NULL,                            -- 최초 클리어 PlayerID
    ManyRecordID    VARCHAR(100) NULL,                            -- 최다 클리어 PlayerID
    ShortRecordID   VARCHAR(100) NULL,                            -- 최단 시간 PlayerID
    WriteDate       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (MissionID)
) ENGINE=InnoDB COMMENT='미션 메타데이터 + 집계 필드. FK/인덱스 없음 (애플리케이션 레벨 검증)';

-- ============================================================================
-- 5. MissionItem — 미션 내 아이템 카탈로그
--    레거시 SQLite MissionItem 그대로 + research2.md §부록 A 컬럼 정밀 분석 반영
-- ============================================================================

DROP TABLE IF EXISTS MissionItem;
CREATE TABLE MissionItem (
    MissionID       VARCHAR(64)  NOT NULL,
    ItemID          INT          NOT NULL,                        -- 미션 내 1부터 자동 증가
    Mandatory       TINYINT      NOT NULL DEFAULT 0,              -- 0=N(선택), 1=Y(필수)
    ItemType        VARCHAR(8)   NOT NULL,                        -- → CodeRef(CodeGroup='ITEM_TYPE')
    Latitude        DECIMAL(10,7) NULL,                           -- WGS84 위도 (소수점 7자리 ≈ 1cm)
    Longitude       DECIMAL(10,7) NULL,                           -- WGS84 경도
    BlackCnt        INT          NOT NULL DEFAULT 5,              -- 다크/지뢰 개수 (런타임 미사용)
    BlackTime       INT          NOT NULL DEFAULT 300,            -- 다크/지뢰 페널티 시간(초). default 5분 (런타임 미사용)
    RangeAR         INT          NOT NULL DEFAULT 30,             -- AR 가시거리 / mine 폭발 / black 영향 반경 (m)
    ShowType        VARCHAR(2)   NOT NULL DEFAULT '4',            -- → CodeRef(CodeGroup='SHOW_TYPE')
    EffectiveRange  INT          NOT NULL DEFAULT 0,              -- 의도상 RunStart↔End 거리 (런타임 미사용)
    EffectiveTime   INT          NOT NULL DEFAULT 0,              -- 타임어택 제한 시간(초). RunStart/End 만 의미
    ItemGame        TINYINT      NOT NULL DEFAULT 0,              -- → CodeRef(CodeGroup='ITEM_GAME') (0=즉시, 1~3=미니게임)
    Info            TEXT         NULL,                            -- 자유 텍스트 (힌트/안내/쿠폰 코드/상품 정보 등)
    RelationItemID  INT          NOT NULL DEFAULT 0,              -- RunStart↔End 짝맞춤 (서로 상대방의 ItemID)
    WriteDate       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (MissionID, ItemID)
) ENGINE=InnoDB COMMENT='아이템 카탈로그. FK/인덱스 없음 (애플리케이션 레벨 검증). ItemType/ShowType/ItemGame 은 CodeRef 참조';

-- ============================================================================
-- 6. ItemQuiz — Quiz / Quiz20 아이템의 퀴즈 변형 (1:N)
-- ============================================================================

DROP TABLE IF EXISTS ItemQuiz;
CREATE TABLE ItemQuiz (
    MissionID    VARCHAR(64)   NOT NULL,
    ItemID       INT           NOT NULL,
    Seq          INT           NOT NULL,                          -- MissionItem.quizSeq 기반 카운터
    Quiz         TEXT          NOT NULL,                          -- 질문
    `Answer`     VARCHAR(255)  NOT NULL,                          -- 정답 (대소문자 무관 비교)
    Probability  INT           NOT NULL DEFAULT 100,              -- 가중치 (현재 런타임은 균등 랜덤, 미사용)
    PRIMARY KEY (MissionID, ItemID, Seq)
) ENGINE=InnoDB COMMENT='퀴즈 변형. Quiz(40)/Quiz20(41) 만 의미. FK 없음';

-- ============================================================================
-- 7. ItemRnP — 보상/특수 아이템 정의 (레거시 SQLite 에 있으나 런타임 미사용)
--    향후 신규 시스템에서 활용 가능
-- ============================================================================

DROP TABLE IF EXISTS ItemRnP;
CREATE TABLE ItemRnP (
    MissionID       VARCHAR(64)  NOT NULL,
    ItemID          INT          NOT NULL,
    Seq             INT          NOT NULL,
    RewardCode      VARCHAR(64)  NULL,
    Probability     INT          NULL,
    Increase        INT          NULL,
    MissionRange    INT          NULL,
    EffectiveRange  INT          NULL,
    EffectiveTime   DATETIME     NULL,
    EffectiveCount  INT          NULL,
    PRIMARY KEY (MissionID, ItemID, Seq)
) ENGINE=InnoDB COMMENT='보상/특수 아이템 정의 (레거시 정의만 존재, 런타임 미사용). FK 없음';

-- ============================================================================
-- 8. MissionInPlay — 사용자별 미션 진행 상태 (current snapshot)
-- ============================================================================

DROP TABLE IF EXISTS MissionInPlay;
CREATE TABLE MissionInPlay (
    MissionID    VARCHAR(64)  NOT NULL,
    PlayerID     VARCHAR(100) NOT NULL,
    StartYN      CHAR(1)      NOT NULL DEFAULT 'N',               -- Start 아이템 획득 여부
    EndYN        CHAR(1)      NOT NULL DEFAULT 'N',               -- 미션 완료 여부
    StartTime    DATETIME     NULL,                               -- 미션 시작 시각 (Start 획득 시점)
    EndTime      DATETIME     NULL,                               -- 미션 종료 시각 (End 획득 시점)
    PRIMARY KEY (MissionID, PlayerID)
) ENGINE=InnoDB COMMENT='사용자별 미션 진행 스냅샷. FK/인덱스 없음';

-- ============================================================================
-- 9. MissionItemInPlay — 사용자별 아이템 획득 상태
-- ============================================================================

DROP TABLE IF EXISTS MissionItemInPlay;
CREATE TABLE MissionItemInPlay (
    MissionID  VARCHAR(64)  NOT NULL,
    PlayerID   VARCHAR(100) NOT NULL,
    ItemID     INT          NOT NULL,
    EndYN      CHAR(1)      NOT NULL DEFAULT 'N',                 -- 'Y' = 획득 완료
    StartTime  DATETIME     NULL,
    EndTime    DATETIME     NULL,                                 -- 획득 시각 (정렬용 — selectLastAcquiredItem)
    FailCnt    INT          NOT NULL DEFAULT 0,                   -- 퀴즈 실패 누적 (페널티 힌트 표시용)
    QuizSeq    INT          NULL,                                 -- 마지막으로 푼 ItemQuiz.Seq
    PRIMARY KEY (MissionID, PlayerID, ItemID)
) ENGINE=InnoDB COMMENT='사용자별 아이템 획득 상태. FK/인덱스 없음';

-- ============================================================================
-- 10. ItemRnPInPlay — 사용자 보상 아이템 획득 현황 (radar/solution/defense)
-- ============================================================================

DROP TABLE IF EXISTS ItemRnPInPlay;
CREATE TABLE ItemRnPInPlay (
    MissionID     VARCHAR(64)  NOT NULL,
    PlayerID      VARCHAR(100) NOT NULL,
    ItemType      VARCHAR(8)   NOT NULL,                          -- → CodeRef(CodeGroup='ITEM_TYPE') (radar*/solution/mineNoBomb)
    AbleCnt       INT          NOT NULL DEFAULT 1,                -- 남은 사용 횟수 (Defense/Solution 만 의미. radar 는 boolean)
    AbleTime      DATETIME     NULL,
    AcquiredTime  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (MissionID, PlayerID, ItemType)
) ENGINE=InnoDB COMMENT='사용자 보상 아이템 획득 현황. radar 는 ableCnt=1 boolean. FK/인덱스 없음';

-- ============================================================================
-- 11. MissionReply — 미션 댓글/리뷰 (레거시 TR=300 / TR=400)
-- ============================================================================

DROP TABLE IF EXISTS MissionReply;
CREATE TABLE MissionReply (
    ReplyID    BIGINT       NOT NULL AUTO_INCREMENT,
    MissionID  VARCHAR(64)  NOT NULL,
    UserID     VARCHAR(100) NOT NULL,
    Score      DECIMAL(2,1) NULL,                                 -- 0.0 ~ 5.0 평점
    Reply      TEXT         NULL,                                 -- 리뷰 텍스트
    CreatedAt  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ReplyID)
) ENGINE=InnoDB COMMENT='댓글 + 평점. FK/인덱스 없음. Mission 의 RecommendCnt/Sum 집계 갱신 트리거 권장';

-- ============================================================================
-- 12. MissionPlayRecord — 플레이 기록 (랭킹 산출용)
--    레거시 TR=c_mission_play_start / finish / fail / ranking
-- ============================================================================

DROP TABLE IF EXISTS MissionPlayRecord;
CREATE TABLE MissionPlayRecord (
    RecordID       BIGINT       NOT NULL AUTO_INCREMENT,
    MissionID      VARCHAR(64)  NOT NULL,
    PlayerID       VARCHAR(100) NOT NULL,
    StartTime      DATETIME     NOT NULL,
    EndTime        DATETIME     NULL,                             -- NULL 이면 진행 중 또는 실패
    DurationSec    INT          GENERATED ALWAYS AS               -- 클리어 시간(초) — 자동 계산. 랭킹 정렬 키
        (CASE WHEN EndTime IS NULL THEN NULL
              ELSE TIMESTAMPDIFF(SECOND, StartTime, EndTime) END) STORED,
    Status         ENUM('PLAYING','FINISHED','FAILED') NOT NULL DEFAULT 'PLAYING',
    IsVirtualMode  TINYINT(1)   NOT NULL DEFAULT 0,
    PRIMARY KEY (RecordID)
) ENGINE=InnoDB COMMENT='플레이 기록. DurationSec 자동 산출. FK/인덱스 없음';

-- ============================================================================
-- 13. IAPTransaction — StoreKit 인앱 결제 로그
-- ============================================================================

DROP TABLE IF EXISTS IAPTransaction;
CREATE TABLE IAPTransaction (
    TransactionID  VARCHAR(128) NOT NULL,                         -- Apple StoreKit transactionIdentifier
    UserID         VARCHAR(100) NOT NULL,
    ProductID      VARCHAR(64)  NOT NULL,                         -- e.g. 'solution_add_10', 'time_add_10'
    Quantity       INT          NOT NULL DEFAULT 1,
    PurchasedAt    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ReceiptData    LONGTEXT     NULL,                             -- base64 encoded receipt (검증용)
    Status         ENUM('PURCHASED','RESTORED','REFUNDED') NOT NULL DEFAULT 'PURCHASED',
    PRIMARY KEY (TransactionID)
) ENGINE=InnoDB COMMENT='IAP 구매 로그. FK/인덱스 없음. User.SolutionCount/TimeAddCount 갱신 트리거 권장';

-- ============================================================================
-- 14. 트리거 — 집계 자동 갱신 (선택)
--    MissionReply 등록 시 Mission.RecommendCnt/Sum 자동 갱신
-- ============================================================================

DROP TRIGGER IF EXISTS trg_reply_after_insert;
DELIMITER $$
CREATE TRIGGER trg_reply_after_insert
AFTER INSERT ON MissionReply
FOR EACH ROW
BEGIN
    IF NEW.Score IS NOT NULL THEN
        UPDATE Mission
        SET RecommendCnt = RecommendCnt + 1,
            RecommendSum = RecommendSum + NEW.Score
        WHERE MissionID = NEW.MissionID;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS trg_record_after_update;
DELIMITER $$
CREATE TRIGGER trg_record_after_update
AFTER UPDATE ON MissionPlayRecord
FOR EACH ROW
BEGIN
    -- 진행 중 → FINISHED 전이 시 PlayCnt + 1
    IF OLD.Status = 'PLAYING' AND NEW.Status = 'FINISHED' THEN
        UPDATE Mission SET PlayCnt = PlayCnt + 1 WHERE MissionID = NEW.MissionID;
    END IF;
    -- 진행 중 → FAILED 전이 시 FailCnt + 1
    IF OLD.Status = 'PLAYING' AND NEW.Status = 'FAILED' THEN
        UPDATE Mission SET FailCnt = FailCnt + 1 WHERE MissionID = NEW.MissionID;
    END IF;
END$$
DELIMITER ;

-- ============================================================================
-- 15. 뷰 — 자주 쓰는 조회 단순화
-- ============================================================================

-- 미션 목록 + 평균 평점 (TR=500 응답용)
CREATE OR REPLACE VIEW v_mission_list AS
SELECT
    m.MissionID, m.Title, m.Description, m.Place, m.Designer,
    m.RunLimitTime, m.Status, m.Quiz, m.`Answer`, m.`Virtual`, m.Lang,
    m.BadgeImageName, m.PlayCnt, m.FailCnt, m.RecommendCnt,
    CASE WHEN m.RecommendCnt > 0
         THEN ROUND(m.RecommendSum / m.RecommendCnt, 1)
         ELSE 0 END AS RecommendAvg,
    m.WriteDate
FROM Mission m
WHERE m.Status = 2;   -- SERVER_UPLOAD 만 노출

-- 미션 랭킹 Top 3 (TR=c_mission_play_ranking 응답용)
CREATE OR REPLACE VIEW v_mission_ranking AS
SELECT
    r.MissionID,
    r.PlayerID,
    u.Nickname,
    r.DurationSec,
    SEC_TO_TIME(r.DurationSec) AS RecordTime,
    ROW_NUMBER() OVER (PARTITION BY r.MissionID ORDER BY r.DurationSec ASC) AS Rank
FROM MissionPlayRecord r
INNER JOIN User u ON r.PlayerID = u.UserID
WHERE r.Status = 'FINISHED' AND r.DurationSec IS NOT NULL;

-- 사용자별 미션 진행률 (TR=602 응답용)
CREATE OR REPLACE VIEW v_user_progress AS
SELECT
    p.MissionID, p.PlayerID, p.StartYN, p.EndYN, p.StartTime, p.EndTime,
    COUNT(DISTINCT i.ItemID) AS TotalItems,
    SUM(CASE WHEN ip.EndYN = 'Y' THEN 1 ELSE 0 END) AS AcquiredItems,
    SUM(CASE WHEN i.Mandatory = 1 THEN 1 ELSE 0 END) AS MandatoryItems,
    SUM(CASE WHEN i.Mandatory = 1 AND ip.EndYN = 'Y' THEN 1 ELSE 0 END) AS MandatoryAcquired
FROM MissionInPlay p
LEFT JOIN MissionItem i ON p.MissionID = i.MissionID
LEFT JOIN MissionItemInPlay ip
       ON ip.MissionID = i.MissionID
      AND ip.ItemID = i.ItemID
      AND ip.PlayerID = p.PlayerID
GROUP BY p.MissionID, p.PlayerID, p.StartYN, p.EndYN, p.StartTime, p.EndTime;

-- ============================================================================
-- 16. 샘플 데이터 — PlaySpot 신규 프로젝트 mock 데이터 (PlaySpot/Resources/MockData/)
--     6개 튜토리얼 미션 / 31개 아이템 / 1개 퀴즈. 운영 전 삭제 권장.
-- ============================================================================

-- Designer 사용자 (모든 튜토리얼 미션의 설계자)
INSERT INTO User (UserID, EmailAddr, Nickname, IsGuest)
VALUES ('playspot', NULL, 'PlaySpot', 0);

-- 6개 튜토리얼 미션 (mock_mission_list.json)
-- RunLimitTime: HH:MM:SS → 초 변환 (00:10:00=600, 00:15:00=900, 00:20:00=1200)
INSERT INTO Mission (MissionID, Title, Description, Place, Designer, RunLimitTime, Status, `Virtual`, Lang, WriteDate) VALUES
    ('tutorial001', '튜토리얼: 기본 미션',
     'Play Spot의 기본 사용법을 배우는 튜토리얼 — Start → 게임 → 퀴즈 → End 순서로 진행합니다.',
     '튜토리얼 광장', 'playspot',  600, 2, 1, 'ko', '2026-05-13'),
    ('mine002',     '지뢰 & 레이더 미션',
     '지뢰를 피하고 방어 아이템과 레이더를 활용해 미션을 완료하세요.',
     '튜토리얼 광장', 'playspot',  900, 2, 1, 'ko', '2026-05-13'),
    ('run003',      '타임 런 미션',
     'Run Start를 획득하면 타이머가 시작됩니다. 제한 시간 안에 Run End를 찾으세요!',
     '튜토리얼 광장', 'playspot',  900, 2, 1, 'ko', '2026-05-13'),
    ('dark004',     '다크 존 미션',
     '다크 아이템 범위 안의 아이템은 지도에서 사라집니다. 스텔스 레이더로 AR에서 찾으세요.',
     '튜토리얼 광장', 'playspot',  900, 2, 1, 'ko', '2026-05-13'),
    ('gambling005', '맵 레이더 & 갬블링 미션',
     '맵 레이더로 숨겨진 아이템을 찾고, 갬블링 박스로 랜덤 아이템을 획득하세요.',
     '튜토리얼 광장', 'playspot',  900, 2, 1, 'ko', '2026-05-13'),
    ('standard006', '스탠다드 복합 미션',
     '힌트, 지뢰, 타임 런이 모두 포함된 복합 미션입니다.',
     '튜토리얼 광장', 'playspot', 1200, 2, 1, 'ko', '2026-05-13');

-- tutorial001 아이템 (mock_items_tutorial001.json)
INSERT INTO MissionItem (MissionID, ItemID, Mandatory, ItemType, Latitude, Longitude, BlackCnt, BlackTime, RangeAR, ShowType, EffectiveRange, EffectiveTime, ItemGame, Info, RelationItemID) VALUES
    ('tutorial001', 1, 1, '49', 37.4850000, 126.8078000, 0,   0, 50, '4', 0,  0, 0, 'Start: 미션을 시작합니다.', 0),
    ('tutorial001', 2, 1, '51', 37.4851081, 126.8078000, 0,   0, 50, '4', 0,  0, 1, '퀴즈 힌트: 정답은 ''서''로 시작하는 두 글자 도시 이름입니다.', 3),
    ('tutorial001', 3, 1, '40', 37.4849459, 126.8079180, 0,   0, 50, '4', 0,  0, 0, '퀴즈 — 정답을 입력하세요.', 0),
    ('tutorial001', 4, 1, '48', 37.4849459, 126.8076820, 0,   0, 50, '4', 0,  0, 0, 'End: 미션을 종료합니다.', 0);

-- mine002 아이템 (mock_items_mine002.json)
INSERT INTO MissionItem (MissionID, ItemID, Mandatory, ItemType, Latitude, Longitude, BlackCnt, BlackTime, RangeAR, ShowType, EffectiveRange, EffectiveTime, ItemGame, Info, RelationItemID) VALUES
    ('mine002', 1, 1, '49', 37.4860000, 126.8078000, 0, 0, 50, '4', 0, 0, 0, 'Start: 지뢰밭 미션을 시작합니다. 방어 아이템을 먼저 찾으세요!', 0),
    ('mine002', 2, 0, '55', 37.4865783, 126.8078568, 0, 0, 50, '1', 0, 0, 0, '지뢰! 최근 획득한 아이템을 잃습니다.', 0),
    ('mine002', 3, 1, '61', 37.4860000, 126.8079249, 0, 0, 50, '4', 0, 0, 0, '방어 아이템: 지뢰 한 번의 피해를 막아줍니다.', 0),
    ('mine002', 4, 1, '68', 37.4859064, 126.8078681, 0, 0, 50, '4', 0, 0, 0, '지뢰 레이더: 지도에서 지뢰 위치가 보입니다.', 0),
    ('mine002', 5, 1, '66', 37.4859220, 126.8077432, 0, 0, 50, '4', 0, 0, 0, '맵 레이더: 지도에서 숨겨진 아이템이 보입니다.', 0),
    ('mine002', 6, 1, '51', 37.4860000, 126.8076751, 0, 0, 50, '4', 0, 0, 0, '힌트: End 아이템은 북서쪽 방향에 있습니다.', 0),
    ('mine002', 7, 1, '48', 37.4860936, 126.8077319, 0, 0, 50, '4', 0, 0, 0, 'End: 지뢰밭을 통과했습니다! 미션 완료.', 0);

-- run003 아이템 (mock_items_run003.json) — Run Start/End 짝(RelationItemID), EffectiveTime=60초
INSERT INTO MissionItem (MissionID, ItemID, Mandatory, ItemType, Latitude, Longitude, BlackCnt, BlackTime, RangeAR, ShowType, EffectiveRange, EffectiveTime, ItemGame, Info, RelationItemID) VALUES
    ('run003', 1, 1, '49', 37.4870000, 126.8078000, 0, 0, 50, '4', 0,  0, 0, 'Start: 타임 런 미션을 시작합니다.', 0),
    ('run003', 2, 1, '42', 37.4870900, 126.8078000, 0, 0, 50, '4', 0,  0, 0, 'Run Start: 카운트다운 시작! 60초 안에 Run End를 찾으세요.', 0),
    ('run003', 3, 1, '43', 37.4870990, 126.8078000, 0, 0, 50, '4', 0, 60, 0, 'Run End: 제한 시간 안에 도착했습니다!', 2),
    ('run003', 4, 1, '48', 37.4871080, 126.8078000, 0, 0, 50, '4', 0,  0, 0, 'End: 타임 런 미션 완료!', 0);

-- dark004 아이템 (mock_items_dark004.json — gambling005 오기재 분 제외)
INSERT INTO MissionItem (MissionID, ItemID, Mandatory, ItemType, Latitude, Longitude, BlackCnt, BlackTime, RangeAR, ShowType, EffectiveRange, EffectiveTime, ItemGame, Info, RelationItemID) VALUES
    ('dark004', 1, 1, '49', 37.4880000, 126.8078000, 0,   0, 50, '4',  0, 0, 0, 'Start: 다크 존 미션을 시작합니다. 스텔스 레이더를 먼저 찾으세요.', 0),
    ('dark004', 2, 0, '56', 37.4880901, 126.8078000, 3, 300, 20, '4', 20, 0, 0, 'Dark: 이 범위(20m) 안의 아이템은 지도에서 숨겨집니다.', 0),
    ('dark004', 3, 1, '65', 37.4878830, 126.8078851, 0,   0, 50, '4',  0, 0, 0, '스텔스 레이더: AR 화면에서 숨겨진 아이템이 보입니다.', 0),
    ('dark004', 4, 1, '51', 37.4882510, 126.8077358, 0,   0, 50, '3',  0, 0, 0, '힌트: End 아이템이 북동쪽에 있습니다. (스텔스 레이더 없이는 AR에서 안 보입니다)', 0),
    ('dark004', 5, 1, '48', 37.4880631, 126.8079376, 0,   0, 50, '4',  0, 0, 0, 'End: 다크 존을 돌파했습니다! 미션 완료.', 0);

-- gambling005 아이템 (mock_items_gambling005.json + dark004 파일의 첫 번째 ItemID=2 합침)
INSERT INTO MissionItem (MissionID, ItemID, Mandatory, ItemType, Latitude, Longitude, BlackCnt, BlackTime, RangeAR, ShowType, EffectiveRange, EffectiveTime, ItemGame, Info, RelationItemID) VALUES
    ('gambling005', 1, 1, '49', 37.4890000, 126.8078000, 0, 0, 50, '4', 0, 0, 0, 'Start: 갬블링 미션을 시작합니다. 맵 레이더로 숨겨진 아이템을 찾으세요.', 0),
    ('gambling005', 2, 1, '66', 37.4890637, 126.8078851, 0, 0, 50, '4', 0, 0, 0, '맵 레이더: 지도에서 숨겨진 아이템이 표시됩니다.', 0),
    ('gambling005', 3, 1, '50', 37.4890002, 126.8079369, 0, 0, 50, '2', 0, 0, 0, '갬블링: 획득하지 않은 아이템 중 하나를 랜덤으로 얻습니다.', 0),
    ('gambling005', 4, 1, '51', 37.4889410, 126.8987952, 0, 0, 20, '2', 0, 0, 0, '힌트: 맵 레이더나 갬블링 없이는 찾기 어렵습니다.', 0),
    ('gambling005', 5, 1, '48', 37.4890892, 126.8079124, 0, 0, 50, '4', 0, 0, 0, 'End: 갬블링 미션 완료!', 0);

-- standard006 아이템 (mock_items_standard006.json) — Run Start/End 짝, 지뢰 포함, 90초 제한
INSERT INTO MissionItem (MissionID, ItemID, Mandatory, ItemType, Latitude, Longitude, BlackCnt, BlackTime, RangeAR, ShowType, EffectiveRange, EffectiveTime, ItemGame, Info, RelationItemID) VALUES
    ('standard006', 1, 1, '49', 37.4900000, 126.8078000, 0, 0, 50, '4', 0,  0, 0, 'Start: 스탠다드 복합 미션을 시작합니다.', 0),
    ('standard006', 2, 1, '51', 37.4900901, 126.8078000, 0, 0, 50, '4', 0,  0, 0, '힌트: Run Start를 획득하면 90초 카운트다운이 시작됩니다. 지뢰를 조심하세요!', 0),
    ('standard006', 3, 0, '55', 37.4899505, 126.8079082, 0, 0, 20, '4', 0,  0, 0, '지뢰! 최근 획득한 아이템을 잃습니다.', 0),
    ('standard006', 4, 1, '42', 37.4899505, 126.8076918, 0, 0, 50, '4', 0,  0, 0, 'Run Start: 90초 카운트다운 시작! Run End를 찾으세요.', 0),
    ('standard006', 5, 1, '43', 37.4900956, 126.8076796, 0, 0, 50, '4', 0, 90, 0, 'Run End: 제한 시간 안에 도착했습니다!', 4),
    ('standard006', 6, 1, '48', 37.4900631, 126.8079376, 0, 0, 50, '4', 0,  0, 0, 'End: 스탠다드 복합 미션 완료! 수고하셨습니다.', 0);

-- 퀴즈 (mock_quizzes_tutorial001.json) — tutorial001 의 Quiz 아이템(ItemID=3)
INSERT INTO ItemQuiz (MissionID, ItemID, Seq, Quiz, `Answer`, Probability) VALUES
    ('tutorial001', 3, 1, '대한민국의 수도는?', '서울', 100);

-- ============================================================================
-- 17. 검증 쿼리 (선택 — 설치 후 동작 확인용)
-- ============================================================================
-- SELECT * FROM v_mission_list;
-- SELECT * FROM CodeRef WHERE CodeGroup = 'ITEM_TYPE' ORDER BY CAST(Code AS UNSIGNED);
-- SELECT * FROM v_user_progress WHERE PlayerID = 'system@playspot.local';

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- 끝.
-- 생성 순서 (FK 없음. 권장 순서):
--   CodeRef → User → Mission → MissionItem → ItemQuiz / ItemRnP
--   → MissionInPlay → MissionItemInPlay / ItemRnPInPlay
--   → MissionReply / MissionPlayRecord / IAPTransaction
--   → 트리거 → 뷰
-- ============================================================================
