#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""This program can be used to update facs urls on topoTEI.
"""
#    Copyright (C) University of Basel 2024  {{{1
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/> 1}}}
import csv
import json
import getopt
import os
import requests
import sys
import urllib.parse
import xml.dom.minidom as MD
from xml.etree import ElementTree
import lxml.etree as LET

DEBUG = False 



def insert_iiif_urls(idList: dict):
    r = requests.post("http://localhost:8080/exist/restxq/updateIIIF",
                  # use name "json"
                  data={'json': json.dumps(idList)})
    print(r.status_code)
    return r.status_code

def usage():
    """prints information on how to use the script
    """
    print(main.__doc__)

def main(argv):
    """This program can be used to update the facsimile/surface/graphic urls.

    updateFacs.py [OPTIONS] csvfile

        OPTIONS:
        -h|--help                   show help
    
        :return: exit code (int)
    """
    csv_file = ''
    try:
        opts, args = getopt.getopt(argv, "h", ["help"])
    except getopt.GetoptError:
        usage()
        return 2
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            return 0
    if len(args) < 1:
        usage()
        return 2
    csv_file = args[0]
    facs = []
    with open(csv_file, newline='') as csvfile:
        reader = csv.DictReader(csvfile)
        fieldnames = reader.fieldnames
        for row in reader:
            facs.append({ 'id': row[fieldnames[0]], 'iiif': row[fieldnames[1]]})
    exit_status = 0
    insert_iiif_urls(facs)
    return exit_status

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

#file = 'file.json'
#with open(file) as json_file:
#    jsonData = json.load(json_file)
#    r = requests.post("http://localhost:8080/exist/restxq/knora",
#                  # use name "json"
#                  data={'dsp-url': 'http://0.0.0.0:3333/','json': json.dumps(jsonData)})
#    print(r.status_code)
