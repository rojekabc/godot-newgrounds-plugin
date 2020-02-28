extends Node


const SAVE_FILE_NAME = "user://ngsettings.save"

var passportUrl = null
var saveFile = File.new()
var saveData = {
		applicationId = null,
		sessionId = null
	}


func _ready():
	if saveFile.file_exists(SAVE_FILE_NAME):
		var saveData
		
		saveFile.open(SAVE_FILE_NAME, File.READ)
		saveData = saveFile.get_var() # Dictionary
		saveFile.close()
		
		$NewGroundsAPI.session_id = saveData.sessionId
		$NewGroundsAPI.applicationId = saveData.applicationId
		
		if saveData.sessionId and saveData.sessionId.length() > 0:
			$UI/Application/Container/Session.text = 'Session: To Check'
		
		$UI/Settings/Container/ApplicationId/Value.text = saveData.applicationId
	
	$UI/Gateway/Container/Version/Button.connect(
			'pressed', 
			self, 
			'_gateway_get_version'
			)
	$UI/Gateway/Container/Ping/Button.connect(
			'pressed', 
			self, 
			'_gateway_ping'
			)
	$UI/Gateway/Container/Datetime/Button.connect(
			'pressed', 
			self, 
			'_gateway_get_datetime'
			)
	$UI/Settings/Container/ApplicationId/Value.connect(
			'text_changed', 
			self, 
			'_settings_applicationid_changed'
			)
	$UI/Medal/Container/Button.connect(
			'pressed', 
			self, 
			'_medal_get_list'
			)
	$UI/Application/Container/SessionAction/Start.connect(
			'pressed', 
			self, 
			'_application_session_start'
			)
	$UI/Application/Container/SessionAction/Check.connect(
			'pressed',
			self, 
			'_application_session_check'
			)
	$UI/Application/Container/SessionAction/End.connect(
			'pressed', 
			self, 
			'_application_session_end'
			)
	$UI/Application/Container/Login.connect(
			'pressed', 
			self, 
			'_passport_login'
			)
	$UI/Scores/Container/GetScores.connect(
			'pressed', 
			self, 
			'_scores_get_scores'
			)
	$UI/Scores/Container/GetBoards.connect(
			'pressed', 
			self, 
			'_scores_get_boards'
			)
	$UI/Scores/Container/AddScore.connect(
			'pressed', 
			self, 
			'_scores_add_score'
			)


func _write_save_file():
	var error = saveFile.open(SAVE_FILE_NAME, File.WRITE)
	
	if error == OK:
		saveData.sessionId = $NewGroundsAPI.session_id
		saveData.applicationId = $NewGroundsAPI.applicationId
		saveFile.store_var(saveData)
		saveFile.close()
	else:
		print('Fail save file')


func _scores_get_boards():
	$UI/Status/Label.text = ''
	
	$UI/Scores/Container/Scores/ItemList.clear()
	$UI/Scores/Container/Boards/ItemList.clear()
	
	$NewGroundsAPI.ScoreBoard.getBoards()
	
	var result = yield($NewGroundsAPI, 'ng_request_complete')
	
	if $NewGroundsAPI.is_ok(result):
		var idx = 0
		for board in result.response.scoreboards:
			$UI/Scores/Container/Boards/ItemList.add_item(
					'[' + str(board.id) + '] ' + board.name
					)
			
			$UI/Scores/Container/Boards/ItemList.set_item_metadata(idx, board.id)
			idx += 1
	else:
		$UI/Status/Label.text = result.error


func _scores_get_scores():
	$UI/Status/Label.text = ''
	$UI/Scores/Container/Scores/ItemList.clear()
	
	var items = $UI/Scores/Container/Boards/ItemList.get_selected_items()
	var boardId = null
	
	if items.size() > 0:
		boardId = $UI/Scores/Container/Boards/ItemList.get_item_metadata(items[0])
	
	$NewGroundsAPI.ScoreBoard.getScores(boardId)
	
	var result = yield($NewGroundsAPI, 'ng_request_complete')
	
	if $NewGroundsAPI.is_ok(result):
		for score in result.response.scores:
			$UI/Scores/Container/Scores/ItemList.add_item(
					str(score.value) + ' - ' + score.user.name
					)
		pass
	else:
		$UI/Status/Label.text = result.error


func _scores_add_score():
	var items = $UI/Scores/Container/Boards/ItemList.get_selected_items()
	var boardId = null
	
	if items.size() > 0:
		boardId = $UI/Scores/Container/Boards/ItemList.get_item_metadata(items[0])
	
	$NewGroundsAPI.ScoreBoard.postScore($UI/Scores/Container/Score/Value.text, boardId)
	
	var result = yield($NewGroundsAPI, 'ng_request_complete')
	
	if not $NewGroundsAPI.is_ok(result):
		$UI/Status/Label.text = result.error


func _passport_login():
	OS.shell_open(passportUrl)
	passportUrl = null
	$UI/Application/Container/Login.disabled = true
	$UI/Status/Label.text = 'Go and login via browser to connect user with session'
	pass


func _application_session_start():
	$UI/Status/Label.text = ''
	$NewGroundsAPI.App.startSession()
	var result = yield($NewGroundsAPI, 'ng_request_complete')
	if $NewGroundsAPI.is_ok(result):
		$NewGroundsAPI.session_id = result.response.session.id
		passportUrl = result.response.session.passport_url
		$UI/Application/Container/Login.disabled = false
		
		if result.response.session.expired:
			$UI/Application/Container/Session.text = 'Session: Expired'
		else:
			$UI/Application/Container/Session.text = 'Session: Valid'
			_write_save_file()
		
		if result.response.session.user:
			$UI/Application/Container/User.text = \
					'User: ' + result.response.session.user.name + \
					'[' + result.response.session.user.id + ']'
		else:
			$UI/Application/Container/User.text = 'User: '
	else:
		$UI/Status/Label.text = result.error
		$UI/Application/Container/Session.text = 'Session: None'
		$UI/Application/Container/User.text = 'User: '


func _application_session_check():
	$UI/Status/Label.text = ''
	$NewGroundsAPI.App.checkSession()
	
	var result = yield($NewGroundsAPI, 'ng_request_complete')
	
	if $NewGroundsAPI.is_ok(result):
		if result.response.session.expired:
			$UI/Application/Container/Session.text = 'Session: Expired'
		else:
			$UI/Application/Container/Session.text = 'Session: Valid'
		if result.response.session.user:
			$UI/Application/Container/User.text = 'User: ' + result.response.session.user.name + ' [' + str(result.response.session.user.id) + ']'
		else:
			$UI/Application/Container/User.text = 'User: '
	else:
		$NewGroundsAPI.session_id = ''
		$UI/Status/Label.text = result.error
		
		passportUrl = null
		
		$UI/Application/Container/Login.disabled = true
		$UI/Application/Container/Session.text = 'Session: None'
		$UI/Application/Container/User.text = 'User: '


func _application_session_end():
	$UI/Status/Label.text = ''
	$NewGroundsAPI.App.endSession()
	
	var result = yield($NewGroundsAPI, 'ng_request_complete')
	
	if $NewGroundsAPI.is_ok(result):
		$NewGroundsAPI.session_id = ''
		passportUrl = null
		$UI/Application/Container/Login.disabled = true
	else:
		$UI/Status/Label.text = result.error
	
	$UI/Application/Container/Session.text = 'Session: None'
	$UI/Application/Container/User.text = 'User: '
	
	_write_save_file()


func _medal_get_list():
	$UI/Status/Label.text = ''
	
	for child in $UI/Medal/Container/List/Container.get_children():
		$UI/Medal/Container/List/Container.remove_child(child)
	
	$NewGroundsAPI.Medal.getList()
	
	var result = yield($NewGroundsAPI, 'ng_request_complete')
	
	if $NewGroundsAPI.is_ok(result):
		for medal in result.response.medals:
			var medalCheck = CheckBox.new()
			medalCheck.text = medal.name
			medalCheck.pressed = medal.unlocked
			medalCheck.connect('toggled', self, '_medal_togled', [medal.id, medalCheck])
			$UI/Medal/Container/List/Container.add_child(medalCheck)
	else:
		$UI/Status/Label.text = result.error


func _medal_togled(toggled, medalId, medalCheck):
	$UI/Status/Label.text = ''
	
	if toggled:
		$NewGroundsAPI.Medal.unlock(medalId)
		
		var result = yield($NewGroundsAPI, 'ng_request_complete')
		
		if $NewGroundsAPI.is_ok(result):
			medalCheck.pressed = true
		else:
			medalCheck.pressed = false
			$UI/Status/Label.text = result.error


func _settings_applicationid_changed(text):
	$NewGroundsAPI.applicationId = text
	_write_save_file()


func _gateway_get_version():
	$UI/Status/Label.text = ''
	$UI/Gateway/Container/Version/Result.text = ''
	
	$NewGroundsAPI.Gateway.getVersion()
	
	var result = yield($NewGroundsAPI, 'ng_request_complete')
	
	if $NewGroundsAPI.is_ok(result):
		$UI/Gateway/Container/Version/Result.text = result.response.version
	else:
		$UI/Status/Label.text = result.error


func _gateway_get_datetime():
	$UI/Status/Label.text = ''
	$UI/Gateway/Container/Datetime/Result.text = ''
	
	$NewGroundsAPI.Gateway.getDatetime()
	
	var result = yield($NewGroundsAPI, 'ng_request_complete')
	
	if $NewGroundsAPI.is_ok(result):
		$UI/Gateway/Container/Datetime/Result.text = result.response.datetime
	else:
		$UI/Status/Label.text = result.error


func _gateway_ping():
	$UI/Status/Label.text = ''
	$UI/Gateway/Container/Ping/Result.text = ''
	
	$NewGroundsAPI.Gateway.ping()
	
	var result = yield($NewGroundsAPI, 'ng_request_complete')
	
	if $NewGroundsAPI.is_ok(result):
		$UI/Gateway/Container/Ping/Result.text = result.response.pong
	else:
		$UI/Status/Label.text = result.error

