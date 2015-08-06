@validateHttpVerb = (method) ->
  if @request.method isnt method
    @response.writeHead 404, {'Content-Type': 'text/html'}
    @response.end "Not Found!"


@isGet = ->
  validateHttpVerb.call @, 'GET'


@isPost = ->
  validateHttpVerb.call @, 'POST'


Router.map ->
  @route "env",
    path: '/env'
    where: "server"
    #onBeforeAction: isGet
    action: ->
      console.log 'public: ', Meteor.settings.public
      knoteup_version = Meteor.settings.public.commit
      github_link = "<a href='https://github.com/Knotable/KnoteUP/commit/#{knoteup_version}'>#{knoteup_version}</a>" if knoteup_version
      meteor_version = Meteor.release
      node_version = process.version
      startedAt = Meteor.settings.public.startedAt
      startedFrom = moment(startedAt).fromNow()
      #
      # Show which node you are on, for example (2u.knotable.com) when behind ELB(Elastic Load Balancer)
      #
      os = Npm.require("os");
      root     = Meteor.absoluteUrl()
      hostname = os.hostname()

      resp = "Knotable: #{github_link || 'unbundled'}<br>Meteor: #{meteor_version}<br>Node: #{node_version}<br>StartedFrom: #{startedFrom} (#{startedAt})<br/><br/>Node Information:<br/>Url: #{root}<br/>Name: #{hostname}"
      resp += "<br/>Dockerized build number: #{process.env.KNOTABLE_BUILD}" if process.env.KNOTABLE_BUILD
      @response.writeHead 200, {'Content-Type': 'text/html; charset=UTF-8'}
      @response.end resp
