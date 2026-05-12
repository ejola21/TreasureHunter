#import <Foundation/Foundation.h>
#import "BaseDao.h"
#import "MissionItem.h"

@interface MissionItemDao : BaseDao {
}

-(NSMutableArray *)selectAt:(NSString *)missionID;
-(MissionItem *)selectWithPK:(NSString *)missionID ItemID:(int)itemID;
-(BOOL)insert:(MissionItem *)missionItem;
-(BOOL)update:(MissionItem *)missionItem;
-(BOOL)delete:(MissionItem *)missionItem;
-(BOOL)save:(MissionItem *)missionItem;
-(int)selecAtMaxItemID:(NSMutableString *)missionID;
-(BOOL)startItemExists:(NSString *)missionID;
@end
