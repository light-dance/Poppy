PRAGMA foreign_keys=OFF;--> statement-breakpoint
CREATE TABLE `__new_releases` (
	`version` text PRIMARY KEY NOT NULL,
	`title` text,
	`changelog` text DEFAULT '' NOT NULL,
	`published_at` integer DEFAULT (unixepoch()) NOT NULL,
	`created_at` integer DEFAULT (unixepoch()) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch()) NOT NULL
);
--> statement-breakpoint
INSERT INTO `__new_releases`(`version`, `title`, `changelog`, `published_at`, `created_at`, `updated_at`)
SELECT `version`, `title`, `changelog`, `published_at`, `created_at`, `updated_at`
FROM (
	SELECT
		`version`,
		`title`,
		`changelog`,
		`published_at`,
		`created_at`,
		`updated_at`,
		row_number() OVER (
			PARTITION BY `version`
			ORDER BY `published_at` DESC, `updated_at` DESC, `build_number` DESC
		) AS `release_rank`
	FROM `releases`
)
WHERE `release_rank` = 1;--> statement-breakpoint
DROP TABLE `releases`;--> statement-breakpoint
ALTER TABLE `__new_releases` RENAME TO `releases`;--> statement-breakpoint
PRAGMA foreign_keys=ON;--> statement-breakpoint
DROP INDEX IF EXISTS `releases_version_idx`;--> statement-breakpoint
CREATE INDEX `releases_published_at_idx` ON `releases` (`published_at`);
