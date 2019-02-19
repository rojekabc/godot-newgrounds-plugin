# Godot NewGrounds Plugin
The plugin is created to communicate with [New Grounds](https://www.newgrounds.com) API in version 3 Beta.
This repository contains two elements:
* the plugin - located in folder _addons_
* the sample Godot project

# Features
* newgrounds.io API in version v3
* communication via HTTPS (HTTP with SSL tunnel)
* API to all described [components](http://www.newgrounds.io/help/components/)
* Allow to use as a Godot node
* Sample Godot project to present how to use plugin

# How to use it
## On side of NewGrounds
1. Go to you project management page
2. Select **API Tools** from menu
3. There is a **Notice: The Newgrounds.io API is now in public beta!** - click the link to use API v3 in beta mode
4. Set encryption settings to **None** (See description in chapter **Encryption**)
5. In **App Information** there's an **App Id** - remember it.
## On side of Godot project (v 3.0.6)
1. Download plugin to Godot
   * Download this whole project or git clone.
   * To your project copy whole _addons_ folder, which contains _addons/newgrounds_
   * Move all files from this project to this directory
1. Configure Godot project
   * Choose _Project/Project Settings_ from the menu
   * In tab _Plugins_ activate _NewGround API_ plugin
   * In tab _General_ go to settings of _Network/SSL_ and select file _certs.pem_ from plugin for _Certificates_ setting
1. Adding Node
   * In your project scene _Add node_ and select node _NewGroundsAPI_ from _HTTPRequest_ parent
   * For node set _Application Id_ to you _App Id_ from NewGrounds project management page
1. That's all - just use it.

# Simple sample of use
```
	$NewGroundsAPI.Gateway.getDatetime()
	result = yield($NewGroundsAPI, 'ng_request_complete')
	if $NewGroundsAPI.is_ok(result):
		print('Datetime: ' + str(result.response.datetime))
	else:
		print('Error: ' + result.error)
```

# Organization - How it works
_NewGroundsAPI_ node contains components same, as defined in [reference]([http://www.newgrounds.io/help/components/).
And in same way there're called functions. But there can be another argues order for used parameters of call (to be more convinient).
So, if you want call _getDatetime_ from _Gateway_ component - do it as in the sample.
After the request is done you application may keep the work. So, you have to _yield_ for signal _ng\_request\_complete_.
When signal is emited from plugin it contains a collected information from response or error, if such occures.

The result contains only two fields
* _error_ - null, if everything is ok or string message with problem
* _result_ - this contains exactly the structure from _result.data_, which is a part of JSON response from NewGrounds API.

# NewGroundsAPI node settings
This node extends _HTTPRequest_ node.

Parameter | Description
------------ | -------------
Application Id | Set up your application Id. It is used to communication with NewGrounds.
Verbose | When enabled print out request and response bodies from communication between plugin and NewGrounds. The payload is in JSON format.
Use Threads | This setting is ok, if you have application exported not as HTML5. It's automatically disabled by plugin for HTML5.

# Sample Godot project
The project may be imported to Godot editor. It is fully prepared to use NewGrounds plugin. NewGrounds for any call needs _ApplicationId_.
For put scores or achieve medals session with logged in user is needed. To user log in the passport URL provided by NewGrounds is used.
NewGrounds _ApplicationId_ and _SessionId_ are stored in save file on user space.

# Some open points
## Encryption
Encryption is disabled right now. The reason is I cannot find out right now how to encrypt/decrypt in Godot engine.
I found, that some encryption is used inside [mbedtils as a third part](https://github.com/godotengine/godot/tree/master/thirdparty/mbedtls).
I have no idea, how to use it right now.

Anyway - I use communication via **HTTPS**. It means, that whole communication is done via **SSL tunnel**.

## HTML5 Use Threads disabled
Yes. This flag should be disabled for HTML5. If you force to turn it on, you'll have a supprise with communication error.
In the fact, godot engine enables also _blocking mode_ in internally used _HttpClient_ for _HTTPRequest_.
And this produce error for HTML5, which doesn't allow to use _blocking mode_.

## Plugin version changes

Plugin version | Changes
--- | ---
1.0.0 | Initial version plugin. Uses NG v3 API.
1.0.1 | Fix naming mistake.
1.1.0 | Create sample usage project.
