#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use Data::Dumper;
use UDS::Server::Dispatch;

sub testServer{
    my ($socket,$string)=@_;
    print Dumper \$socket;
    say "$string";
    say $socket "200 OK";
    
}

UDS::Server::Dispatch->server("/data/tmp/myServer",\&testServer);
say UDS::Server::Dispatch->getLastError if UDS::Server::Dispatch->getLastError;


__DATA__
use strict;
use warnings;
use feature 'say';

use Crypt::CBC;
use Crypt::Cipher::AES;
use Data::Dumper;
my $key="";
my $iv='kfndkrszdfew2345';

## Read 16 bytes from /dev/urandom !!!
open (RND, "/dev/urandom") or
  die "Failed to open /dev/urandom. The error was: $!";
  
my $randomKey=undef;
sysread (RND,$randomKey,16,0) or die "Failed to read 16 bytes form /dev/urandom. The error was: $!";
close (RND);

my $cbc = Crypt::CBC->new( -cipher=>'Cipher::AES', -key=>$key);
my $ciphertext = $cbc->encrypt("secret data");
#2. Convert the binary key 
print Dumper \$randomKey;

print Dumper \$ciphertext;
say "Decrypted text is: " . $cbc->decrypt($ciphertext);
say "This is test !!!";

__DATA__
sub isMounted{
  my ($mountPoint,$fs)=@_;
  return undef unless ($mountPoint);
  my $command="findmnt -T $mountPoint";  
  $command .=" -t $fs" if ($fs);
  my @result=`$command`;
  foreach (@result){
    chomp $_;
    return 'mounted' if m/^$mountPoint/;
  }
  return 'notMounted';
}

sub fuseUmount($){
  my $mountPoint=shift;
  say "Umounting: $mountPoint";
  my $command="fusermount -u \"$mountPoint\"";
  say $command;
}


sub mount($){
  my $mountPoint=shift;
  unless (-d $mountPoint){
    say "Mount point \'$mountPoint\' does not exist !";
    return undef;
  }
  system("mount $mountPoint");
  if ($? != 0){
    say "Failed to mount: $mountPoint !";
    return undef;
  }
  return 1;
  
}

my $mountPoint="/data/mount/esx";
my $fs='fuse.sshfs';
mount($mountPoint);

fuseUmount($mountPoint);

__DATA__
findmnt -t fuse.sshfs
findmnt -t fuse.sshfs --raw
findmnt -S /dev/sda1
findmnt -T /data/mount/esx

FSTAB:
USERNAME@HOSTNAME_OR_IP:/REMOTE/DIRECTORY /LOCAL/MOUNTPOINT fuse.sshfs _netdev,user,idmap=user,transform_symlinks,identityfile=/home/USERNAME/.ssh/id_rsa,allow_other,default_permissions,uid=USER_ID_N,gid=USER_GID_N 0 0