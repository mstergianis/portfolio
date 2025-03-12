---
date: '2025-03-10T20:52:35-04:00'
draft: true
title: 'vwp'
params:
    github: "https://github.com/mstergianis/vwp"
type: 'page'
<!-- showTableOfContents: true -->
---

The vaultwarden-password-syncer

## Premise

I run a home server for a variety of services. One of which is a Vaultwarden
instance. Naturally with a server that is running out of my house, and a
reluctance for spending cloud storage prices for my personal stuff, my backup
situation is not great. So in case my PostgreSQL instance gets corrupted in some
way, I want a local backup. I also want to be able to use my passwords locally,
without making round trips to the server constantly (a la the Bitwarden CLI).

I use [`pass`](https://www.passwordstore.org/) on my personal machine. So
downloading my passwords from Vaultwarden and storing them locally felt like a
natural fit.

## So what is it?

A Vaultwarden utility that downloads all of your passwords and stores them using
the unix password utility `pass`.

## How does it work

By storing your Vaultwarden credentials in a configuration file in your home
directory. `vwp` can hit your Vaultwarden server using its apis, download all of
your ciphers (passwords) and store them in pass.

{{< media/video src=/videos/VWPAnimation.webm type="video/webm" >}}
