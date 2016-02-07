# Known

A single site for the content you create

Known is a simple, social publishing platform for groups and individuals. Publish on your own site, share everywhere.

![logo](https://withknown.com/img/logo_beta.png)

# How to use this image

```bash
docker run --link some-mysql:mysql -d known
```

For testing purpose, you might want to be able to access the instance from the host without the container's IP, standard port mappings can be used:

```bash
docker run --link some-mysql:mysql -p 8080:80 -d known
```

Then, access it via `http://localhost:8080` or `http://host-ip:8080` in a browser.

For production, we recommend the use of TLS.

## Via docker-compose

You can use a setup that is used in production at [IndieHosters/known](https://github.com/indiehosters/known).

## Installation

Once started, you'll arrive at the configuration wizzard.
Follow the steps as indicated.

## Contribute

Pull requests are very welcome!

We'd love to hear your feedback and suggestions in the issue tracker: [github.com/idno/Known-docker/issues](https://github.com/idno/Known-docker/issues).
