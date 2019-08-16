# SmashingSprintBoardStatus
Smashing widget to view the current status of a whole sprint

## Preview

![board](https://user-images.githubusercontent.com/19978733/33788490-e508c7e4-dc72-11e7-8634-7f63f710aac3.png)

## Usage

To use the widget place the files in your smashing project accordingly to the repository folders structure.

To include the widget in a dashboard, add the following snippet to the dashboard layout file:

```
<li data-row="1" data-col="1" data-sizex="3" data-sizey="1">
  <div data-id="boardStatus" data-view="JiraSprintBoardStatus"></div>
</li>
```

## Settings

You should set up the following parameters inside the job file (jira_sprint_issue_status.rb):
* JIRA_URI: Jira Url
* STORY_POINTS_CUSTOMFIELD_CODE: The code of the customfield for the story points of the issue
* view_mapping: Sets all the views to track in the widget
* JIRA_AUTH: Credentials for using Jira
