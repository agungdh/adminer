#!/usr/bin/env php
<?php
namespace Adminer;

require __DIR__ . "/../../adminer/include/errors.inc.php";
require __DIR__ . "/../../adminer/include/functions.inc.php";

// Test comparing versions with the fork suffix.
// Prints found errors, prints nothing and exits with 0 if everything is OK.

$tests = array(
	array("6.3.1-agungdh.2", "6.3.1", 1),
	array("6.3.1", "6.3.1-agungdh.2", -1),
	array("6.3.1-agungdh.3", "6.3.1-agungdh.2", 1),
	array("6.3.1-agungdh.2", "6.3.1-agungdh.2", 0),
	array("6.3.1-agungdh.10", "6.3.1-agungdh.9", 1),
	array("9.4.0", "6.3.1-agungdh.2", 1),
	array("6.3.2", "6.3.1-agungdh.2", 1),
	array("v6.3.0-agungdh.4", "6.3.1-agungdh.1", -1),
	array("v6.3.1", "6.3.1", 0),
);

$errors = 0;
foreach ($tests as $test) {
	$result = version_compare_fork($test[0], $test[1]);
	if ($result != $test[2]) {
		echo "version_compare_fork($test[0], $test[1]) = $result, expected $test[2]\n";
		$errors++;
	}
}

exit($errors ? 1 : 0);
