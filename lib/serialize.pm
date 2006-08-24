package serialize;
use vars qw(@ISA @EXPORT $SERIALIZE_DBG);
@ISA     = qw(Exporter);
@EXPORT  = qw(serialize unserialize);
$VERSION = 0.91;

=pod
Perl implementation of PHP's native serialize() and unserialize() functions.

Scott Hurring
scott at hurring dot com
http://hurring.com/
Please be nice and send bugfixes and code improvements to me.

@version v0.91
@author Scott Hurring; scott at hurring dot com
@copyright Copyright (c) 2005 Scott Hurring
@license http://opensource.org/licenses/gpl-license.php GNU Public License

Most recent version can be found at:
http://hurring.com/code/perl/serialize/

=====================================================================

Unlike modules that make use of language-specific binary formats, the
output of serialize() is an ASCII string, meaning you can easily
manipulate it as you would any other string, i.e. sticking it
into a URL, a database, a file, etc...

Taken along with my python serialize implementation, this code will
enable you to transfer data between PHP, Python, and Perl using PHP's
data serialization format.

To serialize:
	# serialize an array into a string
	my $serialized_string = serialize(\@data);
	# or... serialize a hash into a string
	my $serialized_string = serialize(\%data);

To unserialize:
	# unserialize some string into python data
	$hash_ref = unserialize($serialized_string)

PHP Serialization Format:
	NULL		N;
	Boolean		b:1;			b:$data;
	Integer		i:123;			i:$data;
	Double		d:1.23;			d:$data;
	String		s:5:"Hello"		s:$length:"$data";
	Array		a:1:{i:1;i:2}		a:$key_count:{$key;$value}
						$value can be any data type

Supported Perl Types:
	Serializing:
	NULL (\0), int, double, string, hash, array

	Unserializing:
	NULL (\0), int, double, string, hash

*array is unserialized as a hash, becuase PHP only has one array
type "array()", which is analagous to Perl hash's.  When you try to
serialize a perl array, it's automagically converted into a hash
with keys numbered from 0 up.

Type Translation Table:
	(Perl)	(serialize)	(PHP)	    (unserialize)  (Perl)
	NULL 	=>		NULL 			=> NULL
	int 	=>		int 			=> int
	double 	=>		double			=> double
	string 	=>		string			=> string
	hash 	=>		array			=> hash
	array 	=>		array			=> hash

====================================================================

Warning:

This code comes with absolutely NO warranty... it is a quick hack
that i sometimes work on in my spare time.  This code may or may
not melt-down your computer and give you nonsensical output.

Please, do not use this code in a production enviornment until
you've thoroughly tested it.

=====================================================================

=cut

  #When set to "1", prints out some misc. debugging information
  our $SERIALIZE_DBG = 0;

=pod
Serialize a hash or array (or single value) PHP-style
* Only serializes data (scalar,hashref,arrayref)
* No other references or code/object type stuff will be tolerated
* die() will be called dirty data is encountered.

Usage:

  $stext = serialize(\%hash);
  $stext = serialize(\@array);
  $stext = serialize($value);

  $stext contains the serialized representation of the thing
  you passed to serialize()

=cut
sub serialize {
  my ($ref) = @_;
  my $s;

  #if this is a hash/array, recurse down into it.
  if (ref($ref) =~ /hash|array/i) {
	$s = serialize_sub($ref, '', 1);
  }

  #if this is a single value (string or int)
  #  thanks to Ron Grabowski [ronnie (at) catlover.com] for pointing
  #  out the the need for serialization of single values
  else {
  	return serialize_value($ref);
  }

  return $s;
}

=pod
Fun Recursion.
Goes down the branches of any data structure given to it
and serializes it up.

* WARNING *
will call die() if anything other than a hashref,arrayref,scalar is encountered

@param
  $ref    = value
  	(could be arrayref/hashref, in which case, recurse
  	 for each key of $$ref)
  $k      = keyname
  $no_key = tells serialize_sub not to put a keyname for this value
	(used for the very first part of the array/hash being serialized)

@return	serialized string

=cut
sub serialize_sub {
  my ($ref, $k, $no_key) = @_;
  my $s;

  #The key's name
  $s .= serialize_value($k)
  	unless ($no_key);
  	#the very top level of a hash/array should *not* have a keyname

  if ($no_key) {
	#print "\n\nno_key is set, ref=$ref, ". ref($ref) .", k=$k, s=$s\n\n";
  }

  #This is a hash ref (recurse thru the structure)
  if ( ref($ref) =~ /hash/i) {
	#The data in the hashref
	my $num = keys(%{$ref});
	$s .= "a:$num:{";
	foreach my $k ( keys(%$ref) ) {
		$s .= serialize_sub( $$ref{$k}, $k );
	}
	$s .= "}";

  }

  #This is an array ref (recurse thru the structure)
  elsif ( ref($ref) =~ /array/i) {
	#The data in the arrayref
	my $num = @{$ref};
	$s .= "a:$num:{";
	for (my $k=0; $k < @$ref; $k++ ) {
		$s .= serialize_sub( $$ref[$k], $k ) ;
	}
	$s .= "}";

  }

  #Scalar value (doesn't have a ref)
  elsif ( !ref($ref) ) {
	$s .= serialize_value($ref);
  }

  #Some type of reference that can't be handled. Throw error.
  else {
	  die("Cannot handle $ref = type (". ref($ref) .")" )
  }

  return $s;
}


=pod
Serialize a single value

  differentiates between string and integer types,

  return type:
	string  = s:length:"text";
	integer = i:integer;
	double  = d:double;

  example
	text = s:4:"text";
	5    = i:5;

=cut
sub serialize_value {
  my ($value) = @_;
  my $s;

  #this is an integer
  # Thanks to Konrad Stepien <konrad@interdata.net.pl>
  # for pointing out correct handling of negative numbers.
  if ($value =~ /^\-?\d+$/) {
	# if larger than 32 bits, serialize it as a double
	if (abs($value) > 2**32) {
		$s = "d:$value;";
	}
	else {
		$s = "i:$value;";
	}
  }

  #this is a double
  # Thanks to Konrad Stepien <konrad@interdata.net.pl>
  # for pointing out correct handling of negative numbers.
  elsif ($value =~ /^\-?(\d+)\.(\d+)$/) {
  	$s = "d:$value;";
  }

  #this is a NULL value
  #
  # Only values of "\0" will be serialized as NULL
  # Empty strings are not NULL, they are simply empty.
  # Note: this differs from v0.7 where a string "NULL" would
  #     be serialized as NULL.
  elsif ($value eq "\0")  {
  	##print "NULL: \"$value\" \n";
  	$s = "N;";
  }

  #this is a string
  else {
	my $vlen = length($value);
  	$s = "s:$vlen:\"$value\";";
  }

  return $s;
}





## ##################################################################
## ##################################################################
## ##################################################################
## ##################################################################
## ##################################################################

=pod
Unserializes a PHP-style serialized text string into a perl hashref

  Returns a hashref (or single value) of the serialized text string

  $hashref = unserialize($serialized_array);
  $value   = unserialize($serialized_value);

  returns 0 if it cannot understand what you gave it

  ** Beware: this will never return an array ref, even if the orignal data was an array

=cut
sub unserialize {
  my ($string) = @_;


  #this is a serialized hash/array
  # "s" added to regexp, email from: Joel A. Chornik [joel (at) elserver.com]
  if ( $string =~ /^a:(\d+):({(.*)})$/s )
  {
  	print "Unserializing complex array ($string)"		if ($SERIALIZE_DBG);

	my $keys  = $1 * 2;  		#keys in this serialized array
	my @chars = split(//, $2);	#turn the data into an array of chars
	undef $string;			#to save memory.

	return unserialize_sub( {}, $keys, \@chars);
  }


  #thanks to Ron Grabowski [ronnie (at) catlover.com] for the following
  #single value string and integer code

  #this is a single string
  elsif ($string =~ /^s/)
  {
  	print "Unserializing single string ($string)"		if ($SERIALIZE_DBG);

	$string =~ /^s:(\d+):/;
	return substr($string, length($1) + 4, $1);
  }

  #this is a single integer or double value
  #  handled the same way
  elsif ($string =~ /^i|^d/)
  {
  	print "Unserializing integer or double ($string)"	if ($SERIALIZE_DBG);

	return substr($string, 2) + 0;
  }

  #thanks to Julian Jares [jjares (at) uolsinectis.com.ar] for pointing out
  #the lack of, and contributing code for NULL value handling.

  #this is a NULL value
  #return something equivilent to "NULL" in perl-world
  elsif ($string == /^N/i) {
  	print "Unserializing NULL value ($string)"		if ($SERIALIZE_DBG);

  	#return equivalant of NULL
  	return "\0";
  }

  #invalid data
  else
  {
  	print "Unserializing BAD DATA! ($string)"		if ($SERIALIZE_DBG);

  	#die("Trying to unserialize bad data!");
  	return '';
  }


}



=pod
Resursive unserializing routine for a serialized hash or array

  Traverses the serialized text representation and builds a hash

	due to the way that an array is serialized in PHP, it's impractical
	to return proper array/hash types in perl.  PHP makes no distinction
	between an array and a hash (arrays are just hashes with numeric
	keys and vice versa) -- so in this routine, everything is unserialized
	as a hash.

  @param
  	$hashref	the hashref currently being built
  	$keys		how many keys are in this hash ref
  	$chars		arrayref of characters to process.

  @return		unserialized hashref

=cut
sub unserialize_sub {
  my ($hashref, $keys, $chars) = @_;
  my ($temp, $keyname, $skip, $strlen);
  my $mode = 'normal';		#default mode

  print "unserialize: $hashref, $keys, $chars\n"	if ($SERIALIZE_DBG);

=pod
  this basically iterates through each character one-by-one
  it's a state machine, it keeps the current state in "$mode"
  when $mode ==
  	'string'
  		1) look for a digit, which is the length of the
  		serialized string that we're about to see, save
  		that as $strlen.
  		2) after the next ':', $mode='readstring'
  	'readstring'
  		capture $strlen characters into $temp
  		then, mode='set'
  	'set'
  		1) set $value=$temp and assign the current hash key=$value
  		2) $mode='normal'
	'integer'
		1) put all digits into $temp, skip ":"
		2) at the first ";", $mode='set'
	'double'
		1) same as integer, only allows "." in input
		2) at the first ";", $mode='set'
	'null'
		1) null value, set $temp="\0"
		2) $mode='set'
=cut


  #it loops through each
  #
  #
  while ( defined(my $c = shift @{$chars}) )
  {
	print "\t[$mode] = $c\n"			if ($SERIALIZE_DBG);

  #string processing
  #format: s:length:"data"

	if ($mode eq 'string') {
		$skip = 1;	#how many chars should 'readstring' skip?
				#consider all strings have '"' at beginning...

		#find out how many chars need to be read
		if ($c =~ /\d+/) {
			#get the length of string
			$strlen = $strlen . $c;
			print "string length = $strlen ($c)\n"	if ($SERIALIZE_DBG);
		}

		#if we already have a length, and see ':', we know that
		#the actual string is coming next (see format above)

		if (($strlen =~ /\d+/) && ($c eq ':')) {
			$mode = 'readstring';
		}

	}

	#read in $strlen number of characters (aka. the whole string)
	elsif ($mode eq 'readstring') {
		#skip the appropriate amount of chars
		next 			if ($skip-- > 0);
		$mode = 'set', next	if (!$strlen--);

		#grab characters until we reach $strlen
		$temp .= $c;

	}


  #integer processing
  #format: i:data
	elsif ($mode eq 'integer') {
		next 			if ($c eq ':');
		$mode = 'set', next	if ($c eq ';');

		#grab integers
		# Thanks to Konrad Stepien <konrad@interdata.net.pl>
		# for pointing out correct handling of negative numbers.
		if ($c =~ /\-|\d+/) {
			if ($c eq '-') {
				$temp .= $c unless $temp;
			} else {
				$temp .= $c;
			}
		}


	}


  #double processing
  #format: d:data
	elsif ($mode eq 'double') {
		next 			if ($c eq ':');
		$mode = 'set', next	if ($c eq ';');

		#grab integers and decimal points
		# Thanks to Konrad Stepien <konrad@interdata.net.pl>
		# for pointing out correct handling of negative numbers.
		if ($c =~ /\-|\d+|\./) {
			if ($c eq '-') {
				$temp .= $c unless $temp;
			} else {
				$temp .= $c;
			}
		}

	}


  #thanks to Julian Jares [jjares (at) uolsinectis.com.ar] for pointing out
  #the lack of, and contributing code for NULL value handling.

  #null value processing
  #format: N
	elsif ($mode eq 'null') {

		#set $temp to something equivilent to PHP's NULL,
		#AFAIK, in perl-speak, is "\0".
		#temp should not be set to an empty string, becuase PHP serializes
		#empty strings as 's:0:"";', not 'N;' -- only true NULL values
		#should be serialized as 'N;', thus when we un-serialize, we should
		#be faithful and give perl a "\0" or equivilent NULL value.

		$temp = "\0";

		$mode = 'set', next;
	}


  #array processing
  #format: a:num_of_keys:{...}
	elsif ($mode eq 'array') {

		#end of array definition, start processing it
		if ($c eq '{') {

			#recurse to get the sub-array
			$$hashref{$keyname} =
				unserialize_sub( $$hashref{$keyname}, ($temp * 2), $chars );

			#begin processing as normal again
			undef $keyname;
			$mode = 'normal';

		}

		#find out how many keys are in this sub-array
		elsif ($c =~ /\d+/) {
			$temp = $temp . $c;
			print "array_length = $temp ($c)\n"	if ($SERIALIZE_DBG);
		}

	}


  #set the thing that's waiting for information ('key' or 'value')
  #to the current data held in $temp
	elsif ($mode eq 'set') {

  		#(the keyname has already been specified)
  		#so, $temp is a value for the keyname
  		if (defined($keyname)) {
  			print "set VALUE=$temp\n"	if ($SERIALIZE_DBG);

			$$hashref{$keyname} = $temp;

			#blank out keyname
			undef $keyname;

		}

  		#$temp is a keyname
  		else {
  			print "set KEYNAME=$temp\n"	if ($SERIALIZE_DBG);
			$keyname = $temp;
  		}

		$mode = 'normal';
	}





	if ($mode eq 'normal') {
		#blank out temp vars
		$strlen = $temp = '';

		if (!$keys)
		{
			print "return, no more keys to process = ($keys)\n"	if ($SERIALIZE_DBG);
			return $hashref;
		}

		#Upcoming information is integer
		if ($c eq 'i')
		{
			$mode = 'integer';
			$keys--;
		}
		#Upcoming information is a double
		if ($c eq 'd')
		{
			$mode = 'double';
			$keys--;
		}
		#Upcoming information is a bool,
		#which is the same as an int in perl.
		if ($c eq 'b')
		{
			$mode = 'integer';
			$keys--;
		}
		#Upcoming information is string
		if ($c eq 's')
		{
			$mode = 'string';
			$keys--;
		}
		#Upcoming information is array/hash
		if ($c eq 'a')
		{
			$mode = 'array';
			$keys--;
		}
		#Upcoming information is a null value
		if ($c eq 'N')
		{
		        $mode = 'null';
			$keys--;
	        }

	}



  }#while



  #technically, you should never hit this, becuase
  #the value of $keys should be exactly the value of
  #keys that need to be unserialized, and the loop
  #should never exit from lack of characters
  print "return normally (chars=". (join ',', @$chars) .")\n"	if ($SERIALIZE_DBG);
  return $hashref;
}

1;
