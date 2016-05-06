//
//  VVMethodCommenter.m
//  VVDocumenter-Xcode
//
//  Created by 王 巍 on 13-7-17.
//
//  Copyright (c) 2015 Wei Wang <onevcat@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "VVMethodCommenter.h"
#import "VVArgument.h"

@implementation VVMethodCommenter

-(NSString *) captureReturnType
{
    NSArray * matchedTypes = [self.code componentsSeparatedByString:@";"];
    NSMutableString *codestring = [NSMutableString stringWithString:@"+ (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper {\nreturn @{"];
    [matchedTypes enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *a = [obj componentsSeparatedByString:@"="];
        if (a.count==2) {
            NSRange rang = [a[0] rangeOfString:@"self."];
            NSRange valueR = [a[1] rangeOfString:@"@\""];
            if (rang.location != NSNotFound && valueR.location!=NSNotFound) {
                NSString *name = [a[0] substringFromIndex:rang.location+rang.length];
                NSString *value = [a[1] substringFromIndex:valueR.location+valueR.length];
                NSRange vr = [value rangeOfString:@"\""];
                if (vr.location!=NSNotFound) {
                    value = [value substringToIndex:vr.location];
                }
                [codestring appendFormat:@"@\"%@\" : @\"%@\",\n",name,value];
            }
            
        }
    }];
    [codestring appendString:@"};\n}"];
    return codestring;
}

-(void) captureParameters
{
    NSArray * matchedParams = [self.code vv_stringsByExtractingGroupsUsingRegexPattern:@"\\:\\(([^:]+)\\)(\\w+)"];
    VVLog(@"matchedParams: %@",matchedParams);
    for (int i = 0; i < (int)matchedParams.count - 1; i = i + 2) {
        VVArgument *arg = [[VVArgument alloc] init];
        arg.type = [matchedParams[i] vv_stringByReplacingRegexPattern:@"[\\s*;.*]" withString:@""];
        arg.name = [matchedParams[i + 1] vv_stringByReplacingRegexPattern:@"[\\s*;.*]" withString:@""];
        [self.arguments addObject:arg];
    }
}

-(NSString *) document
{
    return [self captureReturnType];
}

@end
