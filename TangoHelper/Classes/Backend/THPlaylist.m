#import "THPlaylist.h"

#import "THMetadata.h"
#import "THWord.h"

@interface THMetadata ()

- (void)setObject:(NSDate *)object forKey:(THMetadataKey)key;

@end

@implementation THPlaylist

- (NSString *)partialName {
  return [self.filename stringByDeletingPathExtension];
}

- (NSString *)desc {
  return @"";
}

- (NSString *)descWithString:(NSString *)string {
  NSArray<THWordKey *> *matchingKeys = [self searchWithString:string];
  if (!matchingKeys.count) {
    return @"";
  }
  NSMutableString *desc = [NSMutableString stringWithString:@""];
  for (THWordKey *key in matchingKeys) {
    THWordObject *object = [self objectForKey:key];
    if ([object.explanation containsString:string]) {
      [desc appendFormat:@"{%@ :: %@} ", key.contentForDisplay, object.explanation];
    } else {
      [desc appendFormat:@"{%@} ", key.contentForDisplay];
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
