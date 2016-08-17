#!/usr/bin/env perl

package UDS::Server::Dispatch;
use strict;
use warnings;
use feature 'say';
use IO::Socket::UNIX qw( SOCK_STREAM SOMAXCONN );
use POSIX;
use Array::Utils qw(:all);
use Data::Dumper;
use Fcntl;

$| = 1;
require "/opt/lz/modules/errorHandler.pl";
$SIG{CHLD}='IGNORE';

my $connected=1;
my $errMessage=undef;

# Handle the SIGPIPE here.
# SIGPIPE will tell us if the connection with the pear is broken !
$SIG{PIPE} = sub {
     $errMessage="Lost connection to server: $!";
     $connected=0;
};

sub new {
    my %config=(
        init => 'true',
    );
    return bless \%config;
}

sub send {
    my ($self,$socket,$message)=@_;
    unless ($socket){
        $self->setLastError("You need to specify the socket !");
        return undef;
    }
    
    $socket or $socket=$$self{socket};
    unless ($socket){
        $self->setLastError("You tried to use send method before 'server' method. Please use the server method in order to create server first !");
        return undef;
    }
    
    $message=~s/[\n\r]//;
    $message .="\n";
    
    my $length=length($message);
    $socket->autoflush(1);
    
    # TODO: Change the socket state to non-blocking if the state is blocking.
    # Change it back once the transmission is completed successfully. 
    my $rc=syswrite ($socket, $message, $length, 0);
    unless ($connected){
        $self->setLastError("$errMessage");
        return undef;
    }
    if ($rc > 0) {
        while ($rc < $length){
            substr($message,0,$rc) = ' '; # truncate buffer
            $length=length($message);
            $socket->blocking(0);
            $rc=syswrite ($socket, $message, $length, 0);
            if ($! == EWOULDBLOCK){
                $self->setLastError('EWOULDBLOCK');
                return undef;
            }
            
            unless (defined $rc){
                $self->setLastError( "syswrite() to socket error: $!");
                $socket->shutdown;
                $self->setLastError('Failed to send message to socket. Closing the socket !');
                return undef;
            }
            
        }
    } elsif ($! == EWOULDBLOCK) {
        say "syswrite: Under construction. Need to try again here !";
        # TODO: Try again !
        # would block, not an error  # handle blocking, probably just by trying again later.
    
    } else {
        $self->setLastError( "syswrite() to socket error: $!");
        return undef;
    }
    
}    


sub server {
    my ($self,$socketFile,$function)=@_;
    unless ($socketFile){
        $self->setLastError("No socket file sent !");
        return undef;
    }
    
    my $ref=ref $function;
    unless ( $ref eq 'CODE'){
        $self->setLastError("Second parameter must be reference to function, not: $ref");
        return undef;
    }
    
    my $listen=undef;
    my $socket=undef;

    unless ($listen = IO::Socket::UNIX->new(Type => SOCK_STREAM, Local => $socketFile, Listen => SOMAXCONN)){
         $self->setLastError("Cannot create server socket. The error was: $!");
         return undef;
    }
    
    while (1){
        
        unless  ($socket = $listen->accept()){
            $self->setLastError("Can't accept connection: $!");
            return undef;
        }
        
        
        # Prevent "suffering from the buffering" effect
        autoflush $socket 1;
        
        my $pid=fork();
        if ($pid > 0 ){
            say "Successfully forked process: $pid to execute the registered function !";
        }elsif ($pid == 0){
            while (1){
                my $string;
                
                # Make sure that we use blocking socket. This is to allow the server to wait for input from the client.
                # Non blocking I/O here causes infinite loop !!!
                $socket->blocking(1);
                $string = <$socket>;
                $socket->blocking(0);
                $string=~s/[\n\r]//g;
                
                unless ($string){
                    my $message="error-text=emptyMessage";
                    my $result=""; # Call the real socketSend function here !
                    say "1. Result after syswrite is: $result";
                    next;
                }
                
                my $message="text=youAreGoodToGo\n";
                
                say "Terminate the client within 10 seconds !!!";
                    sleep 10;
                    say "Proceedong !";
                    
                    
                
                my $result=$self->send($socket,$message,length($message),0);
                unless ($connected){
                    $socket->shutdown(2);
                    close($socket);
                    $socket=undef;
                    last;
                }
                # TODO: Make sure that we check $connected value here !
                # TODO: Make sure that we do hard check if syswrite sent all data !!!
                
                
                say "2. Result after syswrite is: $result";
                $socket->blocking(0);
                
                
                chomp $string;
                
                unless (defined &$function){
                    say "Child $$: the registered function is gone. Terminating.";
                    last;
                }else{
                    #SELECT->can_write($socket)
                    # TODO: Reduce the @sockets somehow !
                    say "Child $$: sending string: $string to the registered function !";
                    my %config=(
                        socket => $socket
                    );
                    
                    &$function(bless (\%config,'UDS::Server::Dispatch'),$string);
                    $socket->blocking(1);
                }
            }
            say "Child $$: Execution completed !";
            return 0;
        }else{           
            say "FATAL: failed to fork process in order to execute the registered function! ($!)";
        }
    }
}


1;

