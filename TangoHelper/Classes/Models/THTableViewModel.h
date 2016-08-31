#import <UIKit/UIKit.h>

#import "../Shared/THHelpers.h"

@class THWordsCollection;

@protocol THTableViewModelDelegate

- (void)globalCheckFailedWithHints:(NSArray<NSString *> *)hints
                    positiveAction:(THAlertBasicAction)positiveAction;

// tells the delegate to reload the table view.
- (void)modelDidGetUpdated;

- (void)modelDidAddAtRow:(NSUInteger)row;

- (void)modelDidModifyAtRow:(NSUInteger)row;

- (void)modelDidRemoveRows:(NSIndexSet *)rows;

@end

@protocol THTableViewModel

@property(nonatomic, weak) id<THTableViewModelDelegate> delegate;

- (void)reload;

- (NSUInteger)numberOfRows;

// text for the textLabel of the cell
- (NSString *)textAtRow:(NSUInteger)row;

// text for the detailTextLabel of the cell
- (NSString *)detailTextAtRow:(NSUInteger)row;

- (void)filterContentWithString:(NSString *)string ignoresEmptyString:(BOOL)ignoresEmptyString;

// convenient method with a nil content
- (void)add:(NSArray<NSString *> *)texts globalCheck:(BOOL)globalCheck;

// the user wants to add a row (a word or a playlist)
// content means a words collection of the new playlist
- (void)add:(NSArray<NSString *> *)texts content:(id)content globalCheck:(BOOL)globalCheck;

// the user wants to remove row(s)
- (void)remove:(NSIndexSet *)rows;

// texts for modifying a row (editting a word or renaming a playlist)
- (NSArray<NSString *> *)textsForModifyingRow:(NSUInteger)row;

// the user modifies the row with some texts
- (void)modifyRow:(NSUInteger)row
        withTexts:(NSArray<NSString *> *)texts
      globalCheck:(BOOL)globalCheck;

// structed string of metadata
- (NSString *)infoOfRow:(NSUInteger)row;

// returns the merged collection of selected (pre-selected is not included)
- (THWordsCollection *)mergedContentOfRows:(NSIndexSet *)rows;

// the user taps at a row, and this model can return an object to let the delegate init a
// ViewController with it. (Playlists -> one playlist)
- (id)itemAtRow:(NSUInteger)row;

- (NSArray *)itemsAtRows:(NSIndexSet *)rows;

- (NSSet *)allItems;

@optional

- (NSString *)accessibilityLabelAtRow:(NSUInteger)row;

@end
