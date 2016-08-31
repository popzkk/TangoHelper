#import "THFileRW.h"

@interface THPlaylist : THFileRW

@property(nonatomic, readonly) NSString *partialName;

@property(nonatomic, readonly) NSString *desc;

- (NSString *)descWithString:(NSString *)string;

- (void)willPlay;

- (void)didPass;

- (void)didFinish;

@end
