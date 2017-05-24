#!/usr/bin/env python

"""
# Luca Filippin - April 2010 - luca.filippin@gmail.com                                                
# Copyright 2010 Language, Cognition and  Development Laboratory, Sissa, Trieste. All rights reserved.
# 
# PLEASE HAVE A LOOK TO THE SWIG DOCUMENTATION FOR A DEEPER UNDERSTANDING OF THIS CODE
# NOTE: Swig wrapper to t2t makes use of shadow classes and swig helpers (see t2tsw.i)
"""

from argparse import ArgumentParser
import sys
import turtle
from t2tsw import *
from t2tHelpers import *


def banner():
    print ""
    print "+-------------------------------------------------------------------------------------+"
    print "|  This is a sample application which shows eyes movements as tracked by the Tobii ET |"
    print "|-------------------------------------------------------------------------------------|"
    print "|  Luca Filippin - April 2010 - luca.filippin@gmail.com                               |"                                                
    print "|  Copyright 2010 Language, Cognition and  Development Laboratory, Sissa, Trieste     |"
    print "+-------------------------------------------------------------------------------------+"
    print ""

def parseOptions():
    parser = ArgumentParser(description='Display eyes movements by traking them through a Tobii Eyes Tracker')
    parser.add_argument('tobii_ip', help='tobii ip address')
    parser.add_argument('--version', action = 'version', version='%(prog)s v1.0')
    parser.add_argument("-l", "--log-file", dest="tobii_log", default="", help="log file name")
    parser.add_argument("-c", "--calibration-file", dest="calibration_file", default="", help="Use a stored calibration file")
    parser.add_argument("-p", "--port", dest="tobii_port", type=int, default=4455, help="TET server listening port")
    parser.add_argument("-d", "--debug-mode", dest="debug_mode", action="store_true", help="Print gaze samples")
    parser.add_argument("-m", "--camera", dest="camera", action="store_true", help="Use camera coordinates")
    parser.add_argument("-q", "--quick-start", dest="quick_start", action="store_true", help="Start soon after the command has been launched")
    parser.add_argument("-w", "--window-width", dest="window_width", type=float, default=0.5, help="Window width: range (0,1]")
    parser.add_argument("-e", "--window-height", dest="window_height", type=float, default=0.5, help="Window heigth: range (0,1]")
    parser.add_argument("-s", "--shape-size", dest="shape_size", type=float, default=0.4, help="size of the eyes: float > 0")
    parser.add_argument("-t", "--tracking-on", dest="tracking_on", action="store_true", help="Show the path made by the turtle")
    parser.add_argument("-v", "--validity", dest="validity", type=int, default=2, choices=xrange(0, 5), help='validity level: 0 = certainly, 1 = probably, 2 = 50%%, 3 = likely not 4 = surely not')
   
    try:
        o = parser.parse_args()
        if o.shape_size <= 0:
            raise Exception("Bad window shape size value '%(v)f': should be in (0, 1]" %{ 'v' : o.shape_size })
        if o.window_width <= 0 or o.window_width > 1:
            raise Exception("Bad window width value '%(v)f': should be in (0, 1]" %{ 'v' : o.window_width })
        if o.window_height <= 0 or o.window_height > 1:
            raise Exception("Bad window height value '%(v)f': should be in (0, 1]" %{ 'v' : o.window_height })
        if o.tobii_port < 0:
            raise Exception("Bad port value '%(v)s': should be > 0" %{ 'v' : o.tobii_port })
    except Exception, e:
        raise Exception("++ Argument error\n" + e.__str__())
     
    return o

def followEyes(eye_l, eye_r, line, validity, tracking, debug, camera, w, h, root):
    colors = ("red", "orange", "yellow", "blue", "white");
    
    c = t2tCmd()
    c.cmd = "GET_SAMPLE_EXT"    
    smp = cmdEx(c).sample_ext
    
    left = True
    right = True
	
    if camera:
	    lx, ly = 1 - smp.lxcam, smp.lycam
	    rx, ry = 1 - smp.rxcam, smp.rycam
    else:
	    lx, ly = smp.lx, smp.ly
	    rx, ry = smp.rx, smp.ry
	    
    if lx >= 0 and ly >= 0 and rx >= 0 and ry >= 0 and smp.lval <= validity and smp.rval <= validity:
        m = "Sample OO: " + smp.__str__()
        x, y = (lx + rx)*w/2, h-(ly + ry)*h/2
    elif rx >= 0 and  ry >= 0 and smp.rval <= validity:
        m = "Sample OX: " + smp.__str__()
        x, y = rx*w, h-ry*h
        left = False
    elif lx >= 0 and  ly >= 0 and smp.lval <= validity:
        m = "Sample XO: " + smp.__str__()
        x, y = lx*w, h-ly*h
        right = False
    else:
        m = "Sample XX: " + smp.__str__()
        right = False
        left = False
	
    if left:
        eye_l.showturtle()
        eye_l.color(colors[int(smp.lval)])
        eye_l.goto(lx*w, (1-ly)*h)
    else:
        eye_l.hideturtle()
            
    if right:
        eye_r.showturtle()
        eye_r.color(colors[int(smp.rval)])
        eye_r.goto(rx*w, (1-ry)*h)
    else:
        eye_r.hideturtle()
    
    if tracking:
        if left:
            eye_l.stamp()
        if right: 
            eye_r.stamp() 
        if left or right:
            line.goto(x, y)
                
        m += "\nMove to (x, y) = (%.0f, %.0f)" %(x, y)		
    else:
        m += "\nPrevious sample SKIPPED"
    
    if debug:
        print m;
    
    if not root.stop_follow_eyes:
        root.after(10, followEyes, eye_l, eye_r, line, validity, tracking, debug, camera, w, h, root)
    else:
        root.destroy()

def _get_out():
    root.stop_follow_eyes = True
    
try:

    banner()
    tobii_connected = False
    o = parseOptions() 
    if o.tobii_log <> "": 
        t2tOutputFileName(o.tobii_log, "w")
    
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
    
    if o.calibration_file <> "":
        print "Loading calibration data " + o.calibration_file + "..."
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
            bailOut(msg = "Start calibration failed\nExiting", disconnect = True)
        
        # there's no calibend flag set for loading
        if not checkStatus("calibrating", 0, timeout = 20): 
            bailOut(msg = "Start calibration failed\nExiting", disconnect = True)
    
    if o.quick_start:
        print "\n***** QUIT THE TRACKING WINDOW TO STOP *****\n"
    else:
        raw_input("\n***** PRESS <enter> TO START TRACKING, THEN QUIT THE TRACKING WINDOW TO STOP *****\n")
    
    c = t2tCmd()
    c.cmd = "START_TRACKING"
    cmdEx(c)
    checkStatus("running", 1, timeout = 5)
    if not checkStatus("runstarted", 1, timeout = 5):    
        bailOut(msg = "Start tracking failed\nExiting", disconnect = True)
    

    root = turtle.TK.Tk()
    w, h = root.winfo_screenwidth()*o.window_width, root.winfo_screenheight()*o.window_height
    root.title("Follow the eyes movements through a Tobii eyetracker")
    root.resizable(False, False)
    
    canvas = turtle.TK.Canvas(root, width=w, height=h, bg="#000000")
    canvas.pack()
    
    screen = turtle.TurtleScreen(canvas)
    screen.setworldcoordinates(0, 0, w, h)
    screen.bgcolor(0, 0, 0)
    
    eye_l = turtle.RawTurtle(screen)
    eye_r = turtle.RawTurtle(screen)
    
    for e in eye_l,eye_r:   
        e.shape("circle")
        e.color("red")
        e.shapesize(o.shape_size, o.shape_size, o.shape_size)
        e.speed(0)
        e.penup()
        e.hideturtle()
    
    line = turtle.RawTurtle(screen)
    line.color("green")
    line.speed(0)
    line.penup()
    line.hideturtle()
    
    if o.tracking_on:
        line.pendown();
 
    root.protocol( "WM_DELETE_WINDOW", _get_out)
    root.follow_eyes_id = []
    root.stop_follow_eyes = False
    followEyes(eye_l, eye_r, line, o.validity, o.tracking_on, o.debug_mode, o.camera, w, h, root)
    root.mainloop()
    
    c = t2tCmd()
    c.cmd = "STOP_TRACKING"
    cmdEx(c)
    checkStatus("stop", 1, timeout = 1)
    if not checkStatus("running", 0, timeout = 5): 
        bailOut(msg = "Stop tracking failed\nExiting", disconnect = True)
    
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
    