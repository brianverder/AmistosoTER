-- CreateTable
CREATE TABLE `users` (
    `id` VARCHAR(36) NOT NULL,
    `email` VARCHAR(191) NOT NULL,
    `password` VARCHAR(255) NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `phone` VARCHAR(50) NULL,
    `role` VARCHAR(20) NOT NULL DEFAULT 'user',
    `active` BOOLEAN NOT NULL DEFAULT true,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `users_email_key`(`email`),
    INDEX `users_email_idx`(`email`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `teams` (
    `id` VARCHAR(36) NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `instagram` VARCHAR(255) NULL,
    `userId` VARCHAR(36) NOT NULL,
    `country` VARCHAR(50) NULL,
    `state` VARCHAR(100) NULL,
    `footballType` VARCHAR(10) NULL,
    `active` BOOLEAN NOT NULL DEFAULT true,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,
    `gamesWon` INTEGER NOT NULL DEFAULT 0,
    `gamesLost` INTEGER NOT NULL DEFAULT 0,
    `gamesDrawn` INTEGER NOT NULL DEFAULT 0,
    `totalGames` INTEGER NOT NULL DEFAULT 0,
    `goalsFor` INTEGER NOT NULL DEFAULT 0,
    `goalsAgainst` INTEGER NOT NULL DEFAULT 0,
    `points` INTEGER NOT NULL DEFAULT 0,

    INDEX `teams_userId_idx`(`userId`),
    INDEX `teams_country_idx`(`country`),
    INDEX `teams_footballType_idx`(`footballType`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `match_requests` (
    `id` VARCHAR(36) NOT NULL,
    `userId` VARCHAR(36) NOT NULL,
    `teamId` VARCHAR(36) NOT NULL,
    `footballType` VARCHAR(10) NULL,
    `fieldName` VARCHAR(255) NULL,
    `fieldAddress` VARCHAR(500) NULL,
    `fieldLocation` VARCHAR(500) NULL,
    `country` VARCHAR(50) NULL,
    `state` VARCHAR(100) NULL,
    `fieldPrice` DECIMAL(10, 2) NULL,
    `matchDate` DATETIME(3) NULL,
    `league` VARCHAR(255) NULL,
    `description` TEXT NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'active',
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `match_requests_userId_idx`(`userId`),
    INDEX `match_requests_teamId_idx`(`teamId`),
    INDEX `match_requests_status_idx`(`status`),
    INDEX `match_requests_country_idx`(`country`),
    INDEX `match_requests_footballType_idx`(`footballType`),
    INDEX `match_requests_matchDate_idx`(`matchDate`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `matches` (
    `id` VARCHAR(36) NOT NULL,
    `matchRequestId` VARCHAR(36) NOT NULL,
    `team1Id` VARCHAR(36) NOT NULL,
    `team2Id` VARCHAR(36) NOT NULL,
    `userId1` VARCHAR(36) NOT NULL,
    `userId2` VARCHAR(36) NOT NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'pending',
    `finalDate` DATETIME(3) NULL,
    `finalAddress` VARCHAR(500) NULL,
    `finalPrice` DECIMAL(10, 2) NULL,
    `notes` TEXT NULL,
    `confirmedByUser1` BOOLEAN NOT NULL DEFAULT false,
    `confirmedByUser2` BOOLEAN NOT NULL DEFAULT false,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `matches_matchRequestId_key`(`matchRequestId`),
    INDEX `matches_team1Id_idx`(`team1Id`),
    INDEX `matches_team2Id_idx`(`team2Id`),
    INDEX `matches_userId1_idx`(`userId1`),
    INDEX `matches_userId2_idx`(`userId2`),
    INDEX `matches_status_idx`(`status`),
    INDEX `matches_finalDate_idx`(`finalDate`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `match_results` (
    `id` VARCHAR(36) NOT NULL,
    `matchId` VARCHAR(36) NOT NULL,
    `team1Score` INTEGER NOT NULL,
    `team2Score` INTEGER NOT NULL,
    `winnerId` VARCHAR(36) NULL,
    `createdById` VARCHAR(36) NULL,
    `verified` BOOLEAN NOT NULL DEFAULT false,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `match_results_matchId_key`(`matchId`),
    INDEX `match_results_matchId_idx`(`matchId`),
    INDEX `match_results_winnerId_idx`(`winnerId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `rankings` (
    `id` VARCHAR(36) NOT NULL,
    `teamId` VARCHAR(36) NOT NULL,
    `userId` VARCHAR(36) NOT NULL,
    `season` VARCHAR(20) NOT NULL,
    `footballType` VARCHAR(10) NULL,
    `country` VARCHAR(50) NULL,
    `position` INTEGER NOT NULL DEFAULT 0,
    `points` INTEGER NOT NULL DEFAULT 0,
    `gamesPlayed` INTEGER NOT NULL DEFAULT 0,
    `gamesWon` INTEGER NOT NULL DEFAULT 0,
    `gamesLost` INTEGER NOT NULL DEFAULT 0,
    `gamesDrawn` INTEGER NOT NULL DEFAULT 0,
    `goalsFor` INTEGER NOT NULL DEFAULT 0,
    `goalsAgainst` INTEGER NOT NULL DEFAULT 0,
    `goalDiff` INTEGER NOT NULL DEFAULT 0,
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `rankings_teamId_idx`(`teamId`),
    INDEX `rankings_userId_idx`(`userId`),
    INDEX `rankings_season_idx`(`season`),
    INDEX `rankings_points_idx`(`points`),
    INDEX `rankings_country_footballType_idx`(`country`, `footballType`),
    UNIQUE INDEX `rankings_teamId_season_footballType_country_key`(`teamId`, `season`, `footballType`, `country`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `teams` ADD CONSTRAINT `teams_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `match_requests` ADD CONSTRAINT `match_requests_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `match_requests` ADD CONSTRAINT `match_requests_teamId_fkey` FOREIGN KEY (`teamId`) REFERENCES `teams`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `matches` ADD CONSTRAINT `matches_matchRequestId_fkey` FOREIGN KEY (`matchRequestId`) REFERENCES `match_requests`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `matches` ADD CONSTRAINT `matches_team1Id_fkey` FOREIGN KEY (`team1Id`) REFERENCES `teams`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `matches` ADD CONSTRAINT `matches_team2Id_fkey` FOREIGN KEY (`team2Id`) REFERENCES `teams`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `matches` ADD CONSTRAINT `matches_userId1_fkey` FOREIGN KEY (`userId1`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `matches` ADD CONSTRAINT `matches_userId2_fkey` FOREIGN KEY (`userId2`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `match_results` ADD CONSTRAINT `match_results_matchId_fkey` FOREIGN KEY (`matchId`) REFERENCES `matches`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `match_results` ADD CONSTRAINT `match_results_winnerId_fkey` FOREIGN KEY (`winnerId`) REFERENCES `teams`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `rankings` ADD CONSTRAINT `rankings_teamId_fkey` FOREIGN KEY (`teamId`) REFERENCES `teams`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `rankings` ADD CONSTRAINT `rankings_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
