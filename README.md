### Wallboard ###

This is a fairly simple wallboard with the following features:

1) JIRA Sprint Board with swimlanes for each participant in the sprint, and columns for popular statuses.    

2) Zabbix problem display, shows current problems from a given Zabbix server.

3) A clock

4) A graphic summary of JIRA Sprint progress 


It is meant to be run from a Rasberry Pi however can also run from any platform that supports Ruby.

The specific version of the Rasbery Pi that was used during development is the 3B+.

This project was based on Smashing, see
http://smashing.github.io/smashing for more information.

Usage
-----

Set the following environment variables prior to running the wallboard 

| Field | Description |
| ----- | ----------- |
|JIRA_USERNAME | Username that will be used to sign on to JIRA |
| JIRA_PASSWORD | Jira password |
| JIRA_URL | JIRA URL |
| JIRA_CUSTOMFIELD_STORYPOINTS | field that will be used for story points |
| JIRA_VIEW | ID of the saved view to use for the sprint board |
| ZABBIX_SERVER | Base URL of the zabbix server |
| ZABBIX_USERNAME | Zabbix username |
| ZABBIX_PASSWORD | Zabbix password |


You may run the wallboard on a properly equipped environment by executing `smashing start` in the directory containing the files.

License
-------

    Copyright 2019 George Walker

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at 

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
