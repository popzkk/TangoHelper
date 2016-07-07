#import "THViewController.h"
#import "THView.h"
#import "Classes/THWordsViewController.h"
#import "Classes/Backend/THFileRW.h"

@interface THViewController ()

@end

@implementation THViewController

- (void)loadView {
  self.title = @"Tango Helper";
  self.view = [[THView alloc] initWithFrame:[UIScreen mainScreen].bounds];
}

@end
