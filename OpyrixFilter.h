//
//  OpyrixFilter.h
//  Opyrix
//
//  Copyright (c) 2013 Paul. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OsiriXAPI/PluginFilter.h>

#import "OpyrixScript.h"

@interface OpyrixFilter : PluginFilter {
    NSBundle* pythonPluginBundle;
    Class opyrixScriptClass;
}

- (void) initPlugin;
- (long) filterImage:(NSString*) menuName;
+ (void) alert:(NSString*)msg;

@end
