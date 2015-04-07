var locked;

locked = {
  controller: function() {
    var ctrl;
    ctrl = this;
    return this.checkStatus = function() {
      m.request({
        method: 'get',
        url: '/api/truststatus'.then(function(res) {
          if (res.error) {
            switch (res.error) {
              case 'logged_out':
                ctrl.model.message({
                  type: 'error',
                  message: 'You have logged out or your session has expired\n Refresh the page if you are not automatically redirected'
                });
                return window.location.href = '/';
              default:
                return ctrl.model.message({
                  type: 'error',
                  message: "There was an error: <strong>" + res.error + "</strong>"
                });
            }
          } else if (res.done) {
            ctrl.model.message({
              type: 'message',
              message: "Your account has been authorised by " + res.done + "\n Refresh the page if you are not automatically redirected"
            });
            return window.location.href = '/';
          }
        })
      });
    };
  },
  view: function(ctrl) {
    return m('div', m('p', 'Your new account requires manual authorisation by another NCO or staff member.\n You will receive an email when this has been completed.'), m('a[href="javascript:void(0)"]', 'REFRESH STATUS'));
  }
};
