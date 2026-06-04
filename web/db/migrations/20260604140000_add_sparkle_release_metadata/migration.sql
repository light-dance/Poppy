ALTER TABLE `releases` ADD `build` integer DEFAULT 1 NOT NULL;
--> statement-breakpoint
ALTER TABLE `releases` ADD `sparkle_zip_length` integer;
--> statement-breakpoint
ALTER TABLE `releases` ADD `sparkle_zip_signature` text;
--> statement-breakpoint
CREATE UNIQUE INDEX `releases_version_build_idx` ON `releases` (`version`,`build`);
