class @BaseController
  _controllers = {}



  _setupControllerDependencies: (template, controller) ->
    @template = controller.template = template
    template.controller = controller
    template.view._controller = controller
    controllerKey = template.data._id
    if controllerKey
      _controllers[controllerKey] = controller
      template.view.onViewDestroyed ->
        if _controllers[controllerKey] is @_controller
          delete _controllers[controllerKey] if _controllers[controllerKey]
          delete @_controller



  @getController = (entityId) ->
    if entityId then _controllers[entityId] else null