#import <Foundation/Foundation.h>

@class THPlaylist;
@class UIAlertController;

@interface THPlayConfig : NSObject<NSCopying>

@property(nonatomic, assign) NSUInteger repeat;

@property(nonatomic, assign) BOOL lazyAssert;

// (0, 1] means portions, > 1 means the exact number.
@property(nonatomic, assign) double portion;

@end

@interface THPlayResult : NSObject

@property(nonatomic) NSSet *errors;

@end

@protocol THPlayManagerDelegate<NSObject>

- (void)showWithText:(NSString *)text;

- (void)showAlert:(UIAlertController *)alert;

- (void)playFinishedWithResult:(THPlayResult *)result;

@end

@interface THPlayManager : NSObject

@property(nonatomic, readonly) THPlaylist *playlist;

@property(nonatomic, readonly) THPlayConfig *config;

@property(nonatomic, readonly) BOOL isPlaying;

- (instancetype)initWithPlaylist:(THPlaylist *)playlist
                          config:(THPlayConfig *)config
                        delegate:(id<THPlayManagerDelegate>)delegate;

- (void)start;

- (void)commitInput:(NSString *)input;

@end
