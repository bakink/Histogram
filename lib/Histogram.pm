
package Histogram;

use strict;
use warnings;
use Data::Dumper;

=head1 Histogram

 This is a simple histogram function used to visualize the distribution of a series of integer data

 The data may be filtered using < > <= >=

 The following example generates a random range of data, ignoring values > 80

 use Histogram;

 my $randMax=7537;

 my @data = map { int(rand($randMax)) } (1..$randMax);

 my $bucketCount=27; # will actually be +1 for the max value

 # print a histogram
 my $maxHistLineLen=50;
 my $histChar='*';
 my $maxValue=5000;
 my $limitOperator = '<=';

 my $h=Histogram->new(
   {
      LINE_LENGTH =>  $maxHistLineLen,
      HIST_CHAR => '*',
      BUCKET_COUNT => $bucketCount,
      DATA => \@data,
      FILTER_OPER =>  $limitOperator,
      FILTER_LIMIT =>  $maxValue
   }
 );

 print join("\n",  @{$h->prepare} ),"\n";


=cut


sub new {
	
	my $pkg = shift;
	my $class = ref($pkg) || $pkg;
	my $parms= shift;

	#print Dumper($parms);
	#print join(' - ', keys %{$parms}), "\n";

	my $self = $parms;

	my $retval =  bless $self, $class;

	#print 'new: ', Dumper($self);
	$self->_createBuckets();

	return $retval;

}

sub _createBuckets {
	my $self=shift;

	#print join(' - ', keys %{$parms}), "\n";

	my %hdata=();

	FILTER_DATA: {
		if ( defined($self->{FILTER_OPER}) and defined($self->{FILTER_LIMIT}) ) {
			# check for allowed operator
			my $op=$self->{FILTER_OPER};
			my @allowedOperators = qw(< > <= >=);
			if ( ! grep(/^$op$/,@allowedOperators) ) {
				last FILTER_DATA;
			}

			my $filterValue = $self->{FILTER_LIMIT};

			my @tmpData;
			#print "OP: $op\n";
			#print "Value $filterValue\n";
			my $evalStr= q[grep { $_ ]
				. qq[ $op  $filterValue ]
				. q[ } @{$self->{DATA}};];
			#print "Eval String; $evalStr\n";
			@tmpData = eval $evalStr;

			#print Dumper(\@tmpData);

			$self->{DATA} = \@tmpData;

		}
	}

	my ($min,$max) = (10**20,0);

	for (@{$self->{DATA}}) {
		my $n = $_;
		#print "n:|$n|\n";
		$min = $n if $n < $min;
		$max = $n if $n > $max;
	}

	#print '_createBuckets: ', Dumper($self);
	my $bucketSize = int(($max-$min)/$self->{BUCKET_COUNT});
	#print "_createBuckets bucketSize $bucketSize\n";
	$self->{MIN_VALUE} = $min;
	$self->{MAX_VALUE} = $max;

	my $maxHistogramCount=0;

	for (@{$self->{DATA}}) {
		my $n = $_;
		my $bucket = ($n - $n%$bucketSize ) + $bucketSize;
	
		#print "n: $n  bucket $bucket\n";
		
		push @{$hdata{$bucket}}, $n;

	}


	foreach my $bucket ( sort {$a <=> $b} keys %hdata ) {
		my $hCount=$#{$hdata{$bucket}}+1;
		#print "Bucket:Counts:  $bucket : $hCount \n";
		# get the max count
		$maxHistogramCount = $hCount unless $maxHistogramCount > $hCount
	}


	#print "maxHistogramCount $maxHistogramCount\n";

	$self->{HDATA} = \%hdata;
	$self->{_countPerChar} = $self->{LINE_LENGTH} / $maxHistogramCount;
	
	#print '_createBuckets: ', Dumper($self);

}


sub prepare {
	my $self=shift;

	my @histogram;

	#print "PRINT ROUTINE\n";
	my %hdata = %{$self->{HDATA}};

	foreach my $bucket ( sort {$a <=> $b} keys %hdata ) {
	
		my $lineLen = int( $#{$hdata{$bucket}}+1  / $self->{_countPerChar});
		my $hline = sprintf("%10d: ",$bucket );
		$hline .= $self->{HIST_CHAR} x int( $lineLen  * $self->{_countPerChar}) ;
		push @histogram, $hline;
		#print "$hline\n";
	}

	\@histogram;
}

1;


