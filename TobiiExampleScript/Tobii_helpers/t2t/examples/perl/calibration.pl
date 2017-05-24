#!/usr/bin/env perl -w
##
# Luca Filippin - July 2010 - luca.filippin@gmail.com                                                
# Copyright 2010 Language, Cognition and  Development Laboratory, Sissa, Trieste. All rights reserved.
# 
# PLEASE HAVE A LOOK TO THE SWIG DOCUMENTATION FOR A DEEPER UNDERSTANDING OF THIS CODE
# NOTE: Swig wrapper to t2t makes use of shadow classes and swig helpers (see t2tsw.i)
##

#use strict;
use File::Basename;
use Getopt::Long;
use t2tHelpers;
use Time::HiRes;
use Tk::CursorControl;
use Tk::JPEG;
use Tk::PNG;
use Tk;

GetOptions(	"help|h"=>\$opt_help,
			"version"=>\$opt_version,
			"log-file|l:s"=>\$opt_log_file,
   			"port|p:i"=>\$opt_tobii_port,
            "calibration-file|o:s"=>\$opt_calibration_file,
            "load-calibration|d"=>\$opt_calibration_load,
            "start-delay|s:f"=>\$opt_start_delay,
            "output-file|r:s"=>\$opt_output_file);
            
($command) = fileparse($0);

$version=<<VERSION;
+-------------------------------------------------------------------------------------+
|  calibration.pl v1.0                                                                |
|  This is a sample application which performs the calibration of a Tobii ET.         |
|-------------------------------------------------------------------------------------|
|  Luca Filippin - July 2010 - luca.filippin\@gmail.com                                |                                             
|  Copyright 2010 Language, Cognition and  Development Laboratory, Sissa, Trieste     |
+-------------------------------------------------------------------------------------+
VERSION

$usage=<<USAGE;

Usage: $command [options] <TET ip address> <input file>

       <input file> lines fmt: 'x[0,1] y[0,1] height(0,1] width(0,1] delay(ms) picture_file_name', field separator: tab

Calibrate a Tobii Eyes Tracker

Options:
  --version             show program's version number and exit
  -h, --help            show this help message and exit
  -l TOBII_LOG, --log-file=TOBII_LOG
                        log file name
  -p TOBII_PORT, --port=TOBII_PORT
                        TET server listening port
  -o CALIBRATION_FILE, --calibration-file=CALIBRATION_FILE
                        Name of the file which will store the calibration
                        results
  -d, --load-calibration
                        Use existing calibration: just print results
  -s START_DELAY, --start-delay=START_DELAY
                        Start calibration after a specific delay (secs)
  -r OUTPUT_FILE, --output-file=OUTPUT_FILE
                        Name of the file which will store the collected data
USAGE

if ($opt_version) {
	print "$version";
	exit 0;
}

if (@ARGV < 2 or $opt_help) {
  	print "$usage";
  	exit 0;
}

if (!defined($opt_tobii_port)) { $opt_tobii_port=4455; }
if (!defined($opt_start_delay)) { $opt_start_delay=0; }

$opt_tobii_ip = $ARGV[0];
$opt_input_file = $ARGV[1];

sub banner() {
	print "$version\n";
}

sub parseInputFile {
	my $filename = $_[0];
	
	my %data;
	$data{size}  = 0; 
	@$data{pict} = ();
	
	eval {
		open F, '<', $filename or die "Failed to OPEN the data file $filename";
		
		foreach (<F>) {
			if (/^(\d*\.?\d+)\t(\d*\.?\d+)\t(\d*\.?\d+)\t(\d*\.?\d+)\t(\d+)\t(.*)/) {
				
			   	die "Data line is in bad format: $_" if ($1<0 || $1>1 || $2<0 || $2>1 || $3<=0 || $3>1 || $4<=0 || $4>1 || $5<0);
			   	die "File is not existing or is not a readablefile: $6" unless ( -e $6 && -f $6 && -r $6); 
			   
			    my $rec = { 
			    	x => $1,
					y => $2,
					height => $3,
					width => $4,
					delay => $5,
					fname => $6,
				};
				
				$data{size}++;
				push @{$data{pict}}, $rec;
				next;
			}
			elsif (/^#*\s*$/) {
				next;
			}
			close F;
			die "Unexpected line: $_";
		}
		close F;
	} or do {
		die "++ Error reading input file\n   $@";
	};
	
	return \%data;
}

sub writeOutputFile {
	my ($filename, $data) = @_;
	my $ok = 1;
	
	eval {
		open F, '>', $filename or die $!;
		printf F  "%s\n%s", $data->compact_header(), $data->str(1);
		close F;
	} or do {
		$ok = 0;
	};
	return $ok;
}

sub get_image {
	my ($canvas, $w_width, $w_height, $pict) = @_;
	
	my $p1 = $canvas->Photo(-file => $pict->{fname});
	my $r_w = ($w_width * $pict->{width})/$p1->width;
	my $r_h = ($w_height * $pict->{height})/$p1->height;
	my $subs_x = $r_w < 1 ? 1/$r_w : 1;
	my $subs_y = $r_h < 1 ? 1/$r_h : 1;
	my $zoom_x = $r_w > 1 ? $r_w : 1;
	my $zoom_y = $r_h > 1 ? $r_h : 1;
	
	if ($subs_x > 1 || $subs_y > 1) {
		my $p2 = $canvas->Photo();
		$p2->copy($p1, -shrink, -subsample => $subs_x, $subs_y);
		$p1 = $p2;
	}
	if ($zoom_x > 1 || $zoom_y > 1) {
		my $p2 = $canvas->Photo();
		$p2->copy($p1, -zoom => $zoom_x, $zoom_y);
		$p1 = $p2;
	}
	return $p1;
}

sub calibration {
	my ($canvas, $data, $i, $to_delete) = @_;
	my $main_w = $canvas->MainWindow;
	my $w = $main_w->screenwidth();
	my $h = $main_w->MainWindow->screenheight();
	
	if ($i < 0) {
		$main_w->fontCreate('big', -family=>'courier', -weight=>'bold', -size=>int(-18*18/12));
		my $msg = $canvas->createText($w/2, $h/2, -anchor =>'center', -font =>'big', -text => "Please focus on the appearing pictures...", -fill => "green");
		$canvas->update;
		$canvas->after(2000, \&calibration, $canvas, $data, $i+1, $msg);
		return;
	}
	if (defined $to_delete) {
		if ($i > 0) { 
			my $c = new t2tsw::t2tCmd();
        	$c->{cmd} = "DREW_POINT";
        	t2tHelpers::cmdEx($c);
		}
		$canvas->delete($to_delete);
		$canvas->update;
	}
	if ($i < $data->{size}) {
		my $p = $data->{pict}[$i];
		my $img = $canvas->create('image', $p->{x}*$w, $p->{y}*$h, -anchor =>'center', -image => $p->{image});
		$canvas->update;
		
		my $c = new t2tsw::t2tCmd();
        $c->{cmd} = "ADD_CALIBRATION_POINT";
        t2tHelpers::cmdEx($c);
		
		$canvas->after($data->{pict}[$i]->{delay}, \&calibration, $canvas, $data, $i+1, $img);
	} else {
		$main_w->destroy;
	}
}

eval {
	$disconnect = 0;
	banner();
	t2tsw::t2tOutputFileName($opt_log_file, "w") if defined $opt_log_file;
	
	if (! $opt_calibration_load) {
		$data = parseInputFile($opt_input_file);
		t2tHelpers::bailOut("Calibration needs at least 2 points\nExiting\n", 0) unless $data->{size} >= 2;
		
		# Tk initialisation
		$window = MainWindow->new;
		$window->configure(-title => "Tobii Eye Tracker Calibration");
		$window->CursorControl->hide($window);
		$w_height = $window->screenheight();
		$w_width = $window->screenwidth();
		$window->configure( -width=>$w_width, -height=>$w_height );
		$window->resizable( 0, 0 ); # not resizable in any direction
		$canvas = $window->Canvas(-background=>"black", -width=>$w_width, -height=>$w_height, -borderwidth => 0);	
		$canvas->pack(-expand => 1, -fill => 'both');
		
		$data->{images} = [];
		for ($i = 0; $i < $data->{size}; $i++) {
		    $data->{pict}[$i]->{image} = get_image($canvas, $w_width, $w_height, $data->{pict}[$i]);
		}
    }
    
	# Connect to the tobii
    print "Connecting to the TET server @".$opt_tobii_ip.":".$opt_tobii_port."...\n";
    $c = new t2tsw::t2tCmd();
    $c->{cmd} = "CONNECT";
    $c->{prm}->{connect}->{ip_address} = $opt_tobii_ip;
    $c->{prm}->{connect}->{port} = $opt_tobii_port;
    t2tHelpers::cmdEx($c);
	t2tHelpers::checkStatus('connect', 1, 5);
	t2tHelpers::bailOut("Connection failed\nExiting\n", 0) unless t2tHelpers::checkStatus('connected', 1, 5);
	$disconnect = 1;
    
    if ($opt_calibration_load) {
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
    } else {
    	if (defined $opt_start_delay && $opt_start_delay > 0) {
    		 Time::HiRes::usleep $opt_start_delay*1000;
    	} else {
    		t2tHelpers::rawInput("\n***** PRESS ANY KEY TO GET CALIBRATION DATA *****\n");
    	}
    	
    	# A tracking phase seems to be necessary before starting a calibration, or it will fails very often.
    	# There's no explanation or documentation about, but it works like that.
    	$c = new t2tsw::t2tCmd();
		$c->{cmd} = "START_TRACKING";
		t2tHelpers::cmdEx($c);
		t2tHelpers::checkStatus('running', 1, 5);
		t2tHelpers::bailOut("Start tracking failed\nExiting\n", 1) unless t2tHelpers::checkStatus('runstarted', 1, 5);
    	Time::HiRes::sleep 2;
    	$c = new t2tsw::t2tCmd();
		$c->{cmd} = "STOP_TRACKING";
		t2tHelpers::cmdEx($c);
		t2tHelpers::checkStatus('stop', 1, 5);
		t2tHelpers::bailOut("Stop tracking failed\nExiting\n", 0) unless t2tHelpers::checkStatus('running', 0, 5);
    	
    	$c = new t2tsw::t2tCmd();
    	$c->{cmd} = "START_CALIBRATION";
    	$c->{prm}->{start_calibration}->{clear_previous} = 1;
        $c->{prm}->{start_calibration}->{samples_per_point} = 20; 
    	$c->{prm}->{start_calibration}->{load_from_file} = 0;
    	$c->{prm}->{start_calibration}->{cmatrix}->{cols} = 2;
    	$c->{prm}->{start_calibration}->{cmatrix}->{rows} = $data->{size};
    	$c->{prm}->{start_calibration}->{cmatrix}->{vals} = $v = new t2tsw::doubleArrayC(2*$data->{size});
    	$c->{prm}->{start_calibration}->{fname} = $opt_calibration_file;
    	for ($i = 0; $i < $data->{size}; $i++) {
    		t2tsw::doubleArrayC::setitem($v, $i*2, $data->{pict}[$i]->{x});
    		t2tsw::doubleArrayC::setitem($v, $i*2+1, $data->{pict}[$i]->{y}); 
        }
        t2tHelpers::cmdEx($c);
        t2tHelpers::checkStatus('calibrating', 1, 5);
		t2tHelpers::bailOut("Start calibration failed\nExiting\n", 1) unless t2tHelpers::checkStatus('calibstarted', 1, 5);
		
		# Start the the displaying procedure...
		calibration($canvas, $data, -1);
		MainLoop;
		
		t2tHelpers::bailOut("End calibration delayed\nExiting\n", 1) unless t2tHelpers::checkStatus('calibend', 1, 30);
    }
    
    $c = new t2tsw::t2tCmd();
    $c->{cmd} = "CALIBRATION_ANALYSIS";
    $calib_an = t2tHelpers::cmdEx($c);
    
    if (defined($calib_an->{calibration_analysis})) {
        $print_data = (!defined($opt_output_file));
        if  (! $print_data) {
            if (! writeOutputFile($opt_output_file, $calib_an->{calibration_analysis})) {
                print "Error: can't save data file! Print to screen...";
                $print_data = 1;
            }
		}
        print "\nCalibration analisys data:\n\n".$calib_an->{calibration_analysis}->compact_header()."\n".$calib_an->{calibration_analysis}->str(1) if $print_data;
    } else {
        print "Calibration failed: no data\n";
    }
    
    $disconnect = 0;
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
