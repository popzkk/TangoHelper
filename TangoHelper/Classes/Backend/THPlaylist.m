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
  NSMutableString *desc = [NSMutableString stringWithString:@"|"];
  BOOL first = YES;
  for (THWordKey *key in matchingKeys) {
    THWordObject *object = [self objectForKey:key];
    if (first) {
      first = NO;
    } else {
      [desc appendString:@"_|"];
    }
    if ([object.explanation containsString:string]) {
      [desc appendFormat:@"_%@ : %@", key.contentForDisplay, object.explanation];
    } else {
      [desc appendFormat:@"_%@", key.contentForDisplay];
    }
  }
  [desc appendString:@"_|"];
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
