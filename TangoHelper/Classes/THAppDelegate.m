#import "THAppDelegate.h"

#import "Backend/THFileCenter.h"
#import "THPlaylistsViewController.h"

#define ADMIN 0

#if (ADMIN)
#import "Backend/THMetadata.h"
#import "Backend/THFileCenter.h"
#import "Backend/THFileRW.h"
#import "Backend/THDepot.h"
#import "Backend/THPlaylist.h"
#import "Backend/THWord.h"

#define START_DATE [NSDate dateWithTimeIntervalSince1970:1456676400]

@interface THMetadata ()

- (void)setObject:(NSDate *)object forKey:(THMetadataKey)key;

@end

#endif  // ADMIN

static NSTimeInterval thres = 30 * 60;

@implementation THAppDelegate {
  NSDate *_lastTimeStamp;
}

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#if (ADMIN)
  NSString *path = [THFileCenter sharedInstance].directoryPath;
  NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
  /*
  id removeOtherFiles = ^(id obj, NSUInteger idx, BOOL *stop) {
    NSString *filename = (NSString *)obj;
    NSString *extension = filename.pathExtension;
    if (![filename isEqualToString:@"depot"] && ![extension isEqualToString:@"playlist"]) {
      NSLog(@"removing '%@'", filename);
      [[NSFileManager defaultManager]
          removeItemAtPath:[path stringByAppendingPathComponent:filename]
                     error:nil];
    }
  };
   */
  id transformFileFormatBlock = ^(id obj, NSUInteger idx, BOOL *stop) {
    NSString *filename = (NSString *)obj;
    NSString *fullPath = [path stringByAppendingPathComponent:filename];
    NSDictionary *oldContent = [NSDictionary dictionaryWithContentsOfFile:fullPath];
    NSMutableDictionary *newContent = [NSMutableDictionary dictionaryWithCapacity:oldContent.count];
    for (NSString *oldKey in oldContent) {
      NSString *newKey = [oldKey stringByReplacingOccurrencesOfString:@"「" withString:@"\\"];
      newKey = [newKey stringByReplacingOccurrencesOfString:@"」" withString:@""];
      NSString *explanation = [oldContent objectForKey:oldKey];
      THWordObject *object = [[THWordObject alloc] initWithExplanation:explanation];
      [object.metadata setObject:START_DATE forKey:THMetadataKeyCreated];
      [newContent setObject:object.outputPropertyList forKey:newKey];
    }
    THMetadata *metadata = [[THMetadata alloc] init];
    [metadata setObject:START_DATE forKey:THMetadataKeyCreated];
    NSDictionary *file = @{@"metadata":metadata.outputPropertyList, @"content":newContent};
    [file writeToFile:fullPath atomically:YES];
  };

  for (NSString *family in [[UIFont familyNames] sortedArrayUsingSelector:@selector(compare:)]) {
    NSLog(@"%@", family);
    for (NSString *name in
         [[UIFont fontNamesForFamilyName:family] sortedArrayUsingSelector:@selector(compare:)]) {
      NSLog(@"  %@", name);
    }
  }
  exit(0);

  [files enumerateObjectsUsingBlock:transformFileFormatBlock];
  exit(0);
#endif  // ADMIN
  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  self.window.rootViewController = [[UINavigationController alloc]
      initWithRootViewController:[[THPlaylistsViewController alloc] init]];
  self.window.backgroundColor = [UIColor whiteColor];
  [self.window makeKeyAndVisible];
  return YES;
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
  [[THFileCenter sharedInstance] flushAll];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  if (_lastTimeStamp && [_lastTimeStamp timeIntervalSinceNow] < -thres) {
    [[THFileCenter sharedInstance] flushAll];
  }
  _lastTimeStamp = [NSDate date];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  if (_lastTimeStamp && [_lastTimeStamp timeIntervalSinceNow] < -thres) {
    [[THFileCenter sharedInstance] flushAll];
  }
  _lastTimeStamp = [NSDate date];
}

- (void)applicationWillTerminate:(UIApplication *)application {
  [[THFileCenter sharedInstance] flushAll];
}

@end
