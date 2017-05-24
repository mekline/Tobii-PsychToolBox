#!/usr/bin/env python

"""
# Luca Filippin - July 2010 - luca.filippin@gmail.com                                                
# Copyright 2010 Language, Cognition and  Development Laboratory, Sissa, Trieste. All rights reserved.
# 
# PLEASE HAVE A LOOK TO THE SWIG DOCUMENTATION FOR A DEEPER UNDERSTANDING OF THIS CODE
# NOTE: Swig wrapper to t2t makes use of shadow classes and swig helpers (see t2tsw.i)
"""

from argparse import ArgumentParser
from argparse import RawTextHelpFormatter
from t2tsw import *
from t2tHelpers import *
import sys
import os
import time
import re
import pygame

def banner():
    print ""
    print "+-------------------------------------------------------------------------------------+"
    print "|  This is a sample application which performs the calibration of a Tobii ET.         |"
    print "|-------------------------------------------------------------------------------------|"
    print "|  Luca Filippin - July 2010 - luca.filippin@gmail.com                                |"                                                
    print "|  Copyright 2010 Language, Cognition and  Development Laboratory, Sissa, Trieste     |"
    print "+-------------------------------------------------------------------------------------+"
    print ""

def parseOptions():
    parser = ArgumentParser(description='Calibrate a Tobii Eyes Tracker', formatter_class=RawTextHelpFormatter)
    parser.add_argument('tobii_ip', help='tobii ip address')
    parser.add_argument('input_file', help='calibration points file.\nfile line format: "x[0,1] y[0,1] height(0,1] width(0,1] delay(ms) picture_file_name"\nfield separator: tab')
    parser.add_argument('--version', action = 'version', version="%(prog)s v1.0")
    parser.add_argument("-l", "--log-file", dest="tobii_log", default="", help="log file name")
    parser.add_argument("-p", "--port", dest="tobii_port", type=int, default=4455, help="TET server listening port")
    parser.add_argument("-o", "--calibration-file", dest="calibration_file", default=None, help="Name of the file which will store the calibration results")
    parser.add_argument("-d", "--load-calibration", dest="calibration_load", action="store_true", help="Use existing calibration: just print results")
    parser.add_argument("-s", "--start-delay", dest="start_delay", type = float, default=0, help="Start calibration after a specific delay (secs)")
    parser.add_argument("-r", "--output-file", dest="output_file", default="", help="Name of the file which will store the collected data")
    
    try:
        o = parser.parse_args()
        if o.start_delay < 0:
            raise Exception("Bad delay value '%(v)s': should be > 0" %{ 'v' : o.start_delay })
        if o.tobii_port < 0:
            raise Exception("Bad port value '%(v)s': should be > 0" %{ 'v' : o.tobii_port })
    except Exception, e:
        raise Exception("++ Argument error\n" + e.__str__())
    
    return o

class calib_point_data(object):
    pass
    
def parseInputFile(filename):
    ignore_line_re = re.compile("^#*\s*$")
    data_line_re = re.compile("^(\d*\.?\d+)\t(\d*\.?\d+)\t(\d*\.?\d+)\t(\d*\.?\d+)\t(\d+)\t(.*)") # x y height width delay fname
    data = calib_point_data()
    data.size = 0
    data.x = []
    data.y = []
    data.height = []
    data.width = []
    data.delays = []
    data.pictfn = []

    try:
        F = None
        F = open(filename, 'r')
        data_lines = F.read().split('\n')
        
        for i in xrange(0, len(data_lines)):
            if re.match(ignore_line_re, data_lines[i]):
                continue
            m = re.match(data_line_re, data_lines[i])
            if m <> None:
                x = float(m.group(1))
                y = float(m.group(2))
                h = float(m.group(3))
                w = float(m.group(4))
                t = int(m.group(5))
                f = m.group(6)
                
                if (x < 0 or x > 1) or (y < 0 or y> 1) or (h <= 0 or h> 1) or (w <= 0 or w> 1)  or (t < 0):
                    raise Exception("  Data line is in bad format:\n" + data_lines[i])
                if not os.path.isfile(f):
                    raise Exception("  File is not existing or is not a file:\n" + f)
            else:
                raise Exception("  Unexpected line:\n" + data_lines[i])
                
            data.x.append(x)
            data.y.append(y)
            data.height.append(h)
            data.width.append(w)
            data.delays.append(t)
            data.pictfn.append(f)
         
        data.size = len(data.x)
        
    except Exception, e:
        raise Exception("++ Error reading input file\n" + e.__str__())
    finally:
        if F != None: 
            F.close()
    return data
    
def writeOutputFile(filename, data):
    ok = True
    try:
        F = None
        F = open(filename, 'w')
        F.write(t2tCalibrationData._compact_header + "\n" + data.__str__(compact = True)) 
    except Exception, e:
        ok = False
    finally:
        if F != None: 
            F.close()  
    return ok    

try:

    banner()
    tobii_connected = False
    o = parseOptions() 
    if o.tobii_log <> "": 
        t2tOutputFileName(o.tobii_log, "w")
    
    if not o.calibration_load:
        data = parseInputFile(o.input_file)
        if data.size < 2:
            bailOut(msg = "Calibration needs at least 2 points\nExiting", disconnect = False)
        
        # Initialise pygame and load the pictures in memory
        pygame.init()
        pygame.mouse.set_visible(0)
        pygame.display.set_caption("Tobii Eye Tracker Calibration")
        screen = pygame.display.set_mode()
        background = pygame.Surface(screen.get_size()).convert()
        bg_size = background.get_size()
        background.fill((0, 0, 0))
        data.pictures = []
        for i in xrange(0, data.size):
            p = pygame.image.load(data.pictfn[i]).convert()
            h, w = data.height[i], data.width[i]
            data.pictures.append(pygame.transform.scale(p, (int(bg_size[1]*w), int(bg_size[0]*h))))
    
    # Connect to the tobii
    print "Connecting to the TET server @" + o.tobii_ip + ":" + '%(p)d' %{ 'p':o.tobii_port } + "..."
    c = t2tCmd()
    c.cmd = "CONNECT"
    c.prm.connect.ip_address = o.tobii_ip
    c.prm.connect.port = o.tobii_port
    cmdEx(c)
    checkStatus("connect", 1, timeout = 5)
    if not checkStatus("connected", 1, timeout = 5): 
        bailOut(msg = "Connection failed\nExiting", disconnect = False)
    tobii_connected = True
    
    if o.calibration_load:        
        c = t2tCmd()
        c.cmd = "START_CALIBRATION"
        c.prm.start_calibration.load_from_file = 1
        c.prm.start_calibration.cmatrix.cols = 0
        c.prm.start_calibration.fname = o.calibration_file
        c.prm.start_calibration.cmatrix.rows = 0
        c.prm.start_calibration.cmatrix.vals = None
        cmdEx(c)
        
        checkStatus("calibrating", 1, timeout = 5)
        if not checkStatus("calibstarted", 1, timeout = 5): 
            bailOut(msg = "Load calibration failed\nExiting", disconnect = True)
        
        # there's no calibend flag set for loading
        if not checkStatus("calibrating", 0, timeout = 20): 
            bailOut(msg = "Load calibration failed\nExiting", disconnect = True)
            
    else:
        if o.start_delay == 0:
            raw_input("\n***** PRESS <enter> TO START CALIBRATION *****\n")
        else:
            time.sleep(o.start_delay)
        
        # A tracking phase seems to be necessary before starting a calibration, or it will fails very often.
    	# There's no explanation or documentation about, but it works like that.
    	c = t2tCmd()
        c.cmd = "START_TRACKING"
        cmdEx(c)
        checkStatus("running", 1, timeout = 5)
        if not checkStatus("runstarted", 1, timeout = 5):    
            bailOut(msg = "Start tracking failed\nExiting", disconnect = True)
    	time.sleep(2)
    	c = t2tCmd()
        c.cmd = "STOP_TRACKING"
        cmdEx(c)
        checkStatus("stop", 1, timeout = 1)
        if not checkStatus("running", 0, timeout = 5): 
            bailOut(msg = "Stop tracking failed\nExiting", disconnect = True)
        
        # Start now the calibration phase
        c = t2tCmd()
        c.cmd = "START_CALIBRATION"
        c.prm.start_calibration.clear_previous = 1
        c.prm.start_calibration.samples_per_point = 20 
        c.prm.start_calibration.load_from_file = 0
        c.prm.start_calibration.fname = o.calibration_file
        c.prm.start_calibration.cmatrix.cols = 2
        c.prm.start_calibration.cmatrix.rows = data.size
        vals = doubleArrayC(2*data.size)
        c.prm.start_calibration.cmatrix.vals = vals
        for i in xrange(0, data.size):
            vals[i*2] = data.x[i]
            vals[i*2+1] = data.y[i] 
        cmdEx(c)
        
        checkStatus("calibrating", 1, timeout = 5)
        if not checkStatus("calibstarted", 1, timeout = 5): 
            bailOut(msg = "Start calibration failed\nExiting", disconnect = True)
        
        if pygame.font:
            text = pygame.font.Font(None, 36).render("Please focus on the appearing pictures...", 1, (10, 10, 10))
            textpos = text.get_rect(centerx=background.get_width()/2)
            background.blit(text, textpos)
            pygame.display.flip()
            pygame.time.delay(2000)
            screen.blit(text, textpos, special_flags = pygame.BLEND_SUB)
            pygame.display.flip()
            
        # Do not check status while adding/drawing points 
        for i in xrange(0, data.size):
            x, y, h, w = data.x[i], data.y[i], data.height[i], data.width[i]
            screen.blit(data.pictures[i], ((x - w/2) * bg_size[0], (y - h/2) * bg_size[1]))
            pygame.display.flip()
            c = t2tCmd()
            c.cmd = "ADD_CALIBRATION_POINT"
            cmdEx(c)
            pygame.time.delay(data.delays[i])
            c = t2tCmd()
            c.cmd = "DREW_POINT"
            cmdEx(c)
            screen.blit(data.pictures[i], ((x - w/2)*bg_size[0], (y - h/2) * bg_size[1]), special_flags = pygame.BLEND_SUB)
            pygame.display.flip()  
        
        if pygame.font:
            text = pygame.font.Font(None, 36).render("The calibration has been completed. Thanks!", 1, (10, 10, 10))
            textpos = text.get_rect(centerx=background.get_width()/2)
            background.blit(text, textpos)
            pygame.display.flip()
            pygame.time.delay(2000)
            screen.blit(text, textpos, special_flags = pygame.BLEND_SUB)
            pygame.display.flip()
   
        pygame.display.quit()
        
        if not checkStatus("calibend", 1, timeout = 30): 
            bailOut(msg = "End calibration delayed... \nExiting", disconnect = True)
    
    c = t2tCmd()
    c.cmd = "CALIBRATION_ANALYSIS"  
    calib_an = cmdEx(c).calibration_analysis
    if calib_an <> None:
        print_data = (o.output_file == "")
        if not print_data:
            if not writeOutputFile(o.output_file, calib_an):
                print "Error: can't save data file! Print to screen..."
                print_data = True
        if print_data:
            print "\nCalibration analisys data:\n\n" + t2tCalibrationData._compact_header + "\n" + calib_an.__str__(compact = True)
    else:
        print "Calibration failed: no data"
    
    tobii_connected = False
    c = t2tCmd()
    c.cmd = "DISCONNECT"
    cmdEx(c, disconnect = False)
    checkStatus("disconnect", 1, timeout = 5)
    if not checkStatus("connected", 0, timeout = 5): 
        bailOut(msg = "Disconnect failed\nExiting", disconnect = False)
    
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