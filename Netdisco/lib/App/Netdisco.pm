package App::Netdisco;

use strict;
use warnings FATAL => 'all';
use 5.010_000;

use File::ShareDir 'dist_dir';
use Path::Class;

our $VERSION = '2.005000_003';

BEGIN {
  if (not length ($ENV{DANCER_APPDIR} || '')
      or not -f file($ENV{DANCER_APPDIR}, 'config.yml')) {

      my $auto = dir(dist_dir('App-Netdisco'))->absolute;

      $ENV{DANCER_APPDIR}  ||= $auto->stringify;
      $ENV{DANCER_CONFDIR} ||= $auto->stringify;

      $ENV{DANCER_ENVDIR} ||= $auto->subdir('environments')->stringify;
      $ENV{DANCER_PUBLIC} ||= $auto->subdir('public')->stringify;
      $ENV{DANCER_VIEWS}  ||= $auto->subdir('views')->stringify;
  }
}

=head1 NAME

App::Netdisco - An open source web-based network management tool.

=head1 Introduction

The content of this distribution is the next major version of the Netdisco
network management tool. Pieces are still missing however, so if you're a new
user please see L<http://netdisco.org/> for further information on the project
and how to download the current official release.

=over 4

=item *

See the demo at: L<http://demo-ollyg.dotcloud.com/netdisco/>

=back

L<App::Netdisco> provides a web frontend and a backend daemon to handle
interactive requests such as changing port or device properties. There is not
yet a device poller, so please still use the old Netdisco's discovery, arpnip,
and macsuck.

If you have any trouble getting the frontend running, speak to someone in the
C<#netdisco> IRC channel (on freenode).

=head1 Dependencies

Netdisco has several Perl library dependencies which will be automatically
installed. However it's I<strongly> recommended that you first install
L<DBD::Pg> and L<SNMP> using your operating system packages. The following
commands will test for the existence of them on your system:

 perl -MDBD::Pg\ 999
 perl -MSNMP\ 999

With those two installed, we can proceed...

Create a user on your system called C<netdisco> if one does not already exist.
We'll install Netdisco and its dependencies into this user's home area, which
will take about 250MB including MIB files.

 root:~# useradd -m -p x -s /bin/bash netdisco

Netdisco uses the PostgreSQL database server. Install PostgreSQL and then change
to the PostgreSQL superuser (usually C<postgres>). Create a new database and
PostgreSQL user for the Netdisco application:

 root:~# su - postgres
  
 postgres:~$ createuser -DRSP netdisco
 Enter password for new role:
 Enter it again:
  
 postgres:~$ createdb -O netdisco netdisco

=head1 Installation

To avoid muddying your system, use the following script to download and
install Netdisco and its dependencies into the C<netdisco> user's home area
(C<~netdisco/perl5>).

 su - netdisco
 curl -L http://cpanmin.us/ | perl - --notest --quiet \
     --local-lib ~/perl5 \
     App::cpanminus App::local::lib::helper App::Netdisco

Link some of the newly installed apps into the C<netdisco> user's C<$PATH>,
e.g. C<~netdisco/bin>:

 mkdir ~/bin
 ln -s ~/perl5/bin/{localenv,netdisco-*} ~/bin/

Test the installation by running the following command, which should only
produce a status message (and throw up no errors):

 ~/bin/netdisco-daemon status

=head1 Configuration

Make a directory for your local configuration and copy the configuration
template from this distribution:

 mkdir ~/environments
 cp ~/perl5/lib/perl5/auto/share/dist/App-Netdisco/environments/development.yml ~/environments
 chmod +w ~/environments/development.yml

Edit the file and change the database connection parameters to match those for
your local system (that is, the C<dsn>, C<user> and C<pass>).

Optionally, in the same file uncomment and edit the C<domain_suffix> setting
to be appropriate for your local site.

=head1 Bootstrap

The database either needs configuring if new, or updating from the current
release of Netdisco (1.x). You also need vendor MAC address prefixes (OUI
data) and some MIBs if you want to run the daemon. The following script will
take care of all this for you:

 DANCER_ENVDIR=~/environments ~/bin/localenv netdisco-deploy

If you don't want that level of automation, check out the database schema diff
from the current release of Netdisco, and apply it yourself:

 ~/perl5/lib/perl5/App/Netdisco/DB/schema_versions/App-Netdisco-DB-2-3-PostgreSQL.sql

=head1 Startup

Run the following command to start the web-app server as a daemon (port 5000):

 DANCER_ENVDIR=~/environments ~/bin/netdisco-web start

Run the following command to start the job control daemon (port control, etc):

 DANCER_ENVDIR=~/environments ~/bin/netdisco-daemon start

You should (of course) avoid running this Netdisco daemon and the legacy
daemon at the same time.

=head1 Upgrading

Simply install this module again, then upgrade the database schema:

 ~/bin/localenv cpanm --quiet --notest App::Netdisco
 DANCER_ENVDIR=~/environments ~/bin/localenv netdisco-deploy

=head1 Tips and Tricks

=head2 Searching

The main black navigation bar has a search box which is smart enough to work
out what you're looking for in most cases. For example device names, node IP
or MAC addreses, VLAN numbers, and so on.

=head2 SQL and HTTP Trace

For SQL debugging try the following commands:

 DBIC_TRACE_PROFILE=console DBIC_TRACE=1 \
   DANCER_ENVDIR=~/environments ~/bin/localenv plackup ~/bin/netdisco-web-fg
  
 DBIC_TRACE_PROFILE=console DBIC_TRACE=1 \
   DANCER_ENVDIR=~/environments ~/bin/localenv netdisco-daemon-fg

=head2 Deployment

Other ways to run and host the web application can be found in the
L<Dancer::Deployment> page. See also the L<plackup> documentation.

=head2 User Rights

With the default configuration user authentication is disabled and the default
"guest" user has no special privilege. To grant port and device control rights
to this user, create a row in the C<users> table of the Netdisco database with
a username of C<guest> and the C<port_control> flag set to true:

 netdisco=> insert into users (username, port_control) values ('guest', true);

=head2 Database API

Bundled with this distribution is a L<DBIx::Class> layer for the Netdisco
database. This abstracts away all the SQL into an elegant, re-usable OO
interface. See the L<App::Netdisco::Developing> documentation for further
information.

=head2 Plugins

App::Netdisco includes a Plugin subsystem for building the web user interface.
Items in the navigation bar and the tabs on pages are loaded as Plugins, and
you have control over their appearance and ordering. See
L<App::Netdisco::Web::Plugin> for further information.

=head2 Developing

Lots of information about the architecture of this application is contained
within the L<App::Netdisco::Developing> documentation.

=head1 Caveats

Some sections are not yet implemented, e.g. the I<Device Module> tab.

Some menu items on the main black navigation bar go nowhere.

None of the Reports yet exist (e.g. searching for wireless devices, or duplex
mismatches). These will be implemented as a plugin bundle.

The Wireless, IP Phone and NetBIOS Node properies are not yet shown.

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE
 
This software is copyright (c) 2012 by The Netdisco Developer Team.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
     * Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
     * Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
     * Neither the name of the Netdisco Project nor the
       names of its contributors may be used to endorse or promote products
       derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE NETDISCO DEVELOPER TEAM BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
