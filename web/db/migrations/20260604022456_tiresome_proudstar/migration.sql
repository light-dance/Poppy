PRAGMA foreign_keys=OFF;--> statement-breakpoint
CREATE TABLE `__new_releases` (
	`build_number` integer PRIMARY KEY,
	`version` text NOT NULL,
	`title` text,
	`changelog` text DEFAULT '' NOT NULL,
	`published_at` integer DEFAULT (unixepoch()) NOT NULL,
	`created_at` integer DEFAULT (unixepoch()) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch()) NOT NULL
);
--> statement-breakpoint
INSERT INTO `__new_releases`(`build_number`, `version`, `title`, `changelog`, `published_at`, `created_at`, `updated_at`) SELECT `build_number`, `version`, `title`, `changelog`, `published_at`, `created_at`, `updated_at` FROM `releases`;--> statement-breakpoint
DROP TABLE `releases`;--> statement-breakpoint
ALTER TABLE `__new_releases` RENAME TO `releases`;--> statement-breakpoint
PRAGMA foreign_keys=ON;--> statement-breakpoint
CREATE INDEX `releases_version_idx` ON `releases` (`version`);--> statement-breakpoint
CREATE INDEX `releases_published_at_idx` ON `releases` (`published_at`);