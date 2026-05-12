#import <Foundation/Foundation.h>
#import "BaseDao.h"
#import "MissionItemInPlay.h"

@class MissionItem;

@interface MissionItemInPlayDao : BaseDao {
}

- (NSMutableArray *)selectAt:(NSString *)missionID playerID:(NSString *)playerID;
- (NSMutableDictionary *)selectDicAt:(NSString *)missionID playerID:(NSString *)playerID;
- (MissionItemInPlay *)selectWithPK:(NSString *)missionID playerID:(NSString *)playerID itemID:(int)itemID;
- (MissionItemInPlay *)selectLastAcquiredItem:(NSString *)missionID playerID:(NSString *)playerID itemID:(int)itemID;
- (MissionItemInPlay *)selectLastFailedQuiz:(NSString *)missionID playerID:(NSString *)playerID;
- (MissionItemInPlay *)selectlastAcquiredType:(NSString *)missionID playerID:(NSString *)playerID itemType:(NSString *)itemType;
- (MissionItemInPlay *)selectLastStartedTimeOut:(NSString *)missionID playerID:(NSString *)playerID;
- (NSMutableArray *)selectWithMissionID:(NSString *)missionID playerID:(NSString *)playerID itemType:(NSString *)itemType;
- (int)selectQuiz20Seq:(NSString *)missionID playerID:(NSString *)playerID;
- (NSMutableArray *)selectAcquiredQuiz20:(NSString *)missionID playerID:(NSString *)playerID;
- (BOOL)missionCompleted:(NSString *)missionID playerID:(NSString *)playerID;
- (BOOL)missionCompletedExceptEndItem:(NSString *)missionID playerID:(NSString *)playerID;
- (BOOL)insert:(MissionItemInPlay *)missionItemInPlay;
- (BOOL)update:(MissionItemInPlay *)missionItemInPlay;
- (BOOL)save:(MissionItemInPlay *)missionItemInPlay;
- (BOOL)deleteAt:(NSString *)missionID playerID:(NSString *)playerID itemID:(int)itemID;
- (BOOL)deleteAt:(NSString *)missionID playerID:(NSString *)playerID;
- (BOOL)delete:(MissionItemInPlay *)missionItemInPlay;
- (NSMutableArray *)selectRand:(NSString *)missionID playerID:(NSString *)playerID;
- (MissionItem *)loadLastAcquiredItem:(NSString *)missionID playerID:(NSString *)playerID;
@end
