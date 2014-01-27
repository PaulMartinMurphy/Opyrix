//
//  OpyrixFilter.m
//  Opyrix
//
//  Copyright (c) 2013 Paul. All rights reserved.
//

#import "OpyrixFilter.h"

#import <OsiriXAPI/BrowserController.h>

#include "OpyrixWindow.h"

@implementation OpyrixFilter

- (void) initPlugin {
    
    NSString* resourcePath = [[NSBundle bundleForClass:[self class]] resourcePath];
    NSString* pythonPluginPath = [NSString stringWithFormat:@"%@/dist/OpyrixScript.plugin",resourcePath];
    
        //@"/Users/murphp/src/OpyrixScript/dist/OpyrixScript.plugin";
    pythonPluginBundle = [NSBundle bundleWithPath:pythonPluginPath];
    if( pythonPluginBundle == nil ) {
        [OpyrixFilter alert:[NSString stringWithFormat:@"Unable to load %@\nMay need to run py2app",pythonPluginPath]];
        return;
    }
    opyrixScriptClass = [pythonPluginBundle classNamed:@"OpyrixScript"];
    if( opyrixScriptClass == nil ) {
        [OpyrixFilter alert:[NSString stringWithFormat:@"Unable to find class named OpyrixScript in %@",pythonPluginPath]];
        return;
    }
}

- (long) filterImage:(NSString*) menuName{
    
// [NSBundle loadNibNamed:@"OpyrixWindow" owner:self];
    OpyrixWindow* opw = [[OpyrixWindow alloc] init];
    opw.opyrixScriptClass = opyrixScriptClass;
    return 0;
    
    /*
    [OpyrixFilter alert:[NSString stringWithFormat:@"hi, menuname=%@",menuName]];
    
    OpyrixScript* opyrixScript = [[opyrixScriptClass alloc] init];

    BrowserController* browser = [BrowserController currentBrowser];
    
    [opyrixScript run:@"this is where the filename would go" browser:browser o:nil];
    
    [OpyrixFilter alert:[NSString stringWithFormat:@"filename=%@",[opyrixScript getFilename]]];
    
    return 0;
     */

}

+ (void) alert:(NSString *)msg {
    NSAlert* alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:msg];
    [alert runModal];
}
@end
