#import "THPlaylist.h"

#import "THMetadata.h"
#import "THWord.h"

/** TODO
 * add desc.
 */

@interface THMetadata ()

- (void)setObject:(NSDate *)object forKey:(THMetadataKey)key;

@end

@implementation THPlaylist

- (NSString *)partialName {
  return [super.filename stringByDeletingPathExtension];
}

- (NSString *)desc {
  return @"";
}

- (NSString *)descWithString:(NSString *)string {
  NSMutableString *desc = [NSMutableString string];
  NSArray<THWordKey *> *matchingKeys = [self searchWithString:string];
  for (THWordKey *key in matchingKeys) {
    THWordObject *object = [self objectForKey:key];
    if ([object.explanation containsString:string]) {
      [desc appendString:[NSString stringWithFormat:@"%@: %@ | ", key.contentForDisplay, object.explanation]];
    } else {
      [desc appendString:[NSString stringWithFormat:@"%@ | ", key.contentForDisplay]];
    }
  }
  return desc;
}

- (void)willPlay {
  [self.metadata setObject:[NSDate date] forKey:THMetadataKeyPlayed];
}

- (void)didPass {
  [self didFinish];
  [self.metadata setObject:[NSDate date] forKey:THMetadataKeyPassed];
}

- (void)didFinish {
  [self.metadata setObject:[NSDate date] forKey:THMetadataKeyFinished];
}

@end
