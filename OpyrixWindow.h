//
//  OpyrixWindow.h
//  Opyrix
//
//  Created by Paul Murphy on 6/28/13.
//
//

#import <Cocoa/Cocoa.h>
#include <OsiriXAPI/DicomStudy.h>
#include <OsiriXAPI/DicomImage.h>
#include <OsiriXAPI/DCMPix.h>
#include <OsiriXAPI/ROI.h>
#import <OsiriXAPI/ViewerController.h>

#include "DCMCalendarDate.h"

//#include <OsiriXAPI/DCMTKQueryNode.h>

@interface OpyrixWindow : NSWindowController {
    NSTextField *scriptPath;
    NSScrollView *scriptScrollView;
    NSTextView *scriptTextView;
    NSProgressIndicator *scriptProgress;
    
    Class opyrixScriptClass;
    BOOL isScriptStopped;
    //NSLock* lock;
}

@property (assign) IBOutlet NSTextField *scriptPath;
@property (assign) IBOutlet NSScrollView *scriptScrollView;
@property (assign) IBOutlet NSTextView *scriptTextView;
@property (assign) IBOutlet NSProgressIndicator *scriptProgress;

//@property (assign) NSLock *lock;
@property (assign) Class opyrixScriptClass;
@property (assign) BOOL isScriptStopped;

// outlet helpers
- (void)appendText:(NSString*)s; // called by script thread
- (void)setProgress:(double)d;

- (void)appendTextInMainThread:(id)s; // perform action in main thread
- (void)setProgressInMainThread:(id)d;

// buttons
- (IBAction)chooseScript:(id)sender;
- (IBAction)runScript:(id)sender;
- (void)runScriptThread;// for a new thread
- (IBAction)stopScript:(id)sender;

// script helpers
-(DCMPix*) getDCMPix:(DicomImage*)image;
-(NSArray*) getROIs:(DicomStudy*)study image:(DicomImage*)i;
-(NSArray*) computeROI:(DCMPix*)pix roi:(ROI*)roi;
-(NSArray*) getROIValues:(DCMPix*)pix roi:(ROI*)roi;
-(void) saveTriAsTIFF:(DCMPix*)pix p0:(MyPoint*)p0 p1:(MyPoint*)p1 p2:(MyPoint*)p2 WL:(NSNumber*)wl WW:(NSNumber*)ww filename:(NSString*)filename;
-(void) saveROIAsTIFF:(DCMPix*)pix roi:(ROI*)roi WL:(NSNumber*)wl WW:(NSNumber*)ww filename:(NSString*)filename;
//-(NSNumber*) computeAngle:(ROI*)roi;

// query and retrieve helpers
-(NSArray*) getServerTitles;
-(NSDictionary*) getServer:(NSString*)aet;
-(NSArray*) queryStudies: (NSDictionary*)filters server:(NSDictionary*)server;
-(NSArray*) queryNode: (NSDictionary*)filters node:(id)nodeID;

-(int) retrieveStudyByAccessionNumber: (NSString*)accessionNumber server:(NSDictionary*)server;
-(int) retrieveStudyFromQuery:(id)studyFromQuery;

// viewer
-(ViewerController*) displayStudy:(DicomStudy*)study element:(NSManagedObject*)element;
-(void) loadROIs:(ViewerController*)viewer filename:(NSString*)filename;
-(void) deleteAllROIs:(ViewerController*)viewer;
-(void) closeViewer:(ViewerController*)viewer;

@end
