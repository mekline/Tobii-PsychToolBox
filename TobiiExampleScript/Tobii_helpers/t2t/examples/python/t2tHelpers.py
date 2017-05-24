"""
# Luca Filippin - April 2010 - luca.filippin@gmail.com                                                
# Copyright 2010 Language, Cognition and  Development Laboratory, Sissa, Trieste. All rights reserved.
# 
# PLEASE HAVE A LOOK TO THE SWIG DOCUMENTATION FOR A DEEPER UNDERSTANDING OF THIS CODE
# NOTE: Swig wrapper to t2t makes use of shadow classes and swig helpers (see t2tsw.i)
"""

import threading
import time
import sys
from t2tsw import *

class GenericData(object):
    pass
        
class TimedTask(object):
    def __init__(self, period, cb, *cbArgs):
        self._period = period
        self._userCb = (cb, cbArgs)
        self._thread = threading.Timer(period, self._threadCb)
                
    def _threadCb(self):
        if not self._userCb[0](*self._userCb[1]):
            self._thread.cancel()
            del self._thread
            self._thread = None
        else:
            self._thread = threading.Timer(self._period, self._threadCb)
            self._thread.start()
            
    def start(self):
        if self._thread <> None: self._thread.start()
    
    def stop(self):
        if self._thread <> None: self._thread.cancel()
        
class point(object):
    def __init__(self, x, y):
        self.x = x
        self.y = y

class t2tStatus(object):
        
    def __init__(self, st):
        if not isinstance(st, t2tCmdPrms_get_status):
            raise NameError("Bad object: " + st.__name__()) 
        if st.st_matrix.cols < 12:
            raise NameError("Bad columns number: " + st.st_matrix.cols.__str__())
        v = st.st_matrix.vals;
        self.connect = doubleArray_getitem(v, 0) and 1 or 0
        self.connected = doubleArray_getitem(v, 1) and 1 or 0
        self.disconnect = doubleArray_getitem(v, 2) and 1 or 0
        self.calibrating = doubleArray_getitem(v, 3) and 1 or 0
        self.calibstarted = doubleArray_getitem(v, 4) and 1 or 0
        self.running = doubleArray_getitem(v, 5) and 1 or 0
        self.runstarted = doubleArray_getitem(v, 6) and 1 or 0
        self.stop = doubleArray_getitem(v, 7) and 1 or 0
        self.finished = doubleArray_getitem(v, 8) and 1 or 0
        self.synchronise = doubleArray_getitem(v, 9) and 1 or 0
        self.calibend = doubleArray_getitem(v, 10) and 1 or 0
        self.synchronised = doubleArray_getitem(v, 11) and 1 or 0
        self.autosynced = doubleArray_getitem(v, 12) and 1 or 0
        self.removing_samples = doubleArray_getitem(v, 13) and 1 or 0
        self.can_draw_point = doubleArray_getitem(v, 14) and 1 or 0
        
    def __str__(self):
        str = ""
        for attr in vars(self):
            str += attr + " = %(v)d " %{ 'v': getattr(self, attr) }
        return str

class t2tHistoryFact(object):
    def __init__(self, code, time):
        self.time = time
        self.code = int(code)
    
    def __str__(self):
        str = ""
        for attr in vars(self):
            fmt = " = %(v)d "
            if attr == "time": fmt = " = %(v)f "
            str += attr + fmt %{ 'v': int(getattr(self, attr)) }
        return str

class t2tHistory(object):
    def __init__(self, st):
        if not isinstance(st, t2tCmdPrms_get_status):
            raise NameError("Bad object: " + st.__name__()) 
        v = st.hs_matrix.vals
        n = st.hs_matrix.cols/2
        self.facts = []
       
        for i in xrange(0, n):
            self.facts.append(t2tHistoryFact(doubleArray_getitem(v,i), doubleArray_getitem(v, i+n)))
        
    def __str__(self):
        str = ""
        for e in self.facts:
            str += e.__str__() + "\n"
        return str
        
class t2tSample(object):

    def _store(self, v, i, extended):
        self.lx = doubleArray_getitem(v, i+0)
        self.ly = doubleArray_getitem(v, i+1)
        self.rx = doubleArray_getitem(v, i+2)
        self.ry = doubleArray_getitem(v, i+3)
        self.timeSec = doubleArray_getitem(v, i+4)
        self.timeMic = doubleArray_getitem(v, i+5)
        self.lval = doubleArray_getitem(v, i+6)
        self.rval = doubleArray_getitem(v, i+7)
        self.lxcam = doubleArray_getitem(v, i+8)
        self.lycam = doubleArray_getitem(v, i+9)
        self.rxcam = doubleArray_getitem(v, i+10)
        self.rycam = doubleArray_getitem(v, i+11)
        if extended:
            self.lpup_dist = doubleArray_getitem(v, i+12)
            self.rpup_dist = doubleArray_getitem(v, i+13)
            self.lpup_dilat = doubleArray_getitem(v, i+14)
            self.rpup_dilat = doubleArray_getitem(v, i+15)
            self.local_timestamp = doubleArray_getitem(v, i+16)
        else: # this because of backward compatibility
            self.timeLoc = doubleArray_getitem(v, i+12)
    
    def __init__(self, sp, idx = 0, extended = False):
        extended = False
        if isinstance(sp, t2tCmdPrms_get_sample):   
            if sp.smatrix.cols < 12:
                raise NameError("Bad columns number: " + sp.smatrix.cols.__str__())
            v = sp.smatrix.vals;
        elif isinstance(sp, t2tCmdPrms_get_sample_ext):
            extended = True
            if sp.smatrix.cols < 16:
                raise NameError("Bad columns number: " + sp.smatrix.cols.__str__())
            v = sp.smatrix.vals        
        elif True: # what type is this? No way... I have to take everything as good :(
            v = sp
        else:
            raise NameError("Bad status object: " + sp.__name__()) 
            
        self._store(v, 0, extended)
        
    def __str__(self):
        str = ""
        for attr in vars(self):
            str += attr + " = %(v)f " %{ 'v': getattr(self, attr) }
        return str    
        
class t2tCalibrationData(object):
    _compact_header = "truePointX\ttruePointY\tleftMapX\tleftMapY\tleftValidity\trightMapX\trightMapY\trightValidity"
    
    def __init__(self, v, i):
        self.truePointX = doubleArray_getitem(v, i+0)
        self.truePointY = doubleArray_getitem(v, i+1)
        self.leftMapX = doubleArray_getitem(v, i+2)
        self.leftMapY = doubleArray_getitem(v, i+3)
        self.leftValidity = doubleArray_getitem(v, i+4)
        self.rightMapX = doubleArray_getitem(v, i+5)
        self.rightMapY = doubleArray_getitem(v, i+6)
        self.rightValidity = doubleArray_getitem(v, i+7)
        
    def __str__(self, compact = False):
        str = ""
        if not compact:
            for attr in vars(self):
                str += attr + " = %(v)f " %{ 'v': getattr(self, attr) }
        else:
             str = "%f\t%f\t%f\t%f\t%d\t%f\t%f\t%d" %(self.truePointX, self.truePointY, self.leftMapX, self.leftMapY, int(self.leftValidity), self.rightMapX, self.rightMapY, int(self.rightValidity))
        return str
        
class t2tCalibrationAnalysis(object):
    def __init__(self, ca):
        if not isinstance(ca, t2tCmdPrms_calibration_analysis):
            raise NameError("Bad object: " + ca.__name__()) 
        if ca.cmatrix.cols <> 8:
            raise NameError("Bad columns number: " + ca.cmatrix.cols.__str__())
        
        rows = ca.cmatrix.rows
        cols = ca.cmatrix.cols
        v = ca.cmatrix.vals
        self.samples = []
        
        for i in xrange(0, rows):
            self.samples.append(t2tCalibrationData(v, i*cols))
   
    def __str__(self, compact = False):
        str = ""
        for e in self.samples: 
            str += e.__str__(compact = compact) + "\n"
        return str
        
class t2tEvent(object):
    def __init__(self, time, duration, code, details):
        self.time = time
        self.duration = duration
        self.code = code
        self.details = details
    
    def __str__(self):
        str = ""
        for attr in vars(self):
            str += attr + " = " + getattr(self, attr).__str__() + " "
        return str
        
class t2tDataSamples(object):    
    def __init__(self, dt):
        if not isinstance(dt, t2tCmdPrms_get_gazes_data):
            raise NameError("Bad object: " + dt.__name__()) 
        if dt.gmatrix.cols < 16:
            raise NameError("Bad columns number")
        
        self.start_time = dt.start_time
        self.samples = []
        
        v = dt.gmatrix.vals
        for i in xrange(0, dt.gmatrix.rows):
            self.samples.append(t2tSample(v, i*dt.gmatrix.cols, True))
   
    def __str__(self):
        str = "start_time = " + self.start_time.__str__() + "\n"
        for e in self.samples: str += e.__str__() + "\n"
        return str    

class t2tDataEvents(object):    
    def __init__(self, dt):
        if not isinstance(dt, t2tCmdPrms_get_events_data):
            raise NameError("Bad object: " + dt.__name__()) 
        if dt.num_matrix.cols < 2 or dt.str_matrix.cols < 2:
            raise NameError("Bad colums number")
        if not dt.num_matrix.rows == dt.str_matrix.rows:
            raise NameError("Missing events data fields")
        
        self.start_time = dt.start_time
        self.events = []
        
        v = dt.num_matrix.vals
        s = dt.str_matrix.vals
        n = dt.num_matrix.cols
        for i in xrange(0, dt.num_matrix.rows):
            self.events.append(t2tEvent(doubleArray_getitem(v, i*n), 
                                        doubleArray_getitem(v, i*n+1),
                                        charpArray_getitem(s, i*n), 
                                        charpArray_getitem(s, i*n+1)))
        
    def __str__(self):
        str = "start_time = " + self.start_time.__str__() + "\n"
        for e in self.events: str += e.__str__() + "\n"
        return str    

def bailOut(msg = None, disconnect = True):
    if msg <> None: 
        print msg
    if disconnect:
        c = t2tCmd()
        c.cmd = "DISCONNECT"
        t2tCmdDemux(c)
    sys.exit(0)
	
def cmdEx(c, disconnect = True):
    if t2tCmdDemux(c) <> 0:
        cname = c.cmd
        if cname == None: cname = "TIMESTAMP"
        msg = "ERR running cmd: " + cname + "\nExiting..."
        bailOut(msg, disconnect)
        return None
    else:
        data = GenericData()
        dispose = True
        
        # Here, first,  for performance reason
        if c.cmd == None or c.cmd == "TIMESTAMP":
            data.timestamp = GenericData()
            data.timestamp.time = c.prm.timestamp.time
        elif c.cmd == "GET_SAMPLE":
            data.sample = t2tSample(c.prm.get_sample)
        elif c.cmd == "GET_SAMPLE_EXT":
            data.sample_ext = t2tSample(c.prm.get_sample_ext) 
        elif c.cmd == "CALIBRATION_ANALYSIS":
            data.calibration_analysis = None
            if c.prm.calibration_analysis.cmatrix.rows <> 1 and c.prm.calibration_analysis.cmatrix.cols <> 1:
                data.calibration_analysis = t2tCalibrationAnalysis(c.prm.calibration_analysis)
        elif c.cmd == "GET_EVENTS_DATA":
            start_time = c.prm.get_events_data.start_time
            data.events_data = start_time >= 0 and t2tDataEvents(c.prm.get_events_data) or None
        elif c.cmd == "GET_GAZES_DATA":
            start_time = c.prm.get_gazes_data.start_time
            data.gazes_data = start_time >= 0 and t2tDataSamples(c.prm.get_gazes_data) or None
        elif c.cmd == "GET_STATUS":
            data.status_data = t2tStatus(c.prm.get_status)
            data.history_data = c.prm.get_status.get_history and t2tHistory(c.prm.get_status) or None
        elif c.cmd == "EVENT":
            data.event = GenericData()
            data.event.start_time = c.prm.event.start_time;
        else:
            data = None
            dispose = False
            
        if dispose:
            t2tCmdOutputDispose(c)
           
        return data
        
def checkStatus(what, val, timeout = 0, debug = False):
    c = t2tCmd()
    c.cmd = "GET_STATUS"
    c.prm.get_status.get_history = 0
    
    while True:
        st = cmdEx(c)
        match = getattr(st.status_data, what) == val
        if (match or timeout - 0.01 < 0): 
            break
        time.sleep(0.01)
        timeout -= 0.01
  
    if debug:
        print "Status: ", st.status_data
        
    return match