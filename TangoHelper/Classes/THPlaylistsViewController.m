#import "THPlaylistsViewController.h"
#import "THWordsViewController.h"
#import "Shared/THMultiPortionsView.h"
#import "Shared/THItemView.h"
#import "Backend/THFileRW.h"
#import "THWordsViewController.h"

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

- (instancetype)init {
  self = [super init];
  if (self) {
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
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
  return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
  NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
  NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
  _playlists = [NSMutableArray array];
  __block NSUInteger index = 1;
  [files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSString *fullname = (NSString *)obj;
    NSString *extension = [fullname.pathExtension lowercaseString];
    if ([extension isEqualToString:@"list"]) {
      [self addPlaylistWithFilename:fullname.stringByDeletingPathExtension index:index++];
    }
  }];

  _selectedPlaylists = [NSMutableSet set];
}

- (void)viewWillLayoutSubviews {
  CGRect frame = self.view.bounds;
  CGFloat width = frame.size.width - 2 * kPadding;
  _scrollView.frame = CGRectMake(kPadding, kPadding, width, frame.size.height - 2 * kPadding - kBottomBarHeight);
  _actions.frame = CGRectMake(kPadding, frame.size.height - kPadding - kBottomBarHeight, width, kBottomBarHeight);
  [self layoutScrollView];
}

#pragma mark - THMultiPortionsViewDelegate

- (void)portion:(UIView *)portion isTappedInView:(UIView *)view {
  if (view == _actions) {
    if (portion == _left) {
      NSLog(@"Will go to depot");
      [self.navigationController pushViewController:[[THWordsViewController alloc] initUsingDepot] animated:YES];
    } else {
      if (_selectedPlaylists.count > 0) {
        NSLog(@"Will go with selected playlists %@", _selectedPlaylists);
      } else {
        NSLog(@"Will add a playlist");
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add a playlist" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Next" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
          NSString *filename = alert.textFields.firstObject.text;
          [self addPlaylistWithFilename:filename index:_playlists.count + 1];
          [self layoutScrollView];
          [self.navigationController pushViewController:[[THWordsViewController alloc] initUsingDepotWithPlaylist:[THFileRW instanceForFilename:[filename stringByAppendingString:@".list"]]] animated:YES];
        }]];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
          textField.placeholder = @"Playlist name";
        }];
        [self presentViewController:alert animated:YES completion:nil];
      }
    }
  } else {
    if (portion.tag == 1) {
      NSLog(@"Will show %@", [self playlistForView:view].filename);
      [self.navigationController pushViewController:[[THWordsViewController alloc] initWithPlaylist:[self playlistForView:view]] animated:YES];
    } else {
      if (((THItemView *)view).selected) {
        [_selectedPlaylists removeObject:[self playlistForView:view]];
        if (_selectedPlaylists.count == 0) {
          _right.text = kAdd;
        }
      } else {
        if (_selectedPlaylists.count == 0) {
          _right.text = kGoWithSelected;
        }
        [_selectedPlaylists addObject:[self playlistForView:view]];
      }
      [((THItemView *)view) toggle];
    }
  }
}

#pragma mark - private

- (void)addPlaylistWithFilename:(NSString *)filename index:(NSUInteger)idx {
  [_playlists addObject:[THFileRW instanceForFilename:[filename stringByAppendingString:@".list"] create:YES]];
  THPlaylistPreview *preview = [[THPlaylistPreview alloc] initWithFrame:CGRectZero name:filename];
  THItemView *view = [[THItemView alloc] initWithFrame:CGRectZero view:preview];
  view.tag = idx;
  view.delegate = self;
  [_scrollView addSubview:view];
}

- (void)layoutScrollView {
  CGFloat h = 0;
  CGFloat width = _scrollView.frame.size.width;
  for (UIView *view in _scrollView.subviews) {
    if (view.tag) {
      view.frame = CGRectMake(0, h, width, kPlaylistPreviewHeight);
      h += kPlaylistPreviewHeight;
    }
  }
  _scrollView.contentSize = CGSizeMake(width, h);
}

- (THFileRW *)playlistForView:(UIView *)view {
  return [_playlists objectAtIndex:view.tag - 1];
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
