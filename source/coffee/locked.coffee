locked =
   controller: () ->
      ctrl = @


      @checkStatus = () ->
         m.request method: 'get', url: '/api/truststatus' .then (res) ->
            if res.error
               switch res.error
                  when 'logged_out'
                     ctrl.model.message type: 'error', message: 'You have logged out or your session has expired\n
                                                                 Refresh the page if you are not automatically redirected'
                     window.location.href = '/'
                  else
                     ctrl.model.message type: 'error', message: "There was an error: <strong>#{res.error}</strong>"
            else if res.done
               ctrl.model.message type: 'message', message: "Your account has been authorised by #{res.done}\n
                                                             Refresh the page if you are not automatically redirected"
               window.location.href = '/'
         return

   view: (ctrl) ->
      m 'div',
         m 'p', 'Your new account requires manual authorisation by another NCO or staff member.\n
                 You will receive an email when this has been completed.'
         m 'a[href="javascript:void(0)"]', 'REFRESH STATUS'