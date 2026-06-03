CREATE TABLE `releases` (
	`build_number` integer PRIMARY KEY,
	`version` text NOT NULL,
	`changelog` text DEFAULT '' NOT NULL,
	`published_at` integer DEFAULT (unixepoch()) NOT NULL,
	`created_at` integer DEFAULT (unixepoch()) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch()) NOT NULL
);
--> statement-breakpoint
CREATE INDEX `releases_version_idx` ON `releases` (`version`);--> statement-breakpoint
CREATE INDEX `releases_published_at_idx` ON `releases` (`published_at`);