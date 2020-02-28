extends HTTPRequest


const NEW_GROUNDS_API_URL = "https://www.newgrounds.io/gateway_v3.php"

signal ng_request_complete

export var applicationId := ""
export var verbose := false
export var debug := false

var App : ComponentApp
var Event : ComponentEvent
var Gateway : ComponentGateway
var Loader : ComponentLoader
var Medal : ComponentMedal
var ScoreBoard : ComponentScoreBoard

var session_id : String


func _ready():
	use_threads = OS.get_name() != "HTML5"
	
	connect("request_completed", self, "_request_completed")
	
	App = ComponentApp.new(self)
	Event = ComponentEvent.new(self)
	Gateway = ComponentGateway.new(self)
	Loader = ComponentLoader.new(self)
	Medal = ComponentMedal.new(self)
	ScoreBoard = ComponentScoreBoard.new(self)
	
	if OS.get_name() == "HTML5":
		session_id = JavaScript.eval(
				"""
				var urlParams = new URLSearchParams(window.location.search); 
				urlParams.get('ngio_session_id')
				""", 
				true)
		
		_verbose("Session id: " + str(session_id))
		_verbose("Location hostname: " + str(JavaScript.eval("location.hostname")))


func _call_ng_api(
		component : String,
		function : String, 
		parameters := {},  
		_session_id := "",
		echo := ""
		):
	
	var headers := [ "Content-Type: application/x-www-form-urlencoded" ]
	var requestData := {}
	var requestJson : String
	var requestResult : int # @GlobalScope.Error
	
	if applicationId != "":
		requestData.app_id = applicationId
	
	if debug:
		requestData.debug = true
	
	if session_id != "":
		requestData.session_id = _session_id
	
	requestData.call = {}
	requestData.call.component = component + '.' + function
	requestData.call.parameters = parameters
	
	requestJson = JSON.print(requestData)
	
	_verbose(requestJson)
	
	requestResult = request(
			NEW_GROUNDS_API_URL, 
			headers, 
			true, 
			HTTPClient.METHOD_POST, 
			'input=' + requestJson.percent_encode()
			)
	
	if requestResult != OK:
		emit_signal(
			'ng_request_complete', 
			{'error': 'Request result = ' + str(requestResult)}
			)


func _request_completed(
		result : int, 
		response_code : int, 
		headers : PoolStringArray, 
		body : PoolByteArray
		):
	
	var responseBody := body.get_string_from_utf8()
	var jsonBody : JSONParseResult
	var response # TODO: Add typing
	
	_verbose(responseBody)
	
	if result != OK:
		emit_signal(
				'ng_request_complete', 
				{'error': 'Response result = ' + str(result)}
				)
		return
	
	if response_code >= 300:
		emit_signal(
				'ng_request_complete', 
				{'error': 'Response status code = ' + str(response_code)}
				)
		
		return
	
	jsonBody = JSON.parse(responseBody)
	
	if jsonBody.error != OK:
		emit_signal(
				'ng_request_complete', 
				{'error': 'Response has wrong JSON body'}
				)
		
		return
	
	if !jsonBody.result.success:
		emit_signal(
				'ng_request_complete', 
				{
					'error': 'New Grounds error: ' + \
					str(jsonBody.result.error.code) + ' ' + \
					str(jsonBody.result.error.message)
					}
				)
		
		return
	
	if !jsonBody.result.result.data.success:
		emit_signal(
				'ng_request_complete', 
				{
					'error': 'New Grounds data error: ' + \
					str(jsonBody.result.result.data.error.code) + ' ' + \
					str(jsonBody.result.result.data.error.message)
					}
				)
		
		return
	
	response = jsonBody.result.result.data
	
	emit_signal('ng_request_complete', {'response': response, 'error': null})


func _verbose(msg : String):
	if verbose:
		print('[NG Plugin] ' + msg)


func is_ok(ngResult) -> bool:
	return ngResult != null and ngResult.error == null


# TODO: Potentially move these into their own files and give everything a class_name
class ComponentLoader:
	const NAME = 'Loader'
	var api
	
	
	func _init(_api):
		api = _api
	
	
	func loadAuthorUrl(host, redirect=false):
		api._call_ng_api(
				NAME, 
				'loadAuthorUrl', 
				{'host' : host, 'redirect' : redirect}
				)
	
	
	func loadMoreGames(host, redirect=false):
		api._call_ng_api(
				NAME, 
				'loadMoreGames', 
				{'host' : host, 'redirect' : redirect}
				)
	
	
	func loadNewgrounds(host, redirect=false):
		api._call_ng_api(
				NAME, 
				'loadNewgrounds',
				{'host' : host, 'redirect' : redirect}
				)
	
	
	func loadOfficialUrl(host, redirect=false):
		api._call_ng_api(
				NAME, 
				'loadOfficialUrl', 
				{'host' : host, 'redirect' : redirect}
				)
	
	
	func loadReferral(host, referral_name, redirect=false):
		api._call_ng_api(
				NAME, 
				'loadReferral', 
				{
					'host' : host, 
					'referral_name' : referral_name, 
					'redirect' : redirect
					}
				)


class ComponentMedal:
	const NAME = 'Medal'
	var api
	
	
	func _init(_api):
		api = _api
	
	
	func getList(sessionId=api.session_id):
		api._call_ng_api(NAME, 'getList', {}, sessionId)
	
	
	
	func unlock(medalId, sessionId=api.session_id):
		api._call_ng_api(NAME, 'unlock', {'id' : medalId}, sessionId)


class ComponentEvent:
	const NAME = 'Event'
	var api
	
	
	func _init(_api):
		api = _api
	
	
	func logEvent(host, event_name):
		api._call_ng_api(
				NAME, 
				'logEvent', 
				{'host' : host, 'event_name' : event_name}
				)


class ComponentApp:
	const NAME = 'App'
	var api
	
	
	func _init(_api):
		api = _api
	
	
	func checkSession(sessionId=api.session_id):
		api._call_ng_api(NAME, 'checkSession', {}, sessionId)
	
	
	func endSession(sessionId=api.session_id):
		api._call_ng_api(NAME, 'endSession', {}, sessionId)
	
	
	func getCurrentVersion(version=null):
		api._call_ng_api(NAME, 'getCurrentVersion', {'version' : version})
	
	
	func getHostLicense(host=null):
		api._call_ng_api(NAME, 'getHostLicense', {'host' : host})
	
	
	func logView(host):
		api._call_ng_api(NAME, 'logView', {'host' : host})
	
	
	func startSession(force=null):
		api._call_ng_api(NAME, 'startSession', {'force' : force})


class ComponentGateway:
	const NAME = 'Gateway'
	var api
	
	
	func _init(_api):
		api = _api
	
	
	func getVersion():
		api._call_ng_api(NAME, 'getVersion')
	
	
	func getDatetime():
		api._call_ng_api(NAME, 'getDatetime')
	
	
	func ping():
		api._call_ng_api(NAME, 'ping')


class ComponentScoreBoard:
	const NAME = 'ScoreBoard'
	var api
	
	
	func _init(_api):
		api = _api
	
	
	func getBoards():
		api._call_ng_api(NAME, 'getBoards')
	
	
	func getScores(
			scoreId, 
			sessionId=api.session_id, 
			limit=10, 
			skip=0, 
			social=false, 
			tag=null, 
			period=null, 
			userId=null
			):
		
		api._call_ng_api(
				NAME, 
				'getScores', 
				{
					'id' : scoreId, 
					'limit': limit, 
					'skip': skip, 
					'social': social, 
					'tag': tag,
					'period': period, 
					'userId': userId
					},
				sessionId
				)
	
	
	func postScore(value, scoreId, sessionId=api.session_id, tag=null):
		api._call_ng_api(
				NAME, 
				'postScore', 
				{'value' : value, 'id': scoreId, 'tag': tag},
				sessionId
				)
