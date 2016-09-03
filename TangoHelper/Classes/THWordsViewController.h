#import "THBasicTableViewController.h"

#import "Models/THWordsViewModel.h"

@class THWordKey;
@class THWordsCollection;

@interface THWordsViewController : THBasicTableViewController<THWordsViewModelDelegate>

- (instancetype)initWithCollection:(THWordsCollection *)collection;

- (instancetype)initWithCollection:(THWordsCollection *)collection
                      searchString:(NSString *)searchString;

- (instancetype)initWithCollection:(THWordsCollection *)collection
                       preSelected:(NSArray<THWordKey *> *)preSelected
                             title:(NSString *)title
                      searchString:(NSString *)searchString
                       cancelBlock:(THTableViewCancelBlock)executionBlock
                      confirmBlock:(THTableViewConfirmBlock)confirmBlock;

@end
