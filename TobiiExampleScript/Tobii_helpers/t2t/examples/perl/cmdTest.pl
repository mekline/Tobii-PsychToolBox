#!/usr/bin/env perl -w
##
# Luca Filippin - July 2010 - luca.filippin@gmail.com                                                
# Copyright 2010 Language, Cognition and  Development Laboratory, Sissa, Trieste. All rights reserved.
# 
# PLEASE HAVE A LOOK TO THE SWIG DOCUMENTATION FOR A DEEPER UNDERSTANDING OF THIS CODE
# NOTE: Swig wrapper to t2t makes use of shadow classes and swig helpers (see t2tsw.i)
##

#use strict;
use Getopt::Long;
use File::Basename;
use Time::HiRes;
use t2tHelpers;

GetOptions(	"help|h"=>\$opt_help,
			"version"=>\$opt_version,
			"log-file|l:s"=>\$opt_log_file,
   			"port|p:i"=>\$opt_tobii_port,
            "calibration-file|c:s"=>\$opt_calibration_file,
            "tracked-data-file|t:s"=>\$opt_data_file,
            "events-data-file|e:s"=>\$opt_evts_file);
            
($command) = fileparse($0);

$version=<<VERSION;
+-------------------------------------------------------------------------------------+
|  cmdTest.pl v1.0                                                                    |
|  This is a test application which tests some Tobii ET commands.                     |
|-------------------------------------------------------------------------------------|
|  Luca Filippin - July 2010 - luca.filippin\@gmail.com                                |                                                
|  Copyright 2010 Language, Cognition and  Development Laboratory, Sissa, Trieste     |
+-------------------------------------------------------------------------------------+
VERSION

$usage=<<USAGE;

Usage: $command [options] <TET ip address>

Test a Tobii Eye Tracker

Options:
  --version             show program's version number and exit
  -h, --help            show this help message and exit
  -l TOBII_LOG, --log-file=TOBII_LOG
                        log file name
  -c CALIBRATION_FILE, --calibration-file=CALIBRATION_FILE
                        Use a stored calibration file
  -t TRACKED_DATA_FILE, --tracked-data-file=TRACKED_DATA_FILE
                        File where tracked data will be stored in the TET
                        machine
  -e EVENTS_DATA_FILE, --events-data-file=EVENTS_DATA_FILE
                        File where events will be stored in the TET machine
  -p TOBII_PORT, --port=TOBII_PORT
                        TET server listening port

USAGE

if ($opt_version) {
	print "$version";
	exit 0;
}

if (@ARGV < 1 or $opt_help) {
  	print "$usage";
  	exit 0;
}

if (!defined($opt_tobii_port)) { $opt_tobii_port=4455; }
if (!defined($opt_start_delay)) { $opt_start_delay=0; }
if (!defined($opt_data_file)) { $opt_data_file="EyesTrackedData.txt"; }
if (!defined($opt_evts_file)) { $opt_evts_file="EventsData.txt"; }

$opt_tobii_ip = $ARGV[0];

sub banner() {
	print "$version\n";
}

$disconnect = 0;

eval {
	banner();
	t2tsw::t2tOutputFileName($opt_log_file, "w") if defined $opt_log_file;
	
	# Connect to the tobii
    print "Connecting to the TET server @".$opt_tobii_ip.":".$opt_tobii_port."...\n";
    my $c = new t2tsw::t2tCmd();
    $c->{cmd} = "CONNECT";
    $c->{prm}->{connect}->{ip_address} = $opt_tobii_ip;
    $c->{prm}->{connect}->{port} = $opt_tobii_port;
    t2tHelpers::cmdEx($c);
	t2tHelpers::checkStatus('connect', 1, 5);
	t2tHelpers::bailOut("Connection failed\nExiting\n", 0) unless t2tHelpers::checkStatus('connected', 1, 5);
	$disconnect = 1;
    
    t2tHelpers::rawInput("\n***** PRESS ANY KEY TO START THE TEST *****\n");
    
    # Running demo
    printf "Running demo...\n";
    $c = new t2tsw::t2tCmd();
    $c->{cmd} = "DEMO";
    t2tHelpers::cmdEx($c);
    
    if (defined $opt_calibration_file) {
    	print "Loading calibration data $opt_calibration_file...\n";
    	$c = new t2tsw::t2tCmd();
    	$c->{cmd} = "START_CALIBRATION";
    	$c->{prm}->{start_calibration}->{load_from_file} = 1;
    	$c->{prm}->{start_calibration}->{cmatrix}->{cols} = 0;
    	$c->{prm}->{start_calibration}->{cmatrix}->{rows} = 0;
    	$c->{prm}->{start_calibration}->{cmatrix}->{vals} = undef;
    	$c->{prm}->{start_calibration}->{fname} = $opt_calibration_file;
    	t2tHelpers::cmdEx($c);
    	
    	t2tHelpers::checkStatus('calibrating', 1, 5);
		t2tHelpers::bailOut("Load calibration failed\nExiting\n", 1) unless t2tHelpers::checkStatus('calibstarted', 1, 5);
		t2tHelpers::bailOut("Load calibration failed\nExiting\n", 1) unless t2tHelpers::checkStatus('calibstarted', 0, 5);
    
    	$c = new t2tsw::t2tCmd();
    	$c->{cmd} = "CALIBRATION_ANALYSIS";
    	$calib_an = t2tHelpers::cmdEx($c)->{calibration_analysis};
    
    	if (defined($calib_an)) {
        	print "\nCalibration analysis data:\n\n".$calib_an->compact_header()."\n".$calib_an->str(1)."\n";
        }
        
        print "Removing a couple of calibration samples set...\n";
        $c = new t2tsw::t2tCmd();
        $c->{cmd} = "REMOVE_CALIBRATION_SAMPLES";
        $c->{prm}->{remove_calibration_samples}->{rmatrix}->{rows} = 2;
        $c->{prm}->{remove_calibration_samples}->{rmatrix}->{cols} = 4;
        $c->{prm}->{remove_calibration_samples}->{rmatrix}->{vals} = $vals = new t2tsw::doubleArrayC(2*4);
        t2tsw::doubleArrayC::setitem($vals, 0, 1);       # eye 
        t2tsw::doubleArrayC::setitem($vals, 1, 0.2);     # x
        t2tsw::doubleArrayC::setitem($vals, 2, 0.15);    # y
        t2tsw::doubleArrayC::setitem($vals, 3, 0.12);    # radius
        t2tsw::doubleArrayC::setitem($vals, 4, 3);       # eye 
        t2tsw::doubleArrayC::setitem($vals, 5, 0.8);     # x
        t2tsw::doubleArrayC::setitem($vals, 6, 0.7);     # y
        t2tsw::doubleArrayC::setitem($vals, 7, 0.1);     # radius
		t2tHelpers::cmdEx($c);
		my $remove_ok = (t2tHelpers::checkStatus('removing_samples', 1, 5) && t2tHelpers::checkStatus('removing_samples', 0, 5));
		t2tHelpers::bailOut("Calibration samples removal failed\nExiting\n", 1) unless $remove_ok;
		
		print "Recalculating & setting calibration...\n";
    	$c = new t2tsw::t2tCmd();
    	$c->{cmd} = "START_CALIBRATION";
    	$c->{prm}->{start_calibration}->{load_from_file} = 0;
    	$c->{prm}->{start_calibration}->{cmatrix}->{cols} = 0;
    	$c->{prm}->{start_calibration}->{cmatrix}->{rows} = 0;
    	$c->{prm}->{start_calibration}->{cmatrix}->{vals} = undef;
    	$c->{prm}->{start_calibration}->{fname} = undef;
    	t2tHelpers::cmdEx($c);
    	
    	t2tHelpers::checkStatus('calibrating', 1, 5);
		t2tHelpers::bailOut("Load calibration failed\nExiting\n", 1) unless t2tHelpers::checkStatus('calibstarted', 1, 5);
		t2tHelpers::bailOut("Load calibration failed\nExiting\n", 1) unless t2tHelpers::checkStatus('calibstarted', 0, 5);
    } 
    
    printf "Synchronizing...\n";
    $c = new t2tsw::t2tCmd();
    $c->{cmd} = "SYNCHRONISE";
    t2tHelpers::cmdEx($c);
    t2tHelpers::checkStatus('synchronise', 1, 5);
    t2tHelpers::bailOut("Synchronization failed\nExiting\n", 1) unless t2tHelpers::checkStatus('synchronised', 1, 5);
    
    printf "Start auto sync...\n";
    $c = new t2tsw::t2tCmd();
    $c->{cmd} = "START_AUTO_SYNC";
    t2tHelpers::cmdEx($c);
    t2tHelpers::bailOut("Start auto sync failed\nExiting\n", 1) unless t2tHelpers::checkStatus('autosynced', 1, 5);
    
    printf "Start tracking...\n";
    $c = new t2tsw::t2tCmd();
    $c->{cmd} = "START_TRACKING";
    t2tHelpers::cmdEx($c);
    t2tHelpers::checkStatus('running', 1, 5);
    t2tHelpers::bailOut("Start tracking failed\nExiting\n", 1) unless t2tHelpers::checkStatus('runstarted', 1, 5);
    
    printf "Getting some extended samples...\n";
    for (my $i = 0; $i < 10; $i++) {
    	$c = new t2tsw::t2tCmd();
    	$c->{cmd} = "GET_SAMPLE_EXT";
    	my $smp = t2tHelpers::cmdEx($c)->{sample_ext};
    	printf "> %s\n", $smp->str();
    	Time::HiRes::sleep 0.2;
    }
    
    printf "Getting some timestamps...\n";
    for (my $j = 0; $j < 10; $j++) {
    	$c = new t2tsw::t2tCmd();
    	$c->{cmd} = undef;
    	my $timestamp = t2tHelpers::cmdEx($c)->{timestamp};
    	printf "> %f\n", $timestamp;
    }
    
    printf "Start recording...\n";
    $c = new t2tsw::t2tCmd();
    $c->{cmd} = "RECORD";
    t2tHelpers::cmdEx($c);
    Time::HiRes::sleep 2;
	
	print "Sending events...\n";
	for (my $i = 0; $i < 5; $i++) {
    	$c = new t2tsw::t2tCmd();
    	$c->{cmd} = "EVENT";
    	my $name = $c->{prm}->{event}->{name} = "Event $i";
    	my $dur = $c->{prm}->{event}->{duration} = 1;
		$c->{prm}->{event}->{nfields} = 2;
    	my $s = $c->{prm}->{event}->{fields} = t2tsw::new_charpArray(2);
		t2tsw::charpArray_setitem($s, 0, "FIELD 1");
		t2tsw::charpArray_setitem($s, 1, "FIELD 2");
		my $v = $c->{prm}->{event}->{values} = t2tsw::new_doubleArray(2);
		t2tsw::doubleArray_setitem($v, 0, $i*10);
		t2tsw::doubleArray_setitem($v, 1, $i*10+1);
		my @t = Time::HiRes::gettimeofday;
    	my $start = $t[0]+$t[1]/1000000;
		my $evt = t2tHelpers::cmdEx($c);
		t2tsw::delete_doubleArray($v);
		t2tsw::delete_charpArray($s);
		printf "> Name = $name local_start = $start secs real_start = $evt->{start_time} secs duration = $dur secs\n";
        printf "> Sleeping a bit...\n";
    	Time::HiRes::sleep 1.5;
    }
    
    printf "Getting gazes data...\n";
    $c = new t2tsw::t2tCmd();
    $c->{cmd} = "GET_GAZES_DATA";
    $c->{prm}->{get_gazes_data}->{from_sample_idx} = 0;
    my $gazes = t2tHelpers::cmdEx($c)->{gazes_data};
    if (defined $gazes) {
    	printf "> Start time: $gazes->{start_time}\n";
    	if (@{$gazes->samples} > 0) {
			for (my $i = 0; $i < @{$gazes->samples}; $i++) {
				printf "> %s\n", $gazes->samples->[$i]->str();
			}
		} else {
			printf "No data\n";
		}
    }
    
    printf "Getting events data...\n";
    $c = new t2tsw::t2tCmd();
    $c->{cmd} = "GET_EVENTS_DATA";
    $c->{prm}->{get_events_data}->{from_event_idx} = 0;
    my $ev = t2tHelpers::cmdEx($c)->{events_data};
    if (defined $ev) {
    	printf "> Start time: $ev->{start_time}\n";
    	if (@{$ev->events} > 0) {
			for (my $i = 0; $i < @{$ev->events}; $i++) {
				printf "> %s\n", $ev->events->[$i]->str();
			}
		} else {
			printf "No data\n";
		}
    }
    
    printf "Saving data...\n";
    $c = new t2tsw::t2tCmd();
    $c->{cmd} = "SAVE_DATA";
    $c->{prm}->{save_data}->{eye_tracking_fname} = $opt_data_file;   
    $c->{prm}->{save_data}->{events_fname} = $opt_evts_file;
    $c->{prm}->{save_data}->{mode} = "TRUNK";
    t2tHelpers::cmdEx($c);
    
    printf "Getting status and history...\n";
    $c = new t2tsw::t2tCmd();
    $c->{cmd} = "GET_STATUS";
    $c->{prm}->{get_status}->{get_history} = 1;
    my $status = t2tHelpers::cmdEx($c);
    printf "> Status: %s\n",  $status->{status_data}->str();
    for (my $i = 0; $i < @{$status->{history_data}->{facts}}; $i++) {
        printf "> %s\n", $status->{history_data}->{facts}->[$i]->str();
    }
    
    printf "Stop recording...\n";
    $c = new t2tsw::t2tCmd();
    $c->{cmd} = "STOP_RECORD";
    t2tHelpers::cmdEx($c);
    
    printf "Stop tracking...\n";
    $c = new t2tsw::t2tCmd();
    $c->{cmd} = "STOP_TRACKING";
    t2tHelpers::cmdEx($c);
    t2tHelpers::checkStatus('stop', 1, 5);
    t2tHelpers::bailOut("Stop tracking failed\nExiting\n", 0) unless t2tHelpers::checkStatus('running', 0, 5);
    
    printf "Clearing data...\n";
    $c = new t2tsw::t2tCmd();
    $c->{cmd} = "CLEAR_DATA";
    $c->{prm}->{clear_data}->{up_sample_idx} = -2;
    $c->{prm}->{clear_data}->{up_event_idx} = -2;
    t2tHelpers::cmdEx($c);
    
    printf "Clearing history...\n";
    $c = new t2tsw::t2tCmd();
    $c->{cmd} = "CLEAR_HISTORY";
    t2tHelpers::cmdEx($c);
    
	printf "Stop auto sync...\n";
    $c = new t2tsw::t2tCmd();
    $c->{cmd} = "STOP_AUTO_SYNC";
    t2tHelpers::cmdEx($c);
    t2tHelpers::bailOut("Stop auto sync failed\nExiting\n", 1) unless t2tHelpers::checkStatus('autosynced', 0, 5);
    
    $disconnect = 0;
    printf "Disconnecting...\n";
    $c = new t2tsw::t2tCmd();
    $c->{cmd} = "DISCONNECT";
    t2tHelpers::cmdEx($c, 0);
    t2tHelpers::checkStatus('disconnect', 1, 5);
	t2tHelpers::bailOut("Disconnection failed\nExiting\n", 0) unless t2tHelpers::checkStatus('connected', 0, 5);
	
	printf "Cleanup...\n";
    $c = new t2tsw::t2tCmd();
    $c->{cmd} = "CLEANUP";
    t2tHelpers::cmdEx($c);
    
	printf "End.\n";
	
} or do {
	my $msg = "--------------- UNEXPECTED ERROR ---------------\n$@";
    $msg .= "------------------------------------------------\n";
    $msg .= "The application has been forcely closed!\n";
    t2tHelpers::bailOut($msg, $disconnect);
}

    