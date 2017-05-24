package t2tHelpers;
use Time::HiRes;
use Term::ReadKey;
use Carp;
use t2tsw;
use strict;

# *** -----------------------------------------------------

package t2tHelpers::_members;
use Carp;
our $AUTOLOAD;

my %fields = ();

sub new {
	my $class = shift;
 	my $self = {
		%fields,
	};
	bless $self, $class;
	return $self;
}

sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self) or confess "$self is not an object";

	my $name = $AUTOLOAD;
	$name =~ s/.*://; # strip fully-qualified portion
	confess "Can't access `$name' field in class $type" unless (exists $self->{$name});
	
 	if (@_) {
		return $self->{$name} = shift;
	} else {
		return $self->{$name};
	}
}

sub DESTROY {
}

sub str {
	my $self = shift;
	my $s = "";
	while (my ($k, $v) = each %{$self}) {
		$s = "$s $k = $v"; 
	}
	return $s;
}

# *** -----------------------------------------------------

package t2tHelpers::point;
use strict;
our @ISA = qw(t2tHelpers::_members);

sub new {
	my $class = shift;
	my $self = $class->SUPER::new();
	$self->{x} = shift;
	$self->{y} = shift;
	bless $self, $class;
	return $self;
}

# *** -----------------------------------------------------

package t2tHelpers::t2tStatus;
use Carp; 
use strict;
our @ISA = qw(t2tHelpers::_members);

sub new {
	my $class = shift;
	my $st = shift;
	confess "Bad parameter!" unless $st->isa('t2tsw::t2tCmdPrms_get_status');
	confess "Bad columns number!" unless $st->{st_matrix}->{cols} >= 12;
	my $v = $st->{st_matrix}->{vals};
	my $self = $class->SUPER::new();
	$self->{connect} = t2tsw::doubleArray_getitem($v, 0) ? 1 : 0;
	$self->{connected} = t2tsw::doubleArray_getitem($v, 1) ? 1 : 0;
	$self->{disconnect} = t2tsw::doubleArray_getitem($v, 2) ? 1 : 0;
	$self->{calibrating} = t2tsw::doubleArray_getitem($v, 3) ? 1 : 0;
	$self->{calibstarted} = t2tsw::doubleArray_getitem($v, 4) ? 1 : 0;
	$self->{running} = t2tsw::doubleArray_getitem($v, 5) ? 1 : 0;
	$self->{runstarted} = t2tsw::doubleArray_getitem($v, 6) ? 1 : 0;
	$self->{stop} = t2tsw::doubleArray_getitem($v, 7) ? 1 : 0;
	$self->{finished} = t2tsw::doubleArray_getitem($v, 8) ? 1 : 0;
	$self->{synchronise} = t2tsw::doubleArray_getitem($v, 9) ? 1 : 0;
	$self->{calibend} = t2tsw::doubleArray_getitem($v, 10) ? 1 : 0;
	$self->{synchronised} = t2tsw::doubleArray_getitem($v, 11) ? 1 : 0;
	$self->{autosynced} = t2tsw::doubleArray_getitem($v, 12) ? 1 : 0;
	$self->{removing_samples} = t2tsw::doubleArray_getitem($v, 13) ? 1 : 0;
	$self->{can_draw_point} = t2tsw::doubleArray_getitem($v, 14) ? 1 : 0;
	bless $self, $class;
    return $self;
}

# *** -----------------------------------------------------

package t2tHelpers::t2tHistoryFact;
use strict;
our @ISA = qw(t2tHelpers::_members);

sub new {
	my $class = shift;
	my $self = $class->SUPER::new();
	$self->{code} = int(shift);
	$self->{time} = shift;
	bless $self, $class;
	return $self;
}


# *** -----------------------------------------------------

package t2tHelpers::t2tHistory;
use Carp;
use strict;
our @ISA = qw(t2tHelpers::_members);

sub new {
	my $class = shift;
	my $st = shift;
	confess 'Bad parameter!' unless $st->isa('t2tsw::t2tCmdPrms_get_status');
	my $self = $class->SUPER::new();
	my $v = $st->{hs_matrix}->{vals};
	my $n = $st->{hs_matrix}->{cols}/2;
	my $f = $self->{facts} = [];
	for (my $i = 0; $i < $n; $i++) {
		push @$f, t2tHelpers::t2tHistoryFact->new(t2tsw::doubleArray_getitem($v,$i), t2tsw::doubleArray_getitem($v, $i+$n));
	}
	bless $self, $class;
	return $self;
}

# *** -----------------------------------------------------

package t2tHelpers::t2tSample;
use Carp;
use strict;
our @ISA = qw(t2tHelpers::_members);

sub new {
	my $class = shift;
	my $sp = shift;
	my $i = shift;
	my $v = $sp;
	
	if (!defined $i) {
		confess 'Bad parameter!' unless ($sp->isa('t2tsw::t2tCmdPrms_get_sample') or $sp->isa('t2tsw::t2tCmdPrms_get_sample_ext'));
		confess 'Bad columns number!' unless $sp->{smatrix}->{cols} >= 12;
		$v = $sp->{smatrix}->{vals};
		$i = 0;
	} 
	my $self = $class->SUPER::new();
	$self->{lx} = t2tsw::doubleArray_getitem($v, $i+0);
	$self->{ly} = t2tsw::doubleArray_getitem($v, $i+1);
	$self->{rx} = t2tsw::doubleArray_getitem($v, $i+2);
	$self->{ry} = t2tsw::doubleArray_getitem($v, $i+3);
	$self->{timeSec} = t2tsw::doubleArray_getitem($v, $i+4);
	$self->{timeMic} = t2tsw::doubleArray_getitem($v, $i+5);
	$self->{lval} = t2tsw::doubleArray_getitem($v, $i+6);
	$self->{rval} = t2tsw::doubleArray_getitem($v, $i+7);
	$self->{lxcam} = t2tsw::doubleArray_getitem($v, $i+8);
	$self->{lycam} = t2tsw::doubleArray_getitem($v, $i+9);
	$self->{rxcam} = t2tsw::doubleArray_getitem($v, $i+10);
	$self->{rycam} = t2tsw::doubleArray_getitem($v, $i+11);
	$self->{timeLoc} = t2tsw::doubleArray_getitem($v, $i+12);
	bless $self, $class;
	return $self;
}

# *** -----------------------------------------------------

package t2tHelpers::t2tSampleExt;
use Carp;
use strict;
our @ISA = qw(t2tHelpers::t2tSample);

sub new {
	my $class = shift;
	my $sp = shift;
	my $i = shift;
	my $v = $sp;
	
	if (!defined $i) {
		confess 'Bad parameter!' unless $sp->isa('t2tsw::t2tCmdPrms_get_sample_ext');
		confess 'Bad columns number!' unless $sp->{smatrix}->{cols} >= 16;
		$v = $sp->{smatrix}->{vals};
		$i = 0;
	} 
	my $self = $class->SUPER::new($v, $i);
	$self->{lpup_dist} = t2tsw::doubleArray_getitem($v, $i+12);
	$self->{rpup_dist} = t2tsw::doubleArray_getitem($v, $i+13);
	$self->{lpup_dilat} = t2tsw::doubleArray_getitem($v, $i+14);
	$self->{rpup_dilat} = t2tsw::doubleArray_getitem($v, $i+15);
	$self->{timeLoc} = t2tsw::doubleArray_getitem($v, $i+16); # this overwrite the value asssigned in t2tSample() constructor (needed for backward compat)
	bless $self, $class;
	return $self;
}
  
# *** -----------------------------------------------------

package t2tHelpers::t2tCalibrationData;
use strict;
our @ISA = qw(t2tHelpers::_members);

sub new {
	my $class = shift;
	my $v = shift;
	my $i = shift;
	my $self = $class->SUPER::new();
	$self->{truePointX} = t2tsw::doubleArray_getitem($v, $i+0);
	$self->{truePointY} = t2tsw::doubleArray_getitem($v, $i+1);
	$self->{leftMapX} = t2tsw::doubleArray_getitem($v, $i+2);
	$self->{leftMapY} = t2tsw::doubleArray_getitem($v, $i+3);
	$self->{leftValidity} = t2tsw::doubleArray_getitem($v, $i+4);
	$self->{rightMapX} = t2tsw::doubleArray_getitem($v, $i+5);
	$self->{rightMapY} = t2tsw::doubleArray_getitem($v, $i+6);
	$self->{rightValidity} = t2tsw::doubleArray_getitem($v, $i+7);
	bless $self, $class;
	return $self;
}

sub str {
	my $self = shift;
	my $compact = shift;
	my $s;
	if (defined($compact) && $compact) {
		$s = sprintf("%f\t%f\t%f\t%f\t%d\t%f\t%f\t%d", $self->{truePointX}, $self->{truePointY}, $self->{leftMapX}, $self->{leftMapY}, $self->{leftValidity}, $self->{rightMapX}, $self->{rightMapY}, $self->{rightValidity});
	} else {
		$s = $self->SUPER::str();
	}
	return $s;
}

# *** -----------------------------------------------------

package t2tHelpers::t2tCalibrationAnalysis;
use Carp;
use strict;
our @ISA = qw(t2tHelpers::_members);

sub new {
	my $class = shift;
	my $ca = shift;
	confess 'Bad parameter!' unless $ca->isa('t2tsw::t2tCmdPrms_calibration_analysis');
	confess 'Bad column number!' unless  $ca->{cmatrix}->{cols} >= 8;
	my $self = $class->SUPER::new();
	my $rows = $ca->{cmatrix}->{rows};
	my $cols = $ca->{cmatrix}->{cols};
	my $vals = $ca->{cmatrix}->{vals};
	my $s = $self->{samples} = [];
	for (my $i = 0; $i < $rows; $i++) {
		push @$s, t2tHelpers::t2tCalibrationData->new($vals,$i*$cols);
	}
	bless $self, $class;
	return $self;
}

sub compact_header() {
	return "truePointX\ttruePointY\tleftMapX\tleftMapY\tleftValidity\trightMapX\trightMapY\trightValidity";
}

sub str {
	my $self = shift;
	my $compact = shift;
	my $ret = "";
	foreach my $s (@{$self->{samples}}) {
		$ret .= sprintf("%s\n", $s->str($compact));
	}
	return $ret;
}

# *** -----------------------------------------------------

package t2tHelpers::t2tEvent;
use strict;
our @ISA = qw(t2tHelpers::_members);

sub new {
	my $class = shift;
	my ($time, $duration, $code, $details) = @_;
	my $self = $class->SUPER::new();
	$self->{time} = $time;
	$self->{duration} = $duration;
	$self->{details} = $details;
	$self->{code} = $code;
	bless $self, $class;
	return $self;
}


# *** -----------------------------------------------------

package t2tHelpers::t2tDataSamples;
use Carp;
use strict;
our @ISA = qw(t2tHelpers::_members);

sub new {
	my $class = shift;
	my $ds = shift;
	confess 'Bad parameter!' unless $ds->isa('t2tsw::t2tCmdPrms_get_gazes_data');
	confess 'Bad columns number!' unless  $ds->{gmatrix}->{cols} >= 16;
	my $self = $class->SUPER::new();
	my $rows = $ds->{gmatrix}->{rows};
	my $cols = $ds->{gmatrix}->{cols};
	my $vals = $ds->{gmatrix}->{vals};
	$self->{start_time} = $ds->{start_time};
	my $s = $self->{samples} = [];
	for (my $i = 0; $i < $rows; $i++) {
		push @$s, t2tHelpers::t2tSampleExt->new($vals, $i*$cols);
	}
	bless $self, $class;
	return $self;
}

sub str {
	my $self = shift;
	my $ret = sprintf("start_time = %f\n", $self->{start_time});
	my $s = $self->{samples};
	for (my $i = 0; $i <= @{$s}-1; $i++) {
		$ret += sprintf("%s\n", $s->[$i]->str());
	}
	return $ret;
}

# *** -----------------------------------------------------

package t2tHelpers::t2tDataEvents;
use Carp;
use strict;
our @ISA = qw(t2tHelpers::_members);

sub new {
	my $class = shift;
	my $dt = shift;
	confess 'Bad parameter!' unless $dt->isa('t2tsw::t2tCmdPrms_get_events_data');
	confess 'Bad column number!' unless  $dt->{num_matrix}->{cols} >= 2;
	confess 'Bad column number!' unless  $dt->{str_matrix}->{cols} >= 2;
	confess 'Missing events data fields!' unless  $dt->{str_matrix}->{rows} == $dt->{num_matrix}->{rows};
	my $self = $class->SUPER::new();
	my $cols = $dt->{num_matrix}->{cols};
	my $rows = $dt->{num_matrix}->{rows};
	my $num  = $dt->{num_matrix}->{vals};
	my $str  = $dt->{str_matrix}->{vals};
	$self->{start_time} = $dt->{start_time};
	my $e = $self->{events} = [];
	for (my $i = 0; $i < $rows; $i++) {
		push @$e, t2tHelpers::t2tEvent->new(t2tsw::doubleArray_getitem($num, $i*$cols), 
								 t2tsw::doubleArray_getitem($num, $i*$cols+1), 
								 t2tsw::charpArray_getitem($str, $i*$cols), 
								 t2tsw::charpArray_getitem($str, $i*$cols+1));
	}
	bless $self, $class;
	return $self;
}

sub str {
	my $self = shift;
	my $ret = sprintf("start_time = %f\n", $self->{start_time});
	my $e = $self->{events};
	for (my $i = 0; $i <= @{$e}-1; $i++) {
		$ret += sprintf("%s\n", $e->[$i]->str());
	}
	return $ret;
}

# *** -----------------------------------------------------

package t2tHelpers;

sub bailOut {
	my($msg, $disconnect) = @_;
	
	if (!$msg eq "") {
		print $msg;
	}
	if (defined($disconnect) && $disconnect) {
		my $c = new t2tsw::t2tCmd();
		$c->{cmd} = "DISCONNECT";
		t2tsw::t2tCmdDemux($c);
	}
	exit 0
}

sub cmdEx {
	my($c, $disconnect) = @_;
	
	$disconnect = 1 unless defined($disconnect);
	
	if (t2tsw::t2tCmdDemux($c) != 0) {
		 my $cname = $c->{cmd};
		 unless (defined $cname) { $cname = "TIMESTAMP" };
		 my $msg = "ERR running cmd: ".$cname."\nExiting...\n";
		 bailOut($msg, $disconnect);
		 return undef;
	} else {
		my $dispose = 1;
		my $data = {};
		
		# Here, first,  for performance reason
		if ((not defined $c->{cmd}) || ($c->{cmd} eq "TIMESTAMP")) { 
			$data->{timestamp} = $c->{prm}->{timestamp}->{time};
		} 
		elsif ($c->{cmd} eq "GET_SAMPLE") {
			$data->{sample} = t2tHelpers::t2tSample->new($c->{prm}->{get_sample});
		} 
		elsif ($c->{cmd} eq "GET_SAMPLE_EXT") {
			$data->{sample_ext} = t2tHelpers::t2tSampleExt->new($c->{prm}->{get_sample_ext});
		} 
		elsif ($c->{cmd} eq "CALIBRATION_ANALYSIS") {
			if ($c->{prm}->{calibration_analysis}->{cmatrix}->{rows} != 1 && $c->{prm}->{calibration_analysis}->{cmatrix}->{cols} != 1) {
				$data->{calibration_analysis} = t2tHelpers::t2tCalibrationAnalysis->new($c->{prm}->{calibration_analysis});
			}
		} 
		elsif ($c->{cmd} eq "GET_EVENTS_DATA") {
			$data->{start_time} = $c->{prm}->{get_events_data}->{start_time};
			$data->{events_data} = t2tHelpers::t2tDataEvents->new($c->{prm}->{get_events_data}) if ($data->{start_time} >= 0);
		} 
		elsif ($c->{cmd} eq "GET_GAZES_DATA") {
			$data->{start_time} = $c->{prm}->{get_gazes_data}->{start_time};
			$data->{gazes_data} = t2tHelpers::t2tDataSamples->new($c->{prm}->{get_gazes_data}) if ($data->{start_time} >= 0);
		} 
		elsif ($c->{cmd} eq "GET_STATUS") {
			$data->{status_data} = t2tHelpers::t2tStatus->new($c->{prm}->{get_status});
			$data->{history_data} = t2tHelpers::t2tHistory->new($c->{prm}->{get_status}) if $c->{prm}->{get_status}->{get_history};
		}
		elsif ($c->{cmd} eq "EVENT") {
			$data->{start_time} = $c->{prm}->{event}->{start_time};
		}
		else {
			$data = undef;
			$dispose = 0;
		}
		
		if ($dispose) {
			t2tsw::t2tCmdOutputDispose($c);
		}
		return $data;
	}
}

sub checkStatus {
	my($what, $val, $timeout, $debug) = @_;
	
	my $c = new t2tsw::t2tCmd();
	$c->{cmd} = "GET_STATUS";
	$c->{prm}->{get_status}->{get_history} = 0;
	
	if (!defined($timeout)) {
		$timeout = 0;
	}
	
	my $match = 0;
	my $st;
	
	while(1) {
		$st = cmdEx($c)->{status_data};
		$match = ($st->{$what} == $val);
		last if ($match || $timeout - 0.01 < 0);
		Time::HiRes::sleep 0.01;
		$timeout -= 0.01;
	}
	if (defined($debug) && $debug) {
		print "Status: ".$st->str()."\n";
	}
	return $match;
}   

sub rawInput {
	my($msg) = @_;
	
	print $msg;
	ReadMode 4; # Turn off controls keys
	while (!defined (my $key = ReadKey(-1))) {
    	Time::HiRes::sleep 0.05;
	}
	ReadMode 0; # Reset tty mode before exiting
}