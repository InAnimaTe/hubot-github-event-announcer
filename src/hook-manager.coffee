# The list of all GitHub events.
#
# See: https://developer.github.com/v3/activity/events/types/
ALL_EVENTS = [
  'commit_comment'
  'create'
  'delete'
  'deployment'
  'deployment_status'
  'download'
  'follow'
  'fork'
  'fork_apply'
  'gist'
  'gollum'
  'issue_comment'
  'issues'
  'member'
  'membership'
  'page_build'
  'public'
  'pull_request'
  'pull_request_review_comment'
  'push'
  'release'
  'repository'
  'status'
  'team_add'
  'watch'
]

# Public: Manages GitHub event hooks.
class HookManager
  # Public: Constructs a new `HookManager`.
  #
  # * `robot` Robot used to interact with the outside world.
  # * `msg` Message to use to reply back to the user.
  constructor: (@robot, @msg) ->

  # Public: Adds a hook to the repository at the given GitHub `user` and `repo`.
  #
  # * `user` {String} containing the GitHub user name.
  # * `repo` {String} containing the GitHub repository name.
  # * `options` {Object} containing the following options:
  #     * `room` Room name {String} to send events to for this hook.
  addHook: (user, repo, options = {}) ->
    try
      url = @buildHookUrl(user, repo, options)
      token = @getToken()

      data =
        name: 'web'
        active: true
        config:
          content_type: 'json'
          secret: process.env.HUBOT_GITHUB_EVENT_SECRET
          url: url
        events: ALL_EVENTS

      @robot.http("https://api.github.com/repos/#{user}/#{repo}/hooks")
        .header('Accept', 'application/json')
        .header('Authorization', "token #{token}")
        .post(data) (err, res, body) ->
          @robot.logger.info "Response code from add hook: #{res.status}"

          if err
            @robot.logger.error err.toString()
            @msg.reply """
              I encountered an error while adding the GitHub events hook to #{user}/#{repo} ...

              #{err}
              """
            return

          @msg.reply "I was able to successfully add the GitHub events hook to #{user}/#{repo}"
    catch e
      @msg.reply e.message

  # Private: Builds the URL to use for receiving the web hooks.
  #
  # * `user` {String} containing the GitHub user name.
  # * `repo` {String} containing the GitHub repository name.
  # * `options` {Object} containing the following options:
  #     * `room` Room name {String} to send events to for this hook.
  #
  # Returns a {String} containing the URL.
  buildHookUrl: (user, repo, options = {}) ->
    host = process.env.HEROKU_URL ? process.env.HUBOT_GITHUB_EVENT_BASE_URL

    unless host
      throw new Error('Neither HEROKU_URL nor HUBOT_GITHUB_EVENT_BASE_URL are set, cannot add hook')

    url = "#{host}/hubot/github-events"
    url += "?room=#{options.room}" if options.room

    url

  # Private: Gets the security token to use for authorization to access web hooks.
  #
  # Returns a {String} containing the token text.
  getToken: ->
    token = process.env.HUBOT_GITHUB_EVENT_HOOK_TOKEN

    unless token
      throw new Error('HUBOT_GITHUB_EVENT_HOOK_TOKEN is not set, cannot add hook')

    token

module.exports = HookManager