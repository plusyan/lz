#!/usr/bin/env perl

package UDS::Server::Dispatch;
use strict;
use warnings;
use feature 'say';
use IO::Socket::UNIX qw( SOCK_STREAM SOMAXCONN );
use POSIX;
use Array::Utils qw(:all);
use Data::Dumper;   

$| = 1;
require "/opt/lz/modules/errorHandler.pl";
$SIG{CHLD}='IGNORE';

my $connected=1;
my $errMessage=undef;

# Handle the SIGPIPE here.
# SIGPIPE will tell us if the connection with the pear is broken !
$SIG{PIPE} = sub {
     $errMessage="Lost connection to client: $!";
     $connected=0;
};

sub new {
     my $self=shift;
     my %config=(
        init => 'true',
        socket => undef,
     );
    
    return bless \%config;
}

sub send {
    my ($self,$message)=@_;
    my $socket=$$self{socket};
    unless ($socket){
        $self->setLastError("You need to specify the socket !");
        return undef;
    }
    
    $message=~s/[\n\r]{0,}//g;
    $message .="\n";
    say "About to send the following message: [$message]";
    
    my $length=length($message);
    
    my $rc=syswrite ($socket, $message, $length, 0);
    unless ($connected){
          $self->setLastError("$errMessage");
          
          $socket->shutdown(2);
          $socket->close;
          $socket=undef;
          $$self{socket}=undef;
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
    1;
    
}


sub server{
     # 1. Parameters check !
    my ($self,$socketFile,$function)=@_;
    unless ($socketFile){
        $self->setLastError("No socket file sent !");
        return undef;
    }
    
    my $ref=ref $function;
    unless ( $ref eq 'CODE'){
        $self->setLastError("Second parameter must be reference to function, not: [$ref]");
        return undef;
    }
    
    my $listen=undef;
    my $socket=undef;

     # 2. Open the Unix Domain Socket
     unless ($listen = IO::Socket::UNIX->new(Type => SOCK_STREAM, Local => $socketFile, Listen => SOMAXCONN)){
          $self->setLastError("Cannot create server socket. The error was: $!");
          return undef;
     }
     
     # 3. Accept connections on the socket.
     while (1){
          unless ($socket = $listen->accept()){
             $self->setLastError("Can't accept connection: $!");
             return undef;
          }
         
          # Prevent "suffering from the buffering" effect
          autoflush $socket 1;
         
          my $pid=fork();
          if ($pid > 0 ){
               say "Successfully forked process: $pid to execute the registered function !";
          }elsif ($pid == 0){
               #4. Execute external function to handle the request ($string) !
               while (1){
                    my $string=undef;
                   
                    # Make sure that we use blocking socket.
                    # This is to allow the server to wait for input from the client.
                    $socket->blocking(1);
                    
                    # Wait for connection.
                    $string = <$socket>;
                    
                    # The remaining of the communication is done via non-blocking socket !
                    $socket->blocking(0);
                    $string=~s/[\n\r]//g;
                    
                    unless (defined &$function){
                        say "Child $$: the registered function is gone. Terminating.";
                        $self->send($socket,"text=internalServerError:functionNotRegistered\n");
                        
                        $socket->shutdown(2);
                        $socket->close;
                        $socket=undef;
                        $self->setLastError("Registered function does not exist !");
                        return undef;
                    }
                   
                    say "Child $$: sending string: $string to the registered function !";
                    
                    $socket->blocking(0);
                    
                    $$self{socket}=$socket;
                    &$function($string);
                    last unless defined $$self{socket};
               }
               
               $self->setLastError("Child execution terminated.");
               return undef;
          }else{
              $self->setLastError ("FATAL: failed to fork process in order to execute the registered function! ($!)");
              return undef;
          }
     }
}

1;