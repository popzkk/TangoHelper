#import "THAppDelegate.h"

#import "THViewController.h"
#import "Classes/THWordsViewController.h"
#import "Classes/THPlaylistsViewController.h"
#import "Classes/Backend/THFileCenter.h"
#import "Classes/THWordsViewController.h"

@implementation THAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
/*
  for (NSUInteger i = 2; i < 4; ++i) {
    NSString *filename = [NSString stringWithFormat:@"list%lu.list", i];
    THFileRW *fileRW = [THFileRW instanceForFilename:filename create:YES];
    for (NSInteger j = 1; j < 10; ++j) {
      if (i * j > 19) {
        break;
      }
      [fileRW setObject:[NSString stringWithFormat:@"explanation%lu", i * j] forKey:[NSString stringWithFormat:@"word%lu", i * j]];
    }
    [fileRW close];
  }
  exit(0);
  */
/*
  NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
  NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
  [files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSString *filename = (NSString *)obj;
    if (![filename isEqualToString:@"test.depot"]) {
      [[NSFileManager defaultManager] removeItemAtPath:[path stringByAppendingPathComponent:filename] error:nil];
    }
  }];
  exit(0);
*/
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  //UIViewController *rootViewController = [[THWordsViewController alloc] initWithDepot:[THFileRW instanceForFilename:@"test.depot"] playlist:nil];
  //UIViewController *rootViewController = [[THPlaylistsViewController alloc] init];
  UIViewController *rootViewController = [[THWordsViewController alloc] initUsingDepot];
  UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
  navController.toolbarHidden = NO;
  self.window.rootViewController = navController;
  self.window.backgroundColor = [UIColor whiteColor];
  [self.window makeKeyAndVisible];
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

  [[THFileCenter sharedInstance] flushAll];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

  [[THFileCenter sharedInstance] flushAll];
}

@end
