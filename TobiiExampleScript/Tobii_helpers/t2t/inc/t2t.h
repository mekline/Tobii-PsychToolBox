/* 
 *	Luca Filippin - April 2010 - luca.filippin@gmail.com
 *  Copyright 2010 Language, Cognition and  Development Laboratory, Sissa, Trieste. All rights reserved.
 *
 */

#ifndef __T2T_H__
#define __T2T_H__

#define CMD_GET_SAMPLE  				"GET_SAMPLE"
#define CMD_GET_SAMPLE_EXT  			"GET_SAMPLE_EXT"
#define CMD_DEMO						"DEMO"
#define CMD_CONNECT						"CONNECT"
#define CMD_START_CALIBRATION			"START_CALIBRATION"
#define CMD_ADD_CALIBRATION_POINT		"ADD_CALIBRATION_POINT"
#define CMD_CALIBRATION_ANALYSIS		"CALIBRATION_ANALYSIS"
#define CMD_REMOVE_CALIBRATION_SAMPLES	"REMOVE_CALIBRATION_SAMPLES"
#define CMD_DREW_POINT					"DREW_POINT"
#define CMD_START_TRACKING				"START_TRACKING"
#define CMD_SYNCHRONISE					"SYNCHRONISE"
#define CMD_START_AUTO_SYNC				"START_AUTO_SYNC"
#define CMD_STOP_AUTO_SYNC				"STOP_AUTO_SYNC"
#define CMD_EVENT						"EVENT"
#define CMD_RECORD						"RECORD"
#define CMD_STOP_RECORD					"STOP_RECORD"
#define CMD_GET_EVENTS_DATA				"GET_EVENTS_DATA"
#define CMD_GET_GAZES_DATA				"GET_GAZES_DATA"
#define CMD_SAVE_DATA					"SAVE_DATA"
#define CMD_CLEAR_DATA					"CLEAR_DATA"
#define CMD_CLEAR_HISTORY				"CLEAR_HISTORY"
#define CMD_STOP_TRACKING				"STOP_TRACKING"
#define CMD_DISCONNECT					"DISCONNECT"
#define CMD_GET_STATUS					"GET_STATUS"
#define CMD_CLEANUP						"CLEANUP"
#define CMD_TIMESTAMP					"TIMESTAMP"

#define SAVE_DATA_APPEND				"APPEND"
#define SAVE_DATA_TRUNK					"TRUNK"

typedef struct {
	double *vals;
	int cols;
	int rows;
} bmatrix_double;

typedef struct {
	char **vals;
	int cols;
	int rows;
} bmatrix_str;

union t2tCmdPrms {	

	/*-- GET SAMPLE --*/
	struct {
		bmatrix_double smatrix;			// out
	} get_sample;

	/*-- GET SAMPLE EXT --*/
	struct {
		bmatrix_double smatrix;			// out
	} get_sample_ext;	

	/*-- CONNECT --*/
	struct {							// all in
		char *ip_address;
		unsigned short port;
	} connect;
	
	/*-- START CALIBRATION --*/
	struct {
		bmatrix_double cmatrix;			// in: calibration points matrix (at least 2 points x,y) (if void and load_from_file = 0 --> just recalculate & set calibration)
		int load_from_file;				// in: flag !0 -> load calibration from file     
		int clear_previous;				// in: flag !0 -> clear calibration under construction     --> meaningful only when load_from_file = 0 & cmatrix is not void
		int samples_per_point;			// in: number of calibration samples per calibration point --> meaningful only when load_from_file = 0 & cmatrix is not void
		char *fname;					// in: calibration file name (if load_from_file = 0, then used to store data)
	} start_calibration;

	/*-- CALIBRATION SAMPLES REMOVAL --*/
	struct {
		bmatrix_double rmatrix;			// in: matrix of n rows x 4 columns: eye (1 = left, 2 = right, 3 = both), x ([0,1]), y ([0,1]), radius ([0,1]) 
	} remove_calibration_samples;
	
	/*-- CALIBRATION ANALYSIS --*/
	struct {
		bmatrix_double cmatrix;			// out
	} calibration_analysis;
	
	/*-- EVENT --*/
	struct {							
		char *name;                     // in
		double start_time;				// out: time at which the event was added
		double duration;				// in
		char **fields;                  // in				
		double *values;                 // in 
		int nfields;					// number of (field, value) pairs
	} event;
	
	/*-- SAVE DATA --*/
	struct {							// all in
		char *eye_tracking_fname;
		char *events_fname;
		char *mode;						// SAVE_DATA_APPEND | SAVE_DATA_TRUNK
	} save_data;
	
	/*-- GET EVENTS DATA --*/
	struct {							
		int from_event_idx;				// in
		double start_time;				// out
		bmatrix_double num_matrix;		// out		
		bmatrix_str str_matrix;			// out	
	} get_events_data;
	
	/*-- GET GAZES DATA --*/
	struct {							
		int from_sample_idx;			// in
		double start_time;				// out
		bmatrix_double gmatrix;			// out	
	} get_gazes_data;
	
	/*-- CLEAR DATA --*/
	struct {
		int up_sample_idx;				// in, delete samples [0, up_sample_idx), < -1 => delete all, -1 => delete up to last saved
		int up_event_idx;				// in, delete samples [0, up_event_idx), < -1 => delete all, -1 => delete up to last saved
	} clear_data;
	
	/*-- GET STATUS --*/
	struct {
		int get_history;				// in: 0 -> no history
		bmatrix_double st_matrix;		// out: status
		bmatrix_double hs_matrix;		// out: history
	} get_status;
	
	/*-- TIMESTAMP --*/ 				// this is a special command, for cmd = NULL || cmd = TIMESTAMP
	struct {
		double time;					// out
	} timestamp;
}; 
	
typedef struct {
	char *cmd;							// one of the CMD_* string
	union t2tCmdPrms prm;				// command specifications/return values
} t2tCmd;


void bmatrix_double_free(bmatrix_double *bmd);
void bmatrix_str_free(bmatrix_str *bms);

// talk2tobii proxy commands function 
int t2tCmdDemux(t2tCmd *c);
// dispose the output parameters
int t2tCmdOutputDispose(t2tCmd *c);
	
#endif 
