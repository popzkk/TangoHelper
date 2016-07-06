#import "THWordsViewController.h"
#import "Backend/THFileRW.h"
#import "Shared/THMultiPortionsView.h"
#import "Shared/THWordPreview.h"

static CGFloat kPadding = 15;
static CGFloat kWordPreviewHeight = 35;
static CGFloat kBottomBarHeight = 40;

static NSString *kRemove = @"Remove";
static NSString *kAdd = @"Add";
static NSString *kAddToList = @"Add to list";
static NSString *kGoWithSelected = @"Go with selected";

@interface THWordsViewController ()<THMultiPortionsViewDelegate>

@end

@implementation THWordsViewController {
  THFileRW *_depot;
  THFileRW *_playlist;
  NSArray *_keys;
  NSArray *_objects;

  UIScrollView *_scrollView;
  UILabel *_left, *_middle, *_right;
  THMultiPortionsView *_actions;

  NSMutableSet *_newKeys;
}

- (instancetype)initWithDepot:(THFileRW *)depot
                     playlist:(THFileRW *)playlist {
  self = [super init];
  if (self) {
    _depot = depot;
    _playlist = playlist;
  }
  return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
  _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
  if (_depot) {
    _keys = [_depot allKeys];
    _objects = [_depot objectsForKeys:_keys];
    for (NSUInteger i = 0; i < _keys.count; ++i) {
      NSString *key = [_keys objectAtIndex:i];
      THWordPreview *view = [[THWordPreview alloc] initWithFrame:CGRectZero key:key object:[_objects objectAtIndex:i]];
      if ([_playlist objectForKey:key]) {
        view.selected = YES;
        view.canToggle = NO;
      }
      view.tag = i;
      view.delegate = self;
      [_scrollView addSubview:view];
    }
  } else {
    _keys = [_playlist allKeys];
    _objects = [_playlist objectsForKeys:_keys];
    for (NSUInteger i = 0; i < _keys.count; ++i) {
      THWordPreview *view = [[THWordPreview alloc] initWithFrame:CGRectZero key:[_keys objectAtIndex:i] object:[_objects objectAtIndex:i]];
      view.tag = i;
      view.delegate = self;
      [_scrollView addSubview:view];
    }
  }
  [self.view addSubview:_scrollView];

  _left = [[UILabel alloc] initWithFrame:CGRectZero];
  _left.textAlignment = NSTextAlignmentCenter;
  _left.numberOfLines = 0;
  _middle = [[UILabel alloc] initWithFrame:CGRectZero];
  _middle.textAlignment = NSTextAlignmentCenter;
  _middle.numberOfLines = 0;
  _right = [[UILabel alloc] initWithFrame:CGRectZero];
  _right.textAlignment = NSTextAlignmentCenter;
  _right.numberOfLines = 0;
  _actions = [[THMultiPortionsView alloc] initWithFrame:CGRectZero portions:@[ _left, _middle, _right ]];
  _actions.delegate = self;
  [self.view addSubview:_actions];

  if (_depot) {
    if (_playlist) {
      _left.text = @"";
      _middle.text = kAdd;
      _right.text = kAddToList;
    } else {
      _left.text = kRemove;
      _middle.text = kAdd;
      _right.text = kGoWithSelected;
    }
  } else {
    _left.text = kRemove;
    _middle.text = kAdd;
    _right.text = kGoWithSelected;
  }
  _newKeys = [NSMutableSet set];
}

- (void)viewWillLayoutSubviews {
  CGRect frame = self.view.bounds;
  CGFloat width = frame.size.width - 2 * kPadding;
  _scrollView.frame = CGRectMake(kPadding, kPadding, width, frame.size.height - 2 * kPadding - kBottomBarHeight);
  CGFloat h = 0;
  for (UIView *view in _scrollView.subviews) {
    view.frame = CGRectMake(0, h, width, kWordPreviewHeight);
    h += kWordPreviewHeight;
  }
  _scrollView.contentSize = CGSizeMake(width, h - kWordPreviewHeight);
  _actions.frame = CGRectMake(kPadding, frame.size.height - kPadding - kBottomBarHeight, width, kBottomBarHeight);
}

#pragma mark - THMultiPortionsViewDelegate

- (void)portion:(UIView *)portion isTappedInView:(UIView *)view {
  if (view == _actions) {
    if (portion == _left) {
      NSLog(@"Will delete: %@", _newKeys);
    } else if (portion == _right) {
      NSLog(@"Chosen: %@", _newKeys);
    } else {
      NSLog(@"middle tapped");
    }
  } else {
    if (portion.tag == 1) {
      NSLog(@"word [%@] tapped", ((UILabel *)portion).text);
    } else {
      if (((THWordPreview *)view).selected) {
        [_newKeys removeObject:[_keys objectAtIndex:view.tag]];
      } else {
        [_newKeys addObject:[_keys objectAtIndex:view.tag]];
      }
      [((THWordPreview *)view) toggle];
    }
  }
}

@end
