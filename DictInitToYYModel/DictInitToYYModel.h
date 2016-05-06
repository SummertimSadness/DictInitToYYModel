//
//  DictInitToYYModel.h
//  DictInitToYYModel
//
//  Created by Yasin on 16/4/20.
//  Copyright © 2016年 Yasin. All rights reserved.
//

#import <AppKit/AppKit.h>

@class DictInitToYYModel;

static DictInitToYYModel *sharedPlugin;

@interface DictInitToYYModel : NSObject

+ (instancetype)sharedPlugin;

@end