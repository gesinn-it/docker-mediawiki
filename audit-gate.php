<?php
// Audit gate for the Composer packages of the image. Run after "composer update".
//
//   php audit-gate.php <triage.json> <strict|warn> [--no-dev]
//
// Composer itself does not block the build on security advisories (policy.advisories.block is
// false in the Dockerfile). This script is the explicit decision instead:
//   strict: advisories with severity high or critical fail the build, unless they are accepted
//           in the triage file
//   warn:   everything is only reported
// Advisories of any other severity (including unrated ones) are reported as warnings.
// An accepted advisory is reported as well, with its reason; an expired review date is a warning.

[, $triageFile, $mode] = $argv + [null, null, 'warn'];
$args = array_slice($argv, 3);
if ($triageFile === null || !in_array($mode, ['strict', 'warn'], true)) {
	fwrite(STDERR, "usage: php audit-gate.php <triage.json> <strict|warn> [--no-dev]\n");
	exit(2);
}

$accepted = json_decode(file_get_contents($triageFile), true);
if (!is_array($accepted)) {
	fwrite(STDERR, "cannot read {$triageFile}\n");
	exit(2);
}

$cmd = 'composer audit --locked --no-interaction --format=json 2>/dev/null' .
	(in_array('--no-dev', $args, true) ? ' --no-dev' : '');
// composer audit exits non-zero when it finds advisories, the JSON is still written
$json = json_decode((string)shell_exec($cmd), true);
if (!is_array($json) || !isset($json['advisories'])) {
	fwrite(STDERR, "audit gate: no usable output from '{$cmd}'\n");
	exit(2);
}

$failures = 0;
foreach ($json['advisories'] as $package => $advisories) {
	foreach ($advisories as $advisory) {
		$id = $advisory['advisoryId'] ?? '?';
		$severity = strtolower((string)($advisory['severity'] ?? '')) ?: 'unrated';
		$title = $advisory['title'] ?? '';
		$label = "{$package}: {$id} ({$severity}) {$title}";

		if (isset($accepted[$id])) {
			$entry = $accepted[$id];
			$review = $entry['review'] ?? '';
			$expired = $review !== '' && $review < date('Y-m-d');
			echo ($expired ? 'WARNING (review expired ' . $review . ')' : 'ACCEPTED') .
				" {$label} - " . ($entry['reason'] ?? 'no reason given') . "\n";
		} elseif ($mode === 'strict' && in_array($severity, ['high', 'critical'], true)) {
			echo "FAIL {$label}\n";
			$failures++;
		} else {
			echo "WARNING {$label}\n";
		}
	}
}

if ($failures > 0) {
	fwrite(STDERR, "audit gate: {$failures} high/critical advisories in the installed packages. " .
		"Fix them or accept them with a reason in the triage file.\n");
	exit(1);
}
echo "audit gate ({$mode}): passed\n";
