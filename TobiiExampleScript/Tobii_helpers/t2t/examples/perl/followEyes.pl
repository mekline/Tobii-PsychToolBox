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
use t2tHelpers;
use Tk::CursorControl;
use Tk;

GetOptions(	"help|h"=>\$opt_help,
			"version"=>\$opt_version,
			"log-file|l:s"=>\$opt_log_file,
   			"port|p:i"=>\$opt_tobii_port,
            "calibration-file|c:s"=>\$opt_calibration_file,
            "tracking-on|t"=>\$opt_tracking_on,
            "camera|m"=>\$opt_camera,
            "window-width|w:f"=>\$opt_window_width,
            "window-height|e:f"=>\$opt_window_height,
            "quick-start|q"=>\$opt_quick_start,
            "debug-mode|d"=>\$opt_debug_mode,
            "validity|v:i"=>\$opt_validity);
            
($command) = fileparse($0);

$version=<<VERSION;
+-------------------------------------------------------------------------------------+
|  followEyes.pl v1.0                                                                 |
|  This is a sample application which shows eyes movements as tracked by the Tobii ET |
|-------------------------------------------------------------------------------------|
|  Luca Filippin - July 2010 - luca.filippin\@gmail.com                                |	
|  Copyright 2010 Language, Cognition and  Development Laboratory, Sissa, Trieste     |
+-------------------------------------------------------------------------------------+
VERSION

$usage=<<USAGE;

Usage: $command [options] <TET ip address>

Display eyes movements by traking them through a Tobii Eyes Tracker

Options:
  -h, --help            show this help message and exit
  --version
  -l TOBII_LOG, --log-file TOBII_LOG
                        log file name
  -c CALIBRATION_FILE, --calibration-file CALIBRATION_FILE
                        Use a stored calibration file
  -p TOBII_PORT, --port TOBII_PORT
                        TET server listening port
  -d, --debug-mode      Print gaze samples
  -m, --camera          Use camera coordinates
  -q, --quick-start     Start soon after the command has been launched
  -w WINDOW_WIDTH, --window-width WINDOW_WIDTH
                        Window width: range (0,1]
  -e WINDOW_HEIGHT, --window-height WINDOW_HEIGHT
                        Window heigth: range (0,1]
  -t, --tracking-on     Show the path made by the turtle
  -v {0,1,2,3,4}, --validity {0,1,2,3,4}
                        validity level: 0 = certainly, 1 = probably, 2 = 50%,
                        3 = likely not 4 = surely not
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
if (!defined($opt_validity)) { $opt_validity=2; }
if (!defined($opt_window_width)) { $opt_window_width=0.5; }
if (!defined($opt_window_height)) { $opt_window_height=0.5; }

if ($opt_window_height <= 0 || $opt_window_height > 1) { 
	die "Bad window length value: $opt_window_height. Must be in (0,1]"; 
}
if ($opt_window_width <= 0 || $opt_window_width > 1) { 
	die "Bad window length value: $opt_window_width.  Must be in (0,1]"; 
}

$opt_tobii_ip = $ARGV[0];

sub banner() {
	print "$version\n";
}

sub follow_eyes {
	my ($win, $canvas, $p_stop, $validity, $camera, $debug_on, $track_on,  $w, $h, $sx, $sy, $to_delete) = @_;
	my ($move, $msg, $x, $y) = (1, "", 0, 0);
	
	my $c = new t2tsw::t2tCmd();
    $c->{cmd} = "GET_SAMPLE_EXT";
    my $smp = t2tHelpers::cmdEx($c)->{sample_ext};

	if (defined $to_delete) {
		foreach my $o (@{$to_delete}) {
			$canvas->delete($o);
		}
		$canvas->update;
	} 
	
	my ($lx, $ly, $rx, $ry);
	
	if ($camera) {
		$lx = 1 - $smp->{lxcam};
		$ly = $smp->{lycam};
		$rx = 1 - $smp->{rxcam};
		$ry = $smp->{rycam};
	} else {
		$lx = $smp->{lx};
		$ly = $smp->{ly};
		$rx = $smp->{rx};
		$ry = $smp->{ry};
	}
	
	$to_delete = []; 
	
	if ($lx >= 0 && $ly >= 0 && $rx >= 0 && $ry >= 0 && $smp->{lval} <= $validity && $smp->{rval} <= $validity) {
		$m = sprintf("Sample OO: %s", $smp->str());
		$x = ($lx + $rx)*$w/2;
		$y = ($ly + $ry)*$h/2;
	}
	elsif ($rx >= 0 && $ry >= 0 && $smp->{rval} <= $validity) {
		$m = sprintf("Sample OX: %s", $smp->str());
		$x = $rx*$w;
		$y = $ry*$h;
		# just copy over because we draw always both
		$lx = $rx;
		$ly = $ry;
		$smp->{lval} = $smp->{rval};
	}
	elsif ($lx >= 0 && $ly >= 0 && $smp->{lval} <= $validity) {
		$m = sprintf("Sample XO: %s", $smp->str());
		$x = $lx*$w;
		$y = $ly*$h;
		# just copy over because we draw always both
		$rx = $lx;
		$ry = $ly;
		$smp->{rval} = $smp->{lval}; 
	}
	else {
		$m = sprintf("Sample XX: %s", $smp->str());
		$x = $sx;
		$y = $sy;
		$move = 0;
	}
	if ($move) {
		my @colors = ("red", "orange", "yellow", "blue", "white");
		my $osx = $canvas->createOval($lx*$w - 5, $ly*$h - 5, $lx*$w + 5, $ly*$h + 5, -fill => $colors[$smp->{lval}]);
        my $odx = $canvas->createOval($rx*$w - 5, $ry*$h - 5, $rx*$w + 5, $ry*$h + 5, -fill => $colors[$smp->{rval}]);
		if  ($track_on) {
 			$canvas->createLine($sx, $sy, $x, $y, -width => 1, -fill => "green");
        } else {
        	push @$to_delete, $osx;
        	push @$to_delete, $odx;
        }
        $canvas->update;
        $m .= sprintf("\nMove to (x, y) = (%.0f, %.0f)", $x, $y); 
	} else {
		$m .= "\nPrevious sample SKIPPED";
	}
	
	printf("$m\n") if ($debug_on);
	
	if (! $$p_stop) {
		$canvas->after(10, \&follow_eyes, $win, $canvas, $p_stop, $validity, $camera, $debug_on, $track_on,  $w, $h, $x, $y, $to_delete);
	} else {
		$win->destroy();
	}
}

sub _get_out {
	$stop = 1;
}

eval {
	$disconnect = 0;
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
    
    if (defined $opt_calibration_file) {
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
    } 
    
    if ($opt_quick_start) {
    	print "**** QUIT THE APPEARING WINDOW TO STOP *****\n";
    } else {
    	t2tHelpers::rawInput("\n***** PRESS ANY KEY TO START TRACKING AND QUIT THE APPEARING WINDOW TO STOP *****\n");
    }
    
    $c = new t2tsw::t2tCmd();
    $c->{cmd} = "START_TRACKING";
    t2tHelpers::cmdEx($c);
    t2tHelpers::checkStatus('running', 1, 5);
    t2tHelpers::bailOut("Start tracking failed\nExiting\n", 1) unless t2tHelpers::checkStatus('runstarted', 1, 5);
    
    # Tk initialisation
	my $window = MainWindow->new;
	$window->configure(-title => "Follow the eyes movements through a Tobii eyetracker");
	$window->CursorControl->hide($window);
	my $w_height = $window->screenheight() * $opt_window_height;
	my $w_width = $window->screenwidth() * $opt_window_width;
	$window->configure( -width=>$w_width, -height=>$w_height );
	$window->resizable(0, 0);
	my $canvas = $window->Canvas(-background=>"black", -width=>$w_width, -height=>$w_height, -borderwidth => 0);	
	$canvas->pack(-expand => 1, -fill => 'both');
	$stop = 0;
    follow_eyes($window, $canvas, \$stop, $opt_validity, $opt_camera, $opt_debug_mode, $opt_tracking_on,  $w_width, $w_height, $w_width/2, $w_height/2);
    $window->protocol('WM_DELETE_WINDOW',\&_get_out);
	MainLoop;
	
    $c = new t2tsw::t2tCmd();
    $c->{cmd} = "STOP_TRACKING";
    t2tHelpers::cmdEx($c);
    t2tHelpers::checkStatus('stop', 1, 5);
    t2tHelpers::bailOut("Stop tracking failed\nExiting\n", 0) unless t2tHelpers::checkStatus('running', 0, 5);
    
    $disconnect = 0;;
    $c = new t2tsw::t2tCmd();
    $c->{cmd} = "DISCONNECT";
    t2tHelpers::cmdEx($c, 0);
    t2tHelpers::checkStatus('disconnect', 1, 5);
	t2tHelpers::bailOut("Disconnection failed\nExiting\n", 0) unless t2tHelpers::checkStatus('connected', 0, 5);
	
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
