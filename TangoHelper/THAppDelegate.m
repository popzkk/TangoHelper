#import "THAppDelegate.h"

#import "Classes/Backend/THFileCenter.h"
#import "Classes/THPlaylistsViewController.h"

#define ADMIN_

#ifdef ADMIN
#import "Classes/Backend/THFileCenter.h"
#import "Classes/Backend/THFileRW.h"
#import "Classes/Backend/THDepot.h"
#import "Classes/Backend/THPlaylist.h"
#endif  // ADMIN

@implementation THAppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#ifdef ADMIN
  NSString *path = [THFileCenter sharedInstance].directoryPath;
  NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
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
  id changeWordKeyFormatBlock = ^(id obj, NSUInteger idx, BOOL *stop) {
    NSString *filename = (NSString *)obj;
    NSString *fullPath = [path stringByAppendingPathComponent:filename];
    NSMutableDictionary *oldContent = [NSMutableDictionary dictionaryWithContentsOfFile:fullPath];
    NSMutableDictionary *newContent = [NSMutableDictionary dictionaryWithCapacity:oldContent.count];
    for (NSString *oldKey in oldContent.allKeys) {
      NSString *newKey = [oldKey stringByReplacingOccurrencesOfString:@"〈" withString:@"「"];
      newKey = [newKey stringByReplacingOccurrencesOfString:@"〉" withString:@"」"];
      [newContent setObject:[oldContent objectForKey:oldKey] forKey:newKey];
    }
    [newContent writeToFile:fullPath atomically:YES];
  };
  [files enumerateObjectsUsingBlock:changeWordKeyFormatBlock];
  exit(0);
#endif  // ADMIN

  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  self.window.rootViewController = [[UINavigationController alloc]
      initWithRootViewController:[[THPlaylistsViewController alloc] init]];
  self.window.backgroundColor = [UIColor whiteColor];
  [self.window makeKeyAndVisible];
  return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  [[THFileCenter sharedInstance] flushAll];
}

- (void)applicationWillTerminate:(UIApplication *)application {
  [[THFileCenter sharedInstance] flushAll];
}

@end
