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

#import <Cocoa/Cocoa.h>
#import "browserController.h"

/** \brief  Category for DCMTK calls from BrowserController */

@interface BrowserController (BrowserControllerDCMTKCategory)
+ (NSString*) compressionString: (NSString*) string;

#ifndef OSIRIX_LIGHT
- (NSData*) getDICOMFile:(NSString*) file inSyntax:(NSString*) syntax quality: (int) quality;
- (BOOL) testFiles: (NSArray*) files;
- (BOOL) needToCompressFile: (NSString*) path;
- (BOOL) compressDICOMWithJPEG:(NSArray *) paths;
- (BOOL) compressDICOMWithJPEG:(NSArray *) paths to:(NSString*) dest;
- (BOOL) decompressDICOMList:(NSArray *) files to:(NSString*) dest;
#endif
@end
