#ifndef THKeyboardJaChar_h
#define THKeyboardJaChar_h

NSString *hiragana = @"あいうえお"
                      "かきくけこ"
                      "さしすせそ"
                      "たちつてと"
                      "なにぬねの"
                      "はひふへほ"
                      "まみむめも"
                      "や「ゆ」よ"
                      "らりるれろ"
                      "わをん";

NSString *katakana = @"アイウエオ"
                      "カキクケコ"
                      "サシスセソ"
                      "タチツテト"
                      "ナニヌネノ"
                      "ハヒフヘホ"
                      "マミムメモ"
                      "ヤ「ユ」ヨ"
                      "ラリルレロ"
                      "ワヲンー";

NSUInteger small_indexes[] = {0, 1, 2, 3, 4, 17, 35, 37, 39, 45};
NSString *hiragana_small = @"ぁぃぅぇぉ"
                            "っ"
                            "ゃゅょ"
                            "ゎ";
NSString *katakana_small = @"ァィゥェォ"
                            "ッ"
                            "ャュョ"
                            "ヮ";

NSUInteger dakuten_indexes[] = {
    4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 25, 26, 27, 28, 29,
};
NSString *hiragana_dakuten = @"ゔ"
                              "がぎぐげご"
                              "ざじずぜぞ"
                              "だぢづでど"
                              "ばびぶべぼ";
NSString *katakana_dakuten = @"ヴ"
                              "ガギグゲゴ"
                              "ザジズゼゾ"
                              "ダヂヅデド"
                              "バビブベボ";

NSUInteger handakuten_indexes[] = {25, 26, 27, 28, 29};
NSString *hiragana_handakuten = @"ぱぴぷぺぽ";
NSString *katakana_handakuten = @"パピプペポ";

#endif
