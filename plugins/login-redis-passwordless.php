<?php

/** Allow logging in to Redis without a password
* The server still has to accept the empty password, a server requiring one reports its own error.
* @license https://www.apache.org/licenses/LICENSE-2.0 Apache License, Version 2.0
* @license https://www.gnu.org/licenses/gpl-2.0.html GNU General Public License, version 2 (one or other)
*/
class AdminerLoginRedisPasswordless extends Adminer\Plugin {

	/** Authorize the user
	* @return bool|void true for success, null to keep the default check
	*/
	function login($login, $password) {
		if (Adminer\DRIVER == "redis") {
			return true;
		}
	}
}
