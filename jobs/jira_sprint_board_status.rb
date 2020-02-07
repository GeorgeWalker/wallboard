# Displays the status of the current open sprint

require 'net/http'
require 'json'
require 'time'
require 'uri'

# Loads configuration file

USERNAME = ENV["JIRA_USERNAME"]
PASSWORD = ENV["JIRA_PASSWORD"]
JIRA_URI = URI(ENV["JIRA_URL"])
STORY_POINTS_CUSTOMFIELD_CODE = ENV["JIRA_CUSTOMFIELD_STORYPOINTS"]
VIEW_ID = Integer(ENV["JIRA_VIEW"])

puts "JIRA Username is " + USERNAME
puts "JIRA URI is " + ENV["JIRA_URL"]

# gets the view for a given view id
def get_view_for_viewid(view_id)
  http = create_http
  request = create_request("/rest/greenhopper/1.0/rapidviews/list")
  response = http.request(request)
  views = JSON.parse(response.body)["views"]
  views.each do |view|
    if view['id'] == view_id
      puts "FOUND VIEW"
      return view
    end
  end
end

# gets the active sprint for the view
def get_active_sprint_for_view(view_id)
  puts "Getting active sprint for view."
  http = create_http
  request = create_request("/rest/greenhopper/1.0/sprintquery/" + view_id.to_s)
  response = http.request(request)
  result = nil
  sprints = JSON.parse(response.body)["sprints"]
  sprints.each do |sprint|
    if sprint["state"] == "ACTIVE"      
      result = sprint
      break result
    end
  end
  puts "Result is"
  puts result
  return result
end

def get_sprint_details(sprint_id)
  http = create_http
  request = create_request("/rest/agile/1.0/sprint/" + sprint_id.to_s)
  response = http.request(request)
  
  sprint = JSON.parse(response.body)
  return sprint
end

# gets issues in each status
def get_issues_per_status(view_id, sprint_id, issue_count_array, issue_sp_count_array, issueHash)
  current_start_at = 0

  begin
    response = get_response("/rest/agile/1.0/board/#{view_id}/sprint/#{sprint_id}/issue?startAt=#{current_start_at}")
        
    
    page_result = JSON.parse(response.body)
    issue_array = page_result['issues']
    
    issue_array.each do |issue|
      accumulate_issue_information(issue, issue_count_array, issue_sp_count_array, issueHash)
    end

    current_start_at = current_start_at + page_result['maxResults']
  end while current_start_at < page_result['total']
end

# accumulate issue information
def accumulate_issue_information(issue, issue_count_array, issue_sp_count_array, issueHash)

  assignee = issue['fields']['assignee']['displayName']

  if (! issueHash.has_key?(assignee))
    issueHash[assignee] = Array.new(5)
    for i in 0..4
      issueHash[assignee][i] = Array.new()
    end
  end

  issueTypeIndex = 0

  case issue['fields']['status']['name']
    when "Open"
      issueTypeIndex = 0
    when "Ready"
      issueTypeIndex = 1
    when "In Progress"
      issueTypeIndex = 2
    when "Test"
      issueTypeIndex = 3
    when "In Review"
      issueTypeIndex = 3
    when "Done"
      issueTypeIndex = 4
    else
    puts "ERROR: wrong issue status" + issue['fields']['status']['name'] 
  end

  issueSummary = Hash.new()
  
  if !issue["fields"]["issuetype"]["subtask"]
    issue_count_array[issueTypeIndex] = issue_count_array[issueTypeIndex] + 1
  end
  if !issue["fields"][STORY_POINTS_CUSTOMFIELD_CODE].nil?
    issue_sp_count_array[issueTypeIndex] = issue_sp_count_array[issueTypeIndex] + issue["fields"][STORY_POINTS_CUSTOMFIELD_CODE]
    issueSummary["points"] = issue["fields"][STORY_POINTS_CUSTOMFIELD_CODE]
  else
    issueSummary["points"] = 0
  end

  issueSummary["key"] = issue["key"]
  issueSummary["summary"] = issue["fields"]["summary"]
  issueSummary["flagged"] = issue["fields"]["flagged"]

  if issueHash[assignee][issueTypeIndex].length < 10
    issueHash[assignee][issueTypeIndex].push(issueSummary) 
  end
  # totals
  issue_count_array[5] = issue_count_array[5] + 1
  if !issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE].nil?
    issue_sp_count_array[5] = issue_sp_count_array[5] + issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE]
  end
end

# create HTTP
def create_http
  http = Net::HTTP.new(JIRA_URI.host, JIRA_URI.port)
  if ('https' == JIRA_URI.scheme)
    http.use_ssl     = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
  return http
end

# create HTTP request for given path
def create_request(path)
  request = Net::HTTP::Get.new(JIRA_URI.path + path)
  if USERNAME
    request.basic_auth(USERNAME, PASSWORD)
  end
  return request
end

# gets the response after a request
def get_response(path)
  http = create_http
  request = create_request(path)
  response = http.request(request)

  return response
end

SCHEDULER.every '15m', :first_in => 0 do
  # skip if not during regular hours.
  currentTime = Time.now  
  if (currentTime.hour < 8 || # 8:00 AM
      currentTime.hour > 19 || # 6:00 PM 
      currentTime.wday < 1 || # Sunday
      currentTime.wday > 5 )  # Saturday      
      return
  end
  issue_count_array = Array.new(6, 0)
  issue_sp_count_array = Array.new(6, 0)

  issueHash = Hash.new()
	
  view_json = get_view_for_viewid(VIEW_ID)
  
  if (! view_json.nil? )  
    sprint_json = get_active_sprint_for_view(VIEW_ID)
    if (sprint_json)
      get_issues_per_status(VIEW_ID, sprint_json["id"], issue_count_array, issue_sp_count_array, issueHash)
    else
      puts "SPRINT IS EMPTY"
    end
  else
    puts "VIEW IS EMPTY."
  end

  # convert the issueHash into issue data.

  issues = Array.new()

  for assignee in issueHash.keys
    assigneeIssues = Hash.new()
    assigneeIssues['name'] = assignee
    assigneeIssues['issues'] = issueHash[assignee]
    issues.push (assigneeIssues)
  end
  
  send_event('sprintboard', { issues: issues })

  send_event('boardStatus', {
      sprintName: sprint_json["name"],
      toDoCount: issue_count_array[0],
      inProgressCount: issue_count_array[1],
      inReviewCount: issue_count_array[2],
      inTestCount: issue_count_array[3],
      doneCount: issue_count_array[4],

      toDoPercent: issue_sp_count_array[0],
      inProgressPercent: issue_sp_count_array[1],
      inReviewPercent: issue_sp_count_array[2],
      inTestPercent: issue_sp_count_array[3],
      donePercent: issue_sp_count_array[4],
  })

  

  doughnutLabels = [ 'To Do', 'In Progress', 'In Review', 'Test', 'Done' ]
  doughnutData = [
  {
    data: [ issue_sp_count_array[0], 
            issue_sp_count_array[1], 
            issue_sp_count_array[2],
            issue_sp_count_array[3],
            issue_sp_count_array[4] ],

    # colors generated by learnui.design/tools/data-color-picker.html            
    backgroundColor: [
      '#003f5c',
      '#58508d',
      '#bc5090',
      '#ff6361',
      '#ffa600'
    ],
    hoverBackgroundColor: [
      '#003f5c',
      '#58508d',
      '#bc5090',
      '#ff6361',
      '#ffa600'
    ],
  },
  ]
  doughnutOptions = { 
    title: {
      display: true,
      text: sprint_json['name'],
      fontSize: 14,
      fontColor: 'rgb(255, 255, 255)'
    },
    legend: {
      position: 'bottom',
      labels: {
        fontColor: 'rgb(255, 255, 255)'
      }
    }   
  }

  send_event('doughnutchart', { labels: doughnutLabels, datasets: doughnutData, options: doughnutOptions })
  sprintEnd = Time.now + 10 * 86400 # 24 * 60 * 60 
  send_event('clock', { sprintEnd: sprintEnd.to_s })

end

