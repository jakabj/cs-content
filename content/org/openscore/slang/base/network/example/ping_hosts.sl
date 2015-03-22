# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License v2.0 which accompany this distribution.
#
# The Apache License is available at
# http://www.apache.org/licenses/LICENSE-2.0
#
####################################################
# This flow pings addressed from input list and send an email with results
#
# Inputs:
# - address: list of ip's to be checked
#
# For correct work of email part - system_property (mail.yaml) file should be filled and called as '--spf' input
#
# Results:
#  SUCCESS: addressee will get an email with result
#  FAILURE: addressee will get an email with exception of operation
#
####################################################
namespace: org.openscore.slang.base.network.example

imports:
  network: org.openscore.slang.base.network
  mail: org.openscore.slang.base.mail

flow:
  name: ping_hosts

  inputs:
    - ip_list
    - message_body: []
    - all_nodes_are_up: True

  workflow:
    - check_address:
        loop:
          for: address in ip_list
          do:
            network.ping:
              - address
        publish:
              - messagebody: "fromInputs['message_body'].append(message)"
              - all_nodes_are_up: "fromInputs['all_nodes_are_up'] and is_up"
        navigate:
          UP: mail_send
          DOWN: failure_mail_send
          FAILURE: failure_mail_send

    - mail_send:
        do:
          mail.send_mail:
            - hostname:
                system_property: org.openscore.slang.base.hostname
            - port:
                system_property: org.openscore.slang.base.port
            - from:
                system_property: org.openscore.slang.base.from
            - to:
                system_property: org.openscore.slang.base.to
            - subject: "'Ping Result'"
            - body: >
                  "Result: " + " ".join(message_body)
            - username:
                system_property: org.openscore.slang.base.username
            - password:
                system_property: org.openscore.slang.base.password

    - on_failure:
        - failure_mail_send:
            do:
              mail.send_mail:
                - hostname:
                    system_property: org.openscore.slang.base.hostname
                - port:
                    system_property: org.openscore.slang.base.port
                - from:
                    system_property: org.openscore.slang.base.from
                - to:
                    system_property: org.openscore.slang.base.to
                - subject: "'Ping Result'"
                - body: >
                      "Result: Failure to ping: " + "".join(message_body)
                - username:
                    system_property: org.openscore.slang.base.username
                - password:
                    system_property: org.openscore.slang.base.password