#import "THAppDelegate.h"

#import "Classes/Backend/THFileCenter.h"
#import "Classes/THPlaylistsViewController.h"

#define SETUP_
#define CLEANUP_

#if defined(CLEANUP) || defined(SETUP)
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

#ifdef SETUP
  THDepot *depot = [[THFileCenter sharedInstance] depot];
  for (NSUInteger i = 0; i < 20; ++i) {
    [depot setObject:[NSString stringWithFormat:@"explanation%lu", (unsigned long)i]
              forKey:[NSString stringWithFormat:@"word%lu", (unsigned long)i]];
  }
  [depot flush];
  exit(0);
#endif  // SETUP

  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  UINavigationController *navController = [[UINavigationController alloc]
      initWithRootViewController:[[THPlaylistsViewController alloc] init]];
  self.window.rootViewController = navController;
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
