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

NSString* sopInstanceUIDDecode( unsigned char *r, int length);
void* sopInstanceUIDEncode( NSString *sopuid);

@class DCMSequenceAttribute, DicomSeries;

@interface NSData (OsiriX)
- (BOOL) isEqualToSopInstanceUID:(NSData*) sopInstanceUID;
@end

/** \brief  Core Data Entity for an image (frame) */

@interface DicomImage : NSManagedObject
{
	NSString	*completePathCache;
	
	NSString	*sopInstanceUID;
	NSNumber	*inDatabaseFolder;
	NSNumber	*height, *width;
	NSNumber	*numberOfFrames;
	NSNumber	*numberOfSeries;
	NSNumber	*mountedVolume;
	NSNumber	*isKeyImage, *dicomTime;
	NSString	*extension;
	NSString	*modality;
	NSString	*fileType;
}

@property(retain) NSNumber* numberOfFrames;

@property(nonatomic, retain) NSString* comment;
@property(nonatomic, retain) NSData* compressedSopInstanceUID;
@property(nonatomic, retain) NSDate* date;
@property(nonatomic, retain) NSNumber* frameID;
@property(nonatomic, retain) NSNumber* instanceNumber;
@property(nonatomic, retain) NSNumber* pathNumber;
@property(nonatomic, retain) NSString* pathString;
@property(nonatomic, retain) NSNumber* rotationAngle;
@property(nonatomic, retain) NSNumber* scale;
@property(nonatomic, retain) NSNumber* sliceLocation;
@property(nonatomic, retain) NSString* stateText;
@property(nonatomic, retain) NSString* storedExtension;
@property(nonatomic, retain) NSString* storedFileType;
@property(nonatomic, retain) NSNumber* storedHeight;
@property(nonatomic, retain) NSNumber* storedInDatabaseFolder;
@property(nonatomic, retain) NSNumber* storedIsKeyImage;
@property(nonatomic, retain) NSString* storedModality;
@property(nonatomic, retain) NSNumber* storedMountedVolume;
@property(nonatomic, retain) NSNumber* storedNumberOfFrames;
@property(nonatomic, retain) NSNumber* storedNumberOfSeries;
@property(nonatomic, retain) NSNumber* storedWidth;
@property(nonatomic, retain) NSNumber* windowLevel;
@property(nonatomic, retain) NSNumber* windowWidth;
@property(nonatomic, retain) NSNumber* xFlipped;
@property(nonatomic, retain) NSNumber* xOffset;
@property(nonatomic, retain) NSNumber* yFlipped;
@property(nonatomic, retain) NSNumber* yOffset;
@property(nonatomic, retain) NSNumber* zoom;
@property(nonatomic, retain) DicomSeries* series;

+ (NSData*) sopInstanceUIDEncodeString:(NSString*) s;
- (NSString*) uniqueFilename;
- (NSSet*) paths;
- (NSString*) completePath;
- (NSString*) completePathResolved;
- (void) clearCompletePathCache;
#ifndef OSIRIX_LIGHT
- (DCMSequenceAttribute*) graphicAnnotationSequence;
#endif
- (NSImage *)image;
- (NSImage *)thumbnail;
- (NSString*) completePathWithDownload:(BOOL) download;
+ (NSString*) dbPathForManagedContext: (NSManagedObjectContext *) c;
+ (NSString*) completePathForLocalPath:(NSString*) path directory:(NSString*) directory;
- (NSString*) SRFilenameForFrame: (int) frameNo;
- (NSString*) SRPathForFrame: (int) frameNo;
- (NSString*) SRPath;
- (NSString	*)sopInstanceUID;
@property(nonatomic, retain) NSString* modality;

@end

