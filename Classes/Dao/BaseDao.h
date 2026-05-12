#import <Foundation/Foundation.h>

@class FMDatabase;

@interface BaseDao : NSObject {
  FMDatabase *db;
}

@property (nonatomic, retain) FMDatabase *db;

-(NSString *)setTable:(NSString *)sql;

@end
