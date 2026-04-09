# docker-wait-for-port
A handy script to use in *arr containers to wait for their DBs on a host reboot

Starting your *arr stack with `docker compose` works well; `depends_on` is reliable.
...until you reboot the host and docker starts all containers in parallel, and the `depends_on` is not respected.

In the case of radarr, sonarr, prowlarr etc, they will attempt to connect to the DB on startup, but after 3 retries if it didn't work, they're hung... and they wait for human interaction.

This was really frustrating me during a period when I was frequently rebooting my box. I'd have to fix the *arr containers EVERY. SINGLE. TIME. Ugh!

This script aims to solve that problem by adding a 'wait until the port is responsive` check.

It works specifically with the framework that the `linuxserver.io` images provide, and it's working for me. So I figured I'd share it.

### How to use it

Put [the script](./10-wait-for-port.sh) somewhere meaningful and make it executable by the container user you normally specify for those containers that need to use it. 
(I put it in `/volume1/docker/arr_init_scripts`)

Add the following to your `linuxserver.io`-based containers (Sonarr used in my example)

```yml
  sonarr:
    ...
    ...
    environment:
      ...
      ...
      - WAIT_FOR_HOST=sonarr-db
      - WAIT_FOR_PORT=5432
    volumes:
      ...
      - /volume1/docker/arr_init_scripts:/custom-cont-init.d:ro
```

You can also add env variables `WAIT_FOR_TIMEOUT` and `WAIT_FOR_INTERVAL` if you want. They default to 120s and 5s respectively.

Now on startup of the container, you'll see the following:

```
[custom-init] Waiting for sonarr-db:5432 for up to 120s...
[custom-init] sonarr-db:5432 not yet reachable...
[custom-init] sonarr-db:5432 not yet reachable...
[custom-init] sonarr-db:5432 not yet reachable...
[custom-init] sonarr-db:5432 not yet reachable...
[custom-init] sonarr-db:5432 is reachable
[custom-init] 10-wait-for-port.sh: exited 0
[Info] Bootstrap: Starting Sonarr - /app/sonarr/bin/Sonarr - Version 4.0.17.2952 
```

Once the host and port are responsive, the container startup will continue.

Hope it helps you!

### What happens if the port never comes available?

After the timeout value, the script will exit, but the container start will continue as it would've before... so it doesn't do anything "different" from that perspective... just gives you a bit of a better chance that you can delay the start long enough to have the DB be available when the container starts. You can configure the timeout, the interval etc.. but ultimately this will just 'increase your odds'

```
[custom-init] 10-wait-for-port.sh: executing...
sonarr  | [custom-init] Waiting for sonarr-db:5432 for up to 20s...
sonarr  | [custom-init] sonarr-db:5432 not yet reachable...
sonarr  | [custom-init] sonarr-db:5432 not yet reachable...
sonarr  | [custom-init] sonarr-db:5432 not yet reachable...
sonarr  | [custom-init] sonarr-db:5432 not yet reachable...
sonarr  | [custom-init] Timed out after 20s waiting for sonarr-db:5432
sonarr  | [custom-init] 10-wait-for-port.sh: exited 1
sonarr  | [Info] Bootstrap: Starting Sonarr - /app/sonarr/bin/Sonarr - Version 4.0.17.2952
```
