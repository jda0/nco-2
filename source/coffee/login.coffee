login =
   controller: () ->
      ctrl = @


      @model = 
         message: m.prop type: null, message: null

         email: m.prop window.session.email || ''
         name: m.prop ''
         jnco: m.prop false

         invalidEmail: m.prop false
         invalidName: m.prop false

         registerCtx: m.prop false
         getKeyCtx: () -> not @registerCtx()


      @getKey = (e) ->
         e.preventDefault()

         if not e.target.checkValidity or e.target.checkValidity()
            m.request(method: 'post', url: '/api/getkey', data: email: ctrl.model.email()).then (res) ->
               if e.target.email.setCustomValidity then e.target.email.setCustomValidity ''

               if res.error
                  switch res.error
                     when 'bad_email'
                        ctrl.model.message type: 'error', message: 'The email you entered doesn\'t appear to be valid'
                        if e.target.email.setCustomValidity then e.target.email.setCustomValidity 'Invalid email'
                     when 'unregistered'
                        ctrl.model.registerCtx true
                     else
                        ctrl.model.message type: 'error', message: "There was an error: <strong>#{res.error}</strong>"
               else
                  ctrl.model.message type: 'success', message: 'Your key has been sent'

         return false


      @register = (e) ->
         e.preventDefault()

         if not e.target.checkValidity or e.target.checkValidity()
            m.request(method: 'post', 'url': '/api/register', data: 
                        email: ctrl.model.email()
                        name: ctrl.model.name()
                        mod: not ctrl.model.jnco()
            ).then (res) ->
               if e.target.email.setCustomValidity then e.target.email.setCustomValidity ''
               if e.target.name.setCustomValidity then e.target.name.setCustomValidity ''
               if res.error
                  switch res.error
                     when 'bad_email'
                        ctrl.model.message type: 'error', message: 'The email you entered doesn\'t appear to be valid'
                        if e.target.email.setCustomValidity then e.target.email.setCustomValidity 'Invalid email'
                     when 'bad_name'
                        ctrl.model.message type: 'error', message: 'The name you entered doesn\'t appear to be valid'
                        if e.target.email.setCustomValidity then e.target.email.setCustomValidity 'Invalid name'
                     else
                        ctrl.model.message type: 'error', message: "There was an error: <strong>#{res.error}</strong>"
               else
                  ctrl.model.message type: 'success', message: 'You have been registered and your key has been sent'
                  ctrl.model.registerCtx false

         return false
         
         
      return


   view: (ctrl) ->
      m 'div',
         m 'div', hidden: not ctrl.model.message()?, ctrl.model.message().message
      
         m 'form.pure-form.pure-form-aligned', hidden: ctrl.model.registerCtx(), onsubmit: ctrl.getKey,
            m '.pure-control-group',
               m 'label[for="email"]', 'email'
               m 'input[name="email"][type="email"][required]'
                  , value: ctrl.model.email(), onchange: m.withAttr 'value', ctrl.model.email
            
            m '.pure-controls',
               m 'input[type="submit"]', 'get key'

         m 'form.pure-form.pure-form-aligned', hidden: ctrl.model.getKeyCtx(), onsubmit: ctrl.register,
            m '.pure-control-group',
               m 'label[for="email"]', 'email'
               m 'input[name="email"][type="email"][required]'
                  , value: ctrl.model.email(), onchange: m.withAttr 'value', ctrl.model.email
            
            m '.pure-control-group',
               m 'label[for="name"]', 'name'
               m 'input[name="name"][type="text"][minlength="2"][required]'
                  , value: ctrl.model.name(), onchange: m.withAttr 'value', ctrl.model.name

            m '.pure-control-group',
               m 'label[for="rank"]',
                  m 'input[type="checkbox"][required]'
                     , value: ctrl.model.jnco(), onchange: m.withAttr 'value', ctrl.model.jnco
                  'I am a JNCO'

            m '.pure-controls',
               m 'input[type="submit"]', 'register'
               
               
m.module document.body, login