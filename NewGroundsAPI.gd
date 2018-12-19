extends HTTPRequest

const NEW_GROUNDS_API_URL = 'https://www.newgrounds.io/gateway_v3.php'

export(bool) var verbose
export(String) var applicationId

signal ng_request_complete

var Gateway

var _response

func _ready():
	use_threads = OS.get_name() != "HTML5"
	connect("request_completed", self, "_request_completed")
	Gateway = ComponentGateway.new(self)
	pass

func _call_ng_api(component, function, parameters=null, debug=null, echo=null):
	var headers = [
		"Content-Type: application/x-www-form-urlencoded"
	]
	var requestData = {}
	
	requestData.app_id = applicationId
	if debug:
		requestData['debug'] = true
	requestData.call = {}
	requestData.call.component = component + '.' + function
	
	var requestJson = JSON.print(requestData)
	if verbose:
		print(requestJson)
	request(NEW_GROUNDS_API_URL, headers, true, HTTPClient.METHOD_POST, 'input=' + requestJson.percent_encode())
	pass
	
func _request_completed(result, response_code, headers, body):
	var responseBody = body.get_string_from_utf8()
	if verbose:
		print('Response code: ' + str(response_code))
		print('Response body: ' + responseBody)
	var jsonBody = JSON.parse(responseBody)
	if jsonBody.error == OK:
		if jsonBody.result.success:
			match jsonBody.result.result.component:
				'Gateway.ping': _response = jsonBody.result.result.data.pong
				'Gateway.getVersion': _response = jsonBody.result.result.data.version
				'Gateway.getDatetime': _response = jsonBody.result.result.data.datetime
		else:
			print(str(jsonBody.result.error.code) + ' ' + str(jsonBody.result.error.message))
	else:
		print('Wrong JSON body')
	emit_signal('ng_request_complete', _response)
	pass

class ComponentGateway:
	const NAME = 'Gateway'
	var api
	func _init(_api):
		api = _api

	func getVersion():
		api._call_ng_api(NAME, 'getVersion')
		pass
		
	func getDatetime():
		api._call_ng_api(NAME, 'getDatetime')
		pass
		
	func ping():
		api._call_ng_api(NAME, 'ping')
		pass

