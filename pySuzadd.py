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
# * mail can be sent at the end to inform that page has been
#   created/updated,
# * configuration file containing:
#   - wiki address, login and password of bot,
#   - categories by default
#
# exit codes
__FILE_ERROR = 2                    # file error

import mwclient, sys

site = mwclient.Site('wiki_address', force_login=False)
site.login('wiki_login', 'wiki_password')
page = site.Pages[sys.argv[2]]
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
sys.exit(0)
