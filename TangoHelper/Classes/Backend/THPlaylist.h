#import "THFileRW.h"

@interface THPlaylist : THFileRW

@property(nonatomic, readonly) NSString *partialName;

@property(nonatomic, readonly) NSString *desc;

@end
