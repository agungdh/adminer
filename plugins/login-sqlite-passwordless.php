<?php

/** Allow logging in to SQLite without a password
* SQLite has no credentials, the database is selected as a file.
* @license https://www.apache.org/licenses/LICENSE-2.0 Apache License, Version 2.0
* @license https://www.gnu.org/licenses/gpl-2.0.html GNU General Public License, version 2 (one or other)
*/
class AdminerLoginSqlitePasswordless extends Adminer\Plugin {

	/** Authorize the user
	* @return bool|void true for success, null to keep the default check
	*/
	function login($login, $password) {
		if (Adminer\DRIVER == "sqlite") {
			return true;
		}
	}
}
