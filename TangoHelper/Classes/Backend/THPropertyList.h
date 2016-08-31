#import <Foundation/Foundation.h>

// Objects that can init self from and output self as either NSDictionary or NSArray.
@protocol THPropertyList

@property(nonatomic, readonly) id outputPropertyList;

- (instancetype)initWithPropertyList:(id)input;

@end
