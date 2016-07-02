#ifndef THKeyboardJaConstants_h
#define THKeyboardJaConstants_h

static NSString *hiragana_original = @"あいうえお"
                                      "かきくけこ"
                                      "さしすせそ"
                                      "たちつてと"
                                      "なにぬねの"
                                      "はひふへほ"
                                      "まみむめも"
                                      "や「ゆ」よ"
                                      "らりるれろ"
                                      "わをんー";

static NSString *katakana_original = @"アイウエオ"
                                      "カキクケコ"
                                      "サシスセソ"
                                      "タチツテト"
                                      "ナニヌネノ"
                                      "ハヒフヘホ"
                                      "マミムメモ"
                                      "ヤ「ユ」ヨ"
                                      "ラリルレロ"
                                      "ワヲンー";

// static NSUInteger small_indexes[] = {0, 1, 2, 3, 4, 17, 35, 37, 39, 45};
static NSString *hiragana_small = @"ぁぃぅぇぉ"
                                   "かきくけこ"
                                   "さしすせそ"
                                   "たちってと"
                                   "なにぬねの"
                                   "はひふへほ"
                                   "まみむめも"
                                   "ゃ「ゅ」ょ"
                                   "らりるれろ"
                                   "ゎをん";

static NSString *katakana_small = @"ァィゥェォ"
                                   "カキクケコ"
                                   "サシスセソ"
                                   "タチッテト"
                                   "ナニヌネノ"
                                   "ハヒフヘホ"
                                   "マミムメモ"
                                   "ャ「ュ」ョ"
                                   "ラリルレロ"
                                   "ヮヲンー";

/*
static NSUInteger dakuten_indexes[] = {
    4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 25, 26, 27, 28, 29,
};
 */
static NSString *hiragana_dakuten = @"あいゔえお"
                                     "がぎぐげご"
                                     "ざじずぜぞ"
                                     "だぢづでど"
                                     "なにぬねの"
                                     "ばびぶべぼ"
                                     "まみむめも"
                                     "や「ゆ」よ"
                                     "らりるれろ"
                                     "わをん";

static NSString *katakana_dakuten = @"アイヴエオ"
                                     "ガギグゲゴ"
                                     "ザジズゼゾ"
                                     "ダヂヅデド"
                                     "ナニヌネノ"
                                     "バビブベボ"
                                     "マミムメモ"
                                     "ヤ「ユ」ヨ"
                                     "ラリルレロ"
                                     "ワヲンー";

// NSUInteger handakuten_indexes[] = {25, 26, 27, 28, 29};
static NSString *hiragana_handakuten = @"あいうえお"
                                        "かきくけこ"
                                        "さしすせそ"
                                        "たちつてと"
                                        "なにぬねの"
                                        "ぱぴぷぺぽ"
                                        "まみむめも"
                                        "や「ゆ」よ"
                                        "らりるれろ"
                                        "わをん";

static NSString *katakana_handakuten = @"アイウエオ"
                                        "カキクケコ"
                                        "サシスセソ"
                                        "タチツテト"
                                        "ナニヌネノ"
                                        "パピプペポ"
                                        "マミムメモ"
                                        "ヤ「ユ」ヨ"
                                        "ラリルレロ"
                                        "ワヲンー";

#endif /* THKeyboardJaConstants_h */
