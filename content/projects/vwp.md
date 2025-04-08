---
date: '2025-03-10T20:52:35-04:00'
title: 'vwp'
description: "backing up [Vaultwarden](https://www.vaultwarden.ca/) into [pass](https://www.passwordstore.org/)"
params:
    github: "https://github.com/mstergianis/vwp"
    thumbnail: "/images/vwp.png"
type: "project"
# showTableOfContents: true
---

## Premise

I run a home server for a variety of services: home media, automation, this
website you're reading. One of those services is a
[Vaultwarden](https://www.vaultwarden.ca/) instance. I'm generally pretty
reluctant to use cloud storage/compute offerings. Not only because they cost a
lot of money, but also because I like to own my data and services when possible.
So my backup situation is not great. In case my PostgreSQL instance gets
corrupted in some way, I want a local backup. I also want to be able to use my
passwords locally, without making round trips to the server constantly (a la the
Bitwarden CLI).

> A side note about the Bitwarden CLI. I don't know if its because I was
> spelunking in the code and running from a hot-reloading development env, but not
> caching my password for even a few minutes is pretty bad ergonomics. I have a
> keyring running that you could cache in. It's also kinda slow :slightly_frowning_face:. Anyways...

I use [pass](https://www.passwordstore.org/) on my personal machine. So
downloading my passwords from Vaultwarden and storing them locally felt like a
natural fit.

## So what is it?

A Vaultwarden utility that downloads all of your passwords and stores them using
the unix password utility pass.

## How does it work

By storing your Vaultwarden credentials in a configuration file in your home
directory. `vwp` can hit your Vaultwarden server using its apis, download all of
your ciphers (passwords) and store them in pass.

{{< media/video src=/videos/VWPAnimation.webm type="video/webm" >}}
