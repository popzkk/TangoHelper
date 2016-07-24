#import "THAppDelegate.h"

#import "Classes/Backend/THFileCenter.h"
#import "Classes/THPlaylistsViewController.h"

#define CLEANUP_

#if defined(CLEANUP)
#import "THFileCenter.h"
#import "THDepot.h"
#endif

@implementation THAppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#ifdef CLEANUP
  NSString *path = [THFileCenter sharedInstance].directoryPath;
  NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
  [files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSString *filename = (NSString *)obj;
    NSString *extension = filename.pathExtension;
    if (![filename isEqualToString:@"depot"] && ![extension isEqualToString:@"playlist"]) {
      NSLog(@"removing '%@'", filename);
      [[NSFileManager defaultManager]
          removeItemAtPath:[path stringByAppendingPathComponent:filename]
                     error:nil];
    }
  }];
  exit(0);
#endif  // CLEANUP

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
