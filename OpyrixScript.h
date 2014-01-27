//
//  OpyrixScript.h
//  Opyrix
//
//  Created by Paul Murphy on 6/27/13.
//
//

#import <Foundation/Foundation.h>
#import <OsiriXAPI/BrowserController.h>

#import "OpyrixWindow.h"

@interface OpyrixScript : NSObject

- (void) run:(NSString*)filename
     browser:(BrowserController*)b
      window:(OpyrixWindow*)w;

@end
