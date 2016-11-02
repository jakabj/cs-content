#   (c) Copyright 2016 Hewlett-Packard Enterprise Development Company, L.P.
#   All rights reserved. This program and the accompanying materials
#   are made available under the terms of the Apache License v2.0 which accompany this distribution.
#
#   The Apache License is available at
#   http://www.apache.org/licenses/LICENSE-2.0
#
########################################################################################################################
#!!
#! @description: Performs an HTTP request to create or update a virtual machine extension
#!
#! @input subscription_id: Azure subscription ID
#! @input resource_group_name: resource group name
#! @input auth_token: Azure authorization Bearer token
#! @input api_version: The API version used to create calls to Azure
#!                     Default: '2015-06-15'
#! @input location: Specifies the supported Azure location where the extension will be added to the virtual machine
#!                  This can be different from the location of the resource group.
#! @input vm_name: Virtual machine name
#! @input publisher: Specifies name of the extension’s publisher
#! @input file_url: Specifies the script file path
#!                  Example: 'https://raw.githubusercontent.com/Something/do_something.sh'
#! @input extension_name: Name of the extension to be added to the virtual machine
#! @input extension_type: Specifies type of extension
#! @input extension_version: Specifies version of the extension
#! @input command_to_execute: Specifies command used to execute the script
#!                            Example: 'sh do_something.sh 0.5.8'
#! @input proxy_host: optional - proxy server used to access the web site
#! @input proxy_port: optional - proxy server port - Default: '8080'
#! @input proxy_username: optional - username used when connecting to the proxy
#! @input proxy_password: optional - proxy server password associated with the <proxy_username> input value
#! @input trust_keystore: optional - the pathname of the Java TrustStore file. This contains certificates from
#!                        other parties that you expect to communicate with, or from Certificate Authorities that
#!                        you trust to identify other parties.  If the protocol (specified by the 'url') is not
#!                       'https' or if trust_all_roots is 'true' this input is ignored.
#!                        Default value: ..JAVA_HOME/java/lib/security/cacerts
#!                        Format: Java KeyStore (JKS)
#! @input trust_password: optional - the password associated with the Trusttore file. If trust_all_roots is false
#!                        and trust_keystore is empty, trust_password default will be supplied.
#!                        Default: ''
#! @input trust_all_roots: optional - specifies whether to enable weak security over SSL - Default: false
#! @input x_509_hostname_verifier: optional - specifies the way the server hostname must match a domain name in
#!                                 the subject's Common Name (CN) or subjectAltName field of the X.509 certificate
#!                                 Valid: 'strict', 'browser_compatible', 'allow_all' - Default: 'allow_all'
#!                                 Default: 'strict'
#!
#! @output output: json response with information about the created added or updated extension
#! @output status_code: 200 if request completed successfully, others in case something went wrong
#! @output error_message: If the extension could not be created the error message will be populated with a response,
#!                        empty otherwise
#!
#! @result SUCCESS: Virtual machine extension added or updated successfully.
#! @result FAILURE: There was an error while trying to added or update the virtual machine extension.
#!!#
########################################################################################################################

namespace: io.cloudslang.microsoft.azure.compute.virtual_machines.extensions

imports:
  http: io.cloudslang.base.http
  json: io.cloudslang.base.json
  strings: io.cloudslang.base.strings

flow:
  name: add_or_update_extension

  inputs:
    - subscription_id
    - resource_group_name
    - auth_token
    - api_version:
        required: false
        default: '2015-06-15'
    - location
    - vm_name
    - publisher
    - file_url
    - extension_name
    - extension_version
    - command_to_execute
    - proxy_username:
        required: false
    - proxy_password:
        required: false
        sensitive: true
    - proxy_port:
        default: "8080"
        required: false
    - proxy_host:
        required: false
    - trust_all_roots:
        default: "false"
        required: false
    - x_509_hostname_verifier:
        default: "strict"
        required: false
    - trust_keystore:
        required: false
    - trust_password:
        default: ''
        required: false
        sensitive: true

  workflow:
    - add_or_update_extension:
        do:
          http.http_client_put:
            - url: >
                ${'https://management.azure.com/subscriptions/' + subscription_id + '/resourceGroups/' +
                resource_group_name + '/providers/Microsoft.Compute/virtualMachines/' + vm_name +
                '/extensions/' + extension_name + '?api-version=' + api_version}
            - body: >
                ${'{"location":"' + location + '","properties":{"publisher":"' + publisher + '","type":"' +
                extension_type + '","typeHandlerVersion":"' + extension_version +
                '","autoUpgradeMinorVersion":true,"settings":{"fileUris":["' + file_url + '"],"commandToExecute":"' +
                command_to_execute + '"}}}'}
            - headers: "${'Authorization: ' + auth_token}"
            - auth_type: 'anonymous'
            - preemptive_auth: 'true'
            - content_type: 'application/json'
            - request_character_set: 'UTF-8'
            - proxy_host
            - proxy_port
            - proxy_username
            - proxy_password
            - trust_all_roots
            - x_509_hostname_verifier
            - trust_keystore
            - trust_password
        publish:
          - output: ${return_result}
          - status_code
        navigate:
          - SUCCESS: check_error_status
          - FAILURE: check_error_status

    - check_error_status:
        do:
          strings.string_occurrence_counter:
            - string_in_which_to_search: '400,401,404,409'
            - string_to_find: ${status_code}
        navigate:
          - SUCCESS: retrieve_error
          - FAILURE: retrieve_success

    - retrieve_error:
        do:
          json.get_value:
            - json_input: ${output}
            - json_path: 'error,message'
        publish:
          - error_message: ${return_result}
        navigate:
          - SUCCESS: FAILURE
          - FAILURE: retrieve_success

    - retrieve_success:
        do:
          strings.string_occurrence_counter:
            - string_in_which_to_search: '200,202'
            - string_to_find: ${status_code}
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: FAILURE

  outputs:
    - output
    - status_code
    - error_message

  results:
    - SUCCESS
    - FAILURE
