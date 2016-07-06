#import "THPlaylistsViewController.h"
#import "Shared/THMultiPortionsView.h"
#import "Backend/THFileRW.h"

@interface THPlaylistsViewController ()<THMultiPortionsViewDelegate>

@end

static CGFloat kPadding = 15;
static CGFloat kPlaylistPreviewHeight = 35;
static CGFloat kBottomBarHeight = 40;

static NSString *kToDepot = @"To depot";
static NSString *kAdd = @"Add";
static NSString *kGoWithSelected = @"Go with selected";

@implementation THPlaylistsViewController {
  BOOL _somePlaylistSelected;
  UIScrollView *_scrollView;
  UILabel *_left, *_right;
  THMultiPortionsView *_actions;
  NSMutableArray *_playlists;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
  _somePlaylistSelected = NO;
  _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];

  NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
  NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
  _playlists = [NSMutableArray array];
  //NSMutableArray *lists = [NSMutableArray array];
  [files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSString *filename = (NSString *)obj;
    NSString *extension = [filename.pathExtension lowercaseString];
    if ([extension isEqualToString:@"list"]) {
      UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
      label.text = filename;
      label.tag = idx;
      [_scrollView addSubview:label];
      [_playlists addObject:[THFileRW instanceForFilename:filename]];
      //[lists addObject:filename];
    }
  }];

  [self.view addSubview:_scrollView];

  _left = [[UILabel alloc] initWithFrame:CGRectZero];
  _left.textAlignment = NSTextAlignmentCenter;
  _left.numberOfLines = 0;
  _right = [[UILabel alloc] initWithFrame:CGRectZero];
  _right.textAlignment = NSTextAlignmentCenter;
  _right.numberOfLines = 0;
  _actions = [[THMultiPortionsView alloc] initWithFrame:CGRectZero portions:@[ _left, _right ]];
  _actions.delegate = self;
  [self.view addSubview:_actions];

  _left.text = kToDepot;
  _right.text = kAdd;
}

- (void)viewWillLayoutSubviews {
  CGRect frame = self.view.bounds;
  CGFloat width = frame.size.width - 2 * kPadding;
  _scrollView.frame = CGRectMake(kPadding, kPadding, width, frame.size.height - 2 * kPadding - kBottomBarHeight);
  CGFloat h = 0;
  for (UIView *view in _scrollView.subviews) {
    view.frame = CGRectMake(0, h, width, kPlaylistPreviewHeight);
    h += kPlaylistPreviewHeight;
  }
  _scrollView.contentSize = CGSizeMake(width, h - kPlaylistPreviewHeight);
  _actions.frame = CGRectMake(kPadding, frame.size.height - kPadding - kBottomBarHeight, width, kBottomBarHeight);
}

#pragma mark - THMultiPortionsViewDelegate

- (void)portion:(UIView *)portion isTappedInView:(UIView *)view {
  if (view == _actions) {
    if (portion == _left) {
      NSLog(@"Will go to depot");
    } else {
      if (_somePlaylistSelected) {
        NSLog(@"Will go with selected playlists");
      } else {
        NSLog(@"Will add a playlist");
      }
    }
  } else {
    NSLog(@"Will show %@", ((THFileRW *)[_playlists objectAtIndex:view.tag]).filename);
  }
}

@end
