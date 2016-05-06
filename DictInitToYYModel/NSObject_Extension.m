//
//  NSObject_Extension.m
//  DictInitToYYModel
//
//  Created by Yasin on 16/4/20.
//  Copyright © 2016年 Yasin. All rights reserved.
//


#import "NSObject_Extension.h"
#import "DictInitToYYModel.h"

@implementation NSObject (Xcode_Plugin_Template_Extension)

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        sharedPlugin = [DictInitToYYModel sharedPlugin];
    }
}
@end
