extends HTTPRequest

const NEW_GROUNDS_API_URL = 'https://www.newgrounds.io/gateway_v3.php'

export(bool) var verbose
export(String) var applicationId

signal ng_request_complete

var App
var Event
var Gateway
var Loader
var Medal
var ScoreBoard

var session_id

func is_ok(ngResult):
	return ngResult != null and ngResult.error == null

func _ready():
	use_threads = OS.get_name() != "HTML5"
	
	connect("request_completed", self, "_request_completed")
	
	Gateway = ComponentGateway.new(self)
	ScoreBoard = ComponentScoreBoard.new(self)
	App = ComponentApp.new(self)
	Event = ComponentEvent.new(self)
	Loader = ComponentLoader.new(self)
	Medal = ComponentMedal.new(self)
	
	if OS.get_name() == 'HTML5':
		session_id = JavaScript.eval('var urlParams = new URLSearchParams(window.location.search); urlParams.get("ngio_session_id")', true)
		_verbose('Session id: ' + str(session_id))
		_verbose('Location hostname: ' + str(JavaScript.eval('location.hostname')))
	pass

func _call_ng_api(component, function, _session_id=null, parameters=null, debug=null, echo=null):
	var headers = [
		"Content-Type: application/x-www-form-urlencoded"
	]
	var requestData = {}
	
	if applicationId:
		requestData.app_id = applicationId
	if debug:
		requestData.debug = true
	if session_id:
		requestData.session_id = _session_id
	requestData.call = {}
	requestData.call.component = component + '.' + function
	requestData.call.parameters = parameters
	
	var requestJson = JSON.print(requestData)
	_verbose(requestJson)
	var requestResult = request(NEW_GROUNDS_API_URL, headers, true, HTTPClient.METHOD_POST, 'input=' + requestJson.percent_encode())
	if requestResult != OK:
		emit_signal('ng_request_complete', {'error': 'Request result = ' + str(requestResult)})
	pass
	
func _request_completed(result, response_code, headers, body):
	var responseBody = body.get_string_from_utf8()
	_verbose(responseBody)
	if result != OK:
		emit_signal('ng_request_complete', {'error': 'Response result = ' + str(result)})
		return
	if response_code >= 300:
		emit_signal('ng_request_complete', {'error': 'Response status code = ' + str(response_code)})
		return
		
	var jsonBody = JSON.parse(responseBody)
	if jsonBody.error != OK:
		emit_signal('ng_request_complete', {'error': 'Response has wrong JSON body'})
		return
	if !jsonBody.result.success:
		emit_signal('ng_request_complete', {'error': 'New Grounds error: ' + str(jsonBody.result.error.code) + ' ' + str(jsonBody.result.error.message)})
		return
	if !jsonBody.result.result.data.success:
		emit_signal('ng_request_complete', {'error': 'New Grounds data error: ' + str(jsonBody.result.result.data.error.code) + ' ' + str(jsonBody.result.result.data.error.message)})
		return
	var response = jsonBody.result.result.data
	emit_signal('ng_request_complete', {'response': response, 'error': null})
	pass

func _verbose(msg):
	if verbose:
		print('[NG Plugin] ' + msg)

class ComponentLoader:
	const NAME = 'Loader'
	var api
	func _init(_api):
		api = _api
	
	func loadAuthorUrl(host, redirect=false):
		api._call_ng_api(NAME, 'loadAuthorUrl', null, {'host' : host, 'redirect' : redirect})
		pass
		
	func loadMoreGames(host, redirect=false):
		api._call_ng_api(NAME, 'loadMoreGames', null, {'host' : host, 'redirect' : redirect})
		pass
		
	func loadNewgrounds(host, redirect=false):
		api._call_ng_api(NAME, 'loadNewgrounds', null, {'host' : host, 'redirect' : redirect})
		pass
		
	func loadOfficialUrl(host, redirect=false):
		api._call_ng_api(NAME, 'loadOfficialUrl', null, {'host' : host, 'redirect' : redirect})
		pass
		
	func loadReferral(host, referral_name, redirect=false):
		api._call_ng_api(NAME, 'loadReferral', null, {'host' : host, 'referral_name' : referral_name, 'redirect' : redirect})
		pass

class ComponentMedal:
	const NAME = 'Medal'
	var api
	func _init(_api):
		api = _api
		
	func getList(sessionId=api.session_id):
		api._call_ng_api(NAME, 'getList', sessionId)
		pass
	
	func unlock(medalId, sessionId=api.session_id):
		api._call_ng_api(NAME, 'unlock', sessionId, {'id' : medalId})
		pass

class ComponentEvent:
	const NAME = 'Event'
	var api
	func _init(_api):
		api = _api
		
	func logEvent(host, event_name):
		api._call_ng_api(NAME, 'logEvent', null, {'host' : host, 'event_name' : event_name})
		pass
		

class ComponentApp:
	const NAME = 'App'
	var api
	func _init(_api):
		api = _api
		
	func checkSession(sessionId=api.session_id):
		api._call_ng_api(NAME, 'checkSession', sessionId)
		pass
		
	func endSession(sessionId=api.session_id):
		api._call_ng_api(NAME, 'endSession', sessionId)
		pass
		
	func getCurrentVersion(version=null):
		api._call_ng_api(NAME, 'getCurrentVersion', null, {'version' : version})
		pass
		
	func getHostLicense(host=null):
		api._call_ng_api(NAME, 'getHostLicense', null, {'host' : host})
		pass
		
	func logView(host):
		api._call_ng_api(NAME, 'logView', null, {'host' : host})
		pass
		
	func startSession(force=null):
		api._call_ng_api(NAME, 'startSession', null, {'force' : force})
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

class ComponentScoreBoard:
	const NAME = 'ScoreBoard'
	var api
	
	func _init(_api):
		api = _api
	
	func getBoards():
		api._call_ng_api(NAME, 'getBoards')
		pass
	
	func getScores(scoreId, sessionId=api.session_id, limit=10, skip=0, social=false, tag=null, period=null, userId=null):
		api._call_ng_api(NAME, 'getScores', sessionId,
			{
				'id' : scoreId, 'limit': limit, 'skip': skip, 'social': social, 'tag': tag,
				'period': period, 'userId': userId
			})
		pass

	func postScore(value, scoreId, sessionId=api.session_id, tag=null):
		api._call_ng_api(NAME, 'postScore', sessionId, {'value' : value, 'id': scoreId, 'tag': tag})
		pass
