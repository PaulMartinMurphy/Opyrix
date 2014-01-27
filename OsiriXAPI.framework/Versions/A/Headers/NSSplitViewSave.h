/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import <Foundation/Foundation.h>
#import <AppKit/NSSplitView.h>

/** \brief Category saves splitView state to User Defaults */
@interface NSSplitView(Defaults)

+ (void) saveSplitView;
+ (void) loadSplitView;

- (void) restoreDefault: (NSString *) defaultName;
- (void) saveDefault: (NSString *) defaultName;

@end
