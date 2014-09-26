#!/usr/bin/env python
# -*- coding: utf-8 -*-

# usage
#      pySuzadd.py [file] [page name]
#
# Creates a page [page name] in Wiki from the file [file]
# By default it connects the page with categories: foo and bar
# psz, april 2014
#
#
# TODO
# * configuration file containing:
#   - wiki address, login and password of bot,
#   - categories by default
#

# exit codes
__FILE_ERROR = 2                    # file error

import mwclient, smtplib, sys

art_name = sys.argv[2]
site = mwclient.Site('wiki_address', force_login=False)

# for Wiki available on https://wiki_address/wiki, please use
# 
# wiki_addrs = ('https','wiki_address')
# wiki_path = '/wiki/'
#
# site = mwclient.Site(wiki_addrs, wiki_path, force_login=False)

site.login('wiki_login', 'wiki_password')
page = site.Pages[art_name]
page.edit()

categories='[[Category:Foo]][[Category:Bar]]'
text = ''

try:
    f = open (sys.argv[1], 'r')
except IOError as e:
    print str(e)
    exit(__FILE_ERROR)
for line in f:
    text += line
# categories
text += categories

f.close()
page.save(text, None)

# email
from_addr = "foo"
to_addrs = ["foo@bar.com", "foo@bar2.com"]
username = "email_username"
password = "email_password"
server = smtplib.SMTP('stmp_server')
email_text = "Subject: [{0}] {1}\n".format("WIKI", art_name) + "Hello\nArticle: " + art_name + " has been created/updated"
server.starttls()
server.login (username, password)
server.sendmail (from_addr, to_addrs, email_text)
server.quit()
sys.exit(0)
