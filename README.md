# Known: social publishing for groups and individuals

![Known - A social publishing platform for groups and individuals](https://withknown.com/img/home/screens.png)

# How to use this image

```bash
docker run --link some-mysql:mysql -d known
```

Now you can get access to fpm running on port 9000 inside the container. If you want to access it from the Internets, we recommend using a reverse proxy in front. You can find more information on that on the [docker-compose](#docker-compose) section.

## Via docker-compose

You can use a setup that is used in production at [IndieHosters/known](https://github.com/indiehosters/known).

## Installation

Once started, you'll arrive at the configuration wizard.
Follow the steps as indicated.

## Contribute

Pull requests are very welcome!

We'd love to hear your feedback and suggestions in the issue tracker: [github.com/idno/Known-docker/issues](https://github.com/idno/Known-docker/issues).
