CREATE TABLE `releases` (
	`version` text PRIMARY KEY NOT NULL,
	`title` text,
	`changelog` text DEFAULT '' NOT NULL,
	`published_at` integer DEFAULT (unixepoch()) NOT NULL,
	`created_at` integer DEFAULT (unixepoch()) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch()) NOT NULL
);
--> statement-breakpoint
CREATE INDEX `releases_published_at_idx` ON `releases` (`published_at`);
