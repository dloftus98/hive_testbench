#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;

# PROTOTYPES
sub dieWithUsage(;$);

# GLOBALS
my $SCRIPT_NAME = basename( __FILE__ );
my $SCRIPT_PATH = dirname( __FILE__ );

# MAIN
dieWithUsage("one or more parameters not defined") unless @ARGV >= 2;
my $scale = shift;
my $prefix = shift || 2;
my $header = shift || 3;


chdir $SCRIPT_PATH;
chdir "sample-queries-tpcds/impala";
#ls -l | grep -v total | awk {'print $9'} | sed -e 's/\([0-9]\{1,2\}\).sql/\1/g' | sort -n | awk {'print "q"$1".sql"'}
#ls -l | grep -v total | awk {'print $9'} | sed -e 's/q\([0-9]\{1,2\}\)\.sql/\1/g' | sort -n | awk {'print "q"$1".sql"'}
my $glob_cmd="ls -l | grep -v total | awk {'print \$9'} | sed -e 's/q\\([0-9]\\{1,2\\}\\)\\.sql/\\1/g' | sort -n | awk {'print \"q\"\$1\".sql\"'}";
#print "$glob_cmd\n";
#my @queries = glob '*.sql';
my @queries = `$glob_cmd`;
#print @queries;
#print "\n";

my $db = "tpcds_bin_partitioned_${prefix}_parquet_$scale";

if ($header ne "noheader") {
   print "prefix,filename,status,time,rows\n";
}

for my $query ( @queries ) {
        $query =~ s/\n//g;
        my $logname = "$prefix$query.log";
        my $cmd="echo 'use $db; source $query;' | impala-shell 2>&1  | tee $prefix$query.log";
#       my $cmd="cat $query.log";
        print $cmd;

        my $hiveStart = time();

        my @hiveoutput=`$cmd`;
        die "${SCRIPT_NAME}:: ERROR:  impala-shell command unexpectedly exited \$? = '$?', \$! = '$!'" if $?;
	
	my $found = "false";
        my $hiveEnd = time();
        my $hiveTime = $hiveEnd - $hiveStart;
        foreach my $line ( @hiveoutput ) {
                if( $line =~ /Fetched (\d+) row\(s\) in ([\d\.]+)s/ ) {
                        print "$prefix,$query,success,$hiveTime,$1\n";
			$found = "true";
                } elsif(
                        $line =~ /^ERROR: /
                        # || /Task failed!/
                        ) {
                        print "$prefix,$query,failed,$hiveTime\n";
			$found = "true";
                } # end if
        } # end while
        if ($found eq "false") {
                print "$prefix,$query,unknown,$hiveTime\n";
        }
} # end for


sub dieWithUsage(;$) {
	my $err = shift || '';
	if( $err ne '' ) {
		chomp $err;
		$err = "ERROR: $err\n\n";
	} # end if

	print STDERR <<USAGE;
${err}Usage:
	perl ${SCRIPT_NAME} [scale] [prefix]

Description:
	This script runs the sample queries and outputs a CSV file of the time it took each query to run.  Also, all hive output is kept as a log file named 'queryXX.sql.log' for each query file of the form 'queryXX.sql'. Defaults to scale of 2.
USAGE
	exit 1;
}

