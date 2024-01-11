#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""This program can be used to exchange data between topoTEI and the dsp stack.
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
from dsp_tools.dsp_tools import xml_upload
import getpass
import getopt
import glob
import json
import keyring
import keyring.util.platform_ as keyring_platform
import os
import requests
import sys
import urllib.parse
import xml.dom.minidom as MD
from xml.etree import ElementTree
import lxml.etree as LET

DEBUG = False 

def get_credentials(server: str, email: str) -> dict:
    username = email.split('@')[0].replace('.','')
    try:
        credentials = keyring.get_credential(server, username)
        return {'username': credentials.username, 'password': credentials.password, 'email': email, 'server': server}
    except Exception:
        password = getpass.getpass()
        keyring.set_password(server, username, password)
        return {'username': username, 'password': password, 'email': email, 'server': server}

def create_facsimile_data(shortcode: str) -> ElementTree:
    url = 'http://localhost:8080/exist/restxq/facsimiles?shortcode=' + shortcode
    parser = LET.XMLParser(remove_blank_text=True)
    if DEBUG:
        url = url + '&debug=true'
        print(f'HTTP GET {url}')
    return LET.parse(url, parser)

def create_token(dsp_credentials: dict):
    authenticationData = {"identifier_type":"username","username": dsp_credentials["username"],"password": dsp_credentials["password"] }
    endpoint = dsp_credentials["server"] + '/v2/authentication'
    headers = {"Content-Type": "application/json"}
    r = requests.post(endpoint,
                  headers=headers,
                  # use name "json"
                  json=authenticationData)
    if r.status_code == 200:
        dsp_credentials["token"] = r.json()['token']
    else:
        raise Exception(r.status_code)

def _prepare_deletion(resource: dict, context: dict, dsp_credentials: dict) ->dict:
    print(context)
    headers = {"Content-Type": "application/json"}
    add_value_endpoint =  dsp_credentials["server"] + '/v2/values?token=' + dsp_credentials['token']
    update = { "@id": resource["@id"], "@type": resource["@type"], "nietzsche-dm:deleteMe": {
           "@type": "knora-api:IntValue",
            "knora-api:intValueAsInt": 666 
        }, "@context": context["@context"]}
    r = requests.post(add_value_endpoint,
            headers=headers,
            json=update)
    if r.status_code == 200:
        return r.json()['knora-api:valueCreationDate']

def erase_resource(resource: dict, context: dict, dsp_credentials: dict):
    erase_endpoint =  dsp_credentials["server"] + '/v2/resources/erase?token=' + dsp_credentials['token']
    headers = {"Content-Type": "application/json"}
    delete = { '@id': resource['@id'], '@type': resource['@type'], "knora-api:deleteComment": "None"}
    if "knora-api:lastModificationDate" in resource.keys():
        delete["knora-api:lastModificationDate"] = resource["knora-api:lastModificationDate"]
    else:
        delete["knora-api:lastModificationDate"] =  _prepare_deletion(resource, context, dsp_credentials)
    delete['@context'] = context['@context']
    d = requests.post(erase_endpoint,
            headers=headers,
            json=delete)
    if d.status_code != 200:
        print(d.status_code)
        print(d.json())

def erase_old_facsimiles(xml_tree: ElementTree, dsp_credentials: dict, namespaces: dict):
    count_endpoint = dsp_credentials["server"] + '/v2/searchbylabel/count/'
    graph_endpoint = dsp_credentials["server"] + '/v2/searchbylabel/'
    for label in xml_tree.getroot().xpath('//ns:resource/@label', namespaces=namespaces):
        searchterm = label.split(' ')[1] if len(label.split(' ')) > 1 else label
        r = requests.get(count_endpoint + searchterm + '?token=' + dsp_credentials['token'])
        if r.status_code == 200:
            if int(r.json()["schema:numberOfItems"]) > 0:
                print(f'Found {r.json()["schema:numberOfItems"]} old resource(s) with label {searchterm} ...')
                #print(graph_endpoint + searchterm + '?token=' + dsp_credentials['token'])
                results = requests.get(graph_endpoint + searchterm + '?token=' + dsp_credentials['token'])
                if results.status_code == 200:
                    context = { '@context': results.json()['@context'] }
                    if int(r.json()["schema:numberOfItems"]) > 1:
                        for result in results.json()['@graph']:
                            erase_resource(result, context, dsp_credentials)
                    else:
                        erase_resource(results.json(), results.json(), dsp_credentials)
        else:
            raise Exception(r.status_code)

def upload_faksimile(xml_file: str, dsp_credentials: dict, debug: bool) -> str:
    sipi = dsp_credentials["server"].replace('api','iiif').replace('3333','1024')
    fileprefix = xml_file.removesuffix('.xml') + '_id2iri_mapping_'
    if debug:
        list_of_files = [ file for file in glob.glob('*.json') if file.startswith(fileprefix) ]
        return max(list_of_files, key=os.path.getctime)
    if xml_upload(xml_file, dsp_credentials["server"], dsp_credentials["email"], dsp_credentials["password"], './', sipi, True, False, False, False):
        list_of_files = [ file for file in glob.glob('*.json') if file.startswith(fileprefix) ]
        return max(list_of_files, key=os.path.getctime)
    else:
        return ''

def upload_faksimile_tree(xml_tree: ElementTree, dsp_credentials: dict, debug: bool, image_dir: str) -> str:
    sipi = dsp_credentials["server"].replace('api','iiif').replace('3333','1024')
    endswith =  '_id2iri_mapping.json'
    if debug:
        list_of_files = [ file for file in glob.glob('*.json') if file.startswith(fileprefix) ]
        return max(list_of_files, key=os.path.getctime)
    if xml_upload(xml_tree, dsp_credentials["server"], dsp_credentials["email"], dsp_credentials["password"], image_dir, sipi, True, False, False, False):
        list_of_files = [ file for file in glob.glob('*.json') if file.endswith(endswith) ]
        return max(list_of_files, key=os.path.getctime)
    else:
        return ''

def get_iiif_urls(id2iri_file: str, dsp_credentials) -> dict:
    endpoint = dsp_credentials["server"] + '/v2/resources/'
    token = '?token=' + dsp_credentials["token"]
    with open(id2iri_file) as json_file:
        jsonData = json.load(json_file)
        idList = []
        for key in jsonData.keys():
            url = urllib.parse.quote(jsonData[key], safe="")
            r = requests.get(endpoint + url + token)
            if r.status_code == 200:
                idList.append({ 'id': key, 'iri': jsonData[key], 'iiif': r.json()["knora-api:hasStillImageFileValue"][ "knora-api:fileValueAsUrl"]["@value"]})
        return idList

def insert_iiif_urls(idList: dict):
    r = requests.post("http://localhost:8080/exist/restxq/updateIIIF",
                  # use name "json"
                  data={'json': json.dumps(idList)})
    print(r.status_code)

def usage():
    """prints information on how to use the script
    """
    print(main.__doc__)

def main(argv):
    """This program can be used to exchange data between topoTEI and the dsp stack.

    topoTEI2dasch.py [OPTIONS] 

        OPTIONS:
        -h|--help                   show help
        -c|--clear                  delete all facsimiles from dsp stack.
        -m|--mapping + id2iri.json: use an id2iri.json file instead of uploading data to dsp stack
        -s|--server + dsp_server:   provide dsp_server address
        -u|--user + email:          provide username as email address
    
        :return: exit code (int)
    """
    username = 'root@example.com'
    dsp_server = 'http://0.0.0.0:3333/'
    project = '0837'
    id2iri_mapping = ''
    xml_file = ''
    deleteAll = False
    image_dir = './'
    try:
        opts, args = getopt.getopt(argv, "ci:hm:p:s:u:x:", ["clear","images=","help", "mapping=","project=", "server=", "user=", "xml="])
    except getopt.GetoptError:
        usage()
        return 2
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            return 0
        elif opt in ('-c', '--clear'):
            deleteAll = True
        elif opt in ('-c', '--clear'):
            image_dir = arg 
        elif opt in ('-m', '--mapping'):
            id2iri_mapping = arg
        elif opt in ('-p', '--project'):
            project = arg
        elif opt in ('-s', '--server'):
            dsp_server = arg
        elif opt in ('-u', '--user'):
            username = arg
        elif opt in ('-x', '--xml'):
            xml_file = arg
    exit_status = 0
    dsp_credentials = get_credentials(dsp_server.removesuffix('/'), username)
    create_token(dsp_credentials)
#    if DEBUG:
#        xml_tree = LET.parse('debug.xml')
#        erase_old_facsimiles(xml_tree, dsp_credentials)
#        return exit_status
#    elif xml_file == '' and id2iri_mapping == '':
    if xml_file == '' and id2iri_mapping == '':
        xml_tree = create_facsimile_data(project)
        namespaces = { k if k is not None else 'ns': v for k, v in xml_tree.getroot().nsmap.items() }
        resources = xml_tree.getroot().xpath('//ns:resource',namespaces=namespaces)
        print(f'Facsimile data created with {len(resources)} resources ...')
        erase_old_facsimiles(xml_tree, dsp_credentials, namespaces)
        print(f'Uploading faksimile tree ...')
        id2iri_file = upload_faksimile_tree(xml_tree, dsp_credentials, False, image_dir)
    elif id2iri_mapping == '':
        xml_tree = LET.parse(xml_tree)
        erase_old_facsimiles(xml_tree, dsp_credentials)
        id2iri_file = upload_faksimile_tree(xml_tree, dsp_credentials, False, image_dir)
    else:
        id2iri_file = id2iri_mapping
    if id2iri_file != '':
        print(f'Getting iiif urls for iri ...')
        idList = get_iiif_urls(id2iri_file, dsp_credentials)
        print(idList)
        insert_iiif_urls(idList)
        return exit_status
    else:
        return 2

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

#file = 'file.json'
#with open(file) as json_file:
#    jsonData = json.load(json_file)
#    r = requests.post("http://localhost:8080/exist/restxq/knora",
#                  # use name "json"
#                  data={'dsp-url': 'http://0.0.0.0:3333/','json': json.dumps(jsonData)})
#    print(r.status_code)
