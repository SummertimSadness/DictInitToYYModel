//
//  DictInitToYYModel.m
//  DictInitToYYModel
//
//  Created by Yasin on 16/4/20.
//  Copyright © 2016年 Yasin. All rights reserved.
//

#import "DictInitToYYModel.h"
#import "NSTextView+VVTextGetter.h"
#import "NSString+VVSyntax.h"
#import "VVDocumenter.h"
#import "VVKeyboardEventSender.h"
#import "VVDSettingPanelWindowController.h"
#import "VVDocumenterSetting.h"
#import "VVTextResult.h"

@interface DictInitToYYModel()
@property (nonatomic, strong) id eventMonitor;
@property (nonatomic, assign) BOOL prefixTyped;
@property (nonatomic, strong) VVDSettingPanelWindowController *settingPanel;
@end

@implementation DictInitToYYModel

+(instancetype) sharedPlugin {
    static dispatch_once_t once;
    static id instance = nil;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidFinishLaunching:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
    }
    return self;
}

- (void) applicationDidFinishLaunching: (NSNotification*) noti {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textStorageDidChange:)
                                                 name:NSTextDidChangeNotification
                                               object:nil];
    [self addSettingMenu];
}

-(void) addSettingMenu
{
    NSMenuItem *editMenuItem = [[NSApp mainMenu] itemWithTitle:@"Window"];
    if (editMenuItem) {
        [[editMenuItem submenu] addItem:[NSMenuItem separatorItem]];
        
        NSMenuItem *newMenuItem = [[NSMenuItem alloc] initWithTitle:@"YYDocumenter" action:@selector(showSettingPanel:) keyEquivalent:@""];
        
        [newMenuItem setTarget:self];
        [[editMenuItem submenu] addItem:newMenuItem];
    }
}

-(void) showSettingPanel:(NSNotification *)noti {
    self.settingPanel = [[VVDSettingPanelWindowController alloc] initWithWindowNibName:@"VVDSettingPanelWindowController"];
    [self.settingPanel showWindow:self.settingPanel];
}

- (void) textStorageDidChange:(NSNotification *)noti {
    
    if ([[noti object] isKindOfClass:[NSTextView class]]) {
        NSTextView *textView = (NSTextView *)[noti object];
        VVTextResult *currentLineResult = [textView vv_textResultOfCurrentLine];
        if (currentLineResult) {
            
            //Check if there is a "//" already typed in. We do this to solve the undo issue
            //Otherwise when you press Cmd+Z, "///" will be recognized and trigger the doc inserting, so you can not perform an undo.
            NSString *triggerString = [[VVDocumenterSetting defaultSetting] triggerString];
            
            if (triggerString.length > 1) {
                NSString *preTypeString = [triggerString substringToIndex:triggerString.length - 2];
                self.prefixTyped = [currentLineResult.string vv_matchesPatternRegexPattern:[NSString stringWithFormat:@"^\\s*%@$",[NSRegularExpression escapedPatternForString:preTypeString]]] | self.prefixTyped;
            } else {
                self.prefixTyped = YES;
            }
            
            if ([currentLineResult.string vv_matchesPatternRegexPattern:[NSString stringWithFormat:@"^\\s*%@$",[NSRegularExpression escapedPatternForString:triggerString]]] && self.prefixTyped) {
                VVTextResult *previousLineResult = [textView vv_textResultOfPreviousLine];
                
                // Previous line is a documentation comment, so ignore this
                if ([previousLineResult.string vv_matchesPatternRegexPattern:@"^\\s*///"]) {
                    return;
                }
                
                VVTextResult *nextLineResult = [textView vv_textResultOfNextLine];
                
                // Next line is a documentation comment, so ignore this
                if ([nextLineResult.string vv_matchesPatternRegexPattern:@"^\\s*///"]) {
                    return;
                }
                
                //Get a @"///" (triggerString) typed in by user. Do work!
                self.prefixTyped = NO;
                
                __block BOOL shouldReplace = NO;
                VVTextResult *aBraceEnd = [textView vv_textResultOfPreviousLine];
                VVTextResult *bBraceEnd = [textView vv_textResultOfCurrentLine];
                VVTextResult *cBraceEnd = [textView vv_textResultOfNextLine];
                VVTextResult *dBraceEnd = [textView vv_textResultUntilNextString:@"}"];
                VVTextResult *eBraceEnd = [textView vv_textResultWithPairOpenString:@"{" closeString:@"}"];
                VVTextResult *fBraceEnd = [textView vv_textResultToEndOfFile];
                
                VVTextResult *resultUntilBraceEnd = [textView vv_textResultWithPairOpenString:@"{" closeString:@"}"];
                NSString *inputCode = [resultUntilBraceEnd.string vv_stringByConvertingToUniform];
                
                VVDocumenter *doc = [[VVDocumenter alloc] initWithCode:inputCode];
                NSString *documentationString = [doc document];
                
                if (!documentationString) {
                    //Leave the user's input there.
                    //It might be no need to parse doc or something wrong.
                    return;
                }
                
                //Now we are using a simulation of keyboard event to insert the docs, instead of using the IDE's private method.
                //See more at https://github.com/onevcat/VVDocumenter-Xcode/issues/3
                
                //Save current content in paste board
                NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
                NSString *originPBString = [pasteBoard stringForType:NSPasteboardTypeString];
                
                //Set the doc comments in it
                [pasteBoard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
                [pasteBoard setString:documentationString forType:NSStringPboardType];
                
                //Begin to simulate keyborad pressing
                VVKeyboardEventSender *kes = [[VVKeyboardEventSender alloc] init];
                [kes beginKeyBoradEvents];
                //Cmd+delete Delete current line
                [kes sendKeyCode:kVK_Delete withModifierCommand:YES alt:NO shift:NO control:NO];
                //if (shouldReplace) [textView setSelectedRange:resultToDocument.range];
                //Cmd+V, paste (which key to actually use is based on the current keyboard layout)
                NSInteger kKeyVCode = [[VVDocumenterSetting defaultSetting] keyVCode];
                [kes sendKeyCode:kKeyVCode withModifierCommand:YES alt:NO shift:NO control:NO];
                
                //The key down is just a defined finish signal by me. When we receive this key, we know operation above is finished.
                [kes sendKeyCode:kVK_F20];
                
                self.eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:^NSEvent *(NSEvent *incomingEvent) {
                    if ([incomingEvent type] == NSKeyDown && [incomingEvent keyCode] == kVK_F20) {
                        //Finish signal arrived, no need to observe the event
                        [NSEvent removeMonitor:self.eventMonitor];
                        self.eventMonitor = nil;
                        
                        //Restore previois patse board content
                        [pasteBoard setString:originPBString forType:NSStringPboardType];
                        
                        //Set cursor before the inserted documentation. So we can use tab to begin edit.
                        int baseIndentationLength = (int)[doc baseIndentation].length;
                        [textView setSelectedRange:NSMakeRange(currentLineResult.range.location + baseIndentationLength, 0)];
                        
                        //Send a 'tab' after insert the doc. For our lazy programmers. :)
                        [kes sendKeyCode:kVK_Tab];
                        [kes endKeyBoradEvents];
                        
                        shouldReplace = NO;
                        
                        //Invalidate the finish signal, in case you set it to do some other thing.
                        return nil;
                    } else if ([incomingEvent type] == NSKeyDown && [incomingEvent keyCode] == kKeyVCode && shouldReplace == YES) {
                        //Select input line and the define code block.
                        NSRange r = [textView vv_textResultUntilNextString:@";"].range;
                        
                        //NSRange r begins from the starting of enum(struct) line. Select 1 character before to include the trigger input line.
                        [textView setSelectedRange:NSMakeRange(r.location - 1, r.length + 1)];
                        return incomingEvent;
                    } else {
                        return incomingEvent;
                    }
                }];
            }
        }
    }
}

@end
