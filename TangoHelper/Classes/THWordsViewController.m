#import "THWordsViewController.h"
#import "Backend/THFileRW.h"
#import "Shared/THMultiPortionsView.h"
#import "Shared/THItemView.h"

static CGFloat kPadding = 15;
static CGFloat kWordPreviewHeight = 35;
static CGFloat kBottomBarHeight = 40;

static NSString *kRemove = @"Remove";
static NSString *kAdd = @"Add";
static NSString *kAddToList = @"Add to list";
static NSString *kGoWithSelected = @"Go with selected";

@interface THWordPreview : UIView

- (instancetype)initWithFrame:(CGRect)frame key:(NSString *)key object:(NSString *)object;

- (NSString *)key;

- (NSString *)object;

@end

#pragma mark - THWordsViewController

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

#pragma mark - public

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
      THWordPreview *preview = [[THWordPreview alloc] initWithFrame:CGRectZero key:key object:[_objects objectAtIndex:i]];
      THItemView *view = [[THItemView alloc] initWithFrame:CGRectZero view:preview];
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
      THWordPreview *preview = [[THWordPreview alloc] initWithFrame:CGRectZero key:[_keys objectAtIndex:i] object:[_objects objectAtIndex:i]];
      THItemView *view = [[THItemView alloc] initWithFrame:CGRectZero view:preview];
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
      NSLog(@"word [%@] tapped", ((THWordPreview *)portion).key);
    } else {
      if (((THItemView *)view).selected) {
        [_newKeys removeObject:[_keys objectAtIndex:view.tag]];
      } else {
        [_newKeys addObject:[_keys objectAtIndex:view.tag]];
      }
      [((THItemView *)view) toggle];
    }
  }
}

@end

#pragma mark - THWordPreview

@implementation THWordPreview {
  NSString *_key;
  NSString *_object;
  UILabel *_keyLabel;
  UILabel *_objectLabel;
}

#pragma mark - public

- (instancetype)initWithFrame:(CGRect)frame key:(NSString *)key object:(NSString *)object {
  self = [super initWithFrame:frame];
  if (self) {
    _key = [key copy];
    _object = [object copy];
    _keyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _keyLabel.text = key;
    _objectLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _objectLabel.text = object;
    [self addSubview:_keyLabel];
    [self addSubview:_objectLabel];
  }
  return self;
}

- (NSString *)key {
  return _key;
}

- (NSString *)object {
  return _object;
}

#pragma mark - UIView

- (void)layoutSubviews {
  CGRect frame = self.bounds;
  CGFloat height = frame.size.height / 2;
  _keyLabel.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, height);
  _objectLabel.frame = CGRectMake(frame.origin.x, frame.origin.y + height, frame.size.width, height);
}

@end
