#!/usr/bin/env perl

package UDS::Server::Dispatch;
use strict;
use warnings;
use feature 'say';
use IO::Socket::UNIX qw( SOCK_STREAM SOMAXCONN );

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
    if (-e $socketFile){
        unless (unlink($socketFile)){
            $self->setLastError ("Failed to unlink socket file: $socketFile . The error was: $!");
            return undef;
        }
    }

    unless ($listen = IO::Socket::UNIX->new(Type => SOCK_STREAM,Local => $socketFile, Listen => SOMAXCONN,)){
         $self->setLastError("Cannot create server socket. The error was: $!");
         return undef;
    }
    
    unless  ($socket = $listen->accept()){
        $self->setLastError("Can't accept connection: $!");
        return undef;
    }
    
    while (1){    
        chomp (my $string = <$socket>);
        #if ($string){
            my $pid=fork();
            if ($pid > 0 ){
                say "Successfully forked process: $pid to execute the registered function !";
            }elsif ($pid == 0){
                say "Child: sending string: $string to the registered function !";
                &$function($socket,$string);
                say "Child $$: Execution completed !";
                return 0;
            }else{           
                say "WARNING: failed to fork process in order to execute registered function! ($!)";
                say "Executing the registered function without fork. This server will be blocked untill the function completes it's execution !";
                &$function($socket,$string);
            }
        #}
    }
}
1;