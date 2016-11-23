# Orc(hestrator)

This is a script to emulate some of pow's functionality on linux.

For it all to work, it requires:

1. A functional nginx installation
2. A functional dnsmasq installation
3. An app that runs on unicorns
4. Some familiarity with the command line

## Installation

1. Check out orc into `~/.orc`.

    ~~~ sh
    $ git clone https://github.com/anoldguy/orc.git ~/.orc
    ~~~

2. Add `orc init` to your shell to enable shims and autocompletion.

    ~~~ sh
    $ echo 'eval "$(~/.orc/bin/orc init -)"' >> ~/.bash_profile
    ~~~

    _Use `~/.bashrc` on Ubuntu, or `~/.zshrc` for Zsh._

3. Restart your shell so that PATH changes take effect. (Opening a new
   terminal tab will usually do it.) Now check if orc was set up:

    ~~~ sh
    $ type orc
    #=> "orc is a aliased to _orc_wrapper"
    ~~~

## Adding apps to orc

All you really need to do is link your apps under ~/.apps, but if you'd
like a handy shortcut, we've got you covered:

~~~ sh
orc add /path/to/my-cool-app
~~~

Provided you have the nginx config and dnsmasq setup, you can now go to
http://my-cool-app.dev/ and see your app running!

## Removing apps from orc

~~~ sh
orc remove my-cool-app
~~~
This will remove the link to the app and orc cannot manage it anymore.

## Starting an app

~~~ sh
orc start my-cool-app
~~~
This will start your app!  For more details, look at `libexec/orc-start`.

## Stopping an app
~~~ sh
orc stop my-cool-app
~~~

Easy.  Or alternatively, if you need all apps stopped:
~~~ sh
orc stop all
~~~

## Restarting an app
~~~ sh
orc restart my-cool-app
~~~

It's not doing anything fancy, just a stop/restart. Maybe I'll switch that
up to a `kill -USR2` on the unicorn PID in the future.

## Help
Running `orc help` is your friend.

## Nginx and dnsmasq

To handle nginx and dns, we use docker!  [Go install it](https://www.docker.com/products/overview#/install_the_platform).  To get them setup and running, it's pretty easy:
~~~ sh
orc web start
~~~
This will create AND TRUST a local CA for local https development and start the
docker containers.

## Thanks
Many thanks to @noahhl, @sstephenson, @qrush for their excellent support
and encouragement!
