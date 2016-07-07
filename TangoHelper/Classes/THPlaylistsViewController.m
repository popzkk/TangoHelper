#import "THPlaylistsViewController.h"
#import "Shared/THMultiPortionsView.h"
#import "Shared/THItemView.h"
#import "Backend/THFileRW.h"

static CGFloat kPadding = 15;
static CGFloat kPlaylistPreviewHeight = 35;
static CGFloat kBottomBarHeight = 40;

static NSString *kToDepot = @"To depot";
static NSString *kAdd = @"Add";
static NSString *kGoWithSelected = @"Go with selected";

@interface THPlaylistPreview : UILabel

- (instancetype)initWithFrame:(CGRect)frame name:(NSString *)name;

@end

#pragma mark - THPlaylistsViewController

@interface THPlaylistsViewController ()<THMultiPortionsViewDelegate>

@end

@implementation THPlaylistsViewController {
  UIScrollView *_scrollView;
  UILabel *_left, *_right;
  THMultiPortionsView *_actions;
  NSMutableArray *_playlists;
  NSMutableSet *_selectedPlaylists;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
  _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];

  NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
  NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
  _playlists = [NSMutableArray array];
  [files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSString *filename = (NSString *)obj;
    NSString *extension = [filename.pathExtension lowercaseString];
    if ([extension isEqualToString:@"list"]) {
      [_playlists addObject:[THFileRW instanceForFilename:filename]];
      filename = filename.stringByDeletingPathExtension;
      THPlaylistPreview *preview = [[THPlaylistPreview alloc] initWithFrame:CGRectZero name:filename];
      THItemView *view = [[THItemView alloc] initWithFrame:CGRectZero view:preview];
      view.tag = idx;
      view.delegate = self;
      [_scrollView addSubview:view];
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

  _selectedPlaylists = [NSMutableSet set];
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
      if (_selectedPlaylists.count > 0) {
        NSLog(@"Will go with selected playlists %@", _selectedPlaylists);
      } else {
        NSLog(@"Will add a playlist");
      }
    }
  } else {
    if (portion.tag == 1) {
      NSLog(@"Will show %@", ((THFileRW *)[_playlists objectAtIndex:view.tag]).filename);
    } else {
      if (((THItemView *)view).selected) {
        [_selectedPlaylists removeObject:[_playlists objectAtIndex:view.tag]];
        if (_selectedPlaylists.count == 0) {
          _right.text = kAdd;
        }
      } else {
        if (_selectedPlaylists.count == 0) {
          _right.text = kGoWithSelected;
        }
        [_selectedPlaylists addObject:[_playlists objectAtIndex:view.tag]];
      }
      [((THItemView *)view) toggle];
    }
  }
}

@end

#pragma mark - THPlaylistPreview

@implementation THPlaylistPreview

- (instancetype)initWithFrame:(CGRect)frame name:(NSString *)name {
  self = [super initWithFrame:frame];
  if (self) {
    self.text = name;
  }
  return self;
}

@end
