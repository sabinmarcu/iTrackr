const DRIVERS = [\webkit \normal]; Drivers = new IS.Enum DRIVERS

class NotificationHelper extends IS.Object
	~> 

		@timeout ?= 5000

		@driver = DRIVERS.normal
		if Tester[\webkitNotifications]
			unless Tester[\chrome.storage]
				handler = ->
					webkitNotifications.requestPermission()
					window.removeEventListener "click"
				window.addEventListener "click", handler
			@driver = DRIVERS.webkit	
		@echo "Notification Helper Online, with driver : ", @drive, " and timeout : ", @timeout

	toast: (title = "Notification", ...body)~> switch @driver
	| Drivers.webkit => 
		if webkitNotifications.checkPermission() is 0 
			@toast-webkit title, body 
		else @toast-normal title, body
	| otherwise => @toast-normal title, body
	toast-webkit: (title, body)~>
		b = body.shift!
		for item in body then b += "\n#item"
		notif = webkitNotifications.createNotification 'icon.ico', title, b 
		notif.ondisplay = (ev) -> setTimeout (-> ev.currentTarget.cancel()), @timeout
		notif.show!
	toast-normal: (title, body) ~>
		b = ""
		if Modal? 
			for item in body then b += "<p>#item</p>"
			Modal.show {title: title, content: b}, @timeout
		else 
			b = ( [title] ++ body ) * "\n"
			alert b

Helper = new NotificationHelper()
Toast = Helper.toast
module.exports = [ Helper, Toast ]
