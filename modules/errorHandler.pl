#!/usr/bin/env perl;
use strict;
use warnings;

my $lastError=undef;

sub deleteLastError{$lastError=undef}
sub getLastError{return $lastError}

sub setLastError{
	shift;
	$lastError= (caller(1))[3] . " @_";
}

sub getConfigValue{
		my ($self,@data)=@_;
		my $counter=$#data;
		if  ($counter == -1){
			$self->setLastError("Usage: my \$value=\$obj->getConfigValue(level1hash,level2hash,level3hash,....,var");
			return undef;
		}
		
		# Check if the 'new' method is invoked.		
		unless (exists $$self{init}){
			$self->setLastError("This module is not initialized. Please use 'new' method to do so.");
			return undef;
		}
		
		if ($counter == 0){
			my $var=pop @data;
			return $$self{$var} if (exists ($$self{$var}) && defined ($$self{$var}));
			$self->setLastError("var: " . $var . " Does not exist !");
			return undef;
		}
		
		my $var=pop @data;
		
		my $hashRef = $self;
		foreach my $test (@data){
			$hashRef = $hashRef->{$test};
		}
		return $$hashRef{$var} if (exists $$hashRef{$var});
		
		my $vars="";
		$vars .= "\{$_\}" foreach (@data);
		my $errorMessage="Error walking the nested config variables: " . $vars  . " !  Requested variable: \{$var\} is not amond them !";
		$self->setLastError($errorMessage);
		return undef;
}

sub setConfigValue {
		my ($self,@data)=@_;
		my $counter=$#data;
		if  ($counter == -1){
			$self->setLastError("Usage: setConfigValue(level1hash,level2hash,level3hash,....,var,value");
			return undef;
		}
		
		# Check if the 'new' method is invoked.		
		unless (exists $$self{init}){
			$self->setLastError("This module is not initialized. Please use 'init' method to do so.");
			return undef;
		}
		
		if ($counter == 0){
			$$self{pop @data}=undef;
			return 1;
		}
		
		if ($counter == 1){
			$$self{shift @data}=pop @data ;
			return 1;
		}
		
		my $value=pop @data;
		my $var=pop @data;

		my $hashRef = $self;
		foreach (@data){
			$$hashRef{$_} = {} unless (exists $$hashRef{$_});
			$hashRef = $hashRef->{$_};
		}

		$$hashRef{$var}=$value;

		1;
}

1;
