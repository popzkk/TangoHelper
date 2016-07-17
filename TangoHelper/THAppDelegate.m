#import "THAppDelegate.h"

#import "THViewController.h"
#import "Classes/THWordsViewController.h"
#import "Classes/THPlaylistsViewController.h"
#import "Classes/Backend/THFileCenter.h"
#import "Classes/Backend/THDepot.h"
#import "Classes/THWordsViewController.h"

@implementation THAppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  /*
  NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,
  YES).firstObject;
  NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
  [files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSString *filename = (NSString *)obj;
    if (![filename isEqualToString:@"test.depot"]) {
      [[NSFileManager defaultManager] removeItemAtPath:[path
  stringByAppendingPathComponent:filename] error:nil];
    }
  }];
  exit(0);
   */
  /*
  THDepot *depot = [[THFileCenter sharedInstance] depot];
  for (NSUInteger i = 0; i < 20; ++i) {
    [depot setObject:[NSString stringWithFormat:@"explanation%lu", (unsigned long)i]
  forKey:[NSString stringWithFormat:@"word%lu", (unsigned long)i]];
  }
  [depot flush];
  exit(0);
   */

  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  UINavigationController *navController = [[UINavigationController alloc]
      initWithRootViewController:[[THPlaylistsViewController alloc] init]];
  navController.toolbarHidden = NO;
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
