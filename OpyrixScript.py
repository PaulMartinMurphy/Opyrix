#  OpyrixScript.py
#  Opyrix
#
#  Created by Paul Murphy on 8/7/13.
#

#!/usr/bin/python
#
# Embedded Python scripting in OsiriX
#
# (c) Paul Murphy, 2013
#

import sys
import traceback
import os.path
import time
import objc

from Foundation import NSObject

class OpyrixStopScript:
    pass

class OpyrixMetaDataStudy:
    
    def __init__(self,dcmObject):
        self.patientName   = dcmObject.attributeValueWithName_("PatientsName")
        self.patientID     = dcmObject.attributeValueWithName_("PatientID") # long
        self.patientDOB    = dcmObject.attributeValueWithName_("PatientsBirthDate")
        self.patientSex    = dcmObject.attributeValueWithName_("PatientSex")
        #self.patientWeight = float(dcmObject.attributeValueWithName_("PatientsWeight"))
        #self.referringPhysician = dcmObject.attributeValueWithName_("ReferringPhysiciansName")
        
        self.scanner = dcmObject.attributeValueWithName_("StationName")
        self.studyID = dcmObject.attributeValueWithName_("StudyID") # long
        self.studyDate = dcmObject.attributeValueWithName_("StudyDate")
        self.acqTime = dcmObject.attributeValueWithName_("AcquisitionTime")

class OpyrixMetaDataSeries (OpyrixMetaDataStudy):
    
    def __init__(self,dcmObject):
        OpyrixMetaDataStudy.__init__(self,dcmObject)
        
        self.seriesDesc = dcmObject.attributeValueWithName_("SeriesDescription")
        self.seriesID   = dcmObject.attributeValueWithName_("SeriesNumber") # long

class OpyrixMetaDataImageMRI (OpyrixMetaDataSeries):
    
    def __init__(self,dcmObject):
        OpyrixMetaDataSeries.__init__(self,dcmObject)
        
        self.TR = float(dcmObject.attributeValueWithName_("RepetitionTime"))
        self.TE = float(dcmObject.attributeValueWithName_("EchoTime"))
        self.echoNumber = int(dcmObject.attributeValueWithName_("EchoNumbers"))
        self.flipAngle = float(dcmObject.attributeValueWithName_("FlipAngle"))
        self.bandwidth = float(dcmObject.attributeValueWithName_("PixelBandwidth"))
        
        #matrixRows = dcmObject.attributeArrayWithName_("AcquisitionMatrix").objectAtIndex_(0)
        #matrixCols = dcmObject.attributeArrayWithName_("AcquisitionMatrix").objectAtIndex_(3)
        self.pixelSpacingRow = float(dcmObject.attributeArrayWithName_("PixelSpacing").objectAtIndex_(0))
        self.pixelSpacingCol = float(dcmObject.attributeArrayWithName_("PixelSpacing").objectAtIndex_(1))
        self.percentPhaseFOV = float(dcmObject.attributeValueWithName_("PercentPhaseFieldofView"))
        self.rows = int(dcmObject.attributeValueWithName_("Rows"))
        self.cols = int(dcmObject.attributeValueWithName_("Columns"))
        self.rowFOV = self.rows * self.pixelSpacingRow / 10.0
        self.colFOV = self.rows * self.pixelSpacingRow / 10.0
        
        self.sliceThickness = float(dcmObject.attributeValueWithName_("SliceThickness"))
        self.sliceLocation  = float(dcmObject.attributeValueWithName_("SliceLocation"))
        self.sliceID = long(dcmObject.attributeValueWithName_("In-StackPositionNumber"))
        self.spacingBetweenSlices = float(dcmObject.attributeValueWithName_("SpacingBetweenSlices"))
        self.sliceGap = self.spacingBetweenSlices - self.sliceThickness
        
        DCMAttributeTag = objc.lookUpClass("DCMAttributeTag") # should really make this a static data member
        self.psdPath = dcmObject.attributeForTag_(DCMAttributeTag.tagWithGroup_element_(0x19,0x109c)).value()
        self.psdDate = dcmObject.attributeForTag_(DCMAttributeTag.tagWithGroup_element_(0x19,0x109d)).value()
        self.psdType = dcmObject.attributeForTag_(DCMAttributeTag.tagWithGroup_element_(0x19,0x109e)).value()

class OpyrixROI:
    def __init__(self,roi):
        self.roi = roi
        self.name = self.roi.name()
        self.comments = self.roi.comments()
    
    def area(self):
        return self.roi.roiArea()
    
    def centroid(self):
        return self.roi.centroid()

    def angle(self):
        #return self.script.window.computeAngle_(self.roi)
        if self.roi.type() != 12 or self.roi.points().count() != 3:
            return None
        p0 = self.roi.pointAtIndex_(0)
        p1 = self.roi.pointAtIndex_(1)
        p2 = self.roi.pointAtIndex_(2)
        return self.roi.Angle___(p0,p1,p2)

    def length(self):
        if self.roi.type() != 5 or self.roi.points().count() != 2:
            return None

        p0 = self.roi.pointAtIndex_(0)
        p1 = self.roi.pointAtIndex_(1)

        return self.roi.Length__(p0,p1)

    def points(self):
        return self.roi.points()

    def type(self):
        types = ["tWL",\
                 "tTranslate",\
                 "tZoom",\
                 "tRotate",\
                 "tNext",\
                 "tMesure",\
                 "tROI",\
                 "t3DRotate",\
                 "tCross",\
                 "tOval",\
                 "tOPolygon",\
                 "tCPolygon",\
                 "tAngle",\
                 "tText",\
                 "tArrow",\
                 "tPencil",\
                 "t3Dpoint",\
                 "t3DCut",\
                 "tCamera3D",\
                 "t2DPoint",\
                 "tPlain",\
                 "tBonesRemoval",\
                 "tWLBlended",\
                 "tRepulsor",\
                 "tLayerROI",\
                 "tROISelector",\
                 "tAxis",\
                 "tDynAngle",\
                 "tCurvedROI"]
        
        type = self.roi.type()

        if type >= len(types):
            return "Unknown"
        
        return types[ self.roi.type() ]


# From Classes > 2DViewer > Single Window > DCMView.h
#enum {
#tWL							=	0,
#tTranslate,					//	1
#tZoom,						//	2
#tRotate,					//	3
#tNext,						//	4
#tMesure,					//	5
#tROI,						//	6
#t3DRotate,					//	7
#tCross,						//	8
#tOval,						//	9
#tOPolygon,					//	10
#tCPolygon,					//	11
#tAngle ,					//	12
#tText,						//	13
#tArrow,						//	14
#tPencil,					//	15
#t3Dpoint,					//	16
#t3DCut,						//	17
#tCamera3D,					//	18
#t2DPoint,					//	19
#tPlain,						//	20
#tBonesRemoval,				//	21
#tWLBlended,					//  22
#tRepulsor,					//  23
#tLayerROI,					//	24
#tROISelector,				//	25
#tAxis,						//	26
#tDynAngle,					//	27
#tCurvedROI					//	28
#};



class OpyrixROIData:
    def __init__(self,x):
        if len(x) != 5:
            print ">>> OpyrixROIData:: couldn't init from:",x
            return
        
        self.avg = x[0]
        self.sum = x[1]
        self.dev = x[2]
        self.min = x[3]
        self.max = x[4]

class OpyrixImage:
    def __init__(self,dicomImage,dicomStudy,script):
        self.dicomImage = dicomImage
        self.dicomStudy = dicomStudy
        self.script = script
        self.dcmPix = None
    
    def getMetaData(self,metaDataClass=OpyrixMetaDataImageMRI):
        dcmObject = self.script.DCMObject.objectWithContentsOfFile_decodingPixelData_(self.dicomImage.completePath(),False)
        return metaDataClass(dcmObject)
    
    def getROIs(self):
        dicomROIs = self.script.window.getROIs_image_(self.dicomStudy,self.dicomImage)
        if dicomROIs == None:
            return []
        else:
            return [OpyrixROI(x) for x in dicomROIs]
    
    def loadDCMPix(self):
        self.dcmPix = self.script.window.getDCMPix_(self.dicomImage)
    
    def getROIData(self,opyrixROI):
        if self.dcmPix == None:
            self.loadDCMPix()
        return OpyrixROIData(self.script.window.computeROI_roi_(self.dcmPix,opyrixROI.roi))
    
    def getROIValues(self,opyrixROI):
        if self.dcmPix == None:
            self.loadDCMPix()
        return self.script.window.getROIValues_roi_(self.dcmPix,opyrixROI.roi)

#class OpyrixSlices:
#    def __init__(self,dicomSeries,dicomStudy,script):
#        self.dicomSeries = dicomSeries
#        self.dicomStudy  = dicomStudy
#        self.script = script

class OpyrixSeries:
    def __init__(self,dicomSeries,dicomStudy,script):
        self.dicomSeries = dicomSeries
        self.dicomStudy  = dicomStudy
        self.script = script
    
    def getImages(self):
        return [OpyrixImage(x,self.dicomStudy,self.script) for x in self.dicomSeries.sortedImages()]
    
    def getMetaData(self,metaDataClass=OpyrixMetaDataSeries):
        if len(self.dicomSeries.sortedImages()) == 0:
            return None
        return OpyrixImage( self.dicomSeries.sortedImages()[0],
                           self.dicomStudy,
                           self.script ).getMetaData(metaDataClass)

class OpyrixSeriesIterator: # iterator and array
    
    def __init__(self,dicomStudy,script):
        self.dicomStudy = dicomStudy
        self.script = script
        
        self.series = dicomStudy.imageSeries()
        self.index = 0
    
    def __iter__(self):
        return self
    
    def __len__(self):
        return len(self.studies)
    
    def __getitem__(self,i):
        return OpyrixSeries(self.series[i],self.dicomStudy,self.script)
    
    def next(self):
        if self.script.window.isScriptStopped(): # need to make iterators for Series at least
            #raise StopIteration
            raise OpyrixStopScript
        
        if self.index >= len(self.series):
            raise StopIteration
        else:
            i = self.index
            self.index = self.index + 1
            return self.__getitem__(i)

class OpyrixStudy:
    def __init__(self,dicomStudy,script):
        self.dicomStudy = dicomStudy
        self.script = script
    
    def getSeries(self):
        #return [OpyrixSeries(x,self.dicomStudy,self.script) for x in self.dicomStudy.imageSeries()]
        return OpyrixSeriesIterator(self.dicomStudy,self.script)
    
    def getMetaData(self,metaDataClass=OpyrixMetaDataStudy):
        if len(self.dicomStudy.imageSeries()) == 0:
            return None
        return OpyrixSeries( self.dicomStudy.imageSeries()[0],
                            self.dicomStudy,
                            self.script ).getMetaData(metaDataClass)

class OpyrixStudiesIterator: # iterator and array
    
    def __init__(self,script):
        self.script = script
        
        self.studies = []
        for item in self.script.browser.databaseSelection():
            if item.isKindOfClass_(self.script.DicomStudy):
                self.studies.append(item)
        self.index = 0
    
    def __iter__(self):
        return self
    
    def __len__(self):
        return len(self.studies)
    
    def __getitem__(self,i):
        self.script.window.setProgress_(i * 100.0 / len(self.studies))
        return OpyrixStudy(self.studies[i],self.script)
    
    def next(self):
        if self.script.window.isScriptStopped(): # need to make iterators for Series at least
            #raise StopIteration
            raise OpyrixStopScript
        
        if self.index >= len(self.studies):
            self.script.window.setProgress_(100.0)
            raise StopIteration
        else:
            i = self.index
            self.index = self.index + 1
            return self.__getitem__(i)

class OpyrixServer:
    def __init__(self,server):
        self.server = server

class OpyrixQuery:
    
    @staticmethod
    def getDate(querydate):
        DCMCalendarDate = objc.lookUpClass("DCMCalendarDate")
        return DCMCalendarDate.queryDate_(querydate)
    
    def __init__(self,filters):
        if not isinstance(filters,dict):
            raise Exception("OpyrixQuery - please initialize with a dictionary")
        if len(filters) == 0:
            raise Exception("OpyrixQuery - unfiltered queries are not allowed! please add one or more filters to the query")
        # !!! should really do some error checking here
        self.filters = filters

    def __init__(self,first,last,mrn,date,modality):
        self.filters = {"PatientsName":last + "*" + first + "*",
            "PatientID":mrn,
            "StudyDate":OpyrixQuery.getDate(date)}
        if modality != "*":
            self.filters["Modality"] = modality

class OpyrixViewer:
    
    def __init__(self,script,viewerController):
        self.script = script
        self.viewerController = viewerController
    
    def loadROIs(self,filename):
        self.script.window.loadROIs_filename_(self.viewerController,filename)
    
    def loadROIsBackwards(self,filename,order):
        self.script.window.loadROIsBackwards_filename_order_(self.viewerController,filename,order)
    
    def deleteAllROIs(self):
        self.script.window.deleteAllROIs_(self.viewerController)
    
    def close(self):
        self.script.window.closeViewer_(self.viewerController)

class OpyrixDatabase:
    logAllQueries = False
    
    def __init__(self,script):
        self.script = script
    
    def getSelectedStudies(self):
        return OpyrixStudiesIterator(self.script)
    
    def findServer(self,aet):
        pass
    
    def queryStudies(self,server,query):
        if self.script.window.isScriptStopped():
            raise OpyrixStopScript
        
        if OpyrixDatabase.logAllQueries:
            # to keep track of the queries that people are doing
            fout = open("/Users/" + os.getlogin() + "/OpyrixDatabase.log","a")
            line = [time.asctime(),"queryStudies",server.server["AETitle"],server.server["Address"],server.server["Port"]]
            for k,v in query.filters.items():
                line.extend([k,v])
            fout.write('\t'.join([str(x) for x in line]) + "\n")
            fout.close()
    
        return self.script.window.queryStudies_server_(query.filters,server.server)

    def queryNode(self,node,query):
        if self.script.window.isScriptStopped():
            raise OpyrixStopScript
        return self.script.window.queryNode_node_(query.filters,node)

    
    def retrieveStudyByAccessionNumber(self,server,accession_number):
        if self.script.window.isScriptStopped():
            raise OpyrixStopScript
        return self.script.window.retrieveStudyByAccessionNumber_server_(str(accession_number),server.server)
    
    def retrieveStudyFromQuery(self,study):
        if self.script.window.isScriptStopped():
            raise OpyrixStopScript
        
        return self.script.window.retrieveStudyFromQuery_(study)

    def getServerTitles(self):
        return self.script.window.getServerTitles()
            
    def getServer(self,aet):
        return OpyrixServer( self.script.window.getServer_(aet) )

    def saveROIAsTIFF(self,pix,roi,wl,ww,filename):
        self.script.window.saveROIAsTIFF_roi_WL_WW_filename_(pix,roi.roi,wl,ww,filename)
    
    def saveTriAsTIFF(self,pix,p0,p1,p2,wl,ww,filename):
        self.script.window.saveTriAsTIFF_p0_p1_p2_WL_WW_filename_(pix,p0,p1,p2,wl,ww,filename)

    def displayStudy(self,study):
        viewerController = self.script.window.displayStudy_element_(study.dicomStudy,study.dicomStudy)
        return OpyrixViewer(self.script,viewerController)

    def displaySeries(self,series):
        viewerController = self.script.window.displayStudy_element_(series.dicomStudy,series.dicomSeries)
        return OpyrixViewer(self.script,viewerController)


class OpyrixOutput:
    def __init__(self,script):
        self.script = script
    
    def write(self,data):
        self.script.window.appendText_(str(data))

# implementing this as a helper function just to get rid of self

class OpyrixScript(NSObject):
    def __init__(self):
        self = super(OpyrixScript, self).init()
    
    def run_browser_window_(self,filename,browser,window):
        
        self.DicomStudy = objc.lookUpClass("DicomStudy") # XXX would prefer to do these in init, but not sure init is ever called
        self.DCMObject = objc.lookUpClass("DCMObject")
        
        self.filename = filename
        self.browser  = browser
        self.window   = window
        
        self.database = OpyrixDatabase(self)
        
        sys.stdout = OpyrixOutput(self)
        sys.stderr = sys.stdout
        
        #print ">>> OpyrixScript::run_browser_window_"
        
        try:
            return execfile(filename,{"database":self.database,
                            "OpyrixMetaDataStudy":OpyrixMetaDataStudy,
                            "OpyrixMetaDataSeries":OpyrixMetaDataSeries,
                            "OpyrixMetaDataImageMRI":OpyrixMetaDataImageMRI,
                            "OpyrixServer":OpyrixServer,
                            "OpyrixQuery":OpyrixQuery,
                            "OpyrixStopScript":OpyrixStopScript})
        except OpyrixStopScript as e:
            print ">>> Stopped script during execution"
            return 1
        except Exception as e:
            print ">>> Caught an exception during execution:"
            traceback.print_exc()
            return 1


