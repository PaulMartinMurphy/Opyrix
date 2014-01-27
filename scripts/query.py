#  query.py
#  Opyrix
#
#  Created by Paul Murphy on 8/7/13.
#

server = OpyrixServer("LIG_OSI11","172.20.34.202","4006")
query = OpyrixQuery("*","smith","*","*","*")

print "Querying a server..."
studies = database.queryStudies(server,query)
print

print "Found ",len(studies)," matching studies"
print

for study in studies:
    
    print study.name()
    print study.patientID()
    print study.accessionNumber()
    print study.theDescription()
    print study.date()
    print study.time()
    print study.numberImages()
    print

print "Done!"

