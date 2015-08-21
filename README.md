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
    $ echo 'eval "$(orc init -)"' >> ~/.bash_profile
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

Well, it's not all rainbows and unicorns.

### Nginx
Here's an example config for a vanilla Ubuntu 14.04 nginx install:
```
server {
  listen 80;
  listen 127.0.0.1:80;
  server_name ~^(.*\.)?(.*)\.(dev|test);
  set $app_dir $2;
  root /home/<your username>/.apps/$app_dir/public;


  error_page 404 /404.html;
  error_page 502 503 504 /500.html;

  location / {
    try_files $uri/index.html $uri $uri.html @unicorn;
  }

  location @unicorn {
    default_type text/html;
    proxy_pass http://unix:/tmp/unicorn.$app_dir.sock;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Queue-Start "${msec}";
  }
}
```
### Dnsmasq

Here's a command that will add the correct dnsmasq command, again
on a vanilla Ubuntu 14.04 dnsmasq install:

```
sudo echo "address=/.dev/127.0.0.1" > /etc/dnsmasq.d/orc
```
To show these configs again:

~~~ sh
orc example
~~~

## Thanks
Many thanks to @noahhl, @sstephenson, @qrush for their excellent support
and encouragement!
