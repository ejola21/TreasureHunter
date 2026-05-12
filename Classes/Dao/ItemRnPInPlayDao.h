#import <Foundation/Foundation.h>
#import "BaseDao.h"
#import "ItemRnPInPlay.h"

@interface ItemRnPInPlayDao : BaseDao {
}

- (ItemRnPInPlay *)selectWithPK:(NSString *)missionID playerID:(NSString *)playerID itemType:(NSString *)itemType;
//- (ItemRnPInPlay *)selectByReward:(NSString *)missionID playerID:(NSString *)playerID rewardCode:(NSString *)rewardCode;
- (NSMutableDictionary *)selectDicAt:(NSString *)missionID playerID:(NSString *)playerID;
- (BOOL)rnpTaken:(NSString *)missionID playerID:(NSString *)playerID itemType:(NSString *)itemType;
- (NSMutableArray *)selectAcquiredRnP:(NSString *)missionID playerID:(NSString *)playerID;
- (BOOL)insert:(ItemRnPInPlay *)itemRnPInPlay;
- (BOOL)update:(ItemRnPInPlay *)itemRnPInPlay;
- (BOOL)save:(ItemRnPInPlay *)itemRnPInPlay;
- (BOOL)deleteAt:(NSString *)missionID playerID:(NSString *)playerID itemType:(NSString *)itemType;
- (BOOL)deleteAt:(NSString *)missionID playerID:(NSString *)playerID;
- (BOOL)delete:(ItemRnPInPlay *)itemRnPInPlay;
@end

