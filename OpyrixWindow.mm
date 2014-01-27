//
//  OpyrixWindow.m
//  Opyrix
//
//  Created by Paul Murphy on 6/28/13.
//
//

// !!! this code is required to be able to include DCMTKRootQueryNode.h
#undef verify
#define HAVE_CONFIG_H // haven't been able to define this in makefile
#include "dcmtk/config/osconfig.h"
//#include "dcmtk/dcmdata/dctagkey.h"
// also this file has to be objc++, ie be named *.mm
// !!! wtf

#import "OpyrixWindow.h"
#import "OpyrixScript.h"

#import <OsiriXAPI/BrowserController+Activity.h>
#import <OsiriXAPI/ViewerController.h>
#import <OsiriXAPI/ROI.h>
#import <OsiriXAPI/DicomStudy.h>
#import <OsiriXAPI/DicomSeries.h>
#import <OsiriXAPI/DicomStudy.h>
#import <OsiriXAPI/DCMPix.h>
#import <OsiriXAPI/SRAnnotation.h>

#import <Foundation/NSThread.h>

#import <OsiriXAPI/DCMTKRootQueryNode.h>
#import <OsiriXAPI/QueryController.h>

#import <OsiriXAPI/NSUserDefaults+OsiriX.h>

#import "DCMTransferSyntax.h"

#import <OsiriXAPI/DCMTKStudyQueryNode.h>
#import <OsiriXAPI/DCMTKSeriesQueryNode.h>

#import <Foundation/NSData.h>

#import <OsiriXAPI/DCMView.h>


@interface OpyrixWindow ()

@end

@implementation OpyrixWindow

@synthesize scriptPath;
@synthesize scriptScrollView;
@synthesize scriptTextView;
@synthesize scriptProgress;

//@synthesize lock;
@synthesize opyrixScriptClass;
@synthesize isScriptStopped;


- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        [NSBundle loadNibNamed:@"OpyrixWindow" owner:self];
    }
    
    // adjust the script text view to color/font i like
    NSColor* green = [NSColor greenColor];
    NSColor* black = [NSColor blackColor];
    NSFont*  fixed = [NSFont fontWithName:@"Courier" size:12];
    if( green != nil ) [scriptTextView setTextColor:green];
    if( black != nil ) [scriptTextView setBackgroundColor:black];
    if( fixed != nil ) [scriptTextView setFont:fixed];
    
    // create the lock
    // lock = [[NSLock alloc] init];
    
    NSString* resourcePath = [[NSBundle bundleForClass:[self class]] resourcePath];
    scriptPath.stringValue = [NSString stringWithFormat:@"%@/scripts/example.py",resourcePath];
    
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

/*
- (void)appendText:(NSString*)s {
    //[lock lock];
    [scriptTextView setString:[NSString stringWithFormat:@"%@%@",[scriptTextView string],s]];
    //[scriptTextView display];
    NSPoint p = NSMakePoint(0.0,
                            NSMaxY([[scriptScrollView documentView] frame])
                            -NSHeight([[scriptScrollView contentView] bounds]));
    [[scriptScrollView documentView] scrollPoint:p];
    // XXX may need to call display here
    //[lock unlock];
}

- (void)setProgress:(double)d {
    //[lock lock];
    [scriptProgress setDoubleValue:d];
    //[lock unlock];
}
*/

- (void)appendTextInMainThread:(id)s {
    [scriptTextView setString:[NSString stringWithFormat:@"%@%@",[scriptTextView string],(NSString*)s]];
    [scriptTextView display];
    NSPoint p = NSMakePoint(0.0,
                            NSMaxY([[scriptScrollView documentView] frame])
                            -NSHeight([[scriptScrollView contentView] bounds]));
    [[scriptScrollView documentView] scrollPoint:p];
}

- (void)appendText:(NSString*)s {
    [self performSelectorOnMainThread:@selector(appendTextInMainThread:) withObject:s waitUntilDone:YES];
}

- (void)setProgressInMainThread:(id)d {
    [scriptProgress setDoubleValue: [(NSNumber*)d doubleValue]];
}

- (void)setProgress:(double)d {
    [self performSelectorOnMainThread:@selector(setProgressInMainThread:) withObject:[NSNumber numberWithDouble:d] waitUntilDone:YES];
}

- (IBAction)chooseScript:(id)sender {

    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setAllowedFileTypes:[NSArray arrayWithObject:@"py"]];
    
    if( [openPanel runModal] == NSOKButton ) {
        scriptPath.stringValue = [openPanel filename];
    }
}

- (IBAction)runScript:(NSButton *)sender {
    
    //[self appendText:[NSString stringWithFormat:@">>> Starting new thread\n"]];
    [NSThread detachNewThreadSelector:@selector(runScriptThread) toTarget:self withObject:nil];
    
    //scriptThread = [[NSThread alloc] initWithTarget:self selector:@selector(runScriptThread) object:nil];
    //[scriptThread start];
    
    //[self appendText:[NSString stringWithFormat:@">>> Done starting new thread\n"]];
    
    // !!! need to work out locks
}

- (void) runScriptThread {
    //NSAlert* alert = [[[NSAlert alloc] init] autorelease];
    //[alert setMessageText:[NSString stringWithFormat:@"running script %@",[scriptPath stringValue]]];
    //[alert runModal];
    
    @autoreleasepool {

        [self appendText:[NSString stringWithFormat:@">>> Running '%@'\n",[scriptPath stringValue]]];
    
        OpyrixScript* opyrixScript = [[[opyrixScriptClass alloc] init] autorelease];
    
        isScriptStopped = NO;
    
        [opyrixScript run:[scriptPath stringValue]
                  browser:[BrowserController currentBrowser]
                   window:self];
    
        [self appendText:[NSString stringWithFormat:@">>> Done running '%@'\n",[scriptPath stringValue]]];
        
    }

}

- (IBAction)stopScript:(id)sender {
    isScriptStopped = YES;
    // !!! please note that [scriptThread exit] crashes OsiriX
}

-(DCMPix*) getDCMPix:(DicomImage*)image {
    DCMPix* pix = [[[DCMPix alloc] initWithImageObj:image] autorelease];
    return pix; // XXX who owns this!!!
}

-(NSArray*) getROIs:(DicomStudy*)study image:(DicomImage*)image {
    NSArray *roisArray = [[[study roiSRSeries] valueForKey: @"images"] allObjects];
    NSString *str = [study roiPathForImage:image inArray:roisArray];
    NSData *data = [SRAnnotation roiFromDICOM: str];
    
    NSArray *array = 0L;
    @try {
        if (data) {
            array = [NSUnarchiver unarchiveObjectWithData: data];
        }
        else {
            array = [NSUnarchiver unarchiveObjectWithFile: str];
        }
    }
    @catch (NSException * e) {
        [self appendText:@">>> Failed to unarchive an ROI\n"];
    }

    return array; // XXX who owns this!

} // getROIs

-(NSArray*) computeROI:(DCMPix*)pix roi:(ROI*)roi {
    float a,b,c,d,e;
    [pix computeROI:roi:&a:&b:&c:&d:&e];
    return [NSArray arrayWithObjects:
            [NSNumber numberWithFloat:a],
            [NSNumber numberWithFloat:b],
            [NSNumber numberWithFloat:c],
            [NSNumber numberWithFloat:d],
            [NSNumber numberWithFloat:e],
            nil];

}

-(NSMutableArray*) getROIValues:(DCMPix*)pix roi:(ROI*)roi {
    long buflen;
    float *buffer = [pix getROIValue:&buflen :roi :0L];
    NSMutableArray* rval = [NSMutableArray array];
    for( long i = 0; i < buflen; ++i ) {
        [rval addObject:[NSNumber numberWithFloat:buffer[i]]];
    }
    free(buffer);
    return rval;
}

/*
-(NSNumber*) computeAngle:(ROI*)roi {
    if( [roi type] != tAngle or [[roi points] count] != 3) {
        return nil;
    }
    return [NSNumber numberWithFloat:[roi Angle:[roi pointAtIndex:0] :[roi pointAtIndex:1]  :[roi pointAtIndex:2]]];
}
 */

/*
-(NSArray*) performQuery {
    
	NSString *callingAET = @"Opyrix Osirix";
	NSString *calledAET  = @"LIG_OSI11";
	NSString *hostname   = @"172.20.34.202";
	NSString *port       = @"4006";
	NSDictionary *distantServer = nil; //[NSDictionary dictionary]; // whatever...
    
    //NSDictionary *filter = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"PatientID", @"18692467", nil]
    //                                                   forKeys:[NSArray arrayWithObjects:@"value",  @"name", nil]];
    
    NSDictionary *filter1 = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"18692467", @"PatientID", nil]
                                                        forKeys:[NSArray arrayWithObjects:@"value",  @"name", nil]];
    NSDictionary *filter2 = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"41867438", @"AccessionNumber", nil]
                                                        forKeys:[NSArray arrayWithObjects:@"value",  @"name", nil]];
    

    NSMutableArray* filterArray = [NSMutableArray arrayWithObjects:filter1, filter2, nil];

    
    DCMTKQueryNode* root = [DCMTKStudyQueryNode queryNodeWithDataset:nil
                                                         callingAET:callingAET
                                                          calledAET:calledAET
                                                           hostname:hostname
                                                               port:[port intValue]
                                                     transferSyntax:0
                                                        compression:nil
                                                    extraParameters:distantServer];
    
    [root setShowErrorMessage:TRUE];
    [root queryWithValues:filterArray];

    NSMutableArray* queries = [[root children] retain];
    
    return queries;
}
*/


-(NSMutableArray*) getQueryFilterArray:(NSDictionary*)filters {
    NSMutableArray* filterArray = [NSMutableArray array];
    NSEnumerator* e = [filters keyEnumerator];
    NSString* key;
    while( key = [e nextObject]) {
        id value = [filters objectForKey:key];
        if( value != nil ) {
            [filterArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:value,key, nil]
                                                               forKeys:[NSArray arrayWithObjects:@"value", @"name", nil]]];
        }
    }
    return filterArray;
}

-(NSArray*) queryStudies: (NSDictionary*)filters server:(NSDictionary*)server {

    // get the server parameters
	NSString *callingAET = @"Opyrix";
    NSString *calledAET  = [server objectForKey:@"AETitle"];//@"LIG_OSI11";
	NSString *hostname   = [server objectForKey:@"Address"];//@"172.20.34.202";
    id portID = [server objectForKey:@"Port"];
    NSString* port = nil;
    if( [portID isKindOfClass:[NSString class] ] ) {
        port = (NSString*)portID;
    } else if( [portID isKindOfClass:[NSNumber class]] ) {
        port = [(NSNumber*)portID stringValue];
    } else {
        [self appendText:@">>> queryStudies - error unable to determine type of port!!!\n"];
        return nil;
    }
    
    // build the query node
    DCMTKQueryNode* root = [DCMTKRootQueryNode queryNodeWithDataset:nil
                                                         callingAET:callingAET
                                                          calledAET:calledAET
                                                           hostname:hostname
                                                               port:[port intValue]
                                                     transferSyntax:0
                                                        compression:nil
                                                    extraParameters:server];

    
    // get the filter array and perform query
    NSMutableArray* filterArray = [self getQueryFilterArray:filters];
    [root setShowErrorMessage:TRUE];
    [root queryWithValues:filterArray];
    
    // remember the children - autorelease the children?
    NSMutableArray* nodes = [[root children] retain];
    if( nodes == nil ) {
        nodes = [[NSMutableArray array] retain];
    }
    return nodes;

}

-(NSArray*) queryNode: (NSDictionary*)filters node:(id)nodeID {

    // make sure we're calling this on a node...
    if( ![nodeID isKindOfClass:[DCMTKQueryNode class]] ) {
        [self appendText:@">>> queryNode must be called on a result of queryStudies or queryNode!!!\n"];
        return nil;
    }
    DCMTKQueryNode* node = (DCMTKQueryNode*)nodeID;
    
    // build the query node
    NSMutableArray* filterArray = [self getQueryFilterArray:filters];
    [node setShowErrorMessage:TRUE];
    [node queryWithValues:filterArray];
    
    NSMutableArray* nodes = [[node children] retain];
    if( nodes == nil ) {
        nodes = [[NSMutableArray array] retain];
    }
    return nodes;
    
}

/*
 // !!! change the simple dictionary to the crazy format used by DCMTKQueryNode
 NSMutableArray* filterArray = [NSMutableArray array];
 NSEnumerator* e = [filters keyEnumerator];
 NSString* key;
 while( key = [e nextObject]) {
 id value = [filters objectForKey:key];
 if( value != nil ) {
 [filterArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:value,key, nil]
 forKeys:[NSArray arrayWithObjects:@"value", @"name", nil]]];
 }
 }
 */

-(int) retrieveStudyByAccessionNumber:(NSString*)accessionNumber server:(NSDictionary*)server {
        //NSString *myAET = @"Opyrix";
    //    [OpyrixWindow alert:[NSUserDefaults defaultAETitle]];
        //DCMTransferSyntax* transferSyntax = [DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax];
    //NSDictionary *server = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:aet,hostname,port,nil]
    //                                                   forKeys:[NSArray arrayWithObjects:@"AETitle",@"Address",@"Port",nil]];
    
    return [QueryController queryAndRetrieveAccessionNumber:accessionNumber server:server showErrors:TRUE];
    
}

-(int) retrieveStudyFromQuery:(id)studyFromQuery {
    
    if( ![studyFromQuery isKindOfClass:[DCMTKQueryNode class]] ) {
        [self appendText:@">>> retrieveStudy was passed an argument that was not a DCMTKQueryNode!\n"];
        return 1;
    }
    
    //NSArray* studies =  [NSArray arrayWithObject:(DCMTKQueryNode*)studyFromQuery];
    //[QueryController retrieveStudies:studies showErrors:TRUE];
        // XXX need to update the header files for this to work
    [self appendText:@">>> retrieveStudyFromQuery is not available in this version of OsiriX\n"];
    
    return 0;
}

-(NSArray*) getServerTitles {

    NSMutableArray* rval = [NSMutableArray array];
    
    NSString* queryArrayPrefs = @"SavedQueryArray";
    NSArray* sourcesArray = [[NSUserDefaults standardUserDefaults] objectForKey: queryArrayPrefs];
    
    for( NSDictionary* source in sourcesArray ) {
        [rval addObject:[source objectForKey:@"AETitle"]];
    }

    return rval;
}

-(NSDictionary*) getServer:(NSString*)title {

    NSString* queryArrayPrefs = @"SavedQueryArray";
    NSArray* sourcesArray = [[NSUserDefaults standardUserDefaults] objectForKey: queryArrayPrefs];
    
    for( NSDictionary* source in sourcesArray ) {
        //[self appendText: [NSString stringWithFormat:@"%@\n", [source objectForKey:@"AETitle"]]];
        if( [title isEqualToString:[source objectForKey:@"AETitle"]] ) {
            return [source objectForKey:@"server"];
        }
    }

    return nil;
}

-(void) calculateBarycentricCoordinates:(MyPoint*)p0:(MyPoint*)p1:(MyPoint*)p2:(float)x:(float)y:(float*)s:(float*)t {
    float p0x = [p0 x];
    float p0y = [p0 y];
    float p1x = [p1 x];
    float p1y = [p1 y];
    float p2x = [p2 x];
    float p2y = [p2 y];
    
    float A = 1.0/2.0*(-p1y*p2x + p0y*(-p1x + p2x) + p0x*(p1y - p2y) + p1x*p2y);
    
    *s = 1.0/(2.0*A)*(p0y*p2x - p0x*p2y + (p2y - p0y)*x + (p0x - p2x)*y);
    *t = 1.0/(2.0*A)*(p0x*p1y - p0y*p1x + (p0y - p1y)*x + (p1x - p0x)*y);
    
}

-(void) saveTriAsTIFF:(DCMPix*)pix p0:(MyPoint*)p0 p1:(MyPoint*)p1 p2:(MyPoint*)p2 WL:(NSNumber*)WL WW:(NSNumber*)WW filename:(NSString*)filename {
    [pix compute8bitRepresentation];
    long pix_width = [pix pwidth];
    long pix_height = [pix pheight];
    
    NSUInteger xlo = (NSUInteger)floorf(MIN([p0 x], MIN([p1 x], [p2 x])));
    NSUInteger xhi = (NSUInteger) ceilf(MAX([p0 x], MAX([p1 x], [p2 x])));
    NSUInteger ylo = (NSUInteger)floorf(MIN([p0 y], MIN([p1 y], [p2 y])));
    NSUInteger yhi = (NSUInteger) ceilf(MAX([p0 y], MAX([p1 y], [p2 y])));

    NSUInteger roi_width  = (NSUInteger)(xhi - xlo);
    NSUInteger roi_height = (NSUInteger)(yhi - ylo);
    
    NSBitmapImageRep* rep = [[[NSBitmapImageRep alloc]
                                initWithBitmapDataPlanes:nil
                                pixelsWide:roi_width
                                pixelsHigh:roi_height
                                bitsPerSample:8
                                samplesPerPixel:2
                                hasAlpha:YES
                                isPlanar:NO
                                colorSpaceName:NSCalibratedWhiteColorSpace
                                bytesPerRow:roi_width*2
                                bitsPerPixel:16] autorelease];
        
    float wl = [WL floatValue];
    float ww = [WW floatValue];
    float max = wl + ww / 2.0;
    float min = wl - ww / 2.0;
    float diff = max - min;
  
    NSUInteger v[2];
                                  
    for( long x = 0; x < roi_width; x++ ) {
        for( long y = 0; y < roi_height; y++ ) {
                
            //if( xlo <= x and x < xhi and ylo <= y and y < yhi ) {
            float s,t;
            long pix_x = xlo + x;
            long pix_y = ylo + y;
                
            if( pix_x  < pix_width and pix_y < pix_height ) {
                [self calculateBarycentricCoordinates:p0:p1:p2:0.5+pix_x:0.5+pix_y:&s:&t];
                //[self calculateBarycentricCoordinates:p0:p1:p2:pix_x:pix_y:&s:&t];
            

                    // inside
                    // should really have a nonzero alpha along the edges plus a little
                    
                    //long px = xlo + x;
                    //long py = ylo + y;
                    
                    float f = [pix getPixelValueX:pix_x Y:pix_y];
                    if( f > max ) f = max;
                    if( f < min ) f = min;
                    f = 255.0 * (f-min) / diff;
                    v[0] = (NSUInteger)f;
                
                if( 0 <= s and s <= 1 and 0 <= t and t <= 1 and s + t <= 1) {
                    v[1] = 255;
                        /*
                        if( not isScriptStopped ) {
                            float fp = [pix getPixelValueX:pix_x Y:pix_y];
                            [self appendText:[NSString stringWithFormat:@"%lu %lu %lu %lu %f %lu %f\n",x,y,pix_x,pix_y,f,(unsigned long)v[0],fp]];
                        }
                         */
                    
                //} else if( -0.025 <= s and s <= 1.025 and -0.025 <= t and t <= 1.025 and -0.025 <= s + t and s + t <= 1.025 ) {
                //    v[1] = 25;
                }
                else {
                    //v[0] = 0;
                    v[1] = 0;
                    
                }
        
                [rep setPixel:v atX:x y:y];

            }
        }
    }

    NSImage* image = [[[NSImage alloc] init] autorelease];
    [image addRepresentation:rep];
    NSData* tiff = [image TIFFRepresentation];
    [tiff writeToFile:filename atomically:YES];
        
}

-(void) saveROIAsTIFF:(DCMPix*)pix roi:(ROI*)roi WL:(NSNumber*)WL WW:(NSNumber*)WW filename:(NSString*)filename {
    
    if( [roi type] == tCPolygon and [[roi points] count] == 3 ) {
        
        [self appendText:@"dealing with triangle!\n"];
        
        MyPoint* p0 = [[roi points] objectAtIndex:0];
        MyPoint* p1 = [[roi points] objectAtIndex:1];
        MyPoint* p2 = [[roi points] objectAtIndex:2];
        
        [self saveTriAsTIFF:pix p0:p0 p1:p1 p2:p2 WL:WL WW:WW filename:filename];
        
    } else {
        
        [self appendText:@"don't know what to do with this roi\n"];
        
    }
   
}

/*
-(void) saveROIAsTIFF:(DCMPix*)pix roi:(ROI*)roi WL:(NSNumber*)WL WW:(NSNumber*)WW filename:(NSString*)filename {
    [pix compute8bitRepresentation];
    long width = [pix pwidth];
    long height = [pix pheight];
    
    if( [roi type] == tCPolygon) {
        NSArray* points = [roi points];
        for( id point in points ) {
            MyPoint* p = (MyPoint*)point;
            [self appendText:[NSString stringWithFormat:@"%f %f\n",[p x],[p y]]];
        }
    }
    
    

    
    
    NSBitmapImageRep* rep = [[[NSBitmapImageRep alloc]
                              initWithBitmapDataPlanes:nil
                              pixelsWide:width
                              pixelsHigh:height
                              bitsPerSample:8
                              samplesPerPixel:2
                              hasAlpha:YES
                              isPlanar:NO
                              colorSpaceName:NSCalibratedWhiteColorSpace
                              bytesPerRow:width*2
                              bitsPerPixel:16] autorelease];

    float wl = [WL floatValue];
    float ww = [WW floatValue];
    float max = wl + ww / 2.0;
    float min = wl - ww / 2.0;
    float diff = max - min;

    NSPoint p;
    NSUInteger v[2];
    
    for( long x = 0; x < width; ++x ) {
        for( long y = 0; y < height; ++y ) {

            p.x = x;
            p.y = y;
    
            if( [pix isInROI:roi :p] ) {
                float f = [pix getPixelValueX:x Y:y];
                if( f > max ) f = max;
                if( f < min ) f = min;
                f = (f-min) / diff * 255.0;
                v[0] = (NSUInteger)f;
                v[1] = 255;
            } else {
                v[0] = 0;
                v[1] = 0;
            }

            [rep setPixel:v atX:x y:y];
        }
    }

    NSImage* image = [[[NSImage alloc] init] autorelease];
    [image addRepresentation:rep];
    NSData* tiff = [image TIFFRepresentation];
    [tiff writeToFile:filename atomically:YES];

}
*/

-(ViewerController*) findViewer:(NSManagedObject*)element {
    BrowserController* browser = [BrowserController currentBrowser];
    NSMutableArray *viewers = [ViewerController getDisplayed2DViewers];

    id elementType = [element valueForKey:@"type"];
    
    NSString* keyPath = nil;
    if( [elementType isEqualToString: @"Study"]) {
        keyPath = @"series.study";
    } else if ([elementType isEqualToString:@"Series"]) {
        keyPath = @"series";
    }
    
    if( keyPath != nil ) {
        for( ViewerController *viewer in viewers) {
            if( element == [[[viewer fileList] objectAtIndex: 0] valueForKeyPath:keyPath]) {
                [[viewer window] makeKeyAndOrderFront: browser];
                return viewer;
            }
        }
    } else if( [elementType isEqualToString:@"Image"] ) {
        for( ViewerController *viewer in viewers) {
            for( NSManagedObject* dicomImage in [viewer fileList] ) {
                if( element == dicomImage ) {
                    [[viewer window] makeKeyAndOrderFront: browser];
                    [viewer setImage:dicomImage];
                    return viewer;
                }
            }
        }
    }
    
    return nil;
}

-(ViewerController*) displayStudy: (DicomStudy*) study element:(NSManagedObject*)element{
    //[self appendText:@"displaying Study..."];
    [[BrowserController currentBrowser] displayStudy:study object:element command:@"Open"];
    return [self findViewer:element];
}

-(void) loadROIs:(ViewerController*)viewer filename:(NSString*)filename {
    [viewer roiLoadFromSeries:filename];
}


- (void) loadROIsBackwards:(ViewerController*)viewer filename:(NSString*)filename order:(NSDictionary*)order { //sliceLocs:(NSArray*)sliceLocs {

	// Unselect all ROIs
	[viewer roiSelectDeselectAll: nil];
	
	NSArray *roisMovies = [NSUnarchiver unarchiveObjectWithFile: filename];
	
	for( int y = 0; y < [viewer maxMovieIndex]; y++) {
        
		if( [roisMovies count] > y) {
			NSArray *roisSeries = [roisMovies objectAtIndex: y];
            
            NSMutableArray* pixList = [viewer pixList:y];
            
			for( int x = 0; x < [pixList count]; x++) {

				DCMPix *curDCM = [pixList objectAtIndex: x];
                
                // metadata slice location...
                
                [self appendText:[NSString stringWithFormat:@"x=%d sliceLoc=%f\n",x,[curDCM sliceLocation]]];
                
				if( [roisSeries count] > x) {

                    //int z = [pixList count] - 1 - x;
                    
                    NSNumber* z = [order objectForKey:[curDCM imageObj]];
                    if( z == nil ) {
                        [self appendText:@"error! couldn't find dcm"];
                        return;
                    }

					NSArray *roisImages = [roisSeries objectAtIndex: [z intValue]];
					
					for( ROI *r in roisImages) {

                        //Correct the origin only if the orientation is the same
                        r.pix = curDCM;
                        
						[r setOriginAndSpacing: curDCM.pixelSpacingX :curDCM.pixelSpacingY :[DCMPix originCorrectedAccordingToOrientation: curDCM]];
						
                        //[[[[viewer roiList] objectAtIndex:y] objectAtIndex: x] addObject: r];
                        [[[viewer roiList:y] objectAtIndex:x] addObject:r];
						[[viewer imageView] roiSet: r];
					}
				}
			}
		}
	}
	
	[[viewer imageView] setIndex: [[viewer imageView] curImage]];
}


-(void) deleteAllROIs:(ViewerController *)viewer {
    //[viewer roiDeleteAll:nil];
}

-(void) closeViewer:(ViewerController*)viewer {
    [ViewerController closeAllWindows];
    //[[BrowserController currentBrowser] showDatabase:viewer]; // wish this worked but it doesn't
}

@end

/*
-(void) saveROIAsTIFF:(DCMPix*)pix roi:(ROI*)roi WL:(NSNumber*)WL WW:(NSNumber*)WW filename:(NSString*)filename {
    [self appendText:@"saving...\n"];
    [pix compute8bitRepresentation];
    //NSImage* image = [pix image];
    unsigned char		*buf = nil;
	long				i;
	NSBitmapImageRep	*rep;
	
    long width = [pix pwidth];
 long height = [pix pheight];
 
    
    float wl = [WL floatValue];
    float ww = [WW floatValue];
    
    float max = wl + ww / 2.0;
    float min = wl - ww / 2.0;
    float diff = max - min;
    
    [self appendText:[NSString stringWithFormat:@"WL WW MAX MIN DIFF: %f %f %f %f %f\n",wl,ww,max,min,diff]];
    

    rep = [[[NSBitmapImageRep alloc]
            initWithBitmapDataPlanes:nil
            pixelsWide:width
            pixelsHigh:height
            bitsPerSample:8
            samplesPerPixel:1
            hasAlpha:NO
            isPlanar:NO
            colorSpaceName:NSCalibratedWhiteColorSpace
            bytesPerRow:width
            bitsPerPixel:8] autorelease];

    
    rep = [[[NSBitmapImageRep alloc]
            initWithBitmapDataPlanes:nil
            pixelsWide:width
            pixelsHigh:height
            bitsPerSample:8
            samplesPerPixel:2
            hasAlpha:YES
            isPlanar:NO
            colorSpaceName:NSCalibratedWhiteColorSpace
            bytesPerRow:width*2
            bitsPerPixel:16] autorelease];
    
    
    //memcpy( [rep bitmapData], [pix baseAddr], height*width);
    
    float fmin = 0.0;
    float fmax = 0.0;
    float pmax = 0.0;
    float pmin = 0.0;
    
    
    for( long x = 0; x < width; x++ ) {
        for( long y = 0; y < height; y++ ) {
            
            float f = [pix getPixelValueX:x Y:y];

            
            if( x == 0 && y == 0 ) {
                pmax = f;
                pmin = f;
            }
            if( f > pmax ) pmax = f;
            if( f < pmin ) pmin = f;
            
            
            
            if( f > max ) f = max;
            if( f < min ) f = min;
            f = (f-min) / diff * 255.0;
            
            if( x == 0 && y == 0 ) {
                fmax = f;
                fmin = f;
            }
            if( f > fmax ) fmax = f;
            if( f < fmin ) fmin = f;
            
            NSUInteger v[2];
            v[0] = (NSUInteger)f;
            v[1] = 0;
            [rep setPixel:v atX:x y:y];
            
            
        }
    }
    
    [self appendText:[NSString stringWithFormat:@"%f %f\n",pmax,pmin]];
    [self appendText:[NSString stringWithFormat:@"%f %f\n",fmax,fmin]];
    NSUInteger umin, umax;
    umin = (NSUInteger)fmin;
    umax = (NSUInteger)fmax;
    [self appendText:[NSString stringWithFormat:@"%lu %lu\n",(unsigned long)umax,(unsigned long)umin]];
    
    NSImage*   imageRep = [[[NSImage alloc] init] autorelease];
    [imageRep addRepresentation:rep];
    [self appendText:@"got image\n"];
    NSData* data = [imageRep TIFFRepresentation];
    [data writeToFile:filename atomically:YES];
    [self appendText:@"got tiff\n"];
    
}

@end
*/

    //return imageRep;
    //[self appendText:@"got image..."];
    //NSData* tiff = [image TIFFRepresentation];
    //[self appendText:@"got tiff..."];
    //[tiff writeToFile:filename atomically:YES];
    //[self appendText:@"done!!!"];
    //[[[dcmPix image] TIFFRepresentation] writeToFile:dest atomically:YES];
//}

/*
-(void) querySeries {
    
    if (dataset->findAndGetString(DCM_QueryRetrieveLevel, queryLevel).good()){}
	
    
    - (DcmDataset *)queryPrototype // When 'opening' a study -> SERIES level
    {

    DCMTKSeriesQueryNode *newNode = [DCMTKSeriesQueryNode queryNodeWithDataset: dataset
                                                                    callingAET: _callingAET
                                                                     calledAET: _calledAET
                                                                      hostname: _hostname
                                                                          port: _port
                                                                transferSyntax: _transferSyntax
                                                                   compression: _compression
                                                               extraParameters: _extraParameters];
}
 */



/*
-(DCMCalendarDate*) getDCMCalendarDate {
    DCMCalendarDate* rval = [DCMCalendarDate dicomDate:@"20130120"];
    [rval setQueryString:@"20130101-20130831"];
    [rval setIsQuery:TRUE];
    return rval;
}

 @synchronized( self)
 {
 [rootNode release];
 rootNode = [[DCMTKRootQueryNode queryNodeWithDataset: nil
 callingAET: callingAET
 calledAET: calledAET
 hostname: hostname
 port: [port intValue]
 transferSyntax: 0		//EXS_LittleEndianExplicit / EXS_JPEGProcess14SV1TransferSyntax
 compression: nil
 extraParameters: distantServer] retain];
 
 NSMutableArray *filterArray = [NSMutableArray array];
 NSEnumerator *enumerator = [filters keyEnumerator];
 NSString *key;
 while (key = [enumerator nextObject])
 {
 if ([filters objectForKey:key])
 {
 NSDictionary *filter = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[filters objectForKey:key], key, nil] forKeys:[NSArray arrayWithObjects:@"value",  @"name", nil]];
 [filterArray addObject:filter];
 }
 }
 [rootNode setShowErrorMessage: showError];
 [rootNode queryWithValues:filterArray];
 
 //		NSLog( @"Query values: %@", filterArray);
 
 if( [[NSThread currentThread] isCancelled] == NO)
 {
 [queries release];
 queries = [[rootNode children] retain];
 }
 
 if( queries == nil && rootNode != nil)
 queries = [[NSMutableArray array] retain];
 }

 */

/*
 - (void) loadROI:(int)i {
 
 BrowserController* browser = [BrowserController currentBrowser];
 DicomStudy* study = [[browser databaseSelection] objectAtIndex:0];
 DicomSeries* series = [[study imageSeries] objectAtIndex:0];
 DicomImage* image = [[series sortedImages] objectAtIndex:1];
 
 //BOOL isDir = YES;
 //int i, x;
 //DicomStudy *study = [[fileList[0] objectAtIndex:0] valueForKeyPath: @"series.study"];
 
 
 [self appendText:@"roiSRseries\n"];
 NSArray *roisArray = [[[study roiSRSeries] valueForKey: @"images"] allObjects];
 
 // !!! can't figure out how to get access to database, ubt maybe not so imortant
 //[[[[BrowserController currentBrowser] database] managedObjectContext] lock];
 
 
 [self appendText:@"roiPathForImage\n"];
 NSString *str = [study roiPathForImage: image inArray: roisArray];
 [self appendText:str];
 
 [self appendText:@"roiFromDicom\n"];
 NSData *data = [SRAnnotation roiFromDICOM: str];
 
 NSArray *array = 0L;
 
 @try
 {
 if (data) {
 [self appendText:@"unarchive data\n"];
 array = [NSUnarchiver unarchiveObjectWithData: data];
 }
 else {
 [self appendText:@"roiSRseries\n"];
 array = [NSUnarchiver unarchiveObjectWithFile: str];
 }
 
 }
 @catch (NSException * e)
 {
 NSLog( @"failed to read a ROI\n");
 }
 
 [self appendText:@"READ AN ROI\n"];
 
 
 
 [self appendText:[NSString stringWithFormat:@"# roi's=%ld",(unsigned long)[array count]]];
 if( [array count] > 0 ) {
 ROI* roi = [array objectAtIndex:0];
 [self appendText:[roi name]];
 NSNumber* z = [[roi zPositions] objectAtIndex:0];
 if( z == nil ) {
 [self appendText:@"failed to get zpos"];
 } else {
 [self appendText:@"got zpos"];
 [self appendText:[NSString stringWithFormat:@"%@",z]];
 }
 }
 // DicomSeries *originalROIseries = [[fileList[ mIndex] objectAtIndex: i] valueForKey:@"series"];
 */
/*
 
 @try
 {
 if( [[fileList[ mIndex] lastObject] isKindOfClass:[NSManagedObject class]])
 {
 if ([[NSUserDefaults standardUserDefaults] boolForKey: @"SAVEROIS"])
 {
 for( i = 0; i < [fileList[ mIndex] count]; i++)
 {
 if( [[pixList[ mIndex] objectAtIndex:i] generated] == NO)
 {
 NSString *str = [study roiPathForImage: [fileList[ mIndex] objectAtIndex:i] inArray: roisArray];
 
 NSData *data = [SRAnnotation roiFromDICOM: str];
 
 if( data)
 [copyRoiList[ mIndex] replaceObjectAtIndex: i withObject: data];
 else
 [copyRoiList[ mIndex] replaceObjectAtIndex: i withObject: [NSData data]];
 
 //If data, we successfully unarchived from SR style ROI
 NSArray *array = 0L;
 
 @try
 {
 if (data)
 array = [NSUnarchiver unarchiveObjectWithData: data];
 else
 array = [NSUnarchiver unarchiveObjectWithFile: str];
 }
 @catch (NSException * e)
 {
 NSLog( @"failed to read a ROI");
 }
 
 if( array)
 {
 [[roiList[ mIndex] objectAtIndex:i] addObjectsFromArray:array];
 
 for( ROI *r in array)
 {
 if( r.isAliased)
 {
 r.originalIndexForAlias = i;
 
 DicomSeries *originalROIseries = [[fileList[ mIndex] objectAtIndex: i] valueForKey:@"series"];
 
 // propagate it to the entire series IF the images are from the same series
 for( x = 0; x < [pixList[ mIndex] count]; x++)
 {
 if( x != i && originalROIseries == [[fileList[ mIndex] objectAtIndex: x] valueForKey:@"series"])
 {
 [[roiList[ mIndex] objectAtIndex: x] addObject: r];
 }
 }
 }
 }
 
 for( ROI *r in array)
 [imageView roiSet: r];
 }
 }
 }
 }
 }
 }
 @catch ( NSException *e)
 {
 NSLog( @"*** load ROI exception: %@", e);
 }
 [[[[BrowserController currentBrowser] database] managedObjectContext] unlock];
 */
//}


/*
 
 
 
 NSManagedObjectContext	*context = browser.managedObjectContext;
 NSError				*error = nil;
 
 NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
 [dbRequest setEntity: [[browser.managedObjectModel entitiesByName] objectForKey: table]];
 [dbRequest setPredicate: [NSPredicate predicateWithFormat: request]];
 
 NSArray* array = [context executeFetchRequest:dbRequest error:&error];
 
 NSManagedObject* element = [array objectAtIndex: 0];	// We select the first object
 
 
 
 
 
 [browser displayStudy:study object:element command:@"Open"];
 */

/*
 ViewerController* viewer = [browser viewerDICOM:];
 NSArray* roiList = [ViewerController roiList];
 */

/*
 NSMutableData   *volumeData     = [[NSMutableData alloc] initWithLength:0];
 NSMutableArray  *pixList        = [[NSMutableArray alloc] initWithCapacity:0];
 
 int sliceCount      = 2;
 int pixWidth        = 512, pixHeight = 512;
 
 float   pixelSpacingX = 1, pixelSpacingY = 1;
 float   originX = 0, originY = 0, originZ = 0;
 int     colorDepth = 32;
 
 long mem            = pixWidth * pixHeight * sliceCount * 4; // 4 Byte = 32 Bit Farbwert
 float *fVolumePtr   = malloc(mem);
 int i;
 
 for( i = 0; i < sliceCount; i++) {
 
 long size = sizeof( float) * pixWidth * pixHeight;
 float *imagePtr = malloc( size);
 
 DCMPix *emptyPix = [[DCMPix alloc] initWithData:imagePtr :colorDepth :pixWidth :pixHeight :pixelSpacingX :pixelSpacingY :originX :originY :originZ];
 free( imagePtr);
 [pixList addObject: emptyPix];
 
 } // i
 
 if( fVolumePtr) {
 volumeData = [[NSMutableData alloc] initWithBytesNoCopy:fVolumePtr length:mem freeWhenDone:YES];
 }
 
 //NSMutableArray *newFileArray = [NSMutableArray arrayWithArray:[[ViewerController fileList] subarrayWithRange:NSMakeRange(0, sliceCount)]];
 NSMutableArray* newFileArray = [[NSMutableArray alloc] initWithObjects:@"one",@"two",nil];
 ViewerController *new2DViewer = [ViewerController newWindow:pixList :newFileArray :volumeData];
 
 [new2DViewer needsDisplayUpdate];
 */
/*
 [self loadROI:0];
 return;
 BrowserController* browser = [BrowserController currentBrowser];
 DicomStudy* study = [[browser databaseSelection] objectAtIndex:0];
 [browser databaseOpenStudy:study];
 */



