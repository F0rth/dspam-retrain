#!/usr/bin/perl
use Logger::Syslog;

my $DSPAM = '/usr/local/bin/dspam';
# Get arguments
my $class  = shift;
my $sender = shift;
my $recip  = shift;

error("dspam-retrain called without class") unless defined $class;
error("dspam-retrain called without sender") unless defined $sender;
error("dspam-retrain called without recip") unless defined $recip;
die("dspam-retrain not properly initiated") unless defined($class) and defined($sender) and defined($recip);
   
my $user;

# Pull out DSPAM signatures and send them to the dspam program
my $sub;
my $sig;
while (<>) {

   if ((! $user) && (/^[ >]*Delivered-To:\s*(\S+)/i)) {
        $user = $1;
    }
    elsif ((! $subj) && (/^Subject: /)) {
        $subj = $_;
    } elsif (/^[ >]*X-DSPAM-Signature:\s*(\S+)/i) {
        $sig = $1;
        last;
    } elsif ((! $sig) && (/^[ >]*!DSPAM:\s*(S+)/)) {
        $sig = $1;
        last;
}
}


if (! defined($subj)) {
    error("dspam-retrain can't find messages subject");
    die("dspam-retrain can't find messages subject");
}
if (! defined($sig)) {
    error("dspam-retrain can't find DSPAM signature");
    die("dspam-retrain can't find DSPAM signature");
}


my $ret = system($DSPAM, '--client', '--source=error', "--class=$class", '--user', $user, "--signature=$sig");
if ($ret==0) {
    notice("$DSPAM retrained with:$class; $user; $sig; $subj");
    notice("$ret");
} else {
    error("dspam-retrain error on: $DSPAM --source=error --class=$class --user $user --signature=$sig; $subj;");
    if ($ret == -1) {
        error("dspam-retrain: $DSPAM failed to execute: $!");
    } elsif ($ret & 127) {
        error(sprintf "dspam-retrain: child died with signal %d, %s coredump\n", ($? & 127), ($? & 128) ? 'with' :  'without' );
    }
    else {
        error(sprintf "dspam-retrain: child exited with value %d\n", $? >> 8);
    }
}
