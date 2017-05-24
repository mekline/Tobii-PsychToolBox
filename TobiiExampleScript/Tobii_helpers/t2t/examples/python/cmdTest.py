#!/usr/bin/env python

"""
# Luca Filippin - July 2010 - luca.filippin@gmail.com                                                
# Copyright 2010 Language, Cognition and  Development Laboratory, Sissa, Trieste. All rights reserved.
# 
# PLEASE HAVE A LOOK TO THE SWIG DOCUMENTATION FOR A DEEPER UNDERSTANDING OF THIS CODE
# NOTE: Swig wrapper to t2t makes use of shadow classes and swig helpers (see t2tsw.i)
"""

from argparse import ArgumentParser
from t2tsw import *
from t2tHelpers import *
import sys
import os
import time
import re

def banner():
    print ""
    print "+-------------------------------------------------------------------------------------+"
    print "|  This is a test application which tests some Tobii ET commands.                     |"
    print "|-------------------------------------------------------------------------------------|"
    print "|  Luca Filippin - July 2010 - luca.filippin@gmail.com                                |"                                                
    print "|  Copyright 2010 Language, Cognition and  Development Laboratory, Sissa, Trieste     |"
    print "+-------------------------------------------------------------------------------------+"
    print ""

def parseOptions():
    parser = ArgumentParser(description = 'Test a Tobii Eye Tracker')
    parser.add_argument('tobii_ip', help='tobii ip address')
    parser.add_argument('--version', action = 'version', version="%(prog)s v1.0")
    parser.add_argument("-l", "--log-file", dest="tobii_log", default="", help="log file name")
    parser.add_argument("-c", "--calibration-file", dest="calibration_file", default="", help="Use a stored calibration file")
    parser.add_argument("-t", "--tracked-data-file", dest="tracked_data_file", default="EyesTrackedData.txt", help="File where tracked data will be stored in the TET machine")
    parser.add_argument("-e", "--events-data-file", dest="events_data_file", default="EventsData.txt", help="File where events will be stored in the TET machine")
    parser.add_argument("-p", "--port", dest="tobii_port", type=int, default=4455, help="TET server listening port")
   
    try:
        o = parser.parse_args()
        if o.tobii_port < 0:
            raise Exception("Bad port value '%(v)s': should be > 0" %{ 'v' : o.tobii_port })
    except Exception, e:
        raise Exception("++ Argument error\n" + e.__str__())
    
    return o

try:

    banner()
    tobii_connected = False
    o = parseOptions() 
    if o.tobii_log <> "": 
        t2tOutputFileName(o.tobii_log, "w")
    
    # Connect to the tobii
    print "Connecting to the TET server @" + o.tobii_ip + ":" + '%(p)d' %{ 'p':o.tobii_port } + "..."
    c = t2tCmd()
    c.cmd = "CONNECT"
    c.prm.connect.ip_address = o.tobii_ip
    c.prm.connect.port = o.tobii_port
    cmdEx(c)
    checkStatus("connect", 1, timeout = 5, debug=False)
    if not checkStatus("connected", 1, timeout = 5, debug=False): 
        bailOut(msg = "Connection failed\nExiting", disconnect = False)
    tobii_connected = True
    
    raw_input("\n***** PRESS <enter> TO START THE TEST *****\n")
    
    # Run the demo 
    print "Running demo..."
    c = t2tCmd()
    c.cmd = "DEMO"
    cmdEx(c)
    
    if o.calibration_file <> "":
        print "Loading calibration data " + o.calibration_file + "..."
        c = t2tCmd()
        c.cmd = "START_CALIBRATION"
        c.prm.start_calibration.load_from_file = 1
        c.prm.start_calibration.fname = o.calibration_file
        c.prm.start_calibration.cmatrix.cols = 0
        c.prm.start_calibration.cmatrix.rows = 0
        c.prm.start_calibration.cmatrix.vals = None
        cmdEx(c)
        
        checkStatus("calibrating", 1, timeout = 5)
        if not checkStatus("calibstarted", 1, timeout = 5): 
            bailOut(msg = "Start calibration failed\nExiting", disconnect = True)
        
        # there's no calibend flag set for loading
        if not checkStatus("calibrating", 0, timeout = 20): 
            bailOut(msg = "Start calibration failed\nExiting", disconnect = True)
        
        c = t2tCmd()
        c.cmd = "CALIBRATION_ANALYSIS"  
        calib_an = cmdEx(c).calibration_analysis
        print "\nCalibration analisys data:\n\n" + t2tCalibrationData._compact_header + "\n" + calib_an.__str__(compact = True)
        
        print "Removing a couple of calibration samples set..."
        c = t2tCmd()
        c.cmd = "REMOVE_CALIBRATION_SAMPLES"
        c.prm.remove_calibration_samples.rmatrix.rows = 2
        c.prm.remove_calibration_samples.rmatrix.cols = 4
        vals = doubleArrayC(4*2)
        c.prm.remove_calibration_samples.rmatrix.vals = vals
        vals[0] = 1       # eye 
        vals[1] = 0.2     # x
        vals[2] = 0.15    # y
        vals[3] = 0.12    # radius
        vals[4] = 3       # eye
        vals[5] = 0.8     # x
        vals[6] = 0.7     # y
        vals[7] = 0.1     # radius
        cmdEx(c)
        
        if not checkStatus("removing_samples", 1, timeout = 5) or not checkStatus("removing_samples", 0, timeout = 5): 
            bailOut(msg = "Calibration samples removal failed\nExiting", disconnect = True)
        
        print "Recalculating & setting calibration..."
        c = t2tCmd()
        c.cmd = "START_CALIBRATION"
        c.prm.start_calibration.load_from_file = 0
        c.prm.start_calibration.fname = None
        c.prm.start_calibration.cmatrix.cols = 0
        c.prm.start_calibration.cmatrix.rows = 0
        c.prm.start_calibration.cmatrix.vals = None
        cmdEx(c)
        
        checkStatus("calibrating", 1, timeout = 5)
        if not checkStatus("calibstarted", 1, timeout = 5): 
            bailOut(msg = "Start calibration failed\nExiting", disconnect = True)


    # Do sync only after start_tracking or it will fail ??? It happens on T60
    print "Synchronizing..."
    c = t2tCmd()
    c.cmd = "SYNCHRONISE"
    cmdEx(c)
    checkStatus("synchronise", 1, timeout = 5)
    if not checkStatus("synchronised", 1, timeout = 5): 
        bailOut(msg = "Synchronizing failed\nExiting", disconnect = True)
    
    print "Start auto-sync..."
    c = t2tCmd()
    c.cmd = "START_AUTO_SYNC"
    cmdEx(c)
    if not checkStatus("autosynced", 1, timeout = 5): 
        bailOut(msg = "Start auto-sync failed\nExiting", disconnect = True)
    
    print "Start tracking..."
    c = t2tCmd()
    c.cmd = "START_TRACKING"
    cmdEx(c)
    checkStatus("running", 1, timeout = 5)
    if not checkStatus("runstarted", 1, timeout = 5): 
        bailOut(msg = "Start tracking failed\nExiting", disconnect = True)
    
    print "Getting some extended samples..."
    for i in xrange(0, 10):
        c = t2tCmd()
        c.cmd = "GET_SAMPLE_EXT"    
        smp = cmdEx(c).sample_ext
        print "> ", smp
        time.sleep(0.2)
    
    print "Getting some timestamps..."
    for i in xrange(0, 10):
        c = t2tCmd()
        c.cmd = None    
        print "> %f" %(cmdEx(c).timestamp.time)
        
    print "Start recording..."
    c = t2tCmd()
    c.cmd = "RECORD"
    cmdEx(c)
    time.sleep(2)
    
    print "Sending events..."
    for i in xrange(0, 5):
        c = t2tCmd()
        c.cmd = "EVENT"
        c.prm.event.name = "Event %d" %(i) 
        c.prm.event.duration = 1
        c.prm.event.nfields = 2
        c.prm.event.fields = new_charpArray(2)
        charpArray_setitem(c.prm.event.fields, 0, "FIELD 1")
        charpArray_setitem(c.prm.event.fields, 1, "FIELD 2")
        vals = doubleArrayC(2)
        c.prm.event.values = vals
        vals[0] = i*10
        vals[1] = i*10 + 1
        start_time = time.time()
        data = cmdEx(c)
        print "> Name = %s local_start = %f secs real_starts = %f secs duration = %s secs" %(c.prm.event.name, start_time, data.event.start_time, c.prm.event.duration)
        print "> Sleeping a bit..."
        delete_charpArray(c.prm.event.fields);
        time.sleep(1.5)
    
    print "Getting gazes data..."
    c = t2tCmd()
    c.cmd = "GET_GAZES_DATA"
    c.prm.get_gazes_data.from_sample_idx = 0
    data = cmdEx(c)
    if data.gazes_data <> None:
        print "> Start time: %f" %data.gazes_data.start_time
        for s in data.gazes_data.samples:
            print "> " +  s.__str__()
    else:
        print "No data"
    
    print "Getting events data..."
    c = t2tCmd()
    c.cmd = "GET_EVENTS_DATA"
    c.prm.get_events_data.from_event_idx = 0
    data = cmdEx(c)
    if data.events_data <> None:
        print "> Start time: %f" %(data.events_data.start_time)
        for e in data.events_data.events:
            print "> " + e.__str__()
    else:
        print "No data"
    
    c =t2tCmd()
    print "Saving data..."
    c.cmd = "SAVE_DATA"
    c.prm.save_data.eye_tracking_fname = o.tracked_data_file   
    c.prm.save_data.events_fname = o.events_data_file 
    c.prm.save_data.mode = "TRUNK"
    cmdEx(c)   
    
    print "Getting status and history..."
    c = t2tCmd()
    c.cmd = "GET_STATUS"
    c.prm.get_status.get_history = 1
    data = cmdEx(c)
    print "> Status: " + data.status_data.__str__()
    for f in data.history_data.facts:
        print "> " + f.__str__()
     
    print "Stop recording..."
    c = t2tCmd()
    c.cmd = "STOP_RECORD"
    cmdEx(c)
    
    print "Stop tracking..."
    c = t2tCmd()
    c.cmd = "STOP_TRACKING"
    cmdEx(c)
    checkStatus("stop", 1, timeout = 1)
    if not checkStatus("running", 0, timeout = 5): 
        bailOut(msg = "Stop tracking failed\nExiting", disconnect = True)
    
    print "Clearing data..."
    c = t2tCmd()
    c.cmd = "CLEAR_DATA"
    c.prm.clear_data.up_sample_index = -2;
    c.prm.clear_data.up_event_index = -2;
    cmdEx(c)
    
    print "Clearing history..."
    c = t2tCmd()
    c.cmd = "CLEAR_HISTORY"
    cmdEx(c)
    
    print "Stop auto-sync..."
    c = t2tCmd()
    c.cmd = "STOP_AUTO_SYNC"
    cmdEx(c)
    if not checkStatus("autosynced", 0, timeout = 5): 
        bailOut(msg = "Stop auto-sync failed\nExiting", disconnect = True)
   
    tobii_connected = False
    print "Disconnecting..."    
    c = t2tCmd()
    c.cmd = "DISCONNECT"
    cmdEx(c, disconnect = False)
    checkStatus("disconnect", 1, timeout = 5)
    if not checkStatus("connected", 0, timeout = 5): 
        bailOut(msg = "Disconnect failed\nExiting", disconnect = False)
    
    print "Cleanup..."
    c = t2tCmd()
    c.cmd = "CLEANUP"
    cmdEx(c)
    
    print "End.\n"
    
    t2tOutputFileName(None, None)
    
except Exception, e:
    msg =  "--------------- UNEXPECTED ERROR ---------------\n" + e.__str__()
    msg += "\n------------------------------------------------\n"
    msg += "\nThe application has been forcely closed!\n"
    bailOut(msg = msg, disconnect = tobii_connected)