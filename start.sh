#!/bin/bash

# Iniciar el servicio SSH
/usr/sbin/sshd

# Iniciar Apache en segundo plano
apache2-foreground