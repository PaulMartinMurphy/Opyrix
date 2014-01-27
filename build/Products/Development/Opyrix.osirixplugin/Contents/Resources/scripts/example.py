#  example.py
#  Opyrix
#
#  Created by Paul Murphy on 8/7/13.
#

print "Printing data from all ROI's in the selected study"

for study in database.getSelectedStudies():
    print "PatientName: ",study.getMetaData().patientName

    for series in study.getSeries():
        print "\tSeriesDesc: ",series.getMetaData().seriesDesc

        for image in series.getImages():
            
            rois = image.getROIs()
            
            if len(rois) > 0:
            
                print "\t\tNumberOfROIs: ",len(rois)

                for roi in rois:

                    print "\t\t\tROIName: ",roi.name

                    angle = roi.angle()

                    if angle != None:
                    
                        print "\t\t\t\tAngle: ",angle

print "Done"

