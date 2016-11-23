# The Setup for nginx

## The Goal

We want `nginx` to bind to our loopback interface and handle both HTTP and HTTPS
requests, without triggering the "make this seem really scary" feature of our
browsers designed to protect users from shady SSL certificates like ours. We
also want it to cleanly support these features for both `.devel` and `.staging`
TLDs for any number of apps, without requiring us to jump through unnecessary
hoops to get them going.

We are OK with having our various projects live in some kind of sensible
directory hierarchy, and not scattered all over our filesystem.

## The Install

Nothing here, because we'll use a docker image that we'll configure in a moment.

## The Configuration

We're going to use docker to run this. The gist is, replace the stock
`nginx.conf` with one of our own, and place the SSL configuration in place.

Feel free to [read the comments](nginx.conf) in the configuration file and the
[Dockerfile](Dockerfile) for an explanation of what we're up to.  Don't worry,
we'll build the container after we've generated our SSL config.

Our general request path will look like this:
![Docker Dev Request Flow](https://cdn.rawgit.com/anoldguy/orc/master/share/orc/nginx/images/local-docker-dev-request-flow.svg)

## The SSL

When we run our apps in dev mode, it's common to disable things like forced SSL
redirection. This allows easy testing in development but also means one more
thing that differs between development and production. We're going to set up
nginx to handle SSL for us so that we don't have to disable features in dev
mode.

First, we'll set ourselves up as a CA:

    cd CA
    openssl req -new -x509 -extensions v3_ca -keyout private/cakey.pem \
      -out cacert.pem -days 3650 -config ./openssl.cnf
    Generating a 2048 bit RSA private key
    ..........................+++
    ..............................+++
    writing new private key to 'private/cakey.pem'
    Enter PEM pass phrase:<something secure>
    Verifying - Enter PEM pass phrase:<something secure>
    -----
    You are about to be asked to enter information that will be incorporated
    into your certificate request.
    What you are about to enter is what is called a Distinguished Name or a DN.
    There are quite a few fields but you can leave some blank
    For some fields there will be a default value,
    If you enter '.', the field will be left blank.
    -----
    Organization Name (company) []:MyCompany, Inc.
    Organizational Unit Name (department, division) []:
    Email Address []:email@example.com
    Locality Name (city, district) []:Servers
    State or Province Name (full name) []:Internet
    Country Name (2 letter code) []:US
    Common Name (hostname, IP, or your name) []:Local Development CA

Feel free to substitute your own answers for the above. Especially the
passphrase. :)

If all goes well, you'll have a cacert.pem file in the current directory, and a
cakey.pem file in the `private/` subdirectory. Set permissions as restrictively
as possible on the contents of the `private/` subdirectory.

**This CA directory is now a completely self-contained environment set up to
sign any certs for you or your team members. Be sure to keep it in a safe
place. If that safe place is a version control system, be sure to ignore or
encrypt the `private/` directory!**

Next, we need to tell our machine to consider this new root certificate as
trusted:

    sudo security add-trusted-cert -d -r trustRoot \
      -k /Library/Keychains/System.keychain cacert.pem

This adds the certificate as a trusted root certificate in the System keychain.
That should be sufficient for Chrome and Safari browsers, as well as `curl` and
other command line apps. For whatever reason, Firefox decided it would rather
handle this task itself, so if you want it to consider your new CA as valid,
you'll need to import `cacert.pem` from "Advanced Preferences", here:

![Firefox being Firefox](images/firefox-cacert-import.png)

With that out of the way, open
`/usr/local/etc/nginx/ssl/local.devel.openssl.cnf` in your text editor of
choice:

    mvim /usr/local/etc/nginx/ssl/local.devel.openssl.cnf

You'll notice that we have a "common name" set up as `*.local.devel`. We want to
create an SSL certificate that supports more than one hostname. In fact, if you
were wondering up to this point what exactly was up with `local.devel`, and why
we don't use just `devel`, it's because of SSL. Browsers don't generally allow
a wildcard component with just a TLD. They need a domain name, which is why
we need to use `*.local.devel`.

Because we're enabling v3 extensions (via `req_extensions = v3_req` in this
file), we can also set up "subject alternative names", which is just a fancy
way of saying "this certificate should support multiple domain names".

That being said, you'll want to customize the [alt_names] section to your taste.
At a minimum, we want to have `*.local.devel`, `local.devel`, `*.local.staging`,
and `local.staging` entries, to follow along with this guide. If you have some
SOA-style apps, or subdirectories in your project root, you'll want to configure
those here using numbered DNS entries. For example, the file included in this
repository has the following...

    DNS.5 = *.soa-app.devel
    DNS.6 = soa-app.devel
    DNS.7 = *.soa-app.staging
    DNS.8 = soa-app.staging

...which would work for apps in a `<my_project_root>/soa-app` subdirectory.

As of this writing, most of the browsers you probably care about don't support
multiple wildcard sections (such as `*.*.local.devel`), so if you have any apps
for which you need to support subdomains via SSL, you'll want to include them
here, as well. Putting it all together: if you have an app called "nifty-app" in
a subdirectory called "my-soa-app" and you needed to support subdomains, you'd
want to add:

    DNS.9 = *.nifty-app.my-soa-app.devel
    DNS.10 = *.nifty-app.my-soa-app.staging

This would allow the certificate to support those domain names without issue.

With our changes made, let's change into the nginx SSL directory and generate
a certificate signing request:

    cd /usr/local/etc/nginx/ssl
    openssl req -new -nodes -out local.devel.csr -keyout local.devel.key \
      -config ./local.devel.openssl.cnf

Next, go back to your "CA-in-a-box" directory. If you didn't move it anywhere,
that'll be in the `01_nginx/CA` directory of this repo:

    cd <your CA directory>
    openssl ca -out /usr/local/etc/nginx/ssl/local.devel.pem \
      -config ./openssl.cnf -infiles /usr/local/etc/nginx/ssl/local.devel.csr
    Using configuration from ./openssl.cnf
    Enter pass phrase for ./private/cakey.pem:<something secure from earlier>
    Check that the request matches the signature
    Signature ok
    The Subject's Distinguished Name is as follows
    commonName            :ASN.1 12:'*.local.devel'
    Certificate is to be certified until Jun 28 19:45:37 2025 GMT (3650 days)
    Sign the certificate? [y/n]:y


    1 out of 1 certificate requests certified, commit? [y/n]y
    Write out database with 1 new entries
    Data Base Updated

If you'd like to take a look at the newly-signed certificate, you can run:

    openssl x509 -in /usr/local/etc/nginx/ssl/local.devel.pem -noout -text

If all went well, you should see your list of names in the output's
"X509v3 Subject Alternative Name" section.

## Build the Nginx Container

Make sure you're in the 01_nginx directory, and run:

    docker build -t local-dev-nginx .
    Sending build context to Docker daemon 180.7 kB
    Step 1 : FROM nginx:alpine
     ---> 2f3c6710d8f2
    Step 2 : COPY nginx.conf /etc/nginx/nginx.conf
     ---> 3f9029319963
    Removing intermediate container 03508bf7658a
    Step 3 : COPY ssl /etc/nginx/ssl
     ---> 0fc22e7f2fda
    Removing intermediate container 15f927ed6584
    Successfully built 0fc22e7f2fda

A `docker images` should show a newly created image:

    REPOSITORY                      TAG                 IMAGE ID            CREATED             SIZE
    local-dev-nginx                 latest              0fc22e7f2fda        41 seconds ago      54.24 MB

Let's fire it up!

    docker run -d -v ~/path/to/apps:/apps -p "80:80" -p "443:443" local-dev-nginx

Now we're ready to move on to [configuring dnsmasq](../02_dnsmasq/)!
