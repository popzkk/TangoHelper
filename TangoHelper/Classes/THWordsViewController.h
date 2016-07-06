#import <UIKit/UIKit.h>

@class THFileRW;

@interface THWordsViewController : UIViewController

// a nil playlist indicates showing the depot; otherwise, showDepot means whether it is a request to
// add words from depot to the playlist or showing the content of the playlist.
- (instancetype)initWithDepot:(THFileRW *)depot
                     playlist:(THFileRW *)playlist;

@end
