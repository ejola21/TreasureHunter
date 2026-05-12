#import <Foundation/Foundation.h>
#import "BaseDao.h"
#import "MissionInPlay.h"

@interface MissionInPlayDao : BaseDao {
}

- (NSMutableArray *)selectAll;
- (MissionInPlay *)selectWithPK:(NSString *)missionID playerID:(NSString *)playerID;
- (BOOL)missionStarted:(NSString *)missionID playerID:(NSString *)playerID;
- (BOOL)insert:(MissionInPlay *)missionInPlay;
- (BOOL)update:(MissionInPlay *)missionInPlay;
- (BOOL)save:(MissionInPlay *)missionInPlay;
- (BOOL)deleteAt:(NSString *)missionID playerID:(NSString *)playerID;
- (BOOL)delete:(MissionInPlay *)missionInPlay;
@end
