#!/usr/bin/env perl

package UDS::Server::Dispatch;
use strict;
use warnings;
use feature 'say';
use IO::Socket::UNIX qw( SOCK_STREAM SOMAXCONN );
$| = 1;
require "/opt/lz/modules/errorHandler.pl";
$SIG{CHLD}='IGNORE';

sub server {
    my ($self,$socketFile,$function)=@_;
    unless ($socketFile){
        $self->setLastError("No socket file sent !");
        return undef;
    }
    #TODO: Check if the $function variable is function !
    my $ref=ref $function;
    say "Current reference is: $ref";
    unless ( $ref eq 'CODE'){
        $self->setLastError("Second parameter must be reference to function, not: $ref");
        return undef;
    }
    
    my $listen=undef;
    my $socket=undef;

    unless ($listen = IO::Socket::UNIX->new(Type => SOCK_STREAM,Local => $socketFile, Listen => SOMAXCONN,)){
         $self->setLastError("Cannot create server socket. The error was: $!");
         return undef;
    }
     

    
    
    while (1){
        unless  ($socket = $listen->accept()){
            $self->setLastError("Can't accept connection: $!");
            return undef;
        }
        autoflush $socket 1;
        
        #if ($string){
            my $pid=fork();
            if ($pid > 0 ){
                say "Successfully forked process: $pid to execute the registered function !";
            }elsif ($pid == 0){
                while (1){
                    chomp (my $string = <$socket>);
                    say "Child $$: sending string: $string to the registered function !";
                
                    unless (defined &$function){
                        say "Child $$: the registered function is gone. Terminating.";
                        last;
                    }else{                
                        &$function($socket,$string);
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