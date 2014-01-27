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
#import "OSIWindowController.h"
#import "CPRMPRDCMView.h"
#import "VRController.h"
#import "VRView.h"

enum _CPRExportImageFormat {
    CPR8BitRGBExportImageFormat = 0,
    CPR16BitExportImageFormat = 1,
};
typedef NSInteger CPRExportImageFormat;

enum _CPRExportSequenceType {
    CPRCurrentOnlyExportSequenceType = 0,
    CPRSeriesExportSequenceType = 1,
};
typedef NSInteger CPRExportSequenceType;

enum _CPRExportSeriesType {
    CPRRotationExportSeriesType = 0,
    CPRSlabExportSeriesType = 1,
	CPRTransverseViewsExportSeriesType = 2
};
typedef NSInteger CPRExportSeriesType;

enum _CPRExportRotationSpan {
    CPR180ExportRotationSpan = 0,
    CPR360ExportRotationSpan = 1,
};
typedef NSInteger CPRExportRotationSpan;

@class CPRMPRDCMView;
@class CPRView;
@class CPRCurvedPath;
@class CPRDisplayInfo;
@class CPRTransverseView;
@class CPRVolumeData;

@interface CPRController : Window3DController <CPRViewDelegate>
{
	// To avoid the Cocoa bindings memory leak bug...
	IBOutlet NSObjectController *ob;
	
	// To be able to use Cocoa bindings with toolbar...
	IBOutlet NSView *tbLOD, *tbThickSlab, *tbWLWW, *tbTools, *tbShading, *tbMovie, *tbBlending, *tbSyncZoomLevel;
	
	NSToolbar *toolbar;
	
	IBOutlet NSMatrix *toolsMatrix;
	IBOutlet NSPopUpButton *popupRoi;
	
	IBOutlet CPRMPRDCMView *mprView1, *mprView2, *mprView3;
    IBOutlet CPRView *cprView;
    IBOutlet CPRTransverseView *topTransverseView, *middleTransverseView, *bottomTransverseView;
	IBOutlet NSSplitView *horizontalSplit1, *horizontalSplit2, *verticalSplit;
    IBOutlet NSView *tbStraightenedCPRAngle;
    double straightenedCPRAngle; // this is in degrees, the CPRView uses radians
    
    CPRVolumeData *cprVolumeData;
    CPRCurvedPath *curvedPath;
    CPRDisplayInfo *displayInfo;
    N3Vector baseNormal; // this value will depend on which view gets clicked first, it will be used as the basis for deciding what normal to use for what angle
    NSColor *curvedPathColor;
    BOOL curvedPathCreationMode;
	
	// Blending
	DCMView *blendedMprView1, *blendedMprView2, *blendedMprView3;
	float blendingPercentage;
	int blendingMode;
	BOOL blendingModeAvailable;
	NSString *startingOpacityMenu;
	
	NSMutableArray *undoQueue, *redoQueue;
	
	ViewerController *viewer2D, *fusedViewer2D;
	VRController *hiddenVRController;
	VRView *hiddenVRView;
    
	NSMutableArray *filesList[ MAX4D], *pixList[ MAX4D];
	DCMPix *originalPix;
	NSData *volumeData[ MAX4D];
	BOOL avoidReentry;
	
	// 4D Data support
	NSTimeInterval lastMovieTime;
    NSTimer	*movieTimer;
	int curMovieIndex, maxMovieIndex;
	float movieRate;
	IBOutlet NSSlider *moviePosSlider;
	
	Point3D *mousePosition;
	int mouseViewID;
	
	BOOL displayMousePosition;
	
	// Export Dcm & Quicktime
	IBOutlet NSWindow *dcmWindow;
	IBOutlet NSWindow *quicktimeWindow;
	IBOutlet NSView *dcmSeriesView;
	
	CPRMPRDCMView *curExportView;
	BOOL quicktimeExportMode;
	NSMutableArray *qtFileArray;
	
    NSString *exportSeriesName;
    CPRExportImageFormat exportImageFormat;
    CPRExportSequenceType exportSequenceType;
    CPRExportSeriesType exportSeriesType;
    CPRExportRotationSpan exportRotationSpan;
    BOOL exportReverseSliceOrder;
	NSInteger exportNumberOfRotationFrames;
    CGFloat exportSlabThickness;
    BOOL exportSliceIntervalSameAsVolumeSliceInterval;
    CGFloat exportSliceInterval, exportTransverseSliceInterval;
    
	int dcmmN;
	
	// Clipping Range
	float clippingRangeThickness;
	int clippingRangeMode;
	
	NSArray *wlwwMenuItems;
	
	float LOD;
	BOOL lowLOD;
	
	IBOutlet NSPanel *shadingPanel;
	IBOutlet ShadingArrayController *shadingsPresetsController;
	BOOL shadingEditable;
	IBOutlet NSButton *shadingCheck;
	IBOutlet NSTextField *shadingValues;
	
	IBOutlet NSView *tbAxisColors;
	NSColor *colorAxis1, *colorAxis2, *colorAxis3;
	
	NSMutableArray *_delegateCurveViewDebugging;
	NSMutableArray *_delegateDisplayInfoDebugging;
}

@property float clippingRangeThickness, blendingPercentage;
@property int clippingRangeMode, mouseViewID;
@property int curMovieIndex, maxMovieIndex, blendingMode;
@property (retain) Point3D *mousePosition;
@property (retain) NSArray *wlwwMenuItems;
@property (readonly) DCMPix *originalPix;
@property float LOD, movieRate;
@property BOOL lowLOD, displayMousePosition, blendingModeAvailable;
@property (retain) NSColor *colorAxis1, *colorAxis2, *colorAxis3;
@property (readonly) CPRMPRDCMView *mprView1, *mprView2, *mprView3;
@property (readonly) NSSplitView *horizontalSplit1, *horizontalSplit2, *verticalSplit;
@property (readonly, copy) CPRCurvedPath *curvedPath;
@property (readonly, copy) CPRDisplayInfo *displayInfo;
@property BOOL curvedPathCreationMode;
@property (retain) NSColor *curvedPathColor;
@property double straightenedCPRAngle;

// export related properties
@property (nonatomic, retain) NSString *exportSeriesName;
@property (nonatomic) CPRExportImageFormat exportImageFormat;
@property (nonatomic) CPRExportSequenceType exportSequenceType;
@property (nonatomic) CPRExportSeriesType exportSeriesType;
@property (nonatomic) CPRExportRotationSpan exportRotationSpan;
@property (nonatomic) BOOL exportReverseSliceOrder;
@property (nonatomic) NSInteger exportNumberOfRotationFrames;
@property (nonatomic) CGFloat exportSlabThickness;
@property (nonatomic) BOOL exportSliceIntervalSameAsVolumeSliceInterval;
@property (nonatomic) CGFloat exportSliceInterval, exportTransverseSliceInterval;
@property (nonatomic, readonly) NSInteger exportSequenceNumberOfFrames;

+ (double) angleBetweenVector:(float*) a andPlane:(float*) orientation;

- (id)initWithDCMPixList:(NSMutableArray*)pix filesList:(NSMutableArray*)files volumeData:(NSData*)volume viewerController:(ViewerController*)viewer fusedViewerController:(ViewerController*)fusedViewer;
- (DCMPix*) emptyPix: (DCMPix*) originalPix width: (long) w height: (long) h;
- (CPRMPRDCMView*) selectedView;
- (id) selectedViewOnlyMPRView: (BOOL) onlyMPRView;
- (void) computeCrossReferenceLines:(CPRMPRDCMView*) sender;
- (IBAction)setTool:(id)sender;
- (void) setToolIndex: (int) toolIndex;
- (float) getClippingRangeThicknessInMm;
- (void) propagateWLWW:(DCMView*) sender;
- (void) propagateOriginRotationAndZoomToTransverseViews: (CPRTransverseView*) sender;
- (void)bringToFrontROI:(ROI*) roi;
- (id) prepareObjectForUndo:(NSString*) string;
- (void)createWLWWMenuItems;
- (void)UpdateWLWWMenu:(NSNotification*)note;
- (void)ApplyWLWW:(id)sender;
- (void)applyWLWWForString:(NSString *)menuString;
- (void) updateViewsAccordingToFrame:(id) sender;
- (void)findShadingPreset:(id) sender;
- (IBAction)editShadingValues:(id) sender;
- (void) moviePlayStop:(id) sender;
- (IBAction) endDCMExportSettings:(id) sender;
- (void) addMoviePixList:(NSMutableArray*) pix :(NSData*) vData;
- (void)updateToolbarItems;
- (void)toogleAxisVisibility:(id) sender;
- (BOOL) getMovieDataAvailable;
- (void)Apply3DOpacityString:(NSString*)str;
- (void)Apply2DOpacityString:(NSString*)str;
- (NSImage*) imageForROI: (int) i;
- (void) setROIToolTag:(int) roitype;
- (IBAction) roiGetInfo:(id) sender;
- (void) delayedFullLODRendering: (id) sender;

- (NSDictionary*)exportDCMImage16bitWithWidth:(NSUInteger)width height:(NSUInteger)height fullDepth:(BOOL)fullDepth withDicomExport:(DICOMExport *)dicomExport; // dicomExport can be nil

@end
