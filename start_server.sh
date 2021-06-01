#!/bin/bash

chmod 0755 /home/pwn/vuln
/ynetd-0.1.2/ynetd -p 1337 -u pwn -d /home/pwn ./vuln
